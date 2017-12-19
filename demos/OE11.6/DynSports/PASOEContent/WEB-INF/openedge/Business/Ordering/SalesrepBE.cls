/*------------------------------------------------------------------------
    File        : SalesrepBE.cls
    Author(s)   : Code Wizard
    Created     : 03/02/15
    Notes       : Customized BE instance with AFP features available.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Util.FieldInfo from propath.
using Spark.Core.Util.ForeignKey from propath.

block-level on error undo, throw.

class Business.Ordering.SalesrepBE inherits Spark.Core.Service.DynamicEntity:

    {Common/salesrep.i}

    define public override property serviceURI as character
        initial "/web/pdo/ordering" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "salesrep" no-undo get.
        protected set.

    define public override property primaryKeys as character
        initial "ttSalesRep.SalesRep" no-undo get.
        protected set.

    define public override property foreignKeys as character
        initial "" no-undo get.
        protected set.

    define public override property mappingType as character
        initial "AFP" no-undo get.
        protected set.

    define public override property capabilities as character
        initial "" no-undo get.
        protected set.

    define public override property operations as character
        initial "CRUD,Submit" no-undo get.
        protected set.

    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getCount", "count", "get").

        /* Describe any properties to be added the entity tables. */
        define variable oFieldProps as FieldInfo no-undo.
        assign oFieldProps = new FieldInfo("dsSalesrep", "ttSalesrep").
        oFieldProps:addProperty("seq", "semanticType", "Internal").
        Spark.Core.Util.Annotate:describeFields(oFieldProps).
        delete object oFieldProps no-error.
    end method. /* initialize */

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


    method public void getCount ( input filter as character, output numRecs as int64 ):
        assign numRecs = filterData(filter).
    end method. /* getCount */

end class.