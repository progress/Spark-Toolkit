/*------------------------------------------------------------------------
    File        : Spark.Core.Security.OEUserRealm
    Purpose     : Implement methods for OERealm service.
    Description : Applies back-end logic to OEReam authorization requests.
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed Dec 10 09:13:43 EST 2014
    Notes       : <pre>
In the appSecurity-xxxx-oerealm.xml security model, this class
is the target of the realmClass in the OERealmUserDetails bean.
The security model is selected by filename in web.xml under the
context-param section for "contextConfigLocation".
The default operation/response of all methods contained in this class
will return a passing value for all operations of the OERealm process!
To avoid opening up your application to attack, you must provide an
override to the getPassword() and checkPasswordHash() methods!
</pre>
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Constant.OERealmDefs from propath.
using Spark.Core.Message.ConfigMessage from propath.

block-level on error undo, throw.

class Spark.Core.Security.OEUserRealm implements Progress.Security.Realm.IHybridRealm, Spark.Core.Security.IAuthHandler abstract:

    define protected variable oConfig   as ConfigMessage no-undo.
    define protected variable useDebugs as logical       no-undo initial false.

    define private variable clientRole as character no-undo.
    define private variable domains    as JsonArray no-undo.


    constructor public OEUserRealm ( ):
        assign domains = new JsonArray().
        loadConfig().
    end constructor.


    method protected void loadConfig():
        define variable oDomain as JsonObject no-undo.

        file-info:file-name = right-trim(replace(os-getenv("SPARK_CONF"),"~\","/"),"/") + "/SparkRealm.json".
        if file-info:full-pathname eq ? then
            file-info:file-name = right-trim(replace(os-getenv("CATALINA_BASE"),"~\","/"),"/") + "/conf/spark/SparkRealm.json".
        if file-info:full-pathname eq ? then
            file-info:file-name = right-trim(replace(os-getenv("CATALINA_BASE"),"~\","/"),"/") + "/conf/SparkRealm.json".

        if file-info:full-pathname eq ? then
            undo, throw new Progress.Lang.AppError("SparkRealm.json file not found", -404).

        oConfig = new ConfigMessage().
        oConfig:deserializeMessageFromFile(file-info:full-pathname).

        clientRole = oConfig:getParamAsChar("role").
        useDebugs = oConfig:getParamAsLog("debug", true).
        if oConfig:hasParam("domain") or oConfig:hasParam("domains") then do:
            /* Config file has distict domain/password combination. */
            if oConfig:hasParam("domain") and oConfig:hasParam("password") then do:
                assign oDomain = new JsonObject().
                oDomain:Add("domain", oConfig:getParamAsChar("domain")).
                oDomain:Add("password", oConfig:getParamAsChar("password")).
                domains:Add(oDomain).
            end. /* domain/password */

            /* Config file has multiple domains configured. */
            if oConfig:hasParam("domains") then do:
                domains = oConfig:getParamAsJsonArray("domains").
            end. /* domains */
        end.
        else
            message "Notice: No domain(s) configured in SparkRealm config file.".

        if useDebugs then do:
            message "Loaded Config File:" file-info:full-pathname.
            message "Role:" clientRole.
            message "Domains:" string(domains:GetJsonText()).
        end.

        catch err as Progress.Lang.Error:
            message substitute("LoadConfig: &1", err:GetMessage(1)).
        end catch.
    end method.


    method protected logical validateRequest ( ):
        return validateRequest("[No Name]").
    end method.


    method protected logical validateRequest ( input pcSourceName as character ):
        define variable lResult as logical no-undo initial false.
        define variable iX      as integer no-undo.

        /**
         * Each request to this class is expected to be a separate request from the Tomcat server which
         * is authenticating a user. As such, each request must go through this routine to ensure that
         * it is originating from a known point by including a distinct CP token with a non-application
         * domain and passcode. This is meant to deter requests from outside sources that are not here
         * for the express purpose of authenticating a user--in other words, potential attacks.
         */

        define variable oPrincipal as OpenEdge.Security.Principal no-undo.
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).

        if oPrincipal:Token ne ? and valid-handle(oPrincipal:Token) then do:
            DOMAINBLK:
            do iX = 1 to domains:length:
                /* Just confirm if sealed request matches a known password from our config file. */
                assign lResult = oPrincipal:Token:validate-seal(domains:GetJsonObject(iX):GetCharacter("password")).
                if lResult then leave DOMAINBLK. /* Done here. */
            end.

            if lResult eq true then do:
                /* If seal is validated, check the initial CP role. */
                if not oPrincipal:Authorize(clientRole) then do:
                    assign lResult = false.
                    if useDebugs then
                        message substitute("Request CP seal is valid, but role &1 is not.", oPrincipal:Token:roles).
                end. /* clientRole */
            end.
            else if useDebugs then
                message substitute("Unable to validate CP seal for domain &1.", oPrincipal:Token:domain-name).

            if useDebugs then
                message substitute("Request by &1@&2 for '&3' is &4.",
                                   oPrincipal:Token:user-id, oPrincipal:Token:domain-name,
                                   pcSourceName, trim(string(lResult, "valid/invalid"))).
        end. /* hCPO */
        else if useDebugs then
            message "Invalid request CP handle, unable to validate.".

        return lResult.

        finally:
            delete object oPrincipal no-error.
        end finally.
    end method.


    /**************************** IAuthHandler Methods *****************************/

    /**
     * These methods are meant to be "helpers" to the larger tasks provided by the
     * IHybridRealm class. NOTE: The default for these methods is to return a passing
     * value, so if your application does not support a particular function, leaving
     * the default method will allow authentication to continue without error.
     */

    /*------------------------------------------------------------------------------
     Purpose: Compare the user-supplied password to a hashed password.
     Notes: Implement as a protected method in your own class.
        @param pcPassword Externally supplied password by user
        @param pcHashPass Internally stored password for user
        @return Logical pass/fail for operation
    ------------------------------------------------------------------------------*/
    method protected logical checkPasswordHash ( input pcPassword as character,
                                                 input pcHashPass as character ):
        /* Forward to actual method without need of UserID. */
        return checkPasswordHash(?, pcPassword, pcHashPass).
    end method. /* checkPasswordHash */


    /*------------------------------------------------------------------------------
     Purpose: Compare the user-supplied password to a hashed password, with UserID.
     Notes: Implement as a protected method in your own class.
        @param piUserID UserID value, as integer
        @param pcPassword Externally supplied password by user
        @param pcHashPass Internally stored password for user
        @return Logical pass/fail for operation
    ------------------------------------------------------------------------------*/
    method protected logical checkPasswordHash ( input piUserID   as integer,
                                                 input pcPassword as character,
                                                 input pcHashPass as character ):
        return true. /* If not overridden, assume password is good. */
    end method. /* checkPasswordHash */


    /*------------------------------------------------------------------------------
     Purpose: Obtain the password for a given UserID.
     Notes: Implement as a protected method in your own class.
         @param piUserID UserID value, as integer
         @return Internally stored password value
    ------------------------------------------------------------------------------*/
    method protected character getPassword ( input piUserID as integer ):
        return ?. /* If not overridden, assume no password. */
    end method. /* getPassword */


    /*------------------------------------------------------------------------------
     Purpose: Perform an action after authentication (validatePassword).
     Notes: Implement as a protected method in your own class, if needed.
         @param piUserID UserID value, as integer
         @param lRetVal Result of authentication action, as logical
         @return Void
    ------------------------------------------------------------------------------*/
    method protected void postAuthenticate ( input piUserID as integer,
                                             input lRetVal  as logical ):
        /* Override to note this user's success/failure to authenticate. */
    end method. /* postAuthenticate */


    /*------------------------------------------------------------------------------
     Purpose: Obtain the UserID for a given username (and domain, optional).
     Notes:
        @param pcUsername Username portion of credentials
        @param pcDomainName Domain portion of credentials
        @return Unique identifier for user, as integer
    ------------------------------------------------------------------------------*/
    method public integer getUserID ( input pcUsername   as character,
                                      input pcDomainName as character ):
        return 1. /* If not overridden, just return a positive value. */
    end method. /* getUserID */


    /*------------------------------------------------------------------------------
     Purpose: Return active status for a given UserID.
     Notes:
        @param piUserID UserID value, as integer
        @return Logical pass/fail for operation
    ------------------------------------------------------------------------------*/
    method public logical isActive ( input piUserID as integer ):
        return true. /* If not overridden, assume is active. */
    end method. /* isActive */


    /*------------------------------------------------------------------------------
     Purpose: Return expiration status for a given UserID.
     Notes:
        @param piUserID UserID value, as integer
        @return Logical pass/fail for operation
    ------------------------------------------------------------------------------*/
    method public logical isExpired ( input piUserID as integer ):
        return false. /* If not overridden, assume not expired. */
    end method. /* isExpired */


    /*------------------------------------------------------------------------------
     Purpose: Return locked status for a given UserID.
     Notes:
        @param piUserID UserID value, as integer
        @return Logical pass/fail for operation
    ------------------------------------------------------------------------------*/
    method public logical isLocked ( input piUserID as integer ):
        return false. /* If not overridden, assume not locked. */
    end method. /* isLocked */


    /*------------------------------------------------------------------------------
     Purpose: Return available roles for a given UserID.
     Notes:
        @param piUserID UserID value, as integer
        @return Comma-separated list of roles (without ROLE_ prefix)
    ------------------------------------------------------------------------------*/
    method public character getUserRoles ( input piUserID as integer ):
        return "EndUser". /* Provides basic role for access. */
    end method. /* getUserRoles */


    /**************************** IHybridRealm Methods ******************************/

    /**
     * These methods come from the original IHybridRealm class within OpenEdge,
     * and are broken down to call more atomic methods to obtain data. The goal
     * is to not have to know how these are implemented directly, but to only
     * require the individual components be overridden when necessary.
     */

    method public character GetAttribute ( input piUserID   as integer,
                                           input pcAttrName as character ):
        define variable cValue as character no-undo initial ?.

        if not this-object:validateRequest("GetAttribute") then
            message "Unauthorized request".
        else
            case pcAttrName:
                when OERealmDefs:REALM_ATTR_ENABLED then
                    /* Value for OERealm ATTR_ENABLED */
                    assign cValue = string(isActive(piUserID), "1/0").
                when OERealmDefs:REALM_ATTR_LOCKED then
                    /* Value for OERealm ATTR_LOCKED */
                    assign cValue = string(isLocked(piUserID), "1/0").
                when OERealmDefs:REALM_ATTR_EXPIRED then
                    /* Value for OERealm ATTR_EXPIRED */
                    assign cValue = string(isExpired(piUserID), "1/0").
                when OERealmDefs:REALM_ATTR_ROLES then
                    /* Generate a comma-delimited list of roles associated with this user.
                     * These roles will map to intercept-url patterns to grant access to
                     * various resource URI's as defined for the REST adapter services.
                     * A basic role of "EndUser" (mapped to ROLE_EndUser) is required for
                     * minimum secured access, based on this demo code. Your actual app
                     * security may vary.
                     */
                    assign cValue = getUserRoles(piUserID).
                otherwise
                    assign cValue = ?.
            end case.

        if useDebugs then
            message piUserID ":" pcAttrName ":" cValue.

        return cValue.

        catch err as Progress.Lang.Error:
            message substitute("GetAttribute: &1", err:GetMessage(1)).
            return ?.
        end catch.
    end method. /* GetAttribute */


    method public character extent GetAttributeNames ( input piUserID as integer ):
        /* Not configured for this project. */
        define variable cpcAttrNames as character extent no-undo.

        if not this-object:validateRequest("GetAttributeNames") then
            message "Unauthorized request".

        if useDebugs then
            message piUserID.

        return cpcAttrNames.

        catch err as Progress.Lang.Error:
            message substitute("GetAttributeNames: &1", err:GetMessage(1)).
            return cpcAttrNames.
        end catch.
    end method. /* GetAttributeNames */


    method public character extent GetUsernames ( ):
        /* Not configured for this project. */
        define variable cUsernames as character extent no-undo.

        if not this-object:validateRequest("GetUsernames") then
            message "Unauthorized request".

        if useDebugs then
            message "GetUsernames".

        return cUsernames.

        catch err as Progress.Lang.Error:
            message substitute("GetUsernames: &1", err:GetMessage(1)).
            return cUsernames.
        end catch.
    end method. /* GetUsernames */


    method public character extent GetUsernamesByQuery ( input pcQueryString as character ):
        /* Not configured for this project. */
        define variable cUsernames as character extent no-undo.

        if not this-object:validateRequest("GetUsernamesByQuery") then
            message "Unauthorized request".

        if useDebugs then
            message pcQueryString.

        return cUsernames.

        catch err as Progress.Lang.Error:
            message substitute("GetUsernamesByQuery: &1", err:GetMessage(1)).
            return cUsernames.
        end catch.
    end method. /* GetUsernamesByQuery */


    method public character extent GetUsernamesByQuery ( input pcAttrName  as character,
                                                         input pcAttrValue as character ):
        /* Not configured for this project. */
        define variable cUsernames as character extent no-undo.

        if not this-object:validateRequest("GetUsernamesByQuery") then
            message "Unauthorized request".

        if useDebugs then
            message pcAttrName ":" pcAttrValue.

        return cUsernames.

        catch err as Progress.Lang.Error:
            message substitute("GetUsernamesByQuery: &1", err:GetMessage(1)).
            return cUsernames.
        end catch.
    end method. /* GetUsernamesByQuery */


    method public logical RemoveAttribute ( input piUserID   as integer,
                                            input pcAttrName as character ):
        /* Not configured for this project. */
        if not this-object:validateRequest("RemoveAttribute") then
            message "Unauthorized request".

        if useDebugs then
            message piUserID ":" pcAttrName.

        return true.

        catch err as Progress.Lang.Error:
            message substitute("RemoveAttribute: &1", err:GetMessage(1)).
            return false.
        end catch.
    end method. /* RemoveAttribute */


    method public logical SetAttribute ( input piUserID    as integer,
                                         input pcAttrName  as character,
                                         input pcAttrValue as character ):
        /* Not configured for this project. */
        if not this-object:validateRequest("SetAttribute") then
            message "Unauthorized request".

        if useDebugs then
            message piUserID ":" pcAttrName ":" pcAttrValue.

        return true.

        catch err as Progress.Lang.Error:
            message substitute("SetAttribute: &1", err:GetMessage(1)).
            return false.
        end catch.
    end method. /* SetAttribute */


    method public logical ValidatePassword ( input piUserID   as integer,
                                             input pcPassword as character ):
        /* Validate the password hash to the value in the user's profile. */
        if not this-object:validateRequest("ValidatePassword") then do:
            message "Unauthorized request".
            return false.
        end.

        if useDebugs then
            message "UserID:" piUserID "Password:" substring(pcPassword, 1, 1) + fill("*", length(pcPassword) - 1).

        if piUserID eq 0 and pcPassword eq "undefined" then
            assign pcPassword = "".

        define variable lRetVal as logical no-undo initial ?.
        assign lRetVal = checkPasswordHash(piUserID, pcPassword, getPassword(piUserID)).
        postAuthenticate(piUserID, lRetVal).

        return lRetVal.

        catch err as Progress.Lang.Error:
            message substitute("ValidatePassword: &1", err:GetMessage(1)).
            return false.
        end catch.
    end method. /* ValidatePassword */


    method public logical ValidatePassword ( input piUserID    as integer,
                                             input pcDigest    as character,
                                             input pcNonce     as character,
                                             input pcTimestamp as character ):
        /* Not configured for this project. */
        if not this-object:validateRequest("ValidatePassword") then
            message "Unauthorized request".

        if useDebugs then
            message piUserID ":" pcDigest ":" pcNonce ":" pcTimestamp.

        return false.

        catch err as Progress.Lang.Error:
            message substitute("ValidatePassword: &1", err:GetMessage(1)).
            return false.
        end catch.
    end method. /* ValidatePassword */


    method public integer ValidateUser ( input pcUsername as character ):
        /* Users are identified by a unique integer value. */
        define variable cUsername   as character no-undo.
        define variable cDomainName as character no-undo.

        if not this-object:validateRequest("ValidateUser") then do:
            message "Unauthorized request".
            return -1.
        end.

        assign
            cUsername   = entry(1, pcUsername, "@")
            cDomainName = entry(2, pcUsername, "@") when num-entries(pcUsername, "@") eq 2
            no-error
            .

        if useDebugs then
            message "User:" cUsername "Domain:" cDomainName.

        return getUserID(cUsername, cDomainName).

        catch err as Progress.Lang.Error:
            message substitute("ValidateUser: &1", err:GetMessage(1)).
            return -1.
        end catch.
    end method. /* ValidateUser */

end class.
