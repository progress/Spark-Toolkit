/*------------------------------------------------------------------------
    File        : activate.p
    Purpose     : Prepare the user's identity and assert against databases.
    Description : Allows startup of session by asserting user's identity.
    Author(s)   : dugrau
    Created     : Thu Apr 16 11:16:43 EDT 2015
    Notes       : Primarily used for any application that will not make
                  use of the ServiceInterface class and runService().
  ----------------------------------------------------------------------*/

&GLOBAL-DEFINE SECURITY_MODEL Development

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using Progress.Json.* from propath.

define variable hCPO          as handle      no-undo.
define variable dSessionStart as datetime-tz no-undo.

{Spark/Core/Lib/LogMessage.i &IsClass=false &IsPublic=false}

/* ***************************  Main Block  *************************** */

/* Obtain the CP object handle from the session request info. */
assign hCPO = session:current-request-info:GetClientPrincipal() no-error.

if valid-handle(hCPO) then
do on error undo, leave:
    /**
     * To enable "session:error-stack-trace" add -errorstack to agent startup params.
     *    Example: agentStartupParam=-T <TempDir> -errorstack -pf <Startup>.pf
     */
    if session:error-stack-trace or log-manager:logging-level gt 2 then
        logMessage(substitute("&1 | &2: &3@&4 | &5",
                              hCPO:session-id, hCPO:login-state, hCPO:user-id, hCPO:domain-name, hCPO:login-expiration-timestamp), "ACTIVATE", 2).

    /* If not part of the authentication process, establish session. */
    &if "{&SECURITY_MODEL}" eq "Development" &then
    /* For development, allows use of the same APSV instance for OERealm security,
     * otherwise this provides a security hole into the production application.
     */
    if hCPO:domain-name ne "OESPA" then
    &endif
    do on error undo, leave:
        cast(Ccs.Common.Application:SessionManager, Spark.Core.Manager.ISessionManager):establishRequestEnvironment().

        catch err as Progress.Lang.Error:
            logMessage(substitute("Session Error: &1 (&2)", err:GetMessage(1), err:GetMessageNum(1)), "ACTIVATE", 0).
        end catch.
    end. /* hCPO:domain-name ne "OESPA" */
end. /* valid-handle */
else
    undo, throw new Progress.Lang.AppError("Missing or invalid CP handle, unable to validate user identity!.", 0).

catch err as Progress.Lang.Error:
    logMessage(substitute("Error: &1 (&2)", err:GetMessage(1), err:GetMessageNum(1)), "ACTIVATE", 0).
end catch.
finally:
    delete object hCPO no-error.
end finally.
