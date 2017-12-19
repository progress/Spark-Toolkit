/*------------------------------------------------------------------------
    File        : WebProfileBE.cls
    Author(s)   : Code Wizard
    Created     : 05/09/17
    Notes       : Customized BE instance with AFP features available.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Util.FieldInfo from propath.

block-level on error undo, throw.

class Business.System.WebProfileBE inherits Spark.Core.Service.DynamicEntity:

    {Common/webprofile.i}

    define public override property serviceURI as character
        initial "/web/pdo/common" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "webprofile" no-undo get.
        protected set.

    define public override property primaryKeys as character
        initial "" no-undo get.
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

        /* Describe any properties to be added the entity tables. */
        define variable oFieldProps as FieldInfo no-undo.
        assign oFieldProps = new FieldInfo("dsWebProfile", "ttWebProfile").
        oFieldProps:addProperty("UserNum", "editable", false).
        oFieldProps:makeRequired("Username"). /* Add "required" Validator */
        oFieldProps:makeRequired("Password"). /* Add "required" Validator */
        oFieldProps:addProperty("HomePhone", "mask", "000-000-0000").
        oFieldProps:addProperty("HomePhone", "semanticType", "PhoneNumber").
        oFieldProps:addProperty("WorkPhone", "mask", "000-000-0000").
        oFieldProps:addProperty("WorkPhone", "semanticType", "PhoneNumber").
        Spark.Core.Util.Annotate:describeFields(oFieldProps).
        delete object oFieldProps no-error.
    end method. /* initialize */

    constructor public WebProfileBE ( ):
        ProDataSet = dataset dsWebProfile:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 1.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer WebProfile:handle, ?).
        ProDataSource = DataSourceArray.

        /* Skip-list entries for each table in dataset. Should be in temp-table order as defined in DataSet. */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create statement. */
        extent(SkipListArray) = 1.
        SkipListArray[1] = "Username,DomainName".
        SkipList = SkipListArray.
    end constructor.


    method protected override character validateData ( input pcAction as character,
                                                       input-output dataset-handle phDataset ):
        define variable bhTopTable as handle  no-undo.
        define variable bhBefore   as handle  no-undo.
        define variable hQuery     as handle  no-undo.
        define variable lAvail     as logical no-undo.
        define variable iBuffers   as integer no-undo.
        define variable ix         as integer no-undo.
        define variable iy         as integer no-undo.

        if not valid-handle(phDataset) then return "".

        assign iBuffers = phDataset:num-top-buffers.
        do ix = 1 to iBuffers:
            assign bhTopTable = phDataset:get-top-buffer(ix).
            bhTopTable:table-handle:tracking-changes = true.
            assign bhBefore = bhTopTable:before-buffer.

            create query hQuery.
            hQuery:set-buffers(bhBefore).
            hQuery:query-prepare(substitute('FOR EACH &1', bhBefore:name)).
            hQuery:query-open().
            assign lAvail = hQuery:get-first(no-lock).

            VALIDATEBLK:
            do while lAvail:
                if bhBefore:row-state eq row-deleted then do:
                    /* This will return an error to indicate delete is not allowed. */
                    undo, throw new AppError("Delete operation is not allowed. Mark profile as inactive, instead.", -500).
                end. /* row-deleted */

                if bhTopTable:find-first(substitute("where rowid(&1) eq to-rowid('&2')", bhTopTable:name, bhBefore:after-rowid)) then
                do iy = 1 to bhTopTable:num-fields:
                    if bhTopTable:row-state eq row-created then do:
                        if bhTopTable:buffer-field(iy):name eq "UserNum" then do:
                            /* Note: For creates, UserNum should be populated by sequence. */
                            for last WebProfile no-lock
                                  by WebProfile.UserNum:
                                bhTopTable:buffer-field(iy):buffer-value = WebProfile.UserNum + 1.
                            end.
                        end. /* UserNum */

                        if bhTopTable:buffer-field(iy):name eq "Username" and
                           (bhTopTable:buffer-field(iy):buffer-value() gt "") ne true then do:
                            bhTopTable:error = true.
                            bhTopTable:error-string = appendMessage(bhTopTable:error-string, "No username provided").
                            bhTopTable:rejected = true.
                            phDataset:error = true.
                        end. /* Username */

                        if bhTopTable:buffer-field(iy):name eq "Password" and
                           (bhTopTable:buffer-field(iy):buffer-value() gt "") ne true then do:
                            bhTopTable:error = true.
                            bhTopTable:error-string = appendMessage(bhTopTable:error-string, "No password provided").
                            bhTopTable:rejected = true.
                            phDataset:error = true.
                        end. /* Password */

                        if bhTopTable:buffer-field(iy):name eq "Password" and
                           (bhTopTable:buffer-field(iy):buffer-value() gt "") eq true then do:
                            bhTopTable:buffer-field(iy):buffer-value = Spark.Core.Security.Password:encodePassword(bhTopTable:buffer-field(iy):buffer-value).
                        end. /* Password */

                        case bhTopTable:buffer-field(iy):name:
                            when "add_dt" then
                                bhTopTable:buffer-field(iy):buffer-value = today.
                            when "add_time" then
                                bhTopTable:buffer-field(iy):buffer-value = time.
                            when "add_userid" then
                                bhTopTable:buffer-field(iy):buffer-value = oClientContext:userID.
                            when "chg_dt" then
                                bhTopTable:buffer-field(iy):buffer-value = today.
                            when "chg_time" then
                                bhTopTable:buffer-field(iy):buffer-value = time.
                            when "chg_userid" then
                                bhTopTable:buffer-field(iy):buffer-value = oClientContext:userID.
                        end case.
                    end. /* row-created */

                    if bhTopTable:row-state eq row-modified then do:
                        if bhTopTable:buffer-field(iy):name eq "UserNum" then do:
                            if (bhTopTable:buffer-field(iy):buffer-value() gt "") ne true then do:
                                bhTopTable:error = true.
                                bhTopTable:error-string = appendMessage(bhTopTable:error-string, "No user number provided").
                                bhTopTable:rejected = true.
                                phDataset:error = true.
                            end.
                            if bhBefore:buffer-field(iy):buffer-value() ne bhTopTable:buffer-field(iy):buffer-value() then do:
                                bhTopTable:error = true.
                                bhTopTable:error-string = appendMessage(bhTopTable:error-string, "Value for user number changed").
                                bhTopTable:rejected = true.
                                phDataset:error = true.
                            end.
                        end. /* UserNum */

                        if bhTopTable:buffer-field(iy):name eq "Username" and
                           (bhTopTable:buffer-field(iy):buffer-value() gt "") ne true then do:
                            bhTopTable:error = true.
                            bhTopTable:error-string = appendMessage(bhTopTable:error-string, "No username provided").
                            bhTopTable:rejected = true.
                            phDataset:error = true.
                        end. /* Username */

                        if bhTopTable:buffer-field(iy):name eq "Password" and
                           (bhTopTable:buffer-field(iy):buffer-value() gt "") ne true then do:
                            bhTopTable:error = true.
                            bhTopTable:error-string = appendMessage(bhTopTable:error-string, "No password provided").
                            bhTopTable:rejected = true.
                            phDataset:error = true.
                        end. /* Password */

                        if bhTopTable:buffer-field(iy):name eq "Password" and
                           bhBefore:buffer-field(iy):buffer-value() ne bhTopTable:buffer-field(iy):buffer-value() then do:
                            bhTopTable:buffer-field(iy):buffer-value = Spark.Core.Security.Password:encodePassword(bhTopTable:buffer-field(iy):buffer-value).
                        end. /* Password */

                        case bhTopTable:buffer-field(iy):name:
                            when "chg_dt" then
                                bhTopTable:buffer-field(iy):buffer-value = today.
                            when "chg_time" then
                                bhTopTable:buffer-field(iy):buffer-value = time.
                            when "chg_userid" then
                                bhTopTable:buffer-field(iy):buffer-value = oClientContext:userID.
                        end case.
                    end. /* row-modified */
                end. /* table field */
                assign lAvail = hQuery:get-next(no-lock).
            end. /* lAvail */
        end. /* do ix */

        return "".

        finally:
            hQuery:query-close() no-error.
            delete object hQuery no-error.
            delete object bhTopTable no-error.
            delete object bhBefore no-error.
        end finally.
    end method. /* validateData */


    method public override void postRowFill ( input dataset-handle phDataset ):
        define variable hTableBuffer as handle no-undo.
        assign hTableBuffer = phDataset:get-buffer-handle(1).
        if valid-handle(hTableBuffer) then do:
            assign iSeq = iSeq + 1.
            hTableBuffer:buffer-field("seq"):buffer-value = iSeq.
            hTableBuffer:buffer-field("id"):buffer-value = string(hTableBuffer:rowid).

            for each WebRoleProfile no-lock
               where WebRoleProfile.Username eq hTableBuffer:buffer-field("Username"):buffer-value:
                if hTableBuffer:buffer-field("ProfileRoles"):buffer-value eq "" then
                    assign hTableBuffer:buffer-field("ProfileRoles"):buffer-value = WebRoleProfile.RoleID.
                else
                    assign hTableBuffer:buffer-field("ProfileRoles"):buffer-value = substitute("&1,&2",
                                                                                               hTableBuffer:buffer-field("ProfileRoles"):buffer-value,
                                                                                               WebRoleProfile.RoleID).
            end.
        end.
    end method. /* postRowFill */


    method public void getCount ( input filter as character, output numRecs as int64 ):
        assign numRecs = filterData(filter).
    end method. /* getCount */

end class.
