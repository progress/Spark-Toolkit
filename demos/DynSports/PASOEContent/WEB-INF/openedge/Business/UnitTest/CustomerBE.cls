/*------------------------------------------------------------------------
    File        : CustomerBE
    Author(s)   : Code Wizard
    Created     : 08/01/16
    Notes       : Customized BE suited for use with the JFP plugin.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Util.FieldInfo from propath.
using Spark.Core.Util.ForeignKey from propath.

block-level on error undo, throw.

class Business.UnitTest.CustomerBE inherits Spark.Core.Service.DynamicEntity:

    {Common/customer.i}

    define public override property serviceURI as character
        initial "/web/pdo/tests" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "customerjfp" no-undo get.
        protected set.

    define public override property primaryKeys as character
        initial "ttCustomer.CustNum,ttCustomer.Name" no-undo get.
        protected set.

    define public override property foreignKeys as character
        initial "" no-undo get.
        protected set.

    define public override property mappingType as character
        initial "JFP" no-undo get.
        protected set.

    define public override property capabilities as character
        initial "ablFilter,id,skip,top,orderBy" no-undo get.
        protected set.

    define public override property operations as character
        initial "CRUD,Submit" no-undo get.
        protected set.

    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getCount", "count", "get").

        /* Describe any properties to be added the entity tables. */
        define variable oFieldProps as FieldInfo no-undo.
        assign oFieldProps = new FieldInfo("dsCustomer", "ttCustomer").
        oFieldProps:addProperty("seq", "semanticType", "Internal").
        oFieldProps:addProperty("CustNum", "editable", false).
        oFieldProps:makeRequired("CustName"). /* Add "required" Validator */
        oFieldProps:addProperty("Country", "defaultValue", "United States").
        oFieldProps:addProperty("Phone", "mask", "000-000-0000").
        oFieldProps:addProperty("Phone", "semanticType", "PhoneNumber").
        Spark.Core.Util.Annotate:describeFields(oFieldProps).
        delete object oFieldProps no-error.
    end method. /* initialize */

    constructor public CustomerBE ( ):
        ProDataSet = dataset dsCustomer:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 1.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer Customer:handle, ?).
        ProDataSource = DataSourceArray.

        /* Skip-list entries for each table in dataset. Should be in temp-table order as defined in DataSet. */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create statement. */
        extent(SkipListArray) = 1.
        SkipListArray[1] = "".
        SkipList = SkipListArray.
    end constructor.

    method public void getCount ( input filter as character, output numRecs as integer ):
        assign numRecs = integer(filterData(filter)).
    end method. /* count */

end class.
