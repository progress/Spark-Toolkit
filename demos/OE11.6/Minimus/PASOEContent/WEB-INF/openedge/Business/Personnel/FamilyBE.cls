/*------------------------------------------------------------------------
    File        : FamilyBE
    Author(s)   : Dustin Grau
    Created     : Mon Nov 13 14:37:07 EST 2017
    Notes       : BE instance from the native PDSOE code generator
  ----------------------------------------------------------------------*/

@program FILE(name="FamilyBE.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="family", URI="/family", schemaName="dsFamily", schemaFile="Minimus/PASOEContent/WEB-INF/openedge/Common/family.i").

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Util.* from propath.

block-level on error undo, throw.

class Business.Personnel.FamilyBE inherits OpenEdge.BusinessLogic.BusinessEntity:

    {Common/family.i}

    define data-source srcFamily for Family.

    constructor public FamilyBE():
        define variable hDataSourceArray as handle    no-undo extent 1.
        define variable cSkipListArray   as character no-undo extent 1.

        super (dataset dsFamily:handle).

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        hDataSourceArray[1] = data-source srcFamily:handle.


        /* Skip-list entry for each table in dataset. Should be in temp-table order as defined in DataSet */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create stmt */
        cSkipListArray[1] = "".

        this-object:ProDataSource = hDataSourceArray.
        this-object:SkipList = cSkipListArray.
    end constructor.

    method protected JsonObject getFilter ( input pcRawFilter as longchar ):
        define variable oParser as ObjectModelParser no-undo.
        define variable oFilter as JsonObject        no-undo.

        /* Return the filter (default read property) as a JSON object. */
        if pcRawFilter ne ? and pcRawFilter begins "~{" then do:
            assign oParser = new ObjectModelParser().
            assign pcRawFilter = FormatTools:convertToUTF8(pcRawFilter).
            assign oFilter = cast(oParser:Parse(pcRawFilter), jsonObject).
            return oFilter.
        end.

        return ?.

        finally:
            delete object oParser no-error.
        end finally.
    end method. /* getFilter */

    /*------------------------------------------------------------------------------
            Purpose:  Get one or more records, based on a filter string
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json").
    @openapi.openedge.method.property(name="mappingType", value="JFP").
    @openapi.openedge.method.property(name="capabilities", value="ablFilter,top,skip,id,sort,orderBy").
    method public void ReadFamily ( input filter as character, output dataset dsFamily ):
        define variable oFilter as JsonObject no-undo.
        assign oFilter = this-object:getFilter(filter).
        if oFilter:Has("ablFilter") then
            super:ReadData(oFilter:GetCharacter("ablFilter")).
        else
            super:ReadData(filter).
    end method.

    /*------------------------------------------------------------------------------
            Purpose: Create one or more new records
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="create", URI="", alias="", mediaType="application/json").
    method public void CreateFamily ( input-output dataset dsFamily ):
        super:CreateData(input-output dataset dsFamily by-reference).
    end method.

    /*------------------------------------------------------------------------------
            Purpose:  Update one or more records
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="update", URI="", alias="", mediaType="application/json").
    method public void UpdateFamily ( input-output dataset dsFamily ):
        super:UpdateData(input-output dataset dsFamily by-reference).
    end method.

    /*------------------------------------------------------------------------------
            Purpose:    Delete a record
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="delete", URI="", alias="", mediaType="application/json").
    method public void DeleteFamily ( input-output dataset dsFamily ):
        super:DeleteData(input-output dataset dsFamily by-reference).
    end method.

    /*------------------------------------------------------------------------------
            Purpose:    Submit a record
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="true").
    @progress.service.resourceMapping(type="REST", operation="submit", URI="/submit", alias="submit", mediaType="application/json").
    method public void SubmitFamily ( input-output dataset dsFamily ):
        super:Submit(input-output dataset dsFamily by-reference).
    end method.

end class.
