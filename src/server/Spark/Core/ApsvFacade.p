/*------------------------------------------------------------------------
    File        : Spark/Core/ApsvFacade
    Purpose     : Provide facade for APSV (AppServer) access.
    Description : This exists under the APSV transport for PASOE.
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed Mar 02 16:00:25 EST 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.DirectFacade from propath.

block-level on error undo, throw.
{Spark/Core/Lib/LogMessage.i &IsClass=false &IsPublic=false}

/* ***************************  Main Block  *************************** */

/* Primary endpoint for execution by a remote APSV requestor. */
procedure runService:
    define input  parameter pcResourceName as character no-undo.
    define input  parameter pcMethodName   as character no-undo.
    define input  parameter pcHttpMethod   as character no-undo.
    define input  parameter pcService      as character no-undo.
    define input  parameter pcJsonRequest  as longchar  no-undo.
    define output parameter pfElapsedTime  as decimal   no-undo.
    define output parameter piResponseCode as integer   no-undo.
    define output parameter pcJsonHeaders  as longchar  no-undo.
    define output parameter pcJsonResponse as longchar  no-undo.

    define variable oPrincipal as OpenEdge.Security.Principal no-undo.
    assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).

    define variable oServiceFacade as DirectFacade no-undo.
    oServiceFacade = new DirectFacade().
    oServiceFacade:runService( input  oPrincipal:Token,
                               input  pcResourceName,
                               input  pcMethodName,
                               input  pcHttpMethod,
                               input  pcService,
                               input  pcJsonRequest,
                               output pfElapsedTime,
                               output piResponseCode,
                               output pcJsonHeaders,
                               output pcJsonResponse ).

    finally:
        logMessage(substitute("&1 &2/&3/&4: HTTP-&5 &6s &7kb (&8)",
                              pcHttpMethod, pcService, pcResourceName, pcMethodName, piResponseCode,
                              trim(string(pfElapsedTime, ">>>,>>9.999")),
                              trim(string((length(pcJsonResponse, "raw") / 1000), ">>>,>>>,>>9.999")),
                              oPrincipal:Token:session-id), "APSV-DBG", 3) no-error.
        delete object oPrincipal no-error.
    end finally.
end procedure. /* runService */
