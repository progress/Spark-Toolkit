/*------------------------------------------------------------------------
    File        : Access.cls
    Author(s)   : Dustin Grau
    Created     : Wed Nov 29 15:10:04 EST 2017
    Notes       :
  ----------------------------------------------------------------------*/

@program FILE(name="Access.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="access", URI="/access", schemaName="", schemaFile="").

&GLOBAL-DEFINE WEBAPP_NAME sports

using Progress.Lang.* from propath.
using Spark.Core.Manager.ISchemaManager from propath.
using Spark.Core.Util.OSTools from propath.

block-level on error undo, throw.

class Business.System.Access inherits Spark.Core.Service.SparkEntity:

    define private temp-table ttLine
        field lineNo    as integer
        field lineText  as character
        field isComment as logical
        index pkLine is primary unique lineNo
        .

    define private temp-table ttRules
        field ruleOrder     as integer
        field transportName as character
        field interceptURI  as character
        field httpMethod    as character
        field accessRule    as character
        . /* No index, use in the given order! */

    method private character getRulesFilename ( ):
        define variable cWebApp as character no-undo.

        /* Obtain the full path to the expected security intercept rules file for this webapp. */
        assign cWebApp = substitute("&1/webapps/&2", right-trim(OSTools:catalinaBase, "/"), "{&WEBAPP_NAME}").
        return substitute("&1/WEB-INF/oeablSecurity.csv", cWebApp).
    end method. /* getRulesFilename */

    method private void readInterceptRules ( ):
        define variable cLine as character no-undo.
        define variable iLine as integer   no-undo initial 0.

        /* Process file if available on file system. */
        file-info:file-name = this-object:getRulesFilename().
        if file-info:full-pathname ne ? then do:
            empty temp-table ttLine.

            input from value(file-info:full-pathname) unbuffered no-convert.
            repeat:
                /* Read each line until done. */
                import unformatted cLine.
                assign iLine = iLine + 1.

                /* Create temp-table of available lines. */
                create ttLine.
                assign
                    ttLine.lineNo    = iLine
                    ttLine.lineText  = trim(cLine)
                    ttLine.isComment = (cLine begins "#")
                    .

                release ttLine.
            end. /* repeat */
            input close.
        end. /* File Exists */
    end method. /* readInterceptRules */

    method private logical writeInterceptRules ( ):
        define variable iLine as integer no-undo initial 0.

        /* Ignore request if user does not have the proper role. */
        if not can-do(oClientContext:clientPrincipal:roles, "ROLE_WebAdmin") then return false.

        /* Cannot output what we do not have. */
        if not can-find(first ttRules) then return false.

        /* Using the given order, apply a number to each rule. */
        for each ttRules exclusive-lock:
            assign iLine = iLine + 1.
            assign ttRules.ruleOrder = iLine.
        end. /* for each ttRules */

        /* Ensure destination file is available. */
        file-info:file-name = this-object:getRulesFilename().
        if file-info:full-pathname ne ? then do:
            os-copy value(file-info:full-pathname) value(substitute("&1.&2", file-info:full-pathname, mtime)).
            output to value(file-info:full-pathname).

            put unformatted '# "url-pattern","<method>","<spring-access-expression>"' skip. /* Define the file format. */

            /* Output the transport rules first. */
            for each ttRules no-lock
               where ttRules.transportName ne "default"
                 and ttRules.transportName ne "static"
               break by ttRules.transportName
                     by ttRules.ruleOrder:
                if first-of(ttRules.transportName) then do:
                    put unformatted skip(1). /* Skip a line and ouput a comment. */
                    put unformatted substitute("############## Intercept-url definitions for the &1 transport URIs ###############", caps(ttRules.transportName)) skip.
                end. /* first-of */

                put unformatted substitute('"&1","&2","&3"', ttRules.interceptURI, caps(ttRules.httpMethod), ttRules.accessRule) skip.
            end. /* for each ttRules */

            put unformatted skip(1). /* Skip a line and ouput a comment. */
            put unformatted '############## Intercept-url definitions for the default URI space #################' skip.

            /* Output the static rules next. */
            for each ttRules no-lock
               where ttRules.transportName eq "static"
                  by ttRules.ruleOrder:
                put unformatted substitute('"&1","&2","&3"', ttRules.interceptURI, ttRules.httpMethod, ttRules.accessRule) skip.
            end. /* for each ttRules */

            put unformatted skip(1). /* Skip a line and ouput a comment. */
            put unformatted '# Best practice - deny anything not explicitly granted' skip.

            /* Must make sure at least 1 default rule exists for security. */
            if not can-find(first ttRules no-lock
                            where ttRules.transportName eq "default") then do:
                /* This rule denies all access. */
                create ttRules.
                assign
                    ttRules.transportName = "default"
                    ttRules.interceptURI  = "/**"
                    ttRules.httpMethod    = "*"
                    ttRules.accessRule    = "denyAll()"
                    .
                release ttRules.
            end. /* no default */

            /* Output any default rules last. */
            for each ttRules no-lock
               where ttRules.transportName eq "default"
                  by ttRules.ruleOrder:
                put unformatted substitute('"&1","&2","&3"', ttRules.interceptURI, ttRules.httpMethod, ttRules.accessRule) skip.
            end. /* for each ttRules */

            output close.
            return true.
        end. /* File Exists */

        return false.
    end method. /* writeInterceptRules */


    /***** Public Methods *****/


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/rules", alias="rules", mediaType="application/json").
    method public void getInterceptRules ( output rules as Progress.Json.ObjectModel.JsonArray ):
        define variable cRule as character no-undo.

        /* Ignore request if user does not have the proper role. */
        if not can-do(oClientContext:clientPrincipal:roles, "ROLE_WebAdmin") then return.

        this-object:readInterceptRules().
        empty temp-table ttRules.

        for each ttLine no-lock
           where ttLine.lineText gt ""
             and not ttLine.isComment:
            /* Change the delimiter for major components. */
            assign cRule = replace(ttLine.lineText, '","', "|").

            /* Create the rule record using the given line. */
            create ttRules.
            assign
                ttRules.interceptURI = replace(entry(1, cRule, "|"), '"', "")
                ttRules.httpMethod   = replace(entry(2, cRule, "|"), '"', "")
                ttRules.accessRule   = replace(entry(3, cRule, "|"), '"', "")
                .

            /* Determine the correct transport/namespace. */
            case true:
                when ttRules.interceptURI begins "/apsv" then
                    assign ttRules.transportName = "APSV".
                when ttRules.interceptURI begins "/rest" then
                    assign ttRules.transportName = "REST".
                when ttRules.interceptURI begins "/soap" then
                    assign ttRules.transportName = "SOAP".
                when ttRules.interceptURI begins "/web" then
                    assign ttRules.transportName = "WEB".
                when ttRules.interceptURI eq "/**" then
                    assign ttRules.transportName = "DEFAULT".
                otherwise
                    assign ttRules.transportName = "STATIC".
            end case.
        end. /* for each ttLine */

        /* Must output as a JsonArray to avoid an issue with nested temp-table names. */
        define variable lcData as longchar no-undo.
        temp-table ttRules:write-json("longchar", lcData, true, "UTF-8", false, true, false).
        define variable oParse as Progress.Json.ObjectModel.ObjectModelParser no-undo.
        assign oParse = new Progress.Json.ObjectModel.ObjectModelParser().
        rules = cast(oParse:Parse(lcData), Progress.Json.ObjectModel.JsonArray).
        assign lcData = ?.
    end method. /* getInterceptRules */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/apply", alias="apply", mediaType="application/json").
    method public void setInterceptRules ( input  rules as Progress.Json.ObjectModel.JsonArray,
                                           output success as logical ):
        /* Write rules back to file (creates backup first). */
        empty temp-table ttRules.
        temp-table ttRules:read-json("JsonArray", rules, "empty").
        assign success = this-object:writeInterceptRules().
    end method. /* setInterceptRules */

end class.
