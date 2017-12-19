/*------------------------------------------------------------------------
    File        : CustomerBE.cls
    Author(s)   : Code Wizard
    Created     : 12/12/17
    Notes       : Customized BE instance with AFP features available.
  ----------------------------------------------------------------------*/

@program FILE(name="CustomerBE.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="customer", URI="/customer", schemaName="dsCustomer", schemaFile="Sports/PASOEContent/WEB-INF/openedge/Common/customer.i").

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Business.Ordering.CustomerBE inherits Spark.Core.Service.SparkEntity:

    {Common/customer.i} 

    define private variable iCustNum as integer no-undo.

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
                    undo, throw new AppError("Delete operation is not allowed.", -500).

                    /* If delete IS allowed, then this method should return blank. */
                    /* return "". */
                end. /* row-deleted */

                if bhTopTable:find-first(substitute("where rowid(&1) eq to-rowid('&2')", bhTopTable:name, bhBefore:after-rowid)) then
                do iy = 1 to bhTopTable:num-fields:
                    if bhTopTable:row-state eq row-created then do:
                        if bhTopTable:buffer-field(iy):name eq "CustNum" then do:
                            /* Note: For creates, CustNum should be populated by sequence. */
                            for last Customer no-lock
                                  by Customer.CustNum:
                                bhTopTable:buffer-field(iy):buffer-value = Customer.CustNum + 1.
                            end.
                        end. /* CustNum */
                        if bhTopTable:buffer-field(iy):name eq "Name" and
                           (bhTopTable:buffer-field(iy):buffer-value() gt "") ne true then do:
                            bhTopTable:error = true.
                            bhTopTable:error-string = appendMessage(bhTopTable:error-string, "No customer name provided").
                            bhTopTable:rejected = true.
                            phDataset:error = true.
                        end. /* Name */
                        if bhTopTable:buffer-field(iy):name eq "SalesRep" and
                           (bhTopTable:buffer-field(iy):buffer-value() gt "") ne true then do:
                            bhTopTable:error = true.
                            bhTopTable:error-string = appendMessage(bhTopTable:error-string, "No sales rep provided").
                            bhTopTable:rejected = true.
                            phDataset:error = true.
                        end. /* SalesRep */
                    end. /* row-created */

                    if bhTopTable:row-state eq row-modified then do:
                        if bhTopTable:buffer-field(iy):name eq "CustNum" then do:
                            if (bhTopTable:buffer-field(iy):buffer-value() gt "") ne true then do:
                                bhTopTable:error = true.
                                bhTopTable:error-string = appendMessage(bhTopTable:error-string, "No customer number provided").
                                bhTopTable:rejected = true.
                                phDataset:error = true.
                            end.
                            if bhBefore:buffer-field(iy):buffer-value() ne bhTopTable:buffer-field(iy):buffer-value() then do:
                                bhTopTable:error = true.
                                bhTopTable:error-string = appendMessage(bhTopTable:error-string, "Value for customer number changed").
                                bhTopTable:rejected = true.
                                phDataset:error = true.
                            end.
                        end. /* CustNum */
                        if bhTopTable:buffer-field(iy):name eq "Name" and
                           (bhTopTable:buffer-field(iy):buffer-value() gt "") ne true then do:
                            bhTopTable:error = true.
                            bhTopTable:error-string = appendMessage(bhTopTable:error-string, "No customer name provided").
                            bhTopTable:rejected = true.
                            phDataset:error = true.
                        end. /* Name */
                        if bhTopTable:buffer-field(iy):name eq "SalesRep" and
                           (bhTopTable:buffer-field(iy):buffer-value() gt "") ne true then do:
                            bhTopTable:error = true.
                            bhTopTable:error-string = appendMessage(bhTopTable:error-string, "No sales rep provided").
                            bhTopTable:rejected = true.
                            phDataset:error = true.
                        end. /* SalesRep */
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


    method protected override void preCommitLogic ( input pcAction as character,
                                                    input-output dataset-handle phDataset ):
        define variable bhTopTable as handle no-undo.

        assign iCustNum = ?. /* Reset this value on each commit. */

        if not valid-handle(phDataset) then return. /* Leave if handle is invalid. */

        if pcAction eq "Delete" then do:
            /* If explicitly a delete, remember the current record primary value(s). */
            assign bhTopTable = phDataset:get-top-buffer(1).

            if bhTopTable:find-first(substitute("where true", bhTopTable:name)) then
                assign iCustNum = bhTopTable:buffer-field("CustNum"):buffer-value().
        end. /* Delete */

        finally:
            delete object bhTopTable no-error.
        end finally.
    end method. /* preCommitLogic */

    method protected override void postCommitLogic ( input pcAction as character,
                                                     input-output dataset-handle phDataset ):
        /* When explicitly a delete and primary key available, delete child records. */
        if pcAction eq "Delete" and (iCustNum ne ? and iCustNum gt 0) then do:
            message substitute("Removing related records for customer &1.", iCustNum).
            for each Order exclusive-lock
               where Order.CustNum eq iCustNum:
                for each OrderLine exclusive-lock
                   where OrderLine.Ordernum eq Order.Ordernum:
                    delete OrderLine.
                end.
                delete Order.
            end. /* OrderLine */
        end. /* Order */
    end method. /* postCommitLogic */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json").
    @openapi.openedge.method.property(name="mappingType", value="AFP").
    @openapi.openedge.method.property(name="capabilities", value="filter,top,skip,id,sort,orderBy").
    method public void ReadCustomer ( input filter as character, output dataset dsCustomer ):
        define variable iNumRecs as int64 no-undo.
        super:ReadData(filter, iNumRecs, output dataset dsCustomer by-reference).
    end method. /* ReadCustomer */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="submit", URI="/submit", alias="submit", mediaType="application/json").
    method public void SubmitCustomer ( input-output dataset dsCustomer ):
        super:SubmitData(input-output dataset dsCustomer by-reference).
    end method. /* SubmitCustomer */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="count", URI="/count?filter=~{filter~}", alias="count", mediaType="application/json").
    method public void getCount ( input filter as character, output numRecs as integer ):
        assign numRecs = integer(super:getRecCount(filter)).
    end method. /* getCount */

end class.
