/*------------------------------------------------------------------------
    File        : metrics_deactivate.p
    Purpose     : Runs logic on deactivate event of a request
    Description :
    Author(s)   : Dustin Grau
    Created     : Thu May 03 11:14:13 EDT 2018
    Notes       : PAS: Assign as sessionDeactivateProc in openedge.properties
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

using progress.lang.* from propath.

block-level on error undo, throw.

/* ***************************  Main Block  *************************** */

/* Obtain the current request information. */
define variable oRequest as OERequestInfo no-undo.
assign oRequest = cast(session:current-request-info, OERequestInfo).

/* Only run if the request being run is NOT part of the metrics logic. */
if not oRequest:ProcedureName begins "Spark/Diagnostic/Interface/" then
do on error undo, throw:
    define variable iStart as integer no-undo.
    assign iStart = mtime.

    /* Stop the profiler for this request, if enabled. */
    Spark.Diagnostic.Util.OEMetrics:Instance:WriteProfiler().

    /* Output the current ABLObjects report for this agent/session. */
    Spark.Diagnostic.Util.OEMetrics:Instance:PrepareSessionReports().

    if log-manager:logging-level ge 3 then
        message substitute("Elapsed: &1ms", (mtime - iStart)).
end. /* not metrics interface */

catch err as Progress.Lang.Error:
    /* Catch and Release */
    message substitute("Metrics Deactivate Error: &1", err:GetMessage(1)).
end catch.
finally:
    delete object oRequest no-error.
end finally.
