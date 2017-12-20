/*------------------------------------------------------------------------
    File        : WebRoleBE.cls
    Author(s)   : Code Wizard
    Created     : 05/09/17
    Notes       : Customized BE instance with AFP features available.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Business.System.WebRoleBE inherits Spark.Core.Service.DynamicEntity:

    {Common/webrole.i}

    define public override property serviceURI as character
        initial "/web/pdo/common" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "webrole" no-undo get.
        protected set.

    define public override property primaryKeys as character
        initial "ttWebRole.RoleID" no-undo get.
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
        initial "ReadOnly" no-undo get.
        protected set.

    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getCount", "count", "get").
    end method. /* initialize */

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


    method public void getCount ( input filter as character, output numRecs as int64 ):
        assign numRecs = filterData(filter).
    end method. /* getCount */

end class.
