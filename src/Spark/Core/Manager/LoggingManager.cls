using Progress.Lang.AppError from propath.
using Progress.Json.ObjectModel.* from propath.

block-level on error undo, throw.

/**
 * Logging Manager - Responsible for formatting and logging errors
 */
class Spark.Core.Manager.LoggingManager inherits Spark.Core.Manager.Manager implements Spark.Core.Manager.ILoggingManager:

    define protected variable LastConfigDate as datetime no-undo.
    define protected variable ThisConfigDate as datetime no-undo.

    define protected property LogConfigPath as character no-undo
        get:
            file-info:file-name = substitute("&1logging.json", Spark.Core.Util.OSTools:sparkConf).
            if file-info:full-pathname ne ? then do:
                /* If file exists, obtain last modified date/time and return the full path to the file. */
                assign ThisConfigDate = Spark.Core.Util.GenTools:getDateTime(file-info:file-mod-date, file-info:file-mod-time).
                return file-info:full-pathname.
            end. /* File Available */

            return ?.
        end get.
        set.

    define public property oLogConfig as JsonObject no-undo
        get:
            /* Checks if file exists and obtains modified date/time value. */
            if LogConfigPath ne ? then
            do on error undo, throw:
                /* Compare last-modified timestamp for config file. */
                if LastConfigDate eq ? or ThisConfigDate gt LastConfigDate then
                do on error undo, throw:
                    /* Parse config file, if changed since last reading. */
                    define variable oParser as ObjectModelParser no-undo.
                    assign oParser = new ObjectModelParser().
                    assign oLogConfig = cast(oParser:parseFile(LogConfigPath), JsonObject).

                    if LastConfigDate eq ? then
                        logMessage("Setting options from logging config file.", "SPARK-LOG", 2).
                    else
                        logMessage("Detected an updated logging config file.", "SPARK-LOG", 2).

                    assign LastConfigDate = ThisConfigDate.
                    delete object oParser no-error.
                end. /* Config Modified Date - Empty/Changed */

                catch parseErr as Progress.Json.JsonParserError:
                    logError("Error parsing logging config:", parseErr, "SPARK-LOG", 0).
                    assign oLogConfig = new JsonObject().
                end catch.
                catch err as Progress.Lang.Error:
                    logError("Error changing logging settings:", err, "SPARK-LOG", 0).
                    assign oLogConfig = new JsonObject().
                end catch.
            end. /* LogConfigPath ne ? */

            /* As a last resort, create a new config object using current values. */
            if oLogConfig eq ? or not valid-object(oLogConfig) then do:
                assign oLogConfig = new JsonObject().
                oLogConfig:Add("loggingLevel", log-manager:logging-level).
                oLogConfig:Add("logEntryTypes", log-manager:log-entry-types).
            end. /* No Object Available */

            return oLogConfig.
        end get.
        set.

    constructor public LoggingManager ( ):
        super().
    end constructor.

    method override public void initialize ( ):
        updateLoggingLevel().
        updateLogEntryTypes().

        catch err as Progress.Lang.Error:
            logMessage(err:GetMessage(1), "SPARK-LOG", 0).
        end catch.
    end method.

    method override public void dispose ( ):
        delete object oLogConfig no-error.
    end method.

    method public integer updateLoggingLevel ( ):
        define variable iNewLevel as integer no-undo.

        if oLogConfig:Has("loggingLevel") and oLogConfig:GetType("loggingLevel") eq JsonDataType:number then do:
            assign iNewLevel = oLogConfig:GetInteger("loggingLevel").
            if log-manager:logging-level ne iNewLevel then do:
                logMessage(substitute("Changing user-defined logging level from '&1' to '&2'.",
                                      log-manager:logging-level, iNewLevel), "SPARK-LOG", 0).
                log-manager:logging-level = iNewLevel.
            end. /* is different */
        end. /* loggingLevel */

        return log-manager:logging-level.
    end method.

    method public character updateLogEntryTypes ( ):
        define variable cNewTypes as character no-undo.

        if oLogConfig:Has("logEntryTypes") and oLogConfig:GetType("logEntryTypes") eq JsonDataType:string then do:
            assign cNewTypes = oLogConfig:GetCharacter("logEntryTypes").
            if log-manager:log-entry-types ne cNewTypes then do:
                logMessage(substitute("Changing user-defined log entry types from '&1' to '&2'.",
                                      log-manager:log-entry-types, cNewTypes), "SPARK-LOG", 0).
                log-manager:log-entry-types = cNewTypes.
            end. /* is different */
        end. /* loggingLevel */

        return log-manager:log-entry-types.
    end method.

    /**
     * This class utilizes the same LogMessage include as utilized in any application procedures.
     * Passing the IsClass and IsPublic pre-processor flags will cause the include to expose the
     * necessary logic as public methods, instead of internal functions.
     */
    {Spark/Core/Lib/LogMessage.i &IsClass=true &IsPublic=true}

end class.
