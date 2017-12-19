/*------------------------------------------------------------------------
    File        : activate.p
    Purpose     : Executes prior to the start of any session request.
    Description : Set as sessionActivateProc and provide a logging.json
                  file in your "Spark" project config directory. Uses
                  properties loggingLevel (integer) and logEntryTypes
                  (character) to adjust these values in the LogManager.
                  To change on the fly, update the config file and all
                  subsequent requests will pick up and utilize the
                  changes if they differ from the current values.
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Thu Aug 25 16:10:48 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using Progress.Json.ObjectModel.* from propath.

{Spark/Core/Lib/LogMessage.i &IsClass=false &IsPublic=false}

/* ***************************  Main Block  *************************** */

define variable oParser    as ObjectModelParser no-undo.
define variable oLogConfig as JsonObject        no-undo.
define variable iNewLevel  as integer           no-undo.
define variable cNewTypes  as character         no-undo.

file-info:file-name = substitute("&1logging.json", Spark.Core.Util.OSTools:sparkConf).
if file-info:full-pathname ne ? then do:
    assign oParser = new ObjectModelParser().
    oLogConfig = cast(oParser:parseFile(file-info:full-pathname), JsonObject).

    if oLogConfig:Has("loggingLevel") and oLogConfig:GetType("loggingLevel") eq JsonDataType:number then do:
        assign iNewLevel = oLogConfig:GetInteger("loggingLevel").
        if log-manager:logging-level ne iNewLevel then do:
            logMessage(substitute("Changing user-defined logging level from '&1' to '&2'.",
                                  log-manager:logging-level, iNewLevel), "ACTIVATE", 0).
            log-manager:logging-level = iNewLevel.
        end.
    end. /* loggingLevel */

    if oLogConfig:Has("logEntryTypes") and oLogConfig:GetType("logEntryTypes") eq JsonDataType:string then do:
        assign cNewTypes = oLogConfig:GetCharacter("logEntryTypes").
        if log-manager:log-entry-types ne cNewTypes then do:
            logMessage(substitute("Changing user-defined log entry types from '&1' to '&2'.",
                                  log-manager:log-entry-types, cNewTypes), "ACTIVATE", 0).
            log-manager:log-entry-types = cNewTypes.
        end.
    end. /* loggingLevel */
end. /* Logging Config Present */

catch err as Progress.Lang.Error:
    logError("Error changing logging settings:", err, "ACTIVATE", 0).
end catch.
finally:
    delete object oParser no-error.
    delete object oLogConfig no-error.
end finally.
