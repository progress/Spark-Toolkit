/*------------------------------------------------------------------------
    File        : Catalog
    Purpose     : Service to return all catalogs from the CatalogManager
    Syntax      :
    Description :
    Author(s)   : Dustin Grau
    Created     : Thu Aug 02 18:53:04 EDT 2018
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Net.HTTP.MethodEnum from propath.
using OpenEdge.Web.DataObject.* from propath.
using OpenEdge.Web.DataObject.Writer.OpenAPI30ServiceWriter from propath.
using Spark.Core.Manager.ICatalogManager from propath.

block-level on error undo, throw.

class Spark.Core.Service.Catalog implements Spark.Core.Service.ICatalog:

    method public void initialize ( ):
    end method. /* initialize */

    method public void dispose ( ):
    end method. /* dispose */

    method protected JsonObject getDataObjectServiceCatalogs ( ):
        define variable oServices  as DataObjectService no-undo extent.
        define variable oOperation as MappedOperation   no-undo.
        define variable oSvcArray  as JsonArray         no-undo.
        define variable oCatalog   as JsonObject        no-undo.
        define variable cFilename  as character         no-undo.
        define variable iX         as integer           no-undo.

        /* Create a new catalog object with empty services array. */
        assign oCatalog = new JsonObject().
        oCatalog:Add("version", 1.5).
        oCatalog:Add("lastModified", now).
        assign oSvcArray = new JsonArray().

        /* Obtain catalog from each registered service. */
        assign oServices = ServiceRegistry:GetServices().
        do iX = 1 to extent(oServices):
            if not valid-object(oServices[iX]:Catalog) then do:
                assign oOperation = oServices[iX]:GetOperation("/", MethodEnum:Get).
                if valid-object(oOperation) and oOperation:TargetName matches "*.json" then do:
                    assign
                        cFilename = replace(oOperation:TargetName, "$CATALINA_BASE", os-getenv("CATALINA_BASE"))
                        cFilename = replace(cFilename, "$oepas-webapp", trim(web-context:get-cgi-value("env", "CONTEXT_PATH"), "/"))
                        .
                    file-info:file-name = cFilename.
                    if file-info:full-pathname ne ? then do:
                        define variable oParser as ObjectModelParser no-undo.
                        define variable oTemp   as JsonObject        no-undo.

                        assign oParser = new ObjectModelParser().
                        assign oTemp = cast(oParser:ParseFile(file-info:full-pathname), JsonObject).
                        if oTemp:Has("services") then
                            oSvcArray:Add(oTemp:GetJsonArray("services"):GetJsonObject(1)).

                        delete object oParser no-error.
                    end. /* File Exists */
                end. /* Operation Not Available */
            end. /* No Catalog */
            else if oServices[iX]:Catalog:Has("services") then
                oSvcArray:Add(oServices[iX]:Catalog:GetJsonArray("services"):GetJsonObject(1)).
        end. /* do ix */

        /* Add services to new catalog output. */
        if oSvcArray:Length gt 0 then do:
            oCatalog:Add("services", oSvcArray).
            return cast(oCatalog:Clone(), JsonObject).
        end.
        else
            return ?.

        finally:
            delete object oSvcArray no-error.
            delete object oCatalog no-error.
        end finally.
    end method. /* getDataObjectServiceCatalogs */

    method public void getOpenApiCatalog ( output catalog as JsonObject ):
        define variable oServiceWriter as OpenAPI30ServiceWriter no-undo.
        assign oServiceWriter = new OpenAPI30ServiceWriter().
        if valid-object(oServiceWriter) then do:
            oServiceWriter:open().
            oServiceWriter:write(ServiceRegistry:GetServices()).
            oServiceWriter:close().

            assign catalog = cast(oServiceWriter:Value, JsonObject).
            delete object oServiceWriter no-error.
        end.

        /* Return an empty object if catalog object is invalid. */
        if not valid-object(catalog) then
            assign catalog = new Progress.Json.ObjectModel.JsonObject().
    end method. /* getOpenApiCatalog */

    method public void getCatalog ( output catalog as JsonObject ):
        /**
         * First attempt to return a combined catalog from any available services.
         * These would be stored within each DOS object via the Catalog property.
         */
        assign catalog = this-object:getDataObjectServiceCatalogs().

        /**
         * As a last resort, return a catalog of endpoints in OpenAPI format.
         * This format is chosen as it is an open standard and can be easily
         * consumed via many available parsers in multiple languages.
         */
        if not valid-object(catalog) then
            this-object:getOpenApiCatalog(output catalog).

        define variable cNames as character no-undo extent.
        if valid-object(catalog) then
            assign cNames = catalog:GetNames(). /* Check for properties of object. */
        if not valid-object(catalog) or extent(cNames) eq 0 then
            assign catalog = new Progress.Json.ObjectModel.JsonObject(). /* Otherwise, return an empty object. */

        if log-manager:logging-level ge 3 then
            catalog:WriteFile(substitute("&1/catalog.json", session:temp-directory), true).
    end method. /* getCatalog */

end class.