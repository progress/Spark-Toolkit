/*------------------------------------------------------------------------
    File        : WebRoleBE.cls
    Author(s)   : Code Wizard
    Created     : 12/12/17
    Notes       : Customized BE instance with AFP features available.
  ----------------------------------------------------------------------*/

@program FILE(name="WebRole.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="webrole", URI="/webrole", schemaName="dsWebRole", schemaFile="Sports/PASOEContent/WEB-INF/openedge/Common/webrole.i").

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Business.System.WebRoleBE inherits Spark.Core.Service.SparkEntity:

    {Common/webrole.i}

    constructor public WebRoleBE ( ):
        ProDataSet = dataset dsWebRole:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 1.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer WebRole:handle, ?).
        ProDataSource = DataSourceArray.

        /* Skip-list entries for each table in dataset. Should be in temp-table order as defined in DataSet. */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create statement. */
        extent(SkipListArray) = 1.
        SkipListArray[1] = "RoleID".
        SkipList = SkipListArray.
    end constructor.


    method public override void postRowFill ( input dataset-handle phDataset ):
        define variable hTableBuffer as handle no-undo.
        assign hTableBuffer = phDataset:get-buffer-handle(1).
        if valid-handle(hTableBuffer) then do:
            assign iSeq = iSeq + 1.
            hTableBuffer:buffer-field("seq"):buffer-value = iSeq.
            hTableBuffer:buffer-field("id"):buffer-value = string(hTableBuffer:rowid).

            for each WebRoleTask no-lock
               where WebRoleTask.RoleID eq hTableBuffer:buffer-field("RoleID"):buffer-value:
                if hTableBuffer:buffer-field("TaskList"):buffer-value eq "" then
                    assign hTableBuffer:buffer-field("TaskList"):buffer-value = WebRoleTask.TaskID.
                else
                    assign hTableBuffer:buffer-field("TaskList"):buffer-value = substitute("&1,&2",
                                                                                           hTableBuffer:buffer-field("TaskList"):buffer-value,
                                                                                           WebRoleTask.TaskID).
            end.
        end.
    end method. /* postRowFill */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json").
    @openapi.openedge.method.property(name="mappingType", value="AFP").
    @openapi.openedge.method.property(name="capabilities", value="filter,top,skip,id,sort,orderBy").
    method public void ReadWebRole ( input filter as character, output dataset dsWebRole ):
        define variable iNumRecs as int64 no-undo.
        super:ReadData(filter, iNumRecs, output dataset dsWebRole by-reference).
    end method. /* ReadWebRole */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="count", URI="/count?filter=~{filter~}", alias="count", mediaType="application/json").
    method public void getCount ( input filter as character, output numRecs as integer ):
        assign numRecs = integer(super:getRecCount(filter)).
    end method. /* getCount */

end class.
