using Progress.Lang.* from propath.
using Spark.Core.Manager.* from propath.

block-level on error undo, throw.

/**
 * Usage Stats Manager
 * Responsible for tracking various pieces of information for usage reporting
 */
class Spark.Core.Manager.StatsManager inherits Spark.Core.Manager.Manager implements IStatsManager:

    define public property ServicePath   as character   no-undo get. set.
    define public property ResourceName  as character   no-undo get. set.
    define public property MethodName    as character   no-undo get. set.
    define public property ContentType   as character   no-undo get. set.
    define public property ApiVersion    as decimal     no-undo get. set.
    define public property HttpMethod    as character   no-undo get. set.
    define public property RequestTime   as datetime-tz no-undo get. set.
    define public property RequestSize   as decimal     no-undo get. set.
    define public property ResponseCode  as integer     no-undo get. set.
    define public property ResponseSize  as decimal     no-undo get. set.
    define public property SessionID     as character   no-undo get. set.
    define public property ElapsedTime   as decimal     no-undo get. set.

    constructor public StatsManager (  ):
        super().
    end constructor.

    method override public void initialize ( ):
        resetStatistics().
    end method.

    method override public void dispose ( ):
        /* No action needed. */
    end method.

    method public void resetStatistics ( ):
        ServicePath = "".
        ResourceName = "".
        MethodName = "".
        ContentType = "".
        HttpMethod = "".
        RequestTime = ?.
        RequestSize = 0.
        ResponseCode = 0.
        ResponseSize = 0.
        SessionID = "".
        ElapsedTime = 0.
    end method.

    method public logical saveStatistics ( ):
        /* Default behavior is to write stats to the log file when logging-level is 3 or above. */
        define variable oLoggingManager as ILoggingManager no-undo.
        assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
        oLoggingManager:logMessage(substitute("&1 &2/&3/&4 v&5", HttpMethod, ServicePath, ResourceName, MethodName, ApiVersion), "SPARK-STAT", 3).
        oLoggingManager:logMessage(substitute("&1 @ &2", SessionID, RequestTime), "SPARK-STAT", 3).
        oLoggingManager:logMessage(substitute("Requested: &1kb as &2",
                                              trim(string((RequestSize / 1000), ">>>,>>>,>>9.999")),
                                              ContentType), "SPARK-STAT", 3).
        oLoggingManager:logMessage(substitute("Responded: &1kb with HTTP-&2 in &3s",
                                              trim(string((ResponseSize / 1000), ">>>,>>>,>>9.999")),
                                              ResponseCode, trim(string(ElapsedTime, ">>>,>>9.999"))), "SPARK-STAT", 3).
    end method.

end class.
