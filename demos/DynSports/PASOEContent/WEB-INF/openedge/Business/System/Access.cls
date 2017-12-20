/*------------------------------------------------------------------------
    File        : Access.cls
    Author(s)   : Dustin Grau
    Created     : Wed Nov 29 15:10:04 EST 2017
    Notes       :
  ----------------------------------------------------------------------*/

&GLOBAL-DEFINE WEBAPP_NAME DynSports

using Progress.Lang.* from propath.
using Spark.Core.Manager.ISchemaManager from propath.
using Spark.Core.Util.OSTools from propath.

block-level on error undo, throw.

class Business.System.Access inherits Spark.Core.Service.DynamicResource:

    define override public property serviceURI as character
        initial "/web/pdo/system" no-undo get.
        set.

    define override public property resourceName as character
        initial "access" no-undo get.
        set.

    define private temp-table ttLine
        field lineNo    as integer
        field lineText  as character
        field isComment as logical
        index pkLine is primary unique lineNo
        .

    define private temp-table rules
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
        if not can-find(first rules) then return false.

        /* Using the given order, apply a number to each rule. */
        for each rules exclusive-lock:
            assign iLine = iLine + 1.
            assign rules.ruleOrder = iLine.
        end. /* for each rules */

        /* Ensure destination file is available. */
        file-info:file-name = this-object:getRulesFilename().
        if file-info:full-pathname ne ? then do:
            os-copy value(file-info:full-pathname) value(substitute("&1.&2", file-info:full-pathname, mtime)).
            output to value(file-info:full-pathname).

            put unformatted '# "url-pattern","<method>","<spring-access-expression>"' skip. /* Define the file format. */

            /* Output the transport rules first. */
            for each rules no-lock
               where rules.transportName ne "default"
                 and rules.transportName ne "static"
               break by rules.transportName
                     by rules.ruleOrder:
                if first-of(rules.transportName) then do:
                    put unformatted skip(1). /* Skip a line and ouput a comment. */
                    put unformatted substitute("############## Intercept-url definitions for the &1 transport URIs ###############", caps(rules.transportName)) skip.
                end. /* first-of */

                put unformatted substitute('"&1","&2","&3"', rules.interceptURI, caps(rules.httpMethod), rules.accessRule) skip.
            end. /* for each rules */

            put unformatted skip(1). /* Skip a line and ouput a comment. */
            put unformatted '############## Intercept-url definitions for the default URI space #################' skip.

            /* Output the static rules next. */
            for each rules no-lock
               where rules.transportName eq "static"
                  by rules.ruleOrder:
                put unformatted substitute('"&1","&2","&3"', rules.interceptURI, rules.httpMethod, rules.accessRule) skip.
            end. /* for each rules */

            put unformatted skip(1). /* Skip a line and ouput a comment. */
            put unformatted '# Best practice - deny anything not explicitly granted' skip.

            /* Must make sure at least 1 default rule exists for security. */
            if not can-find(first rules no-lock
                            where rules.transportName eq "default") then do:
                /* This rule denies all access. */
                create rules.
                assign
                    rules.transportName = "default"
                    rules.interceptURI  = "/**"
                    rules.httpMethod    = "*"
                    rules.accessRule    = "denyAll()"
                    .
                release rules.
            end. /* no default */

            /* Output any default rules last. */
            for each rules no-lock
               where rules.transportName eq "default"
                  by rules.ruleOrder:
                put unformatted substitute('"&1","&2","&3"', rules.interceptURI, rules.httpMethod, rules.accessRule) skip.
            end. /* for each rules */

            output close.
            return true.
        end. /* File Exists */

        return false.
    end method. /* writeInterceptRules */


    /***** Public Methods *****/


    method public override void initialize ( ):

        define variable hTable as handle no-undo.
        assign hTable = temp-table rules:handle.
        cast(Ccs.Common.Application:StartupManager:getManager(get-class(ISchemaManager)), ISchemaManager):registerTempTable(input hTable).
        delete object hTable no-error.

        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getInterceptRules", "rules", "get").
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "setInterceptRules", "apply", "put").
    end method. /* initialize */

    method public void getInterceptRules ( output table for rules ):
        define variable cRule as character no-undo.

        /* Ignore request if user does not have the proper role. */
        if not can-do(oClientContext:clientPrincipal:roles, "ROLE_WebAdmin") then return.

        this-object:readInterceptRules().
        empty temp-table rules.

        for each ttLine no-lock
           where ttLine.lineText gt ""
             and not ttLine.isComment:
            /* Change the delimiter for major components. */
            assign cRule = replace(ttLine.lineText, '","', "|").

            /* Create the rule record using the given line. */
            create rules.
            assign
                rules.interceptURI = replace(entry(1, cRule, "|"), '"', "")
                rules.httpMethod   = replace(entry(2, cRule, "|"), '"', "")
                rules.accessRule   = replace(entry(3, cRule, "|"), '"', "")
                .

            /* Determine the correct transport/namespace. */
            case true:
                when rules.interceptURI begins "/apsv" then
                    assign rules.transportName = "APSV".
                when rules.interceptURI begins "/rest" then
                    assign rules.transportName = "REST".
                when rules.interceptURI begins "/soap" then
                    assign rules.transportName = "SOAP".
                when rules.interceptURI begins "/web" then
                    assign rules.transportName = "WEB".
                when rules.interceptURI eq "/**" then
                    assign rules.transportName = "DEFAULT".
                otherwise
                    assign rules.transportName = "STATIC".
            end case.
        end. /* for each ttLine */
    end method. /* getInterceptRules */

    method public void setInterceptRules ( input  table for rules,
                                           output success as logical ):
        /* Write rules back to file (creates backup first). */
        assign success = this-object:writeInterceptRules().
    end method. /* setInterceptRules */

end class.
