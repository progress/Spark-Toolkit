/*------------------------------------------------------------------------
    File        : StartTrackingObjects.p
    Purpose     : Prepare metrics for a given Agent/Procedure.
    Description : 
    Author(s)   : Dustin Grau
    Created     : Wed May 09 13:08:50 EDT 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

define input parameter piAgentID   as integer   no-undo.
define input parameter pcProcedure as character no-undo.

/* ***************************  Main Block  *************************** */

if log-manager:logging-level ge 3 then
    message "Agent/Proc:" piAgentID "/" pcProcedure.

Spark.Diagnostic.Util.OEMetrics:Instance:StartTrackingObjects(piAgentID, pcProcedure).
