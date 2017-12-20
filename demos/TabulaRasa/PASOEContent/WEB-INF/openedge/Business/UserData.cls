/*------------------------------------------------------------------------
    File        : UserData
    Purpose     : Simple class for User context data
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed May 13 15:21:07 EST 2015
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Service.DynamicResource from propath.
using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

class Business.UserData inherits DynamicResource:

    define public override property serviceURI as character
        initial "/web/pdo/common" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "user" no-undo get.
        protected set.


    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getMenu", "menu", "get").
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getSessionInfo", "session", "get").
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getTranslations", "translations", "put").
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "changePassword", "password", "put").
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "setLocale", "locale", "put").
    end method. /* initialize */


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

        /* Insert code here to perform a password change. */
    end method. /* changePassword */


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


    method public void setLocale ( input  language as character,
                                   input  timezone as integer,
                                   output changed  as JsonArray ):
        define variable cLanguage as character no-undo.
        define variable cTimezone as character no-undo.
        define variable oChanged  as JsonArray no-undo.

        assign /* Parameters are specified on method, but are still optional. */
            cLanguage = oRequest:getParamAsChar("language", true)
            cTimezone = string(oRequest:getParamAsInt("timezone", true), "+HH:MM")
            changed   = new JsonArray()
            .

        if (cLanguage gt "") eq true then do:
            oClientContext:setUserProperty("ClientLanguage", cLanguage).
            changed:Add("language").
        end. /* cLanguage */

        if (cTimezone gt "") eq true then do:
            if (cTimeZone begins "-" or cTimeZone begins "+") and cTimeZone matches "*:00" then do:
                oClientContext:setUserProperty("timezoneOffset", cTimezone).
                changed:Add("timezone").
            end.
            else
                undo, throw new ApplicationError("Timezone must be in the format of +/-HH:00").
        end. /* cTimezone */
    end method. /* setLocale */


    method public void contextFetch ( input  contextName  as character,
                                      output contextValue as character ):
        /* Filter specific types of context, allowing only known "safe" items to be retrieved. */
        if contextName matches "grid:*" and oClientContext:hasUserProperty(contextName) then
            assign contextValue = oClientContext:getUserPropertyAsChar(contextName).
        else
            assign contextValue = ?.
    end method. /* contextFetch */


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