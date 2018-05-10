/*------------------------------------------------------------------------
    File        : metrics_activate.p
    Purpose     : Runs logic on activate event of a request
    Description :
    Author(s)   : Dustin Grau
    Created     : Thu May 03 11:14:04 EDT 2018
    Notes       : PAS: Assign as sessionActivateProc in openedge.properties
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

    /* Begin tracking all objects for the current agent. */
    Spark.Diagnostic.Util.OEMetrics:Instance:StartTrackingObjects().

    /* Start the profiler for this request, if enabled. */
    Spark.Diagnostic.Util.OEMetrics:Instance:StartProfiler().

    if log-manager:logging-level ge 3 then
        message substitute("Elapsed: &1ms", (mtime - iStart)).
end. /* not metrics interface */

catch err as Progress.Lang.Error:
    /* Catch and Release */
    message substitute("Metrics Activate Error: &1", err:GetMessage(1)).
end catch.
finally:
    delete object oRequest no-error.
end finally.
