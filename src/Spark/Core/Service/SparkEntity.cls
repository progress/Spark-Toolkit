 /*------------------------------------------------------------------------
    File        : SparkEntity
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Mar 17 09:31:42 EDT 2015
    Notes       :
    Resources for Error-Handling:
        https://wiki.progress.com/pages/viewpage.action?title=Error+handling+in+the+JSDO&spaceKey=oeagile#ErrorhandlingintheJSDO-HTTP200(JSONobjectwithprods:errors)
        https://documentation.progress.com/output/ua/OpenEdge_latest/index.html#page/dvpds/setting-and-using-error,-error-string,-and-rejec.html
        https://documentation.progress.com/output/pdo/#page/pdo%2Fgeterrors(-)-method.html
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.* from propath.
using Ccs.BusinessLogic.* from propath.
using Spark.Core.Manager.IClientContext from propath.
using Spark.Core.Manager.ICatalogManager from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Message.IContextMessage from propath.
using Spark.Core.Util.* from propath.

block-level on error undo, throw.
&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW

class Spark.Core.Service.SparkEntity inherits OpenEdge.BusinessLogic.BusinessEntity implements Spark.Core.Service.ISparkEntity use-widget-pool abstract:

    /**
     * Defined in OpenEdge.BusinessLogic.BusinessEntity as handle to DataSet in context:
     *   define protected property ProDataSet as handle no-undo get. set.
     */

    define protected property oClientContext as IClientContext no-undo
        get:
            if not valid-object(oClientContext) then
                assign oClientContext = cast(Ccs.Common.Application:SessionManager:CurrentClientContext, IClientContext).
            return oClientContext.
        end get.
        set.

    define protected property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.

    define protected property oCatalogManager as ICatalogManager no-undo
        get:
            if not valid-object(oCatalogManager) then do:
                /* Manager may be optionally created, so check for existence before using. */
                define variable oManager as Ccs.Common.IManager no-undo.
                assign oManager = Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)).
                if valid-object(oManager) then
                    assign oCatalogManager = cast(oManager, ICatalogManager).
            end.
            return oCatalogManager.
        end get.
        set.

    define protected variable iSeq as integer no-undo.

    define protected variable cRowField as character no-undo initial "id".
    define protected variable cSeqField as character no-undo initial "seq".

    define protected variable DataSourceArray as handle    no-undo extent.
    define protected variable SkipListArray   as character no-undo extent.

    /***** Public *****/

    /* Hold non-fatal messages for output (as determined by interface for class access). */
    define public property oContextMessage as IContextMessage no-undo
        get:
            if not valid-object(oContextMessage) then
                assign oContextMessage = new Spark.Core.Message.ContextMessage().
            return oContextMessage.
        end get.
        private set.

    /* To be used by DOHEventHandler to supply record count on response object for READ. */
    define public property LastCount as int64 no-undo get. protected set.

    constructor public SparkEntity ( ):
        /* Implement constructor in each class instance to provide a handle to ProDataSet! */
        super(input ?).
    end constructor.

    constructor public SparkEntity ( input dataset-handle phDataset ):
        super(input phDataset).
    end constructor.

    /***** Protected *****/

    method protected int64 filterData ( input pcFilter as character ):
        define variable hQuery         as handle    no-undo.
        define variable hDBBuffer      as handle    no-undo extent.
        define variable hTTBuffer      as handle    no-undo extent.
        define variable cFilter        as character no-undo initial "".
        define variable cRecID         as character no-undo initial "".
        define variable cSortBy        as character no-undo initial "".
        define variable cTableName     as character no-undo initial "".
        define variable iMaxRows       as int64     no-undo initial ?.
        define variable iStartRow      as int64     no-undo initial ?.
        define variable ix             as integer   no-undo.

        if not valid-handle(ProDataSet) then
            undo, throw new Progress.Lang.AppError("Warning: ProDataSet handle is not available.", 0).

        assign iSeq = 0. /* Reset record sequence on filter. */

        /* Set row field value according to catalog manager property. */
        if valid-object(oCatalogManager) and (oCatalogManager:IdProperty gt "") eq true then
            assign cRowField = oCatalogManager:IdProperty.
        else
            assign cRowField = "id". /* Default per JSDO spec. */

        getFilterParams( input  getFilter(pcFilter),
                         output cFilter,
                         output cSortBy,
                         output cRecID,
                         output iStartRow,
                         output iMaxRows ).

        if (cFilter gt "") eq true then
            oLoggingManager:logMessage(substitute("Filter: &1", cFilter), "ENTITY-DBG", 3).

        if (cSortBy gt "") eq true then
            oLoggingManager:logMessage(substitute("Sort: &1", cSortBy), "ENTITY-DBG", 3).

        ValidateDataSources().
        DataSetTools:emptyDataSet(ProDataSet).

        extent(hTTBuffer) = ProDataSet:num-buffers.
        do ix = 1 to ProDataSet:num-buffers:
            assign hTTBuffer[ix] = ProDataSet:get-buffer-handle(ix) no-error.
            if valid-handle(hTTBuffer[ix]) then do:
                hTTBuffer[ix]:empty-temp-table().
                hTTBuffer[ix]:attach-data-source(ProDataSource[ix]).
            end.
        end. /* ProDataSet */

        if not valid-handle(hTTBuffer[1]) then return 0.

        /* Set batch size per max rows to return. */
        if iMaxRows gt 0 then
            hTTBuffer[1]:batch-size = integer(iMaxRows).
        else do:
            if (cRecID gt "") eq true then
                hTTBuffer[1]:batch-size = 1.
            else
                hTTBuffer[1]:batch-size = 0.
        end.

        /* Prepare to fill Dataset via where phrase. */
        extent(hDBBuffer) = extent(ProDataSource).
        do ix = 1 to extent(ProDataSource):
            assign hDBBuffer[ix] = ProDataSource[ix]:get-source-buffer(1) no-error.
        end. /* ProDataSource */

        /* Set where string for first buffer. */
        ProDataSource[1]:fill-where-string = substitute("where &1 &2",
                                                        if (cFilter gt "") eq true then cFilter else "true",
                                                        cSortBy).

        /* Start fill operation at specified offset (by page or record). */
        if (iStartRow ne ? and iStartRow gt 0) then
            ProDataSource[1]:restart-row = integer(iStartRow + 1).
        else if (cRecID gt "") eq true then
            ProDataSource[1]:restart-rowid(1) = to-rowid((cRecID)).

        /* Fill dataset and set additional values as needed. */
        hTTBuffer[1]:set-callback("after-row-fill", "postRowFill", this-object).
        ProDataSet:fill().

        return getRecCount(cFilter, hDBBuffer[1]).

        finally:
            delete object hQuery no-error.

            if valid-handle(ProDataSet) and extent(hTTBuffer) ne ? then
            do ix = 1 to ProDataSet:num-buffers:
                if valid-handle(hTTBuffer[ix]) then
                    hTTBuffer[ix]:detach-data-source() no-error.
                delete object hTTBuffer[ix] no-error.
            end.

            if extent(hDBBuffer) ne ? then
            do ix = 1 to extent(hDBBuffer):
                delete object hDBBuffer[ix] no-error.
            end.
        end finally.
    end method. /* filterData */

    method final protected character getClassName ( ):
        return this-object:GetClass():TypeName.
    end method. /* getClassName */

    method protected JsonObject getFilter ( input pcRawFilter as longchar ):
        define variable oParser as ObjectModelParser no-undo.
        define variable oFilter as JsonObject        no-undo.

        /* Return the filter (default read property) as a JSON object. */
        if pcRawFilter ne ? and pcRawFilter begins "~{" then do:
            assign oParser = new ObjectModelParser().
            assign pcRawFilter = FormatTools:convertToUTF8(pcRawFilter).
            assign oFilter = cast(oParser:Parse(pcRawFilter), jsonObject).
            return oFilter.
        end.

        return ?.

        finally:
            delete object oParser no-error.
        end finally.
    end method. /* getFilter */

    method protected JsonArray getCriteria ( input pcRawFilter as longchar ):
        define variable oParser   as ObjectModelParser no-undo.
        define variable oFilter   as JsonObject        no-undo.
        define variable oCriteria as JsonArray         no-undo.

        /* Obtain filter criteria, if available as an array. */
        assign oFilter = getFilter(pcRawFilter).
        if valid-object(oFilter) then do:
            /* Utilizes a more open parser system, which can check the client
             * type as reported by the request. This way we can support many
             * UI criteria objects in a more dynamic way. This will also mean
             * creation of a better structure for the parser classes.
             */
            define variable oParse as IClientParse no-undo.
            if oFilter:Has("client") then do:
                case oFilter:GetCharacter("client"):
                    when "KendoUI" then
                        /* Parse from KendoUI criteria object into a standard ABL "where" phrase. */
                        assign oParse = new KendoParse(input ProDataSet).
                end case.
            end. /* Has Client */
            else
                /* Default to JavascriptFilterPattern, using a plain-text "where" phrase. */
                assign oParse = new JFPParse(input ProDataSet).

            /* Default name for Read Filter is just "filter" by JSDO specs. */
            define variable cReadFilter as character no-undo initial "filter".
            if valid-object(oCatalogManager) then
                assign cReadFilter = oCatalogManager:ReadFilter.

            /* Object must contain a JSON property named according to catalog ReadFilter. */
            if oFilter:Has(cReadFilter) and not oFilter:IsNull(cReadFilter) and
               oFilter:GetType(cReadFilter) eq JsonDataType:object then
                return oParse:getRawCriteria(oFilter:GetJsonObject(cReadFilter)).
        end. /* valid-object(oFilter) */

        return (new JsonArray()).

        finally:
            delete object oParser no-error.
        end finally.
    end method. /* getCriteria */

    method protected void getFilterParams ( input  poFilter as JsonObject,
                                            output pcFilter as character,
                                            output pcSortBy as character,
                                            output pcRecID  as character,
                                            output piStart  as int64,
                                            output piMaxRow as int64 ):
        assign /* Defaults */
            pcFilter = ""
            pcSortBy = ""
            pcRecID  = ""
            piStart  = ?
            piMaxRow = ?
            .

        if valid-object(poFilter) then do {&THROW}:
            /* Utilizes a more open parser system, which can check the client
             * type as reported by the request. This way we can support many
             * UI criteria objects in a more dynamic way. This will also mean
             * creation of a better structure for the parser classes.
             */
            define variable oParse as IClientParse no-undo.
            if poFilter:Has("client") then do:
                case poFilter:GetCharacter("client"):
                    when "KendoUI" then
                        /* Parse from KendoUI criteria object into a standard ABL "where" phrase. */
                        assign oParse = new KendoParse(input ProDataSet).
                end case.
            end. /* Has Client */
            else
                /* Default to JavascriptFilterPattern, using a plain-text "where" phrase. */
                assign oParse = new JFPParse(input ProDataSet).

            /* Default name for Read Filter is just "filter" by JSDO specs. */
            define variable cReadFilter as character no-undo initial "filter".
            if valid-object(oCatalogManager) then
                assign cReadFilter = oCatalogManager:ReadFilter.

            /* Filter Criteria */
            if poFilter:Has(cReadFilter) and not poFilter:IsNull(cReadFilter) and
               poFilter:GetType(cReadFilter) eq JsonDataType:object /* Must be a JSON object! */ then
                assign pcFilter = oParse:buildWherePhrase(poFilter:GetJsonObject(cReadFilter)) no-error.
            else if poFilter:Has("ablFilter") and not poFilter:IsNull("ablFilter") then
                assign pcFilter = poFilter:GetCharacter("ablFilter") no-error.

            /* Record ID */
            if poFilter:Has("id") and not poFilter:IsNull("id") then
                assign pcRecID = poFilter:GetCharacter("id") no-error.

            /* Paging */
            if poFilter:Has("skip") and not poFilter:IsNull("skip") then
                assign piStart = poFilter:GetInt64("skip") no-error.

            /* Sorting */
            if poFilter:Has("sort") and not poFilter:IsNull("sort") then
                assign pcSortBy = oParse:buildSortPhrase(poFilter:GetJsonArray("sort")) no-error.
            else if poFilter:Has("orderBy") and not poFilter:IsNull("orderBy") then do:
                if poFilter:GetType("orderBy") eq JsonDataType:array then
                    assign pcSortBy = oParse:buildSortPhrase(poFilter:GetJsonArray("orderBy")) no-error.
                else
                    assign pcSortBy = oParse:buildSortPhrase(poFilter:GetCharacter("orderBy")) no-error.
            end.

            /* Results per Page */
            if poFilter:Has("top") and not poFilter:IsNull("top") then
                assign piMaxRow = poFilter:GetInt64("top") no-error.

            finally:
                delete object oParse no-error.
            end finally.
        end.

        if pcRecID eq "?" then assign pcRecID = "".
    end method. /* getFilterParams */

    method public void getDataset ( output dataset-handle phDataset ):
        phDataset = ProDataSet. /* Return current dataset handle. */
    end method. /* getDataset */

    method public IGetDataResponse getData ( poRequest as IGetDataRequest,
                                             output dataset-handle phDataSet ):
    end method. /* getData */

    method public IGetResultCountResponse getResultCount ( poRequest as IGetDataRequest ):
    end method. /* getResultCount */

    method public Progress.Lang.Object updateData ( input-output dataset-handle phDataSet,
                                                    poUpdateDataRequest as IUpdateDataRequest ):
        /**
         * Should act like the "submit" operation with CUD mode
         * being determined by the dataset before/after data.
         */
    end method. /* updateData */

    method protected int64 getRecCount ( input pcRawFilter as character ):
        define variable hDBBuffer  as handle    no-undo extent.
        define variable cFilter    as character no-undo initial "".
        define variable cRecID     as character no-undo initial "".
        define variable cSortBy    as character no-undo initial "".
        define variable cTableName as character no-undo initial "".
        define variable iMaxRows   as int64     no-undo initial ?.
        define variable iStartRow  as int64     no-undo initial ?.
        define variable ix         as integer   no-undo.

        extent(hDBBuffer) = extent(ProDataSource).
        do ix = 1 to extent(ProDataSource):
            assign hDBBuffer[ix] = ProDataSource[ix]:get-source-buffer(1) no-error.
        end. /* ProDataSource */

        this-object:getFilterParams( input  this-object:getFilter(pcRawFilter),
                                     output cFilter,
                                     output cSortBy,
                                     output cRecID,
                                     output iStartRow,
                                     output iMaxRows ).

        return this-object:getRecCount(cFilter, hDBBuffer[1]).

        finally:
            do ix = 1 to extent(hDBBuffer):
                delete object hDBBuffer[ix] no-error.
            end.
        end finally.
    end method. /* getRecCount */

    method protected int64 getRecCount ( input pcFilter as character,
                                         input phTable  as handle ):
        define variable hQuery as handle no-undo.
        define variable iCount as int64  no-undo initial 0.

        if not valid-handle(phTable) then return 0.

        if (pcFilter gt "") ne true then
            assign pcFilter = "where true".

        if not pcFilter begins "where" then
            assign pcFilter = "where " + pcFilter.

        create query hQuery.
        hQuery:set-buffers(phTable).
        hQuery:query-prepare(substitute("preselect each &1 &2", phTable:name, pcFilter)).
        hQuery:query-open.
        assign iCount = hQuery:num-results.
        hQuery:query-close().

        return iCount.

        finally:
            delete object hQuery no-error.
        end finally.
    end method. /* getRecCount */

    method protected void preCommitLogic ( input pcAction as character,
                                           input-output dataset-handle phDataSet ):
    end method. /* preCommitLogic */

    method protected void postCommitLogic ( input pcAction as character,
                                            input-output dataset-handle phDataSet ):
    end method. /* postCommitLogic */

    method protected void postFetchRecord ( ):
    end method. /* postFetchRecord */

    method protected character validateData ( input pcAction as character,
                                              input-output dataset-handle phDataSet ):
    end method. /* validateData */

    /******* Public *******/

    method public void initialize ( ):
    end method. /* initialize */

    method public void dispose ( ):
        define variable ix as integer no-undo.
        do ix = 1 to extent(DataSourceArray):
            delete object DataSourceArray[ix] no-error.
        end.

        delete object ProDataSet no-error.
    end method. /* dispose */

    method public void postRowFill ( input dataset-handle phDataset ):
        /* By default, specify Sequence and ROWID on top table. */
        define variable hTableBuffer as handle no-undo.
        assign hTableBuffer = phDataset:get-buffer-handle(1).
        if valid-handle(hTableBuffer) then do:
            assign iSeq = iSeq + 1.
            hTableBuffer:buffer-field(cSeqField):buffer-value = iSeq.
            hTableBuffer:buffer-field(cRowField):buffer-value = string(hTableBuffer:rowid).
        end. /* valid-handle */
        delete object hTableBuffer no-error.
    end method. /* postRowFill */

    method protected override void readData ( input pcRawFilter as character ):
        this-object:LastCount = this-object:filterData(pcRawFilter).
    end method. /* readData */

    method public void readData ( input  filter  as character,
                                  output numRecs as int64,
                                  output dataset-handle phDataSet ):
        if not valid-handle(ProDataSet) and valid-handle(phDataSet) then
            assign ProDataSet = phDataSet. /* Ensure proper handle is set. */

        /* Custom readData that uses filter and returns record count with dataset. */
        this-object:LastCount = this-object:filterData(filter).
        assign numRecs = this-object:LastCount. /* Get record count */
        postFetchRecord(). /* Extra fetch logic. */

        /* If handles are different, copy the internal dataset back to the param. */
        if phDataSet ne ProDataSet then
            phDataSet:copy-dataset(ProDataSet).

        finally:
            delete object phDataSet no-error.
        end finally.
    end method. /* readData */

    method public override void createData ( input-output dataset-handle phDataSet ):
        if valid-handle(phDataSet) then
            assign ProDataSet = phDataSet. /* Ensure proper handle is set. */

        validateData(input "Create", input-output dataset-handle phDataSet by-reference).
        preCommitLogic(input "Create", input-output dataset-handle phDataSet by-reference).
        super:CreateData(input-output dataset-handle phDataSet by-reference).
        postCommitLogic(input "Create", input-output dataset-handle phDataSet by-reference).

        finally:
            delete object phDataSet no-error.
        end finally.
    end method. /* createData */

    method public override void updateData ( input-output dataset-handle phDataSet ):
        if valid-handle(phDataSet) then
            assign ProDataSet = phDataSet. /* Ensure proper handle is set. */

        validateData(input "Update", input-output dataset-handle phDataSet by-reference).
        preCommitLogic(input "Update", input-output dataset-handle phDataSet by-reference).
        super:UpdateData(input-output dataset-handle phDataSet by-reference).
        postCommitLogic(input "Update", input-output dataset-handle phDataSet by-reference).

        finally:
            delete object phDataSet no-error.
        end finally.
    end method. /* updateData */

    method public override void deleteData ( input-output dataset-handle phDataSet ):
        if valid-handle(phDataSet) then
            assign ProDataSet = phDataSet. /* Ensure proper handle is set. */

        validateData(input "Delete", input-output dataset-handle phDataSet by-reference).
        preCommitLogic(input "Delete", input-output dataset-handle phDataSet by-reference).
        super:DeleteData(input-output dataset-handle phDataSet by-reference).
        postCommitLogic(input "Delete", input-output dataset-handle phDataSet by-reference).

        finally:
            delete object phDataSet no-error.
        end finally.
    end method. /* deleteData */

    method public void submitData ( input-output dataset-handle phDataSet ):
        validateData(input "Submit", input-output dataset-handle phDataSet by-reference).

        if valid-handle(phDataSet) then
            assign ProDataSet = phDataSet. /* Ensure proper handle is set. */

        preCommitLogic(input "Submit", input-output dataset-handle phDataSet by-reference).
        super:Submit(input-output dataset-handle phDataSet by-reference).
        postCommitLogic(input "Submit", input-output dataset-handle phDataSet by-reference).

        finally:
            delete object phDataSet no-error.
        end finally.
    end method. /* submitData */

end class.