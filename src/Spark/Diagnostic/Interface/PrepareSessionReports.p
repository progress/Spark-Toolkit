    /*------------------------------------------------------------------------
    File        : PrepareSessionReports.p
    Purpose     : Run metrics on a given Agent/Session
    Description : 
    Author(s)   : Dustin Grau
    Created     : Wed May 09 13:08:50 EDT 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

define input parameter piAgentID   as integer no-undo.
define input parameter piSessionID as integer no-undo.

/* ***************************  Main Block  *************************** */

if log-manager:logging-level ge 3 then
    message "Agent/Session:" piAgentID "/" piSessionID.

Spark.Diagnostic.Util.OEMetrics:Instance:PrepareSessionReports(piAgentID, piSessionID).
