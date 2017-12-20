/*------------------------------------------------------------------------
    File        : WebDataBE.cls
    Author(s)   : Code Wizard
    Created     : 12/12/17
    Notes       : Customized BE instance with AFP features available.
  ----------------------------------------------------------------------*/

@program FILE(name="WebData.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="webdata", URI="/webdata", schemaName="dsWebDataStore", schemaFile="Sports/PASOEContent/WEB-INF/openedge/Common/webdatastore.i").

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Business.System.WebData inherits Spark.Core.Service.SparkEntity:

    {Common/webdatastore.i}

    constructor public WebData ( ):
        ProDataSet = dataset dsWebDataStore:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 1.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer WebDataStore:handle, ?).
        ProDataSource = DataSourceArray.

        /* Skip-list entries for each table in dataset. Should be in temp-table order as defined in DataSet. */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create statement. */
        extent(SkipListArray) = 1.
        SkipListArray[1] = "WebSessionID,ObjectName".
        SkipList = SkipListArray.
    end constructor.


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json").
    @openapi.openedge.method.property(name="mappingType", value="AFP").
    @openapi.openedge.method.property(name="capabilities", value="filter,top,skip,id,sort,orderBy").
    method public void ReadWebData ( input filter as character, output dataset dsWebDataStore ):
        define variable iNumRecs as int64 no-undo.
        super:ReadData(filter, iNumRecs, output dataset dsWebDataStore by-reference).
    end method. /* ReadWebData */

end class.
