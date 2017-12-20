/*------------------------------------------------------------------------
    File        : <Spark_EntityName>.cls
    Author(s)   : <Spark_GenAuthor>
    Created     : <Spark_GenDate>
    Notes       : Customized BE suited for dynamic routing.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

class <Spark_Namespace><Spark_EntityName>BE inherits Spark.Core.Service.DynamicEntity:

    {<Spark_SchemaFile>}

    define public override property serviceURI as character
        initial "<Spark_ServiceURI>" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "<Spark_ResourceName>" no-undo get.
        protected set.

    define public override property primaryKeys as character
        initial "<Spark_SkipListArray>" no-undo get.
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

    constructor public <Spark_EntityName>BE ( ):
        ProDataSet = dataset <Spark_DatasetName>:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 1.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer <Spark_MasterTable>:handle, ?).
        ProDataSource = DataSourceArray.

        /* Skip-list entries for each table in dataset. Should be in temp-table order as defined in DataSet. */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create statement. */
        extent(SkipListArray) = 1.
        SkipListArray[1] = "<Spark_SkipListArray>".
        SkipList = SkipListArray.
    end constructor.

    method public void getCount ( input filter as character, output numRecs as int64 ):
        assign numRecs = filterData(filter).
    end method. /* count */

end class.
