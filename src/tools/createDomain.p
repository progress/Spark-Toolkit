/*------------------------------------------------------------------------
    File        : createDomain.p
    Purpose     : Create or update a single domain for securing API requests.
    Syntax      : Execute procedure while connected to application databases.
    Description :
    Author(s)   : Dustin Grau
    Created     : Mon Dec 19 15:06:27 EST 2016
    Notes       : Adds domain to database(s), and produces a Spark config file.
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

using Progress.Lang.Error from propath.
using OpenEdge.DataAdmin.* from propath.
using OpenEdge.DataAdmin.Error.* from propath.
using OpenEdge.DataAdmin.Lang.Collections.* from propath.

block-level on error undo, throw.

/* NOTICE: Do not use the "@" symbol in any passcodes! */
&global-define DLC C:\Progress\OpenEdge
&global-define DomainType _extsso
&global-define ResetName "SparkReset.cp"

define variable domainName        as character no-undo.
define variable domainAccessCode  as character no-undo.
define variable domainDescription as character no-undo.

define variable oService as DataAdminService no-undo.
define variable oDomain  as IDomain          no-undo.

define variable iDB as integer no-undo.
define variable ix as integer no-undo.
define variable iy as integer no-undo.

define variable oSession as Progress.Json.ObjectModel.JsonObject no-undo.
define variable oConfig  as Progress.Json.ObjectModel.JsonObject no-undo.
define variable oParams  as Progress.Json.ObjectModel.JsonArray  no-undo.
define variable oReset   as Progress.Json.ObjectModel.JsonObject no-undo.
define variable oEntry   as Progress.Json.ObjectModel.JsonObject no-undo.
define variable oDomains as Progress.Json.ObjectModel.JsonArray  no-undo.

/* ***************************  Main Block  *************************** */

define frame domain-info
    domainName format "X(15)" label "{&DomainType} Domain Name" colon 20
    skip(1)
    domainAccessCode format "X(15)" label "Domain Access Code" colon 20
    skip(1)
    domainDescription format "X(25)" label "Domain Description" colon 20
    with centered width 75 side-labels row 4.

update
    domainName
    domainAccessCode
    domainDescription
    with frame domain-info.

/* Apply changes to all connected databases. */
do iDB = 1 to num-dbs:
    /* Used for Spark config file. */
    assign oSession = new Progress.Json.ObjectModel.JsonObject().
    assign oConfig = new Progress.Json.ObjectModel.JsonObject().
    assign oParams = new Progress.Json.ObjectModel.JsonArray().
    assign oReset = new Progress.Json.ObjectModel.JsonObject().
    assign oDomains = new Progress.Json.ObjectModel.JsonArray().
    oReset:Add("ResetClientPrincipal", {&ResetName}).
    oParams:Add(oReset).
    oConfig:Add("SessionParam", oParams).

    assign oService = new DataAdminService(ldbname(iDB)).
    if valid-object(oService) then do:
        message substitute("Modifying '&1'.", ldbname(iDB)) view-as alert-box.

        assign oDomain = oService:GetDomain(domainName).
        if valid-object(oDomain) then do:
            /* Update Existing Domain */
            message substitute("Updating Domain &1", domainName) view-as alert-box.
            assign
                oDomain:AccessCode = domainAccessCode
                oDomain:Description = domainDescription
                .
            oService:UpdateDomain(oDomain).
        end. /* valid-object(oDomain) */
        else do:
            /* Create New Domain */
            message substitute("Creating Domain &1", domainName) view-as alert-box.
            assign
                oDomain = oService:NewDomain(domainName)
                oDomain:AuthenticationSystem = oService:GetAuthenticationSystem("{&DomainType}")
                oDomain:AccessCode = domainAccessCode
                oDomain:Description = domainDescription
                oDomain:IsEnabled = true
                .
            oService:CreateDomain(oDomain).
        end. /* not valid-object(oDomain) */

        /* Add info to necessary metadata objects. */
        assign oEntry = new Progress.Json.ObjectModel.JsonObject().
        oEntry:Add("domain", domainName).
        oEntry:Add("accessCode", security-policy:encode-domain-access-code(domainAccessCode)).
        oEntry:Add("description", oDomain:Description).
        oDomains:Add(oEntry).

        delete object oService.
    end. /* valid-object(oService) */

    /* Output domain data to session.json config file for Spark. */
    oConfig:Add("Domains", oDomains).
    oSession:Add("Config", oConfig).
    oSession:WriteFile("session.json", true).
end. /* iDB */

/* Generate reset CP for "Default" domain. */
message "Generating reset CP token..." view-as alert-box.
os-command silent value(substitute("{&DLC}\bin\genspacp -password &1 -user sparkRest -role NoAccess -domain &2 -file SparkReset.cp",
                                   domainAccessCode + "Realm", domainName)).

catch e as Error:
    define variable errorHandler as DataAdminErrorHandler no-undo.
    errorHandler = new DataAdminErrorHandler().
    errorHandler:Error(e).
end catch.
finally:
    delete object oDomain no-error.
end finally.
