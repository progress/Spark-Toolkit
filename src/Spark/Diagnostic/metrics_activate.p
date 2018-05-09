/*------------------------------------------------------------------------
    File        : metrics_activate.p
    Purpose     : Runs logic on activate event of a request
    Description :
    Author(s)   : Dustin Grau
    Created     : Thu May 03 11:14:04 EDT 2018
    Notes       : PAS: Assign as sessionActivateProc in openedge.properties
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ***************************  Main Block  *************************** */

do on error undo, leave:

    /* Start the profiler for this request, if enabled. */
    Spark.Diagnostic.Util.OEMetrics:Instance:StartProfiler().

    /* Begin tracking all objects for the current agent. */
    Spark.Diagnostic.Util.OEMetrics:Instance:StartTrackingObjects().

    catch err as Progress.Lang.Error:
        /* Catch and Release */
        message substitute("Error in Metrics Activate: &1", err:GetMessage(1)).
    end catch.
end.
