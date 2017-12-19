/*------------------------------------------------------------------------
    File        : Timer
    Purpose     : Provide a system for tracking/profiling code via timers
    Description :
    Author(s)   : Dustin Grau (dgrau@progress.com)
    Created     : Thu Aug 31 09:27:33 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.

block-level on error undo, throw.

class Spark.Core.Util.Timer:

    define private static variable iMinLog  as integer    no-undo initial 3.
    define private static variable iMaxText as integer    no-undo initial 20.
    define private static variable oTimers  as JsonObject no-undo.

    constructor static Timer ( ):
        purgeTimers(). /* Reset the timers object. */
    end constructor.

    method public static void purgeTimers ( ):
        if log-manager:logging-level ge iMinLog then
            message "- Purged Timers -".

        assign
            oTimers  = new JsonObject()
            iMaxText = 20
            .
    end method. /* purgeTimers */

    method public static void startTimer ( input pcTimerName as character ):
        if log-manager:logging-level ge iMinLog then do:
            assign iMaxText = length(pcTimerName) when (length(pcTimerName) gt iMaxText).

            if oTimers:Has(pcTimerName) then
                oTimers:Set(pcTimerName, mtime).
            else
                oTimers:Add(pcTimerName, mtime).
        end.
    end method. /* startTimer */

    method public static integer endTimer ( input pcTimerName as character ):
        define variable iElapsed as integer no-undo.

        if log-manager:logging-level ge iMinLog then do:
            if oTimers:Has(pcTimerName) and oTimers:GetType(pcTimerName) eq JsonDataType:Number then do:
                assign iElapsed = (mtime - oTimers:GetInteger(pcTimerName)).
                message substitute("&1:&2&3s", pcTimerName, fill(" ", iMaxText - length(pcTimerName)), string(if iElapsed gt 0 then (iElapsed / 1000) else 0, ">>9.999")).
            end. /* Has Time */
        end. /* Logging Enabled */

        return iElapsed.
    end method. /* endTimer */

end class.