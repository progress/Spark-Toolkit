/*------------------------------------------------------------------------
    File        : SalesrepBE.cls
    Author(s)   : Code Wizard
    Created     : 12/12/17
    Notes       : Customized BE instance with AFP features available.
  ----------------------------------------------------------------------*/

@program FILE(name="SalesrepBE.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writedatasetBeforeImage="false").
@progress.service.resource FILE(name="salesrep", URI="/salesrep", schemaName="dsSalesrep", schemaFile="Sports/PASOEContent/WEB-INF/openedge/Common/salesrep.i").

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Business.Ordering.SalesrepBE inherits Spark.Core.Service.SparkEntity:

    {Common/salesrep.i}

    constructor public SalesrepBE ( ):
        ProDataSet = dataset dsSalesrep:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 1.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer Salesrep:handle, ?).
        ProDataSource = DataSourceArray.

        /* Skip-list entries for each table in dataset. Should be in temp-table order as defined in DataSet. */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create statement. */
        extent(SkipListArray) = 1.
        SkipListArray[1] = "".
        SkipList = SkipListArray.
    end constructor.


    method protected override character validateData ( input pcAction as character,
                                                       input-output dataset-handle phDataset ):
        define variable hTable as handle  no-undo.
        define variable hQuery as handle  no-undo.
        define variable lAvail as logical no-undo.
        define variable ix     as integer no-undo.

        if not valid-handle(phDataset) then return "".

        assign hTable = phDataset:get-top-buffer().

        create query hQuery.
        hQuery:set-buffers(hTable).
        hQuery:query-prepare(substitute('FOR EACH &1', hTable:name)).
        hQuery:query-open().
        lAvail = hQuery:get-first(share-lock).
        do while lAvail:
            do ix = 1 to hTable:num-fields:
                if hTable:row-state eq row-created then do:
                    /* If given a new record where SalesRep is 0, get next number. */
                    if hTable:buffer-field(ix):name eq "SalesRep" and
                       hTable:buffer-field(ix):buffer-value() eq "" then do:
                        hTable:error = true.
                        hTable:error-string = "No salesrep abbreviation given.".
                    end. /* SalesRep */
                end. /* Matching Row-State */
            end. /* field */
            lAvail = hQuery:get-next(share-lock).
        end. /* lAvail */

        return "".

        finally:
            hQuery:query-close() no-error.
            delete object hQuery no-error.
        end finally.
    end method. /* validateData */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json").
    @openapi.openedge.method.property(name="mappingType", value="AFP").
    @openapi.openedge.method.property(name="capabilities", value="filter,top,skip,id,sort,orderBy").
    method public void ReadSalesrep ( input filter as character, output dataset dsSalesrep ):
        define variable iNumRecs as int64 no-undo.
        super:ReadData(filter, iNumRecs, output dataset dsSalesrep by-reference).
    end method. /* ReadSalesrep */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="submit", URI="/submit", alias="submit", mediaType="application/json").
    method public void SubmitSalesrep ( input-output dataset dsSalesrep ):
        super:SubmitData(input-output dataset dsSalesrep by-reference).
    end method. /* SubmitSalesrep */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="count", URI="/count?filter=~{filter~}", alias="count", mediaType="application/json").
    method public void getCount ( input filter as character, output numRecs as integer ):
        assign numRecs = integer(super:getRecCount(filter)).
    end method. /* getCount */

end class.