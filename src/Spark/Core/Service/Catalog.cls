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

class Spark.Core.Service.Catalog inherits Spark.Diagnostic.Util.OSPath implements Spark.Core.Service.ICatalog use-widget-pool:

    /* Tracks the last time the CB props file was loaded from the file system. */
    define protected variable dCBPropsLastLoaded as datetime no-undo initial ?.

    /* Find a better default port in use with this instance. */
    define protected variable iPort as integer no-undo.

    method public void initialize ( ):
        this-object:Discovery(). /* Perform local discovery of server info. */
    end method. /* initialize */

    method public void dispose ( ):
    end method. /* dispose */

    method protected void Discovery ( ):
        define variable cLine        as character  no-undo.
        define variable cAppName     as character  no-undo.
        define variable cAppNames    as character  no-undo.
        define variable cWebApp      as character  no-undo.
        define variable cTransport   as character  no-undo.
        define variable lcConfigTemp as longchar   no-undo.
        define variable iLines       as integer    no-undo.
        define variable iLine        as integer    no-undo.
        define variable iX           as integer    no-undo.
        define variable iHttpPort    as integer    no-undo.
        define variable iHttpsPort   as integer    no-undo.
        define variable lFound       as logical    no-undo.
        define variable dLastDate    as datetime   no-undo.
        define variable oWebAppList  as JsonArray  no-undo.

        /* Examine the catalina.properties for info about the available ports. */
        file-info:file-name = substitute("&1/conf/catalina.properties", this-object:CatalinaBase).
        if file-info:full-pathname ne ? then do:
            /* Get the current date/time that the file was last modified. */
            assign dLastDate = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000).

            if dLastDate ne dCBPropsLastLoaded then do:
                /* Mark down the current modified date/time for this file. */
                assign dCBPropsLastLoaded = dLastDate.

                /* Read the file into a longchar value (avoids keeping the file open). */
                copy-lob from file file-info:full-pathname to lcConfigTemp no-error.

                assign iLines = num-entries(lcConfigTemp, "~n").
                if iLines ge 1 then cfgblk:
                do iLine = 1 to iLines:
                    assign cLine = trim(entry(iLine, lcConfigTemp, "~n")).

                    case true:
                        when cLine begins "psc.as.http.port=" then
                            assign iHttpPort = integer(trim(entry(2, cLine, "="))).
                        when cLine begins "psc.as.https.port=" then
                            assign iHttpsPort = integer(trim(entry(2, cLine, "="))).
                    end case.
                end. /* do iLines */

                /* Look to the same server at either the HTTP or HTTPS port for OEManager. */
                if iHttpPort gt 0 then
                    this-object:iPort = iHttpPort.
                else if iHttpsPort gt 0 then
                    this-object:iPort = iHttpsPort.

                assign lcConfigTemp = ?. /* Reset the variable. */
            end. /* file updated */
        end. /* catalina.properties */
    end method. /* Discovery */

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
                        cFilename = replace(oOperation:TargetName, "$CATALINA_BASE", this-object:CatalinaBase)
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
                /* Each service should only have one defined catalog for that service. */
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
        /* Specialized method to return an Open API v3.0 formatted description of resource endpoints. */
        define variable oServiceWriter as OpenAPI30ServiceWriter no-undo.
        assign oServiceWriter = new OpenAPI30ServiceWriter().
        if valid-object(oServiceWriter) then do:
            oServiceWriter:open().
            oServiceWriter:write(ServiceRegistry:GetServices()).
            oServiceWriter:close().

            assign catalog = cast(oServiceWriter:Value, JsonObject).
            if valid-object(catalog) then do:
                define variable oVars as JsonObject no-undo.

                assign oVars = catalog:GetJsonArray("servers"):GetJsonObject(1):GetJsonObject("variables").
                oVars:GetJsonObject("port"):Set("default", string(iPort)). /* Use the discovered port for the instance. */
                oVars:GetJsonObject("basePath"):Set("default", "/api"). /* Use the default typically set for a Spark-based application. */

                assign oVars = catalog:GetJsonArray("servers"):GetJsonObject(2):GetJsonObject("variables").
                oVars:GetJsonObject("basePath"):Set("default", "/api"). /* Use the default typically set for a Spark-based application. */
            end.
            delete object oServiceWriter no-error.
        end.

        /* Return an empty object if catalog object is invalid. */
        if not valid-object(catalog) then
            assign catalog = new Progress.Json.ObjectModel.JsonObject().

        catch err as Progress.Lang.Error:
            message err:GetMessage(1).
            if session:error-stack-trace then
                message err:CallStack.
        end catch.
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

        catch err as Progress.Lang.Error:
            message err:GetMessage(1).
            if session:error-stack-trace then
                message err:CallStack.
        end catch.
    end method. /* getCatalog */

end class.