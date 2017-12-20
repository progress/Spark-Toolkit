/*------------------------------------------------------------------------
    File        : SparkRequest
    Purpose     : Custom WebRequest object for Spark-based WebHandlers
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Mar 22 15:12:07 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Manager.ICatalogManager from propath.

block-level on error undo, throw.
&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW
&GLOBAL-DEFINE CATALOG_METHOD getCatalog

class Spark.Core.Web.SparkRequest inherits OpenEdge.Web.WebRequest implements Spark.Core.Web.IWebRequest use-widget-pool:

    define private variable lIsCatalog as logical   no-undo initial false.
    define private variable cSvcPrefix as character no-undo initial "pdo".

    define protected property ReadFilter as character no-undo
        get():
            if (ReadFilter gt "") ne true then do:
                if valid-object(Ccs.Common.Application:StartupManager) and
                   valid-object(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager))) then
                    assign ReadFilter = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager):ReadFilter.
                else
                    assign ReadFilter = "filter".
            end.
            return ReadFilter.
        end get.
        protected set.


    define public property SparkPathArray as JsonArray no-undo
        get():
            if not valid-object(SparkPathArray) then
                SparkPathArray = getParsedPathInfo().
            return SparkPathArray.
        end get.
        protected set.


    define public property SparkQueryData as JsonObject no-undo
        get():
            if not valid-object(SparkQueryData) then
                SparkQueryData = getParsedQueryString().
            return SparkQueryData.
        end get.
        protected set.


    define public property SparkApiVersion as decimal no-undo initial ?
        get():
            if SparkApiVersion eq ? then do:
                SparkApiVersion = decimal(GetPathParameter("version")) no-error.
                if error-status:error then SparkApiVersion = ?.
            end.
            return SparkApiVersion.
        end get.
        protected set.


    define public property SparkServiceName as character no-undo initial ?
        get():
            if SparkServiceName eq ? then
                SparkServiceName = GetPathParameter("service").
            return SparkServiceName.
        end get.
        protected set.


    define public property SparkServiceURI as character no-undo initial ?
        get():
            if SparkServiceURI eq ? then
                SparkServiceURI = getServiceURI().
            return SparkServiceURI.
        end get.
        protected set.


    define public property SparkResourceName as character no-undo initial ?
        get():
            if SparkResourceName eq ? then
                SparkResourceName = GetPathParameter("resource").
            return SparkResourceName.
        end get.
        protected set.


    define public property SparkMethodName as character no-undo initial ?
        get():
            if SparkMethodName eq ? then
                SparkMethodName = getJSDOMethod().
            return SparkMethodName.
        end get.
        protected set.


    define public property SparkMetadata as character no-undo initial ?
        get():
            if SparkMetadata eq ? then
                SparkMetadata = getMetadata().
            return SparkMetadata.
        end get.
        protected set.


    define public property SparkBody as longchar no-undo
        get():
            if this-object:Method eq "GET" then
                return getJSDOFilter().
            else
                return getJsonBody().
        end get.
        private set.


    define public property SparkStopAfter as integer no-undo initial ?
        get():
            if SparkStopAfter eq ? and
               SparkQueryData:Has("stopafter") then
            do:
                SparkStopAfter = integer(SparkQueryData:GetCharacter("stopafter")) no-error.
                if error-status:error then SparkStopAfter = ?.
            end.
            return SparkStopAfter.
        end get.
        protected set.


    constructor SparkRequest ( ):
        super().
    end constructor.


    constructor SparkRequest ( input pcServicePrefix as character ):
        super().

        /* Retain given prefix value if passed. */
        if (pcServicePrefix gt "") eq true then
            assign cSvcPrefix = pcServicePrefix.
    end constructor.


    destructor SparkRequest ( ):
        assign
            SparkPathArray = ?
            SparkQueryData = ?
            .
    end destructor.


    /** Protected Methods **/


    method protected character getServiceURI ( ):
        define variable cServiceURI as character no-undo.
        define variable iStart      as integer   no-undo.
        define variable iX          as integer   no-undo.

        /* If full service object is specified in header, use that instead. */
        if HasHeader("X-SERVICE-OBJECT") then
            assign cServiceURI = GetHeader("X-SERVICE-OBJECT"):toString().
        else do:
            /* Start with the transport path for this URI. */
            assign cServiceURI = this-object:TransportPath.

            /* Start counting from element containing service prefix. */
            do iX = 1 to SparkPathArray:Length:
                if SparkPathArray:GetCharacter(iX) eq cSvcPrefix then
                    assign iStart = iX.
            end.

            /* If start point matches service prefix position, return a full catalog. */
            if SparkPathArray:Length eq iStart then
                assign
                    lIsCatalog  = true
                    cServiceURI = "" /* Return for all services. */
                    .
            else if SparkPathArray:Length eq (iStart + 1) and
                 SparkPathArray:GetCharacter(iStart + 1) eq SparkServiceName then
                 assign /* Path has only 1 extra item, and matches the service name. */
                    lIsCatalog  = true
                    cServiceURI = substitute("&1/&2/&3", cServiceURI, SparkPathArray:GetCharacter(iStart), SparkServiceName)
                    .
            else /* Obtain the full path up to the last entry. */
            do iX = iStart to SparkPathArray:Length:
                /* Stop when we encounter the item that matches our resource name. */
                if SparkPathArray:GetCharacter(iX) eq SparkResourceName then leave.

                /* Otherwise append the next path entry to the service URI. */
                assign cServiceURI = substitute("&1/&2", cServiceURI, SparkPathArray:GetCharacter(iX)).
            end. /* iStart to Length */
        end. /* No Service-Object */

        return cServiceURI.
    end method. /* getServiceURI */


    method protected longchar getJSDOFilter ( ):
        /* If working with the "read" method, which includes a specific "filter" query parameter,
         * attempt to extract only the ReadFilter property from the URL query data (as JSON object).
         */
        if SparkMethodName eq "read" and SparkQueryData:Has(ReadFilter) and SparkQueryData:GetType(ReadFilter) eq JsonDataType:object then
            return SparkQueryData:GetJsonObject(ReadFilter):GetJsonText(). /* Return filter object. */
        else
            return SparkQueryData:GetJsonText(). /* Otherwise return entire query string object. */
    end method. /* getJSDOFilter */


    method protected character getJSDOMethod ( ):
        /* Since the service can have a bearing on the resulting method,
         * we must first determine if we are making a catalog request.
         */
        if SparkServiceURI eq ? then
            SparkServiceURI = getServiceURI(). /* Get service URI if property is still unset. */
        if lIsCatalog then
            assign SparkMethodName = "{&CATALOG_METHOD}". /* Treat as special catalog method. */
        else
            SparkMethodName = GetPathParameter("method"). /* Obtain given method name from URL. */

        /* If no service and no resource, then default to the catalog method. */
        if SparkServiceURI begins this-object:TransportPath and
           SparkServiceURI matches substitute("*/&1/*", cSvcPrefix) and
           (SparkResourceName gt "") ne true then
            assign SparkMethodName = "{&CATALOG_METHOD}". /* Set to special catalog method. */
        else if (SparkResourceName gt "") eq true and (SparkMethodName gt "") ne true then
            /* If resource is present but method is still blank,
             * then obtain a default method name from HTTP verb.
             */
            case this-object:Method:
                when "GET" then
                    assign SparkMethodName = "read".
                when "POST" then
                    assign SparkMethodName = "create".
                when "PUT" then
                    assign SparkMethodName = "update".
                when "DELETE" then
                    assign SparkMethodName = "delete".
            end case.

        /* If method name is still unknown, then set property to blank. */
        if SparkMethodName eq ? then assign SparkMethodName = "".

        return SparkMethodName.
    end method. /* getJSDOMethod */


    method protected character getMetadata ( ):
        return "".
    end method. /* getMetadata */


    method protected JsonArray getParsedPathInfo ( ):
        define variable oPathArr as JsonArray no-undo.
        define variable cItem    as character no-undo.
        define variable iX       as integer   no-undo.

        assign oPathArr = new JsonArray().

        do iX = 1 to num-entries(this-object:PathInfo, "/"):
            assign cItem = entry(iX, this-object:PathInfo, "/").
            if (cItem gt "") eq true then
                oPathArr:add(cItem).
        end. /* do */

        return oPathArr.
    end method. /* getParsedPathInfo */


    method protected JsonObject getParsedQueryString ( ):
        define variable oQuery       as JsonObject        no-undo.
        define variable oArray       as JsonArray         no-undo.
        define variable oParser      as ObjectModelParser no-undo.
        define variable cQueryString as character         no-undo.
        define variable cParam       as character         no-undo.
        define variable cName        as character         no-undo.
        define variable cValue       as character         no-undo.
        define variable iIndex       as integer           no-undo.
        define variable iParam       as integer           no-undo.

        assign oQuery = new JsonObject().

        /* Convert query string name/value pairs into a JSON object. */
        assign cQueryString = GetContextValue("QUERY_STRING").
        if (cQueryString gt "") eq true then
        do iParam = 1 to num-entries(cQueryString, "&"):
            assign cParam = entry(iParam, cQueryString, "&").
            assign iIndex = index(cParam, "=").
            if iIndex gt 0 then do:
                assign cName = substring(cParam, 1, iIndex - 1).
                assign cValue = substring(cParam, iIndex + 1).
                if (cValue gt "") eq true then do:
                    assign cValue = OpenEdge.Net.URI:Decode(cValue).
                    if cValue begins "~{" then do {&throw}:
                        /* Param value is a JSON object and must be parsed. */
                        assign oParser = new ObjectModelParser().
                        /* Only add object if a property by this name does not exist. */
                        if not oQuery:has("cName") then
                            oQuery:add(cName, cast(oParser:Parse(cValue), jsonObject)).

                        catch pErr as Progress.Json.JsonParserError:
                            message substitute("Error parsing param object at byte &1.", pErr:Offset).
                        end catch.
                        finally:
                            delete object oParser no-error.
                        end finally.
                    end. /* Stringified Object */
                    else do:
                        if oQuery:has(cName) then do:
                            /* Query param already exists by this name, convert to an array. */
                            if oQuery:GetType(cName) eq JsonDataType:ARRAY then do:
                                /* Add values to array and overwrite parameter. */
                                assign oArray = oQuery:GetJsonArray(cName).
                                oArray:Add(cValue). /* Add current value. */
                            end. /* Already Array */
                            else do:
                                /* Re-create this param as a new JSON array. */
                                assign oArray = new JsonArray().
                                oArray:Add(oQuery:GetCharacter(cName)). /* Original value. */
                                oArray:Add(cValue). /* Add current value to the new array. */
                            end. /* Convert to Array */
                            oQuery:Set(cName, oArray). /* Overwrite the existing parameter. */
                        end. /* Parameter Exists */
                        else /* Simply add the parameter if it does not already exist. */
                            oQuery:add(cName, cValue).
                    end. /* Standard Parameter (String) */
                end. /* Non-Blank Value */
            end. /* iIndex > 0 */
        end. /* do iX */

        return oQuery.
    end method. /* getParsedQueryString */


    /** Public Methods **/


    method public longchar getJsonBody ( ):
        /* Only attempt to access the Entity property if Body is expected, and is JSON. */
        if web-context:is-json and this-object:Method ne "GET" and
           this-object:ContentType begins "application/json" then do:
            if type-of(this-object:Entity, "Progress.Json.ObjectModel.JsonConstruct") then
                return cast(this-object:Entity, JsonObject):getJsonText().
        end. /* GET and JSON */

        return "".
    end method. /* getJsonBody */


    method public OpenEdge.Net.MultipartEntity getMultipartEntity ( ):
        define variable oEntityWriter as OpenEdge.Net.HTTP.Filter.Payload.MessageWriter no-undo.
        define variable oHeader       as OpenEdge.Net.HTTP.HttpHeader                   no-undo.

        if OpenEdge.Net.MimeTypeHelper:IsMultipart(this-object:ContentType) then do:
            oEntityWriter = OpenEdge.Net.HTTP.Filter.Writer.EntityWriterBuilder:Build(this-object):Writer.
            oEntityWriter:Open().
            oEntityWriter:Write(this-object:Entity).
            oEntityWriter:Close().

            return cast(oEntityWriter:Entity, OpenEdge.Net.MultipartEntity).
        end.

        return new OpenEdge.Net.MultipartEntity().
    end method. /* getMultipartEntity */

end class.