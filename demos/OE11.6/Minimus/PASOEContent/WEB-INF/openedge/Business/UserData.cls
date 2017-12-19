/*------------------------------------------------------------------------
    File        : UserData
    Purpose     : Simple class for User context data
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed May 13 15:21:07 EST 2015
    Notes       :
  ----------------------------------------------------------------------*/

@program FILE(name="UserData.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="user", URI="/user", schemaName="", schemaFile="").

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

class Business.UserData inherits Spark.Core.Service.SparkEntity:


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/password", alias="password", mediaType="application/json").
    method public void changePassword ( input  oldPassword   as character,
                                        input  newPassword   as character,
                                        output changeSuccess as logical,
                                        output changeMessage as character ):
        define buffer bProfile for WebProfile.

        assign changeSuccess = false.

        if (oldPassword gt "") ne true then do:
            assign changeMessage = "Old password is missing.".
            return. /* We're done here, leave. */
        end. /* no oldPassword */

        if (newPassword gt "") ne true then do:
            assign changeMessage = "New password is missing.".
            return. /* We're done here, leave. */
        end. /* no newPassword */

        if oldPassword eq newPassword then do:
            assign changeMessage = "Passwords are the same, not changing.".
            return. /* We're done here, leave. */
        end. /* no newPassword */

        find first bProfile exclusive-lock
             where bProfile.Username eq oClientContext:userID no-error.
        if available(bProfile) then do:
            if not Spark.Core.Security.Password:checkPassword(oldPassword, bProfile.Password) then do:
                assign changeMessage = "Old password does not match account.".
                return. /* We're done here, leave. */
            end. /* not checkPassword */

            assign bProfile.Password = Spark.Core.Security.Password:encodePassword(newPassword).
            assign
                changeSuccess = true
                changeMessage = "Password has been successfully changed."
                .
            release bProfile no-error.
        end.
        else
            assign changeMessage = "User account is not available.".
    end method. /* changePassword */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/menu", alias="menu", mediaType="application/json").
    method public void getMenu ( output menuData as JsonArray ):
        define variable oParser as ObjectModelParser no-undo.

        menuData = new JsonArray(). /* Set to empty array. */

        /* For now, just output the menu data as given from a flat file. */
        file-info:file-name = Spark.Core.Util.OSTools:sparkConf + "/menu.json".
        if file-info:full-pathname eq ? then
            message substitute("Error: Menu file not found: &1", file-info:file-name).
        else do:
            oParser = new ObjectModelParser().
            menuData = cast(oParser:parseFile(file-info:full-pathname), JsonArray).
        end.

        finally:
            delete object oParser no-error.
        end finally.
    end method. /* getMenu */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/session", alias="session", mediaType="application/json").
    method public void getSessionInfo ( output anonymous        as logical,
                                        output dateFormat       as character,
                                        output decimalPoint     as character,
                                        output domainName       as character,
                                        output expires          as datetime-tz,
                                        output language         as character,
                                        output numericSeparator as character,
                                        output serverTime       as datetime-tz,
                                        output sessionID        as character,
                                        output timezone         as character,
                                        output fullname         as character,
                                        output username         as character ):
        if valid-object(oClientContext) then do:
            assign
                anonymous        = can-do(oClientContext:clientPrincipal:roles, "ROLE_ANONYMOUS")
                                       or oClientContext:clientPrincipal:roles eq ""
                                       or oClientContext:userID begins "anonymous"
                serverTime       = now
                expires          = oClientContext:loginExpiration
                domainName       = oClientContext:userDomain
                sessionID        = oClientContext:contextID
                username         = oClientContext:userID
                no-error.
            if error-status:error then
                message substitute("Notice[1]: &1", error-status:get-message(1)).

            if oClientContext:hasUserProperty("dateFormat") then
                assign dateFormat = oClientContext:getUserProperty("dateFormat").

            if oClientContext:hasUserProperty("numericDecimalPoint") then
                assign decimalPoint = oClientContext:getUserProperty("numericDecimalPoint").

            if oClientContext:hasUserProperty("numericSeparator") then
                assign numericSeparator = oClientContext:getUserProperty("numericSeparator").

            if oClientContext:hasUserProperty("timezoneOffset") then
                assign timezone = oClientContext:getUserProperty("timezoneOffset").

            if not oClientContext:hasUserProperty("ClientLanguage") then
                oClientContext:setUserProperty("ClientLanguage", "en-US").
            assign language = oClientContext:getUserProperty("ClientLanguage").

            if oClientContext:hasUserProperty("FullName") then
                assign fullname = oClientContext:getUserProperty("FullName").
        end. /* Valid Context Object */
        else
            assign
                anonymous  = true
                serverTime = now
                no-error.

        /* Output a message for any errors, except for a "find first/last failed". */
        if error-status:error and error-status:get-number(1) ne 565 then
            message substitute("Notice[2]: &1", error-status:get-message(1)).
    end method. /* getSessionInfo */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/translations", alias="translations", mediaType="application/json").
    method public void getTranslations ( input  langCode      as character,
                                         output localLanguage as character,
                                         output langStrings   as JsonObject ):
        /* Determine proper language to use for translations. */
        if (langCode gt "") eq true then
            assign localLanguage = langCode.
        else if oClientContext:hasUserProperty("ClientLanguage") then
            assign localLanguage = oClientContext:getUserProperty("ClientLanguage").
        else
            assign localLanguage = "en-US".

        /* Prepare simplistic name/value pairing in a JSON object. */
        assign langStrings = new JsonObject().

        /* Add some sample translations. */
        case localLanguage:
            when "es-ES" then do:
                langStrings:Add("SalesRepHelp", "Seleccione el vendedor que ayud&oacute; con este pedido.").
            end.
            when "fr-FR" then do:
                langStrings:Add("SalesRepHelp", "S&eacute;lectionnez le vendeur qui a assist&eacute; &agrave; cette commande.").
            end.
            otherwise do:
                langStrings:Add("SalesRepHelp", "Select the salesperson who assisted with this order.").
            end.
        end case.
    end method. /* getTranslatations */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/locale", alias="locale", mediaType="application/json").
    method public void setLocale ( input  userLanguage as character,
                                   input  userTimezone as character,
                                   output changed      as JsonArray ):
        define variable oChanged as JsonArray no-undo.

        assign changed = new JsonArray().

        if (userLanguage gt "") eq true then do:
            oClientContext:setUserProperty("ClientLanguage", userLanguage).
            changed:Add("language").
        end. /* cLanguage */

        if (userTimezone gt "") eq true then do:
            if (userTimezone begins "-" or userTimezone begins "+") and userTimezone matches "*:00" then do:
                oClientContext:setUserProperty("timezoneOffset", userTimezone).
                changed:Add("timezone").
            end.
            else
                undo, throw new ApplicationError("Timezone must be in the format of +/-HH:00").
        end. /* cTimezone */
    end method. /* setLocale */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/contextFetch", alias="", mediaType="application/json").
    method public void contextFetch ( input  contextName  as character,
                                      output contextValue as character ):
        /* Filter specific types of context, allowing only known "safe" items to be retrieved. */
        if contextName matches "grid:*" and oClientContext:hasUserProperty(contextName) then
            assign contextValue = oClientContext:getUserPropertyAsChar(contextName).
        else
            assign contextValue = ?.
    end method. /* contextFetch */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/contextStore", alias="", mediaType="application/json").
    method public void contextStore ( input  contextName  as character,
                                      input  contextValue as character,
                                      output success      as logical ):
        /* Filter specific types of context, allowing only known "safe" items to be stored. */
        if contextName matches "grid:*" then do:
            oClientContext:setUserProperty(contextName, contextValue).
            assign success = true.
        end.
    end method. /* contextStore */

end class.