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

    /**
     * The default for the OE.W.DO.DOH pattern is "pdo" which will be used here to maintain consistency.
     * However, if intending to use both the Spark and DOH service patterns in the same application, this
     * should be overriden by use if the catalog.json file's general "ServicePrefix" property.
     */
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
                SparkPathArray = this-object:getParsedPathInfo().
            return SparkPathArray.
        end get.
        protected set.


    define public property SparkQueryData as JsonObject no-undo
        get():
            if not valid-object(SparkQueryData) then
                SparkQueryData = this-object:getParsedQueryString().
            return SparkQueryData.
        end get.
        protected set.


    define public property SparkApiVersion as decimal no-undo initial ? get. protected set.


    define public property SparkServiceName as character no-undo get. protected set.


    define public property SparkServiceURI as character no-undo get. protected set.


    define public property SparkResourceName as character no-undo get. protected set.


    define public property SparkMethodName as character no-undo get. protected set.


    define public property SparkMetadata as character no-undo initial ?
        get():
            if SparkMetadata eq ? then
                SparkMetadata = this-object:getMetadata().
            return SparkMetadata.
        end get.
        protected set.


    define public property SparkBody as longchar no-undo
        get():
            if this-object:Method eq "GET" then
                return this-object:getJSDOFilter().
            else
                return this-object:getJsonBody().
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

        this-object:parseRequestPath(). /* Determine service, version, resource, and method. */
    end constructor.


    constructor SparkRequest ( input pcServicePrefix as character ):
        super().

        /* Retain given prefix value if passed. */
        if (pcServicePrefix gt "") eq true then
            assign cSvcPrefix = pcServicePrefix.

        this-object:parseRequestPath(). /* Determine service, version, resource, and method. */
    end constructor.


    destructor SparkRequest ( ):
        assign
            this-object:SparkPathArray = ?
            this-object:SparkQueryData = ?
            .
    end destructor.


    /** Protected Methods **/


    method protected void setMethodName ( input pcMethodName as character ):
        if pcMethodName gt "" then
            this-object:SparkMethodName = pcMethodName.

        /**
         * If resource is present but method is still blank or just the catalog request,
         * then obtain a default method name from the current HTTP verb.
         */
        if this-object:SparkServiceName gt "" and this-object:SparkResourceName gt "" and
          (this-object:SparkMethodName eq "" or this-object:SparkMethodName eq "{&CATALOG_METHOD}") then
            case this-object:Method:
                when "GET" then
                    this-object:SparkMethodName = "read".
                when "POST" then
                    this-object:SparkMethodName = "create".
                when "PUT" then
                    this-object:SparkMethodName = "update".
                when "DELETE" then
                    this-object:SparkMethodName = "delete".
            end case.

        /* If resource and method names are blank, assume use of the catalog method. */
        if this-object:SparkResourceName eq "" and this-object:SparkMethodName eq "" then
            this-object:SparkMethodName = "{&CATALOG_METHOD}".
    end method. /* setMethodName */


    method protected void parseRequestPath ( ):
        define variable cEntry as character no-undo.
        define variable iEntry as decimal   no-undo.
        define variable iStart as integer   no-undo.
        define variable iX     as integer   no-undo.

        /**
         * A request path should begin with a transport plus a distinct service prefix.
         * By default the prefix traditionally used is "pdo" for Progress Data Object.
         * This can be altered for purposes of the Spark DOH implementation, though the
         * overall URL schema should remain the same to maintain consistency with the
         * JSDO on the front-end. There is an optional version number which may now
         * preceed the service name (supported also in the standard DOH class).
         * Pattern: /web/<service_prefix>[[/version][/service[/resource][/method]]]
         */

        /* Start with the transport path for this URI. */
        this-object:SparkServiceURI = this-object:TransportPath.

        /* Start counting from element containing service prefix. */
        do iX = 1 to this-object:SparkPathArray:Length:
            if this-object:SparkPathArray:GetCharacter(iX) eq cSvcPrefix then
                assign iStart = iX.
        end.

        if iStart eq 0 then /* Cannot proceed if the service prefix does not exist in the requested URL! */
            undo, throw new AppError(substitute("Unable to locate expected service prefix '&1'.", cSvcPrefix), 0).

        /* If only a single item in the path, return a full catalog. */
        if this-object:SparkPathArray:Length eq iStart then do:
            this-object:SparkServiceURI = "". /* Return all services for this prefix. */
            this-object:SparkServiceName = "". /* Return all services for this prefix. */
            this-object:SparkResourceName = "". /* Return all resources for all services. */
            this-object:SparkMethodName = "{&CATALOG_METHOD}". /* Treat as catalog request. */
        end. /* single-item path */
        else /* Decipher the full path up through the last entry. */
        do iX = iStart to this-object:SparkPathArray:Length:
            if iX eq iStart then /* Start by appending the service prefix to the transport. */
                this-object:SparkServiceURI = substitute("&1/&2", SparkServiceURI, cSvcPrefix).

            /* Parse the current string value in the path (should be a character). */
            assign cEntry = this-object:SparkPathArray:GetCharacter(iX).

            if cEntry eq cSvcPrefix then next. /* Ignore the service prefix portion. */

            /* Check if the path entry begins with a number (indicating a service version). */
            if can-do("0,1,2,3,4,5,6,7,8,9", substring(cEntry, 1, 1)) then
                this-object:SparkApiVersion = decimal(cEntry) no-error.
            else do:
                /* Take elements of the path based on whether a version exists or not. */
                if this-object:SparkApiVersion eq ? then
                    case iX:
                        when 2 then do:
                            /* If we stopped here, assume a request for a catalog. */
                            this-object:SparkServiceName = cEntry.
                            this-object:SparkServiceURI = substitute("&1/&2", SparkServiceURI, cEntry).
                            this-object:SparkResourceName = "". /* Reset the resource name. */
                            this-object:SparkMethodName = "{&CATALOG_METHOD}". /* Assume catalog. */
                        end.
                        when 3 then do:
                            /* When resource is present, the method must be valid. */
                            this-object:SparkResourceName = cEntry.
                            this-object:setMethodName("").
                        end.
                        when 4 then
                            /* Confirm that a proper method is set. */
                            this-object:setMethodName(cEntry).
                    end case.
                else
                    case iX:
                        when 3 then do:
                            /* If we stopped here, assume a request for a catalog. */
                            this-object:SparkServiceName = cEntry.
                            this-object:SparkServiceURI = substitute("&1/&2", SparkServiceURI, cEntry).
                            this-object:SparkResourceName = "". /* Reset the resource name. */
                            this-object:SparkMethodName = "{&CATALOG_METHOD}". /* Assume catalog. */
                        end.
                        when 4 then do:
                            /* When resource is present, the method must be valid. */
                            this-object:SparkResourceName = cEntry.
                            this-object:setMethodName("").
                        end.
                        when 5 then
                            /* Confirm that a proper method is set. */
                            this-object:setMethodName(cEntry).
                    end case.
            end. /* character entry */
        end. /* iStart to Length */
    end method. /* parseRequestPath */


    method protected longchar getJSDOFilter ( ):
        /* If working with the "read" method, which includes a specific "filter" query parameter,
         * attempt to extract only the ReadFilter property from the URL query data (as JSON object).
         */
        if this-object:SparkMethodName eq "read" and this-object:SparkQueryData:Has(ReadFilter) and
           this-object:SparkQueryData:GetType(ReadFilter) eq JsonDataType:object then
            return this-object:SparkQueryData:GetJsonObject(ReadFilter):GetJsonText(). /* Return filter object. */
        else
            return this-object:SparkQueryData:GetJsonText(). /* Otherwise return entire query string object. */
    end method. /* getJSDOFilter */


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