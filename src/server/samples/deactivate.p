/*------------------------------------------------------------------------
    File        : deactivate.p
    Purpose     : Perform session tear-down and agent de-authentication.
    Description : Flush session attributes to disk/table and return the
                  agent to an unpriviledged state to prevent hijacking.
    Author(s)   : dugrau
    Created     : Thu Apr 16 11:17:05 EDT 2015
    Notes       : Primarily used for any application that will not make
                  use of the ServiceInterface class and runService().
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

{Spark/Core/Lib/LogMessage.i &IsClass=false &IsPublic=false}

/* ***************************  Main Block  *************************** */

Ccs.Common.Application:SessionManager:endRequestEnvironment().

catch err as Progress.Lang.Error:
    logMessage(substitute("Error: &1", err:GetMessage(1)), "DEACTIVATE", 0).
end catch.
