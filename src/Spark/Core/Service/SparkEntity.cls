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
using OpenEdge.BusinessLogic.* from propath.
using OpenEdge.BusinessLogic.Filter.* from propath.
using OpenEdge.BusinessLogic.Query.* from propath.
using Progress.Reflect.Method from propath.
using Progress.Lang.ParameterList from propath.
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

    /***** Public | Properties, Constructor, Destructor *****/

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

    method final protected character getClassName ( ):
        return this-object:GetClass():TypeName.
    end method. /* getClassName */

    method protected JsonObject getFilterObject ( input pcRawFilter as longchar ):
        define variable oParser as ObjectModelParser no-undo.
        define variable oFilter as JsonObject        no-undo.

        /* Return the filter (default read property) as a JSON object. */
        if pcRawFilter ne ? and pcRawFilter begins "~{" then do:
            assign oParser = new ObjectModelParser().
            assign pcRawFilter = FormatTools:convertToUTF8(pcRawFilter).
            assign oFilter = cast(oParser:Parse(pcRawFilter), JsonObject).
            return oFilter. /* Return the parsed JSON filter object. */
        end. /* non-empty string beginning with { */

        return new JsonObject(). /* Return an empty JSON object. */

        finally:
            if valid-object(oParser) then
                delete object oParser no-error.
        end finally.
    end method. /* getFilter */

    method protected int64 filterData ( input pcFilter as character ):
        define variable oFilter        as JsonObject          no-undo.
        define variable hDataSet       as handle              no-undo.
        define variable oFilterBuilder as FilterParserBuilder no-undo.
        define variable oDataRequest   as IGetDataRequest     no-undo.

        if not valid-handle(ProDataSet) then
            undo, throw new Progress.Lang.AppError("Warning: ProDataSet handle is not available.", 0).

        /* Extract a JSON object from the incoming "filter" data. */
        assign oFilter = this-object:getFilterObject(pcFilter).

        /**
         * The purpose of the FilterParserBuilder is to normalize the creation of criteria data
         * such that no matter what client-side pattern was used to pass the data it will appear
         * within a consistent OOP pattern for parsing. At this level there is no concern about
         * mapping of fields (serialize-name) or confirming schema (datatype, etc.), simply the
         * creation of the necessary query clauses and any sort options.
         */

        /* First, check an obvious mapping type as provided by the client (easiest detection). */
        if oFilter:Has("mappingType") and
           oFilter:GetType("mappingType") eq JsonDataType:string then
            assign oFilterBuilder = FilterParserBuilder:Build(oFilter:GetCharacter("mappingType")).
        else if oFilter:Has("client") and
                oFilter:GetType("client") eq JsonDataType:string then
            /* Next, try checking for any given "client" type and parse using that value. */
            case oFilter:GetCharacter("client"):
                when "Kendo" or
                when "KendoUI" then
                    /* Parse from KendoUI criteria object passed as filter data. */
                    assign oFilterBuilder = FilterParserBuilder:Build("kendo").
            end case.
        else
            /* Last, let the filter parser builder figure out the mapping. */
            assign oFilterBuilder = FilterParserBuilder:Build(oFilter).

        /* As a last resort, just create a simple ABL filter. */
        if not valid-object(oFilterBuilder) then
            assign oFilterBuilder = FilterParserBuilder:Build("ABL").

        /* Use the filter builder to create a valid data request from the filter data. */
        if valid-object(oFilterBuilder) then
        do on error undo, throw:
            /* Assume filtering on the top temp-table name (used for schema info as well). */
            oFilterBuilder:TableName(ProDataSet:get-top-buffer(1):name).
            assign oDataRequest = oFilterBuilder:Parser:Parse(oFilter).
        end.

        /* Utilizes the method as expected by the CCS IBusinessEntity interface. */
        if valid-object(oDataRequest) then
            this-object:getData(oDataRequest, output dataset-handle hDataSet).

        /* Utilizes the method as expected by the CCS IBusinessEntity interface. */
        define variable oCountResponse as IGetResultCountResponse no-undo.
        if valid-object(oDataRequest) then
            assign oCountResponse = this-object:getResultCount(oDataRequest).

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Error Filtering Data:", err, "ENTITY-ERR", 1).
        end catch.
        finally:
            define variable iCount as int64 no-undo initial 0.

            if valid-object(oCountResponse) then do:
                assign iCount = if valid-object(oCountResponse:ResultCounts[1])
                                then oCountResponse:ResultCounts[1]:NumResults else 0.
                delete object oCountResponse no-error.
            end.

            if valid-object(oDataRequest) then
                delete object oDataRequest no-error.

            if valid-object(oFilter) then
                delete object oFilter no-error.

            return iCount. /* Always return the count, whether on success or failure. */
        end finally.
    end method. /* filterData */

    method protected character getFilterOnly ( input poFilter as JsonObject ):
        define variable oDataRequest   as IGetDataRequest     no-undo.
        define variable oFilterBuilder as FilterParserBuilder no-undo.
        define variable oQueryBuilder  as QueryBuilder        no-undo.
        define variable cFilter        as character           no-undo initial "".

        if valid-object(poFilter) then do:
            if poFilter:Has("mappingType") and
               poFilter:GetType("mappingType") eq JsonDataType:string then
                assign oFilterBuilder = FilterParserBuilder:Build(poFilter:GetCharacter("mappingType")).
            else if poFilter:Has("client") and
                    poFilter:GetType("client") eq JsonDataType:string then
                /* Next, try checking for any given "client" type and parse using that value. */
                case poFilter:GetCharacter("client"):
                    when "Kendo" or
                    when "KendoUI" then
                        /* Parse from KendoUI criteria object passed as filter data. */
                        assign oFilterBuilder = FilterParserBuilder:Build("kendo").
                end case.
            else
                /* Last, let the filter parser builder figure out the mapping. */
                assign oFilterBuilder = FilterParserBuilder:Build(poFilter).

            /* As a last resort, just create a simple ABL filter. */
            if not valid-object(oFilterBuilder) then
                assign oFilterBuilder = FilterParserBuilder:Build("ABL").

            /* Utilize the FilterBuilder and QueryBuilder to generate a "where" phrase. */
            oFilterBuilder:TableName(ProDataSet:get-top-buffer(1):name).
            assign oDataRequest = oFilterBuilder:Parser:Parse(poFilter).
            assign oQueryBuilder = new QueryBuilder().
            oQueryBuilder:BuildQueryString(oDataRequest, ProDataSet).

            /**
             * Only need the top table's query string for this operation.
             * Reason: This must begin with a "where" and is only applicable
             * to one table when the dynamic query does a "preselect each".
             */
            assign cFilter = oDataRequest:TableRequests[1]:QueryString.
        end. /* valid-object */

        finally:
            delete object oDataRequest no-error.
            delete object oFilterBuilder no-error.
            delete object oQueryBuilder no-error.

            return cFilter.
        end finally.
    end method. /* getFilterOnly */

    method protected int64 getRecCount ( input pcRawFilter as character ):
        define variable cFilter as character no-undo initial "".

        /* Obtain a valid query phrase from the available filter data. */
        assign cFilter = this-object:getFilterOnly(this-object:getFilterObject(pcRawFilter)).

        /* Run the filter on the top table in the available datasource. */
        return this-object:getRecCount(cFilter, ProDataSource[1]:get-source-buffer(1)).
    end method. /* getRecCount */

    method protected int64 getRecCount ( input pcFilter as character,
                                         input phTable  as handle ):
        define variable hQuery as handle no-undo.
        define variable iCount as int64  no-undo initial 0.

        if not valid-handle(phTable) then return 0.

        create query hQuery.
        hQuery:set-buffers(phTable).
        hQuery:query-prepare(substitute("preselect each &1 &2", phTable:name, pcFilter)).
        hQuery:query-open.
        assign iCount = hQuery:num-results.

        finally:
            if valid-handle(hQuery) then do:
                hQuery:query-close().
                delete object hQuery no-error.
            end.

            return iCount.
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

    /******* Public | IService Methods *******/

    method public void initialize ( ):
    end method. /* initialize */

    method public void dispose ( ):
        define variable ix as integer no-undo.

        if extent(DataSourceArray) ne ? and
           extent(DataSourceArray) ge 1 then
        do ix = 1 to extent(DataSourceArray):
            if valid-object(DataSourceArray[ix]) then
                delete object DataSourceArray[ix] no-error.
        end.

        if valid-object(ProDataSet) then
            delete object ProDataSet no-error.
    end method. /* dispose */

    /******* Public | Helper Methods *******/

    method public void getDataset ( output dataset-handle phDataset ):
        phDataset = ProDataSet. /* Return current dataset handle. */
    end method. /* getDataset */

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

    /******* Public | Legacy CRUD+Submit (Create, Read, Update, Delete, Submit) *******/

    method public void readData ( input  filter  as character,
                                  output numRecs as int64,
                                  output dataset-handle phDataSet ):
        /**
         * Custom filterData method which expects the given filter data and returns a record count with dataset.
         * Here, the "filter" is a stringified JSON object which must be parsed to extract any query/sort data.
         */
        this-object:LastCount = this-object:filterData(filter).
        assign numRecs = this-object:LastCount. /* Get record count. */

        /* If handles are different, copy the internal dataset back to the param. */
        if valid-handle(phDataSet) and valid-handle(ProDataSet) then do:
            if phDataSet ne ProDataSet then
                phDataSet:copy-dataset(ProDataSet).
        end. /* valid-handle */

        finally:
            delete object phDataSet no-error.
        end finally.
    end method. /* readData */

    method public override void createData ( input-output dataset-handle phDataSet ):
        if valid-handle(phDataSet) then
            assign ProDataSet = phDataSet. /* Ensure proper handle is set. */

        this-object:validateData(input "Create", input-output dataset-handle phDataSet by-reference).
        this-object:preCommitLogic(input "Create", input-output dataset-handle phDataSet by-reference).
        if not phDataset:error then do:
            /* Do not attempt to proceed with modification if an error exists. */
            super:CreateData(input-output dataset-handle phDataSet by-reference).
            this-object:postCommitLogic(input "Create", input-output dataset-handle phDataSet by-reference).
        end. /* no error on dataset */

        finally:
            delete object phDataSet no-error.
        end finally.
    end method. /* createData */

    method public override void updateData ( input-output dataset-handle phDataSet ):
        if valid-handle(phDataSet) then
            assign ProDataSet = phDataSet. /* Ensure proper handle is set. */

        this-object:validateData(input "Update", input-output dataset-handle phDataSet by-reference).
        this-object:preCommitLogic(input "Update", input-output dataset-handle phDataSet by-reference).
        if not phDataset:error then do:
            /* Do not attempt to proceed with modification if an error exists. */
            super:UpdateData(input-output dataset-handle phDataSet by-reference).
            this-object:postCommitLogic(input "Update", input-output dataset-handle phDataSet by-reference).
        end. /* no error on dataset */

        finally:
            delete object phDataSet no-error.
        end finally.
    end method. /* updateData */

    method public override void deleteData ( input-output dataset-handle phDataSet ):
        if valid-handle(phDataSet) then
            assign ProDataSet = phDataSet. /* Ensure proper handle is set. */

        this-object:validateData(input "Delete", input-output dataset-handle phDataSet by-reference).
        this-object:preCommitLogic(input "Delete", input-output dataset-handle phDataSet by-reference).
        if not phDataset:error then do:
            /* Do not attempt to proceed with modification if an error exists. */
            super:DeleteData(input-output dataset-handle phDataSet by-reference).
            this-object:postCommitLogic(input "Delete", input-output dataset-handle phDataSet by-reference).
        end. /* no error on dataset */

        finally:
            delete object phDataSet no-error.
        end finally.
    end method. /* deleteData */

    method public void submitData ( input-output dataset-handle phDataSet ):
        define variable oRequest  as IUpdateDataRequest   no-undo.
        define variable oResponse as Progress.Lang.Object no-undo.

        /* Utilizes the method as expected by the CCS IUpdatableBusinessEntity interface. */
        assign oRequest = new UpdateDataRequest(). /* Create new, empty request object. */
        assign oResponse = this-object:updateData(input-output dataset-handle phDataSet, oRequest).

        finally:
            delete object phDataSet no-error.
            delete object oRequest no-error.
            delete object oResponse no-error.
        end finally.
    end method. /* submitData */

    /******* Public | CCS-compliant Read, Count, and Update (aka. Submit) *******/

    method public IGetDataResponse getData ( input  poRequest as IGetDataRequest,
                                             output dataset-handle phDataSet ):
        define variable hDBBuffer     as handle        no-undo extent.
        define variable hTTBuffer     as handle        no-undo extent.
        define variable cQueryString  as character     no-undo.
        define variable oMethod       as Method        no-undo.
        define variable oParams       as ParameterList no-undo.
        define variable oQueryBuilder as QueryBuilder  no-undo.
        define variable ix            as integer       no-undo.

        assign iSeq = 0. /* Reset record sequence on read operation. */

        if not valid-handle(ProDataSet) then
            undo, throw new Progress.Lang.AppError("Warning: ProDataSet handle is not available.", 0).

        if not valid-handle(ProDataSet) and valid-handle(phDataSet) then
            assign ProDataSet = phDataSet. /* Ensure proper handle is set. */

        /* Set row field value according to catalog manager property. */
        if valid-object(oCatalogManager) and (oCatalogManager:IdProperty gt "") eq true then
            assign cRowField = oCatalogManager:IdProperty.
        else
            assign cRowField = "id". /* Default per JSDO spec. */

        this-object:ValidateDataSources().
        DataSetTools:emptyDataSet(ProDataSet).

        /* Attach data sources for each table buffer. */
        extent(hTTBuffer) = ProDataSet:num-buffers.
        do ix = 1 to ProDataSet:num-buffers:
            assign hTTBuffer[ix] = ProDataSet:get-buffer-handle(ix) no-error.

            if valid-handle(hTTBuffer[ix]) then do:
                hTTBuffer[ix]:empty-temp-table().
                hTTBuffer[ix]:attach-data-source(ProDataSource[ix]).
            end.
        end. /* ProDataSet */

        /* If no valid first temp-table buffer, just leave. */
        if not valid-handle(hTTBuffer[1]) then return ?.

        /* Set parameters for a BuildQueryString method with appropriate datatypes/values. */
        oParams = new ParameterList(4).
        oParams:SetParameter(1, "class Ccs.BusinessLogic.IGetDataTableRequest", "input", ?).
        oParams:SetParameter(2, "logical", "input", true).
        oParams:SetParameter(3, "logical", "input", true).
        oParams:SetParameter(4, "handle", "input", ?).

        /**
         * Attempt to obtain a particular method via class reflection, which will indicate
         * if a newer QueryBuilder class is present which supports enhanced methods.
         */
        assign oMethod = get-class(QueryBuilder):GetMethod("BuildQueryString", oParams).

        /* Prepare a QueryBuilder class to convert the request object into a valid "where" phrases. */
        assign oQueryBuilder = new QueryBuilder().

        /* Needs to be called once prior to filling the where-string on each data source. */
        /* Only necessary if the newer 4-parameter BuildQueryString method isn't present. */
        if not valid-object(oMethod) then
            assign cQueryString = oQueryBuilder:BuildQueryString(poRequest, ProDataSet).

        /* Prepare to fill Dataset via where phrase from the table request. */
        extent(hDBBuffer) = extent(ProDataSource).
        do ix = 1 to extent(ProDataSource):
            assign hDBBuffer[ix] = ProDataSource[ix]:get-source-buffer(1) no-error.

            if extent(poRequest:TableRequests) ge ix and
               valid-object(poRequest:TableRequests[ix]) and
               valid-object(hTTBuffer[ix]) then do:
                if valid-object(oMethod) then do:
                    /**
                     * Newer method, which more intelligently builds a query string for the given table request and buffer.
                     * This combines the natural query for child tables with a data-relation together with the user's query. 
                     */
                    oParams:SetParameter(1, "class Ccs.BusinessLogic.IGetDataTableRequest", "input", poRequest:TableRequests[ix]).
                    oParams:SetParameter(4, "handle", "input", hTTBuffer[ix]).
                    ProDataSource[ix]:fill-where-string = oMethod:Invoke(oQueryBuilder, oParams).
                end.
                else do:
                    /* Use the older method, which uses a pre-built QueryString for the Pro-Dataset. */
                    if poRequest:TableRequests[ix]:QueryString gt "" then
                        ProDataSource[ix]:fill-where-string = poRequest:TableRequests[ix]:QueryString.
                    else if cQueryString begins "each" and cQueryString matches "*where*" then
                        ProDataSource[ix]:fill-where-string = substring(cQueryString, index(cQueryString, "where")).
                    else
                        ProDataSource[ix]:fill-where-string = cQueryString.
                end.
 
                /* Set batch size and max rows to return, or use paging context if available. */
                if poRequest:TableRequests[ix]:NumRecords gt 0 then
                    hTTBuffer[ix]:batch-size = integer(poRequest:TableRequests[ix]:NumRecords).
                else do:
                    if (poRequest:TableRequests[ix]:PagingContext gt "") eq true then
                        hTTBuffer[ix]:batch-size = 1.
                    else
                        hTTBuffer[ix]:batch-size = 0.
                end. /* NumRecords = 0 */

                /* Echo the current query phrase to the log if debugging is enabled. */
                oLoggingManager:logMessage(substitute("Query: &1", ProDataSource[ix]:fill-where-string), "ENTITY-DBG", 3).

                /* Start fill operation at specified offset (by page or record) when supplied. */
                if (poRequest:TableRequests[ix]:Skip ne ? and poRequest:TableRequests[ix]:Skip gt 0) then
                    ProDataSource[ix]:restart-row = integer(poRequest:TableRequests[ix]:Skip + 1).
                else if (poRequest:TableRequests[ix]:PagingContext gt "") eq true then
                    ProDataSource[ix]:restart-rowid(1) = to-rowid((poRequest:TableRequests[ix]:PagingContext)).
            end. /* valid-object (TableRequests) */
        end. /* ProDataSource */

        /* Fill dataset and set additional record values via the callback on the top table as needed. */
        hTTBuffer[1]:set-callback("after-row-fill", "postRowFill", this-object).
        ProDataSet:fill(). /* Where the magic happens... */

        this-object:postFetchRecord(). /* Perform any extra fetch logic on the dataset overall. */

        /**
         * Prepare a new response object to hold the result count any any other data.
         * The ProDataSet should contain the actual results (records) at this point.
         */
        define variable oResponse as IGetDataResponse no-undo.
        assign oResponse = new GetDataResponse().
        return oResponse.

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Error Getting Data:", err, "ENTITY-ERR", 1).
        end catch.
        finally:
            delete object oQueryBuilder no-error.

            if valid-handle(ProDataSet) and extent(hTTBuffer) ne ? then
            do ix = 1 to ProDataSet:num-buffers:
                if valid-handle(hTTBuffer[ix]) then do:
                    hTTBuffer[ix]:detach-data-source() no-error.
                    delete object hTTBuffer[ix] no-error.
                end.
            end.

            if extent(hDBBuffer) ne ? then
            do ix = 1 to extent(hDBBuffer):
                delete object hDBBuffer[ix] no-error.
            end.
        end finally.
    end method. /* getData */

    method public IGetResultCountResponse getResultCount ( input poRequest as IGetDataRequest ):
        define variable oCount    as GetTableResultCountResponse no-undo.
        define variable oResponse as GetResultCountResponse      no-undo.

        assign /* Create the main response, and the count object to be held within. */
            oResponse = new GetResultCountResponse()
            oCount    = new GetTableResultCountResponse(poRequest:TableRequests[1]:TableName)
            .

        /**
         * By default this call works only against the primary table on the dataset,
         * as anything which needs a record count may be based on this structure.
         */
        oCount:NumResults = this-object:getRecCount(poRequest:TableRequests[1]:QueryString,
                                                    ProDataSource[1]:get-source-buffer(1)).

        /* Returns only the primary table count. */
        extent(oResponse:ResultCounts) = 1.
        assign oResponse:ResultCounts[1] = oCount.

        return oResponse.
    end method. /* getResultCount */

    method public Progress.Lang.Object updateData ( input-output dataset-handle phDataSet,
                                                    input        poUpdateDataRequest as IUpdateDataRequest ):
        this-object:validateData(input "Submit", input-output dataset-handle phDataSet by-reference).

        if valid-handle(phDataSet) then
            assign ProDataSet = phDataSet. /* Ensure proper handle is set. */

        /**
         * Note: poUpdateDataRequest is currently ignored by this implementation.
         * Override this method if you wish to utilize the object for processing.
         */

        /**
         * Should act like the "submit" operation with CUD mode
         * being determined by the dataset's before/after data.
         */
        preCommitLogic(input "Submit", input-output dataset-handle phDataSet by-reference).

        if not phDataset:error then do:
            /* Do not attempt to proceed with modification if an error exists. */
            super:Submit(input-output dataset-handle phDataSet by-reference).
            postCommitLogic(input "Submit", input-output dataset-handle phDataSet by-reference).
        end. /* no error on dataset */

        /* The return value may be any valid Progress object. */
        define variable oResponse as Progress.Lang.Object no-undo.
        assign oResponse = new Progress.Lang.Object().

        return oResponse.
    end method. /* updateData */

end class.