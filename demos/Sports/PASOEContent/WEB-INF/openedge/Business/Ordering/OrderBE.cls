/*------------------------------------------------------------------------
    File        : OrderBE.cls
    Author(s)   : Code Wizard
    Created     : 12/12/17
    Notes       : Customized BE instance with AFP features available.
  ----------------------------------------------------------------------*/

@program FILE(name="OrderBE.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="order", URI="/order", schemaName="dsOrder", schemaFile="Sports/PASOEContent/WEB-INF/openedge/Common/order.i").

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Business.Ordering.OrderBE inherits Spark.Core.Service.SparkEntity:

    {Common/order.i}

    constructor public OrderBE ( ):
        ProDataSet = dataset dsOrder:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 2.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer Order:handle, ?).
        create data-source DataSourceArray[2].
        DataSourceArray[2]:add-source-buffer(buffer OrderLine:handle, ?).
        ProDataSource = DataSourceArray.

        /* Skip-list entries for each table in dataset. Should be in temp-table order as defined in DataSet. */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create statement. */
        extent(SkipListArray) = 2.
        SkipListArray[1] = "".
        SkipListArray[2] = "".
        SkipList = SkipListArray.
    end constructor.


    method protected override character validateData ( input pcAction as character,
                                                       input-output dataset-handle phDataset ):
        define variable hTable as handle  no-undo.
        define variable hQuery as handle  no-undo.
        define variable lAvail as logical no-undo.
        define variable ix     as integer no-undo.

        if not valid-handle(phDataset) then return "".

        define buffer bOrder for Order.

        assign hTable = phDataset:get-top-buffer().

        create query hQuery.
        hQuery:set-buffers(hTable).
        hQuery:query-prepare(substitute('FOR EACH &1', hTable:name)).
        hQuery:query-open().
        lAvail = hQuery:get-first(share-lock).
        do while lAvail:
            do ix = 1 to hTable:num-fields:
                if hTable:row-state eq row-created then do:
                    /* If given a new record where OrderNum is 0, get next number. */
                    if hTable:buffer-field(ix):name eq "OrderNum" and
                       hTable:buffer-field(ix):buffer-value() eq 0 then do:
                        /* Assign a value to the table field. */
                        find last bOrder no-lock no-error.
                        if available bOrder then
                            assign hTable:buffer-field(ix):buffer-value() = bOrder.OrderNum + 1.
                    end. /* OrderNum */
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


    method public override void postRowFill ( input dataset-handle phDataset ):
        define variable hTableBuffer as handle no-undo.
        assign hTableBuffer = phDataset:get-buffer-handle(1).
        if valid-handle(hTableBuffer) then do:
            assign iSeq = iSeq + 1.
            hTableBuffer:buffer-field("seq"):buffer-value = iSeq.
            hTableBuffer:buffer-field("id"):buffer-value = string(hTableBuffer:rowid).

            find first Customer no-lock
                 where Customer.CustNum eq hTableBuffer:buffer-field("CustNum"):buffer-value no-wait no-error.
            if available Customer then
                assign hTableBuffer:buffer-field("CustName"):buffer-value = Customer.Name.
            else
                assign hTableBuffer:buffer-field("CustName"):buffer-value = string(hTableBuffer:buffer-field("CustNum"):buffer-value).

            find first SalesRep no-lock
                 where SalesRep.SalesRep eq hTableBuffer:buffer-field("SalesRep"):buffer-value no-wait no-error.
            if available SalesRep then
                assign hTableBuffer:buffer-field("SalesRepName"):buffer-value = Salesrep.RepName.
            else
                assign hTableBuffer:buffer-field("SalesRepName"):buffer-value = string(hTableBuffer:buffer-field("SalesRep"):buffer-value).
        end.
    end method. /* postRowFill */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json").
    @openapi.openedge.method.property(name="mappingType", value="AFP").
    @openapi.openedge.method.property(name="capabilities", value="filter,top,skip,id,sort,orderBy").
    method public void ReadOrder ( input filter as character, output dataset dsOrder ):
        define variable iNumRecs as int64 no-undo.
        super:ReadData(filter, iNumRecs, output dataset dsOrder by-reference).

        for each ttOrderLine share-lock:
            for first Item no-lock
                where Item.ItemNum eq ttOrderLine.ItemNum:
                assign ttOrderLine.ItemName = Item.ItemName.
            end. /* for first */
        end. /* for each */
    end method. /* ReadOrder */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="submit", URI="/submit", alias="submit", mediaType="application/json").
    method public void SubmitOrder ( input-output dataset dsOrder ):
        super:SubmitData(input-output dataset dsOrder by-reference).
    end method. /* SubmitOrder */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="count", URI="/count?filter=~{filter~}", alias="count", mediaType="application/json").
    method public void getCount ( input filter as character, output numRecs as integer ):
        assign numRecs = integer(super:getRecCount(filter)).
    end method. /* getCount */

end class.