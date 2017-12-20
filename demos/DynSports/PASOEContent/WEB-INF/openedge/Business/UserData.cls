/*------------------------------------------------------------------------
    File        : UserData
    Purpose     : Simple class for User context data
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed May 13 15:21:07 EST 2015
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Util.ApplicationError from propath.
using Spark.Core.Util.Sendmail from propath.

block-level on error undo, throw.

class Business.UserData inherits Spark.Core.Service.DynamicResource:

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


    method public void sendResetCode ( input  username  as character,
                                       input  emailAddr as character,
                                       output opSuccess as logical,
                                       output opMessage as character ):
        define buffer bProfile for WebProfile.

        if (username gt "") ne true and (emailAddr gt "") ne true then do:
            assign
                opSuccess = false
                opMessage = "No criteria provided for account lookup (username/email)."
                .
            return.
        end. /* no username/email */

        /* Search for account by username or email. */
        find first bProfile exclusive-lock
             where bProfile.UserNum gt 1
               and bProfile.IsActive
               and not bProfile.IsLocked
               and ((username gt "" and bProfile.Username eq username) or
                    (emailAddr gt "" and bProfile.Email eq emailAddr)) no-error.
        if available(bProfile) then do on error undo, throw:
            define variable lSuccess  as logical  no-undo.
            define variable oSendmail as Sendmail no-undo.

            if (bProfile.Email gt "") ne true then do:
                assign
                    opSuccess = false
                    opMessage = "No valid email address is available for your account. Please contact a system administrator to complete this process."
                    .
                return.
            end. /* missing email */

            assign /* Generate a temporary code for the reset operation. */
                bProfile.ResetCode = Spark.Core.Security.Password:createCode(6)
                oSendmail          = new Sendmail()
                .

            /* Notify the located account with a confirmation code. */
            oSendmail:SendFrom = "noreply@progress.com".
            oSendmail:SubjectLine = "Password Reset Request".
            oSendmail:Recipient = bProfile.Email.
            oSendmail:EmailBody = substitute("A password reset was requested for your account at the MDBA Dashboard. If you DID NOT request this, "
                                            + "don't worry--your existing account password remains unaffected and no further action is required. "
                                            + "If you DID request this operation, please use the following code to complete the reset process: &1", bProfile.ResetCode).
            assign lSuccess = oSendmail:SendEmail().

            if lSuccess then
                assign
                    opSuccess = true
                    opMessage = "Confirmation code successfully sent."
                    .
            else
                assign
                    opSuccess = false
                    opMessage = "An error occurred while sending your confirmation code via email. Please try again or contact a system administrator."
                    .

            finally:
                delete object oSendmail no-error.
            end finally.
        end. /* available(bProfile) */
        else
            assign
                opSuccess = false
                opMessage = "Unable to locate account."
                .
    end method. /* sendResetCode */


    method public void resetPassword ( input  username  as character,
                                       input  emailAddr as character,
                                       input  resetCode as character,
                                       output opSuccess as logical,
                                       output opMessage as character ):
        define buffer bProfile for WebProfile.

        if (username gt "") ne true and (emailAddr gt "") ne true then do:
            assign
                opSuccess = false
                opMessage = "No criteria provided for account lookup (username/email)."
                .
            return.
        end. /* no username/email */

        if (resetCode gt "") ne true then do:
            assign
                opSuccess = false
                opMessage = "Confirmation code was not provided."
                .
            return.
        end. /* no reset code */

        /* Search for account by username or email. */
        find first bProfile exclusive-lock
             where bProfile.UserNum gt 1
               and bProfile.IsActive
               and not bProfile.IsLocked
               and ((username gt "" and bProfile.Username eq username) or
                    (emailAddr gt "" and bProfile.Email eq emailAddr)) no-error.
        if available(bProfile) then do on error undo, throw:
            define variable rSalt     as raw       no-undo.
            define variable lSuccess  as logical   no-undo.
            define variable cNewPass  as character no-undo.
            define variable oSendmail as Sendmail  no-undo.

            /* Cannot proceed if the reset code does not match! */
            if bProfile.ResetCode ne resetCode then do:
                assign
                    opSuccess = false
                    opMessage = "Confirmation code does not match account."
                    .
                return.
            end. /* code mismatch */

            if (bProfile.Email gt "") ne true then do:
                assign
                    opSuccess = false
                    opMessage = "No valid email address is available for your account. Please contact a system administrator to complete this process."
                    .
                return.
            end. /* missing email */

            assign /* Generate a new password. */
                rSalt     = generate-random-key
                cNewPass  = encode(string(rSalt))
                oSendmail = new Sendmail()
                .

            assign /* Remember previous encoded password, create new encoded password. */
                bProfile.OldPassword = bProfile.Password
                bProfile.Password    = Spark.Core.Security.Password:encodePassword(cNewPass)
                .

            /* Notify the located account with a new password. */
            oSendmail:SendFrom = "noreply@progress.com".
            oSendmail:SubjectLine = "Password Reset Confirmation".
            oSendmail:Recipient = bProfile.Email.
            oSendmail:EmailBody = substitute("Your password for the MDBA Dashboard has been successfully reset. Please use the following password "
                                            + "to access the website, along with your existing username. Once you have logged in, you may change your "
                                            + "password via the profile option at the top-right of the application. Your new password is &1", cNewPass).
            assign lSuccess = oSendmail:SendEmail().

            if lSuccess then
                assign
                    opSuccess = true
                    opMessage = "A new password has been generated and emailed to you. Please log into the site using your updated credentials."
                    .
            else
                assign
                    opSuccess = false
                    opMessage = "An error occurred while sending your confirmation code via email. Please try again or contact a system administrator."
                    .

            finally:
                delete object oSendmail no-error.
            end finally.
        end. /* available(bProfile) */
        else
            assign
                opSuccess = false
                opMessage = "Unable to locate account."
                .
    end method. /* resetPassword */


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

            assign
                bProfile.OldPassword = bProfile.Password
                bProfile.Password    = Spark.Core.Security.Password:encodePassword(newPassword)
                .

            assign
                changeSuccess = true
                changeMessage = "Password has been successfully changed."
                .
            release bProfile no-error.
        end.
        else
            assign changeMessage = "User account is not available.".
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

        if valid-object(oClientContext) then do:
            /* If user has the appropriate security, add some extra menu options. */
            if can-do(oClientContext:clientPrincipal:roles, "ROLE_WebAdmin") then do:
                define variable oSystemMenu  as JsonObject no-undo.
                define variable oSystemItems as JsonArray  no-undo.
                define variable oItem1       as JsonObject no-undo.
                define variable oItem2       as JsonObject no-undo.
                define variable oItem3       as JsonObject no-undo.

                oSystemMenu = new JsonObject().
                oSystemItems = new JsonArray().

                oItem1 = new JsonObject().
                oItem1:Add("text", "Account Maintenance").
                oItem1:Add("url", "#/WebProfile").
                oSystemItems:Add(oItem1).

                oItem2 = new JsonObject().
                oItem2:Add("text", "Security Rules").
                oItem2:Add("url", "#/SecurityRules").
                oSystemItems:Add(oItem2).

                oItem3 = new JsonObject().
                oItem3:Add("text", "Web Data").
                oItem3:Add("url", "#/WebDataGrid").
                oSystemItems:Add(oItem3).

                oSystemMenu:Add("text", "System").
                oSystemMenu:Add("items", oSystemItems).

                menuData:Add(oSystemMenu).
            end. /* ROLE_WebAdmin */
        end. /* valid-object */

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
                                        output username         as character,
                                        output emailAddr        as character ):
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

            if oClientContext:hasUserProperty("EmailAddr") then
                assign emailAddr = oClientContext:getUserProperty("EmailAddr").
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
                langStrings:Add("StateProvinceHelp", "Help text provided via UserData:getTranslations.").
                langStrings:Add("TransportNameHelp", "Prefijos est&aacute;ndar para el tipo de transporte/punto final.").
                langStrings:Add("InterceptURIHelp", "Una URL espec&iacute;fica para coincidir con esta regla (valores comod&iacute;n permitidos con '*').").
                langStrings:Add("HttpMethodHelp", "Un m&eacute;todo HTTP específico para hacer coincidir las solicitudes (o * para todas).").
                langStrings:Add("AccessRuleHelp", "Regla de Spring Security Framework para permitir el acceso en funci&oacute;n de los roles de los usuarios.").
            end.
            when "fr-FR" then do:
                langStrings:Add("SalesRepHelp", "S&eacute;lectionnez le vendeur qui a assist&eacute; &agrave; cette commande.").
                langStrings:Add("StateProvinceHelp", "Help text provided via UserData:getTranslations.").
                langStrings:Add("TransportNameHelp", "Pr&eacute;fixes standard pour le type de transport/point de terminaison.").
                langStrings:Add("InterceptURIHelp", "Une URL sp&eacute;cifique pour correspondre &agrave; cette r&egrave;gle (valeurs g&eacute;n&eacute;riques autoris&eacute;es avec '*').").
                langStrings:Add("HttpMethodHelp", "Une m&eacute;thode HTTP sp&eacute;cifique pour faire correspondre les requ&ecirc;tes (ou * pour tous).").
                langStrings:Add("AccessRuleHelp", "R&egrave;gle du cadre de s&eacute;curit&eacute; de Spring permettant l'acc&egrave;s en fonction des r&ocirc;les de l'utilisateur.").
            end.
            otherwise do:
                langStrings:Add("SalesRepHelp", "Select the salesperson who assisted with this order.").
                langStrings:Add("StateProvinceHelp", "Help text provided via UserData:getTranslations.").
                langStrings:Add("TransportNameHelp", "Standard prefixes for the type of transport/endpoint.").
                langStrings:Add("InterceptURIHelp", "A specific URL to match for this rule (wildcard values allowed with '*').").
                langStrings:Add("HttpMethodHelp", "A specific HTTP method to match for requests (or * for all).").
                langStrings:Add("AccessRuleHelp", "Spring Security Framework rule for allowing access based on user roles.").
            end.
        end case.
    end method. /* getTranslatations */


    method public void getProfile ( output FirstName     as character,
                                    output LastName      as character,
                                    output Email         as character,
                                    output MobilePhone   as character,
                                    output MobileCarrier as character,
                                    output UseTFA        as logical,
                                    output TFAMethod     as character,
                                    output QR            as character ):
        define buffer bProfile for WebProfile.

        find first bProfile no-lock
             where bProfile.Username eq oClientContext:userID
               and bProfile.IsActive
               and not bProfile.IsLocked no-error.
        if available(bProfile) then do:
            assign
                FirstName     = bProfile.FirstName
                LastName      = bProfile.LastName
                Email         = bProfile.Email
                MobilePhone   = bProfile.MobilePhone
                MobileCarrier = bProfile.MobileCarrier
                UseTFA        = bProfile.UseTFA
                TFAMethod     = bProfile.TFAMethod
                .

            /* Create string for QR code, to be used with 2FA device (eg. Google Authenticator). */
            define variable cIssuer as character no-undo initial "DynSports".
            if bProfile.UseTFA and bProfile.TFAMethod eq "Device" and bProfile.TFASecret gt "" then
                assign QR = substitute("otpauth://totp/&1:&2?secret=&3&4issuer=&1", cIssuer, bProfile.Email, bProfile.TFASecret, "&").
        end. /* available */

        release bProfile no-error.
    end method. /* getProfile */


    method public void setProfile ( input  FirstName     as character,
                                    input  LastName      as character,
                                    input  Email         as character,
                                    input  MobilePhone   as character,
                                    input  MobileCarrier as character,
                                    input  UseTFA        as logical,
                                    input  TFAMethod     as character,
                                    output updateSuccess as logical ):
        define buffer bProfile for WebProfile.

        assign updateSuccess = false.

        find first bProfile exclusive-lock
             where bProfile.Username eq oClientContext:userID
               and bProfile.IsActive
               and not bProfile.IsLocked no-error.
        if available(bProfile) then do:
            if UseTFA eq true then do:
                /* If not previously enabled, or secret is blank, create a new Base32-encoded value. */
                if not bProfile.UseTFA or (bProfile.TFASecret gt "") ne true then
                    assign bProfile.TFASecret = replace(Spark.Core.Util.Base32:EncodeData(Spark.Core.Security.Password:createCode(10)), "=", "").

                assign
                    bProfile.UseTFA    = true
                    bProfile.TFAMethod = TFAMethod
                    bProfile.TFAToken  = ""
                    .
            end.
            else
                assign
                    bProfile.UseTFA    = false
                    bProfile.TFAMethod = ""
                    bProfile.TFASecret = ""
                    bProfile.TFAToken  = ""
                    .

            assign
                bProfile.FirstName     = FirstName
                bProfile.LastName      = LastName
                bProfile.Email         = Email
                bProfile.MobilePhone   = MobilePhone
                bProfile.MobileCarrier = MobileCarrier
                .

            assign updateSuccess = true.
        end. /* available */

        release bProfile no-error.
    end method. /* setProfile */


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