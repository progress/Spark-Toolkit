/**
 * Logging Manager Interface
 */
interface Spark.Core.Manager.ILoggingManager inherits Ccs.Common.IManager:

    define public property oLogConfig as Progress.Json.ObjectModel.JsonObject no-undo get. set.

    /**
     * Log a message to the appserver logfile.
     * NOTE: This method will be defined in the LogMessate.i include, so take care if modifications are made to that file.
     */
    method public void logMessage( pcMessage as character, pcSubSystem as character, piLogLevel as integer).

    /**
     * Log a caught error to the appserver logfile.
     * NOTE: This method will be defined in the LogMessate.i include, so take care if modifications are made to that file.
     */
    method public void logError( input pcContextMessage as character, input poErr as Progress.Lang.Error, input pcSubSystem as character, input piLogLevel as integer).

    method public integer updateLoggingLevel ( ).

    method public character updateLogEntryTypes ( ).

end interface.