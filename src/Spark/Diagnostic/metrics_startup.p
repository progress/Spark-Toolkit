/*------------------------------------------------------------------------
    File        : metrics_startup.p
    Purpose     : Runs logic on startup event of a session
    Description :
    Author(s)   : Dustin Grau
    Created     : Wed Jan 30 08:14:04 EDT 2019
    Notes       : PAS: Assign as sessionStartupProc in openedge.properties
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

/* Standard input parameter as set via sessionStartupProcParam */
define input parameter startup-data as character no-undo.

/* ***************************  Main Block  *************************** */

define variable iStart as integer no-undo.
assign iStart = mtime.

/* Start the profiler for this session, if enabled. */
Spark.Diagnostic.Util.OEMetrics:Instance:StartProfiler("session").

if log-manager:logging-level ge 3 then
    message substitute("Elapsed: &1ms", (mtime - iStart)).

catch err as Progress.Lang.Error:
    /* Catch and Release */
    message substitute("Metrics Startup Error: &1", err:GetMessage(1)).
end catch.

