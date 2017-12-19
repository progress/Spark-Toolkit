using Progress.Lang.* from propath.
using Ccs.Common.IManager from propath.

/**
 * Stats Manager Interface
 * Responsible for tracking various pieces of information for usage reporting
 */
interface Spark.Core.Manager.IStatsManager inherits IManager:

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

    method public void resetStatistics ( ).
    method public logical saveStatistics ( ).

end interface.