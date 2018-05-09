/*------------------------------------------------------------------------
    File        : metrics_deactivate.p
    Purpose     : Runs logic on deactivate event of a request
    Description :
    Author(s)   : Dustin Grau
    Created     : Thu May 03 11:14:13 EDT 2018
    Notes       : PAS: Assign as sessionDeactivateProc in openedge.properties
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ***************************  Main Block  *************************** */

do on error undo, leave:

    /* Output the current ABLObjects report for this agent/session. */
    Spark.Diagnostic.Util.OEMetrics:Instance:PrepareABLObjectReport().

    /* Stop the profiler for this request, if enabled. */
    Spark.Diagnostic.Util.OEMetrics:Instance:WriteProfiler().

    catch err as Progress.Lang.Error:
        /* Catch and Release */
        message substitute("Error in Metrics Deactivate: &1", err:GetMessage(1)).
    end catch.
end.
