/*------------------------------------------------------------------------
    File        : CustomerBE
    Syntax      :
    Author(s)   : Dustin Grau
    Created     : Mon Aug 28 08:34:31 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

@program FILE(name="CustomerBE.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="customer", URI="/customer", schemaName="dsCustomer", schemaFile="Minimus/PASOEContent/WEB-INF/openedge/Common/customer.i").

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Business.Ordering.CustomerBE inherits Spark.Core.Service.SparkEntity:

    {Common/customer.i}

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

    /*------------------------------------------------------------------------------
            Purpose:  Get one or more records, based on a filter string
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json").
    @openapi.openedge.method.property(name="mappingType", value="AFP").
    @openapi.openedge.method.property(name="capabilities", value="filter,top,skip,id,sort,orderBy").
    method public void ReadCustomer ( input filter as character, output dataset dsCustomer ):
        define variable iNumRecs as int64 no-undo.
        super:ReadData(filter, iNumRecs, output dataset dsCustomer by-reference).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

    /*------------------------------------------------------------------------------
            Purpose: Count records for query filter
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="count", URI="/count?filter=~{filter~}", alias="count", mediaType="application/json").
    method public void CountRecs ( input filter as character, output numRecs as integer ):
        assign numRecs = integer(super:getRecCount(filter)).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

    /*------------------------------------------------------------------------------
            Purpose: Create one or more new records
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="create", URI="", alias="", mediaType="application/json").
    method public void CreateCustomer ( input-output dataset dsCustomer ):
        super:CreateData(input-output dataset dsCustomer by-reference).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

    /*------------------------------------------------------------------------------
            Purpose:  Update one or more records
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="update", URI="", alias="", mediaType="application/json").
    method public void UpdateCustomer ( input-output dataset dsCustomer ):
        super:UpdateData(input-output dataset dsCustomer by-reference).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

    /*------------------------------------------------------------------------------
            Purpose:    Delete a record
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="delete", URI="", alias="", mediaType="application/json").
    method public void DeleteCustomer ( input-output dataset dsCustomer ):
        super:DeleteData(input-output dataset dsCustomer by-reference).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

    /*------------------------------------------------------------------------------
            Purpose:    Submit a record
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="submit", URI="/submit", alias="submit", mediaType="application/json").
    method public void SubmitCustomer ( input-output dataset dsCustomer ):
        super:SubmitData(input-output dataset dsCustomer by-reference).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

    /*------------------------------------------------------------------------------
            Purpose: Throw an error to test event handling
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/error", alias="error", mediaType="application/json").
    method public void ErrorTest ( input errorCode    as integer,
                                   input errorMessage as character ):
        undo, throw new AppError(errorMessage, errorCode).
    end method.

end class.
