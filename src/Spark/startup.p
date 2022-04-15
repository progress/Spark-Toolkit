/*------------------------------------------------------------------------
    File        : Spark/startup
    Purpose     : Run any "bootloader" type processes for dynamic code
                : and provide the information necessary to generate a
                : JSDO catalog for use with other Progress technology.
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Apr 26 15:03:17 EDT 2016
    Notes       : PAS: Assign as sessionStartupProc in openedge.properties,
                : uses sessionStartupProcParam to pass "ConfigDir" as JSON.
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* Standard input parameter as set via sessionStartupProcParam */
define input parameter startup-data as character no-undo.

/* Set up a custom log file if not in an MSAS environment (eg. ABLUnit). */
if session:client-type eq "4GLCLIENT" then do:
    log-manager:logfile-name = session:temp-directory + "server.log".
end. /* session:client-type */

{Spark/Core/Lib/LogMessage.i &IsClass=false &IsPublic=false}

/* ***************************  Main Block  *************************** */
logMessage(substitute("Starting Spark, version &1", Spark.Core.Util.OSTools:CurrentVersion), "SPARK-STRT", 0).
logMessage(substitute("Session Startup Param [&1], num-dbs: &2", startup-data, num-dbs), "SPARK-STRT", 3).
logMessage(substitute("Internal Codepage: &1", session:cpinternal), "SPARK-STRT", 2).
logMessage(substitute("Stream Codepage: &1", session:cpstream), "SPARK-STRT", 2).

run getStartupParams. /* Obtain any startup params to use as overrides to default behavior. */

/* Touch the StartupManager:instance to start the framework (bootstrap process). */
logMessage(substitute("Configs: &1", Spark.Core.Util.OSTools:sparkConf), "SPARK-STRT", 3).
Ccs.Common.Application:StartupManager = Spark.Core.Manager.StartupManager:Instance.
logMessage("Session Startup - Application Initialized", "SPARK-STRT", 3).

/**
 * Create a persistent handler for OpenEdge.Web.DataObject.DataObjectHandler events.
 * This defines overrides to the default DOH class events and provides integration
 * into the current session's implementation of the Progress Spark Toolkit through
 * use of the CCS Manager classes. Additionally, starting the class will subscribe
 * to the necessary events and begin loading the necessary registries ahead of any
 * requests. This greatly reduces the "time to first data" on the initial request.
 * Only relevant if using OE 11.6.3 or later.
 */
new Spark.Core.Handler.DOHEventHandler().

catch err as Progress.Lang.Error:
    logError("Session Startup Error", err, "SPARK-STRT", 0).
end catch.

/* Private procedure to parse any JSON options passed via startup-data. */
procedure getStartupParams private:
    /* If startup params are given, parse the value as a JSON object. */
    if startup-data begins "~{" then do:
        define variable oParser  as Progress.Json.ObjectModel.ObjectModelParser no-undo.
        define variable oStartup as Progress.Json.ObjectModel.JsonObject        no-undo.

        /* Parse the params as JSON. */
        assign oParser = new Progress.Json.ObjectModel.ObjectModelParser().
        assign oStartup = cast(oParser:Parse(replace(startup-data, "~\", "/")),
                               Progress.Json.ObjectModel.JsonObject).

        /* Set a custom project directory for locating the config files.
         * Must be set prior to running any code that depends on configs.
         */
        if valid-object(oStartup) and oStartup:Has("ConfigDir") then
            Spark.Core.Util.OSTools:configProjectDir = oStartup:GetCharacter("ConfigDir").

        delete object oParser  no-error.
        delete object oStartup no-error.
    end. /* startup-data */
end procedure.
