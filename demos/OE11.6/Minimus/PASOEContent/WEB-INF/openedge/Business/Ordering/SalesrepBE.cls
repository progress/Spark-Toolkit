/*------------------------------------------------------------------------
    File        : SalesrepBE
    Syntax      :
    Author(s)   : Dustin Grau
    Created     : Wed Aug 30 09:07:04 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

@program FILE(name="SalesrepBE.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writedatasetBeforeImage="false").
@progress.service.resource FILE(name="salesrep", URI="/salesrep", schemaName="dsSalesrep", schemaFile="Minimus/PASOEContent/WEB-INF/openedge/Common/salesrep.i").

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Business.Ordering.SalesrepBE inherits Spark.Core.Service.SparkEntity:

    {Common/salesrep.i}

    constructor public SalesrepBE():
        ProDataSet = dataset dsSalesrep:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 1.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer Salesrep:handle, ?).
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
    @openapi.openedge.export(type="REST", useReturnValue="false", writedatasetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json").
    @openapi.openedge.method.property(name="mappingType", value="JFP").
    @openapi.openedge.method.property(name="capabilities", value="ablFilter,top,skip,id,orderBy").
    method public void ReadSalesrepBE ( input filter as character, output dataset dsSalesrep ):
        define variable iNumRecs as int64 no-undo.
        super:ReadData(filter, iNumRecs, output dataset dsSalesrep by-reference).

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
    @openapi.openedge.export(type="REST", useReturnValue="false", writedatasetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="create", URI="", alias="", mediaType="application/json").
    method public void CreateSalesrep ( input-output dataset dsSalesrep ):
        super:CreateData(input-output dataset dsSalesrep by-reference).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

    /*------------------------------------------------------------------------------
            Purpose:  Update one or more records
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writedatasetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="update", URI="", alias="", mediaType="application/json").
    method public void UpdateSalesrep ( input-output dataset dsSalesrep ):
        super:UpdateData(input-output dataset dsSalesrep by-reference).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

    /*------------------------------------------------------------------------------
            Purpose:    Delete a record
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writedatasetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="delete", URI="", alias="", mediaType="application/json").
    method public void DeleteSalesrep ( input-output dataset dsSalesrep ):
        super:DeleteData(input-output dataset dsSalesrep by-reference).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

    /*------------------------------------------------------------------------------
            Purpose:    Submit a record
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writedatasetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="submit", URI="/submit", alias="submit", mediaType="application/json").
    method public void SubmitSalesrep ( input-output dataset dsSalesrep ):
        super:SubmitData(input-output dataset dsSalesrep by-reference).

        catch err as Progress.Lang.Error:
            message trim(substitute(("&1~nStack Trace:~n&2"), err:GetMessage(1), err:CallStack)).
        end catch.
    end method.

end class.
