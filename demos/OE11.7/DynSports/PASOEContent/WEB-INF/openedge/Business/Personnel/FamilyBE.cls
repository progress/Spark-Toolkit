/*------------------------------------------------------------------------
    File        : FamilyBE.cls
    Author(s)   : Code Wizard
    Created     : 11/27/17
    Notes       : Customized BE instance with AFP features available.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Business.Personnel.FamilyBE inherits Spark.Core.Service.DynamicEntity:

    {Common/family.i}

    define public override property serviceURI as character
        initial "/web/pdo/personnel" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "family" no-undo get.
        protected set.

    define public override property primaryKeys as character
        initial "ttFamily.EmpNum,ttFamily.RelativeName" no-undo get.
        protected set.

    define public override property foreignKeys as character
        initial "" no-undo get.
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
    end method. /* initialize */

    constructor public FamilyBE ( ):
        ProDataSet = dataset dsFamily:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 1.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer Family:handle, ?).
        ProDataSource = DataSourceArray.

        /* Skip-list entries for each table in dataset. Should be in temp-table order as defined in DataSet. */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create statement. */
        extent(SkipListArray) = 1.
        SkipListArray[1] = "".
        SkipList = SkipListArray.
    end constructor.

    method public void getCount ( input filter as character, output numRecs as int64 ):
        assign numRecs = filterData(filter).
    end method. /* getCount */

end class.
