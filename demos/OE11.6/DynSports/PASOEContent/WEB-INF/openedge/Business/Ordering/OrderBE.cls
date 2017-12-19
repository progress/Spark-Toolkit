/*------------------------------------------------------------------------
    File        : OrderBE.cls
    Author(s)   : Code Wizard
    Created     : 05/28/15
    Notes       : Customized BE instance with AFP features available.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Message.ErrorTypeEnum from propath.
using Spark.Core.Util.FieldInfo from propath.
using Spark.Core.Util.ForeignKey from propath.

block-level on error undo, throw.

class Business.Ordering.OrderBE inherits Spark.Core.Service.DynamicEntity:

    {Common/order.i}

    define public override property serviceURI as character
        initial "/web/pdo/ordering" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "order" no-undo get.
        protected set.

    define public override property primaryKeys as character
        initial "ttOrder.OrderNum,ttOrderLine.OrderNum" no-undo get.
        protected set.

    define public override property foreignKeys as character no-undo
        get():
            if foreignKeys eq "" then do:
                define variable oKey1 as ForeignKey no-undo.
                define variable oKeys as JsonArray  no-undo.

                assign oKey1 = new ForeignKey("ttSalesrepFK").
                oKey1:setForeignTable("salesrep.ttSalesrep").
                oKey1:addForeignField("SalesRep").
                oKey1:addLocalField("SalesRep").

                /* Create an array of keys. */
                assign oKeys = new JsonArray().
                oKeys:Add(oKey1).

                foreignKeys = string(oKeys:GetJsonText()).

                delete object oKey1 no-error.
                delete object oKeys no-error.
            end.
            return foreignKeys.
        end get.
        protected set.

    define public override property mappingType as character
        initial "AFP" no-undo get.
        protected set.

    define public override property capabilities as character
        initial "filter,id,orderBy,skip,sort,top" no-undo get.
        protected set.

    define public override property operations as character
        initial "CRUD,Submit" no-undo get.
        protected set.

    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getCount", "count", "get").

        /* Describe any properties to be added the entity tables. */
        define variable oFieldProps as FieldInfo no-undo.
        assign oFieldProps = new FieldInfo("dsOrder", "ttOrder").
        oFieldProps:addProperty("seq", "semanticType", "Internal").
        oFieldProps:addProperty("OrderNum", "editable", false).
        oFieldProps:makeRequired("CustNum"). /* Add "required" Validator */
        Spark.Core.Util.Annotate:describeFields(oFieldProps).
        delete object oFieldProps no-error.
    end method. /* initialize */

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


    method public override void readData ( input  filter  as character,
                                           output numRecs as int64,
                                           output dataset-handle phDataSet ):
        assign numRecs = filterData(filter).
        for each ttOrderLine share-lock:
            for first Item no-lock
                where Item.ItemNum eq ttOrderLine.ItemNum:
                assign ttOrderLine.ItemName = Item.ItemName.
            end. /* for first */
        end. /* for each */
        phDataSet:copy-dataset(ProDataSet).
    end method. /* readData */


    method public override void submitData ( input-output dataset-handle phDataSet ):
        super:submitData(input-output dataset-handle phDataSet).
        this-object:oResponse:addError("", ErrorTypeEnum:success, "Order successfully updated.").
    end method. /* submitData */


    method public void getCount ( input filter as character, output numRecs as int64 ):
        assign numRecs = filterData(filter).
    end method. /* getCount */

end class.