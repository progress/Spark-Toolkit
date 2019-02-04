/*------------------------------------------------------------------------
    File        : metrics_shutdown.p
    Purpose     : Runs logic on shutdown event of a session
    Description :
    Author(s)   : Dustin Grau
    Created     : Wed Jan 30 08:14:04 EDT 2019
    Notes       : PAS: Assign as sessionShutdownProc in openedge.properties
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

using progress.lang.* from propath.

block-level on error undo, throw.

/* ***************************  Main Block  *************************** */

define variable iStart as integer no-undo.
assign iStart = mtime.

/* Stop the profiler for this session, if enabled. */
Spark.Diagnostic.Util.OEMetrics:Instance:WriteProfiler("session").

if log-manager:logging-level ge 3 then
    message substitute("Elapsed: &1ms", (mtime - iStart)).

catch err as Progress.Lang.Error:
    /* Catch and Release */
    message substitute("Metrics Shutdown Error: &1", err:GetMessage(1)).
end catch.
