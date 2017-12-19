/*------------------------------------------------------------------------
    File        : OrderBE
    Syntax      :
    Author(s)   : Dustin Grau
    Created     : Wed Sep 20 07:49:23 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

@program FILE(name="OrderBE.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="order", URI="/order", schemaName="dsOrder", schemaFile="Minimus/PASOEContent/WEB-INF/openedge/Common/order.i").

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Business.Ordering.OrderBE inherits Spark.Core.Service.SparkEntity:

    {Common/order.i}

    constructor public OrderBE():
        ProDataSet = dataset dsOrder:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 2.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer Order:handle, ?).
        create data-source DataSourceArray[2].
        DataSourceArray[2]:add-source-buffer(buffer OrderLine:handle, ?).
        ProDataSource = DataSourceArray.

        /* Skip-list entries for each table in dataset. Should be in temp-table order as defined in DataSet. */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create statement. */
        extent(SkipListArray) = 2.
        SkipListArray[1] = "".
        SkipListArray[2] = "".
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
    method public void ReadOrder ( input filter as character, output dataset dsOrder ):
        define variable iNumRecs as int64 no-undo.
        super:ReadData(filter, iNumRecs, output dataset dsOrder by-reference).

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
    method public void CreateOrder ( input-output dataset dsOrder ):
        super:CreateData(input-output dataset dsOrder by-reference).

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
    method public void UpdateOrder ( input-output dataset dsOrder ):
        super:UpdateData(input-output dataset dsOrder by-reference).

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
    method public void DeleteOrder ( input-output dataset dsOrder ):
        super:DeleteData(input-output dataset dsOrder by-reference).

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
    method public void SubmitOrder ( input-output dataset dsOrder ):
        super:SubmitData(input-output dataset dsOrder by-reference).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

end class.
