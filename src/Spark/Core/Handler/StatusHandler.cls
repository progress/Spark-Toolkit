/*------------------------------------------------------------------------
    File        : StatusHandler
    Purpose     : Custom WebHandler to validate login/server status.
    Description :
    Author(s)   : Progress
    Created     : Thu Feb 11 10:24:51 EST 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.AppError from propath.
using OpenEdge.Web.IWebRequest from propath.
using OpenEdge.Web.WebResponse from propath.
using OpenEdge.Web.WebResponseWriter from propath.

block-level on error undo, throw.

class Spark.Core.Handler.StatusHandler inherits OpenEdge.Web.WebHandler use-widget-pool:

    method protected override integer HandleNotAllowedMethod ( input poRequest as IWebRequest ):
        /* Return error that is coordinated with Spring Security policies */
        message "** Status handler returned 405 (not allowed)".
        return 405.
    end method.

    method protected override integer HandleNotImplemented ( input poRequest as IWebRequest ):
        /* Return error that is coordinated with Spring Security policies */
        message "** Status handler returned 501 (not implemented)".
        return 501.
    end method.

    method protected override integer HandleGet ( input poRequest as IWebRequest ):
        define variable oResponse as WebResponse             no-undo.
        define variable oWriter   as WebResponseWriter       no-undo.
        define variable iStatus   as integer   initial 000   no-undo.
        define variable cAccept   as character initial ?     no-undo.
        define variable cReason   as character initial "OK"  no-undo.
        define variable cBody     as character initial ""    no-undo.
        define variable cPage     as character initial "yes" no-undo.
        define variable cType     as character initial ""    no-undo.
        define variable cServer   as character initial "N/A" no-undo.
        define variable cClient   as character initial "N/A" no-undo.

        if valid-object(poRequest) then do:
            assign cType = poRequest:GetPathParameter("type").
            assign cAccept = poRequest:GetHeader("Accept"):Value.
        end.

        if (cAccept eq ?) then
            assign cPage = "yes". /* Use page output, no Accept type present. */
        else do:
            /* Check for application/json pattern when Accept header exists. */
            if (cAccept matches "*application*json*" ) then
                assign cPage = "no".
        end.

        define variable oPrincipal as OpenEdge.Security.Principal no-undo.
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).

        case (cType):
            when "login" then do:
                assign cReason = "Status Handler: Login".
                assign cClient = if valid-handle(oPrincipal:Token) then oPrincipal:Token:login-state else "Invalid".
            end.
            when "server" then do:
                assign cReason = "Status Handler: Server".
                assign cServer = "ACTIVE". /* Override as needed to return status. */
            end.
            when "all" then do:
                assign cReason = "Status Handler: All".
                assign cClient = if valid-handle(oPrincipal:Token) then oPrincipal:Token:login-state else "Invalid".
                assign cServer = "ACTIVE". /* Override as needed to return status. */
            end.
            otherwise do:
                assign iStatus = 500.
                assign cReason = "Unknown Status Type: " + cType.
            end.
        end case.

        message "** " + cReason.

        /* Build the output response */
        if (iStatus eq 0) then do:
            oResponse = new WebResponse().
            oWriter = new WebResponseWriter(oResponse).

            /* For some crazy reason you cannot return success */
            oResponse:StatusCode = 200.
            oResponse:StatusReason = cReason.

            if (cPage eq "yes") then do:
                /* Return as HTML page. */
                oResponse:ContentType = "text/html".
                oWriter:write( "<html>" ).
                oWriter:write( "<head>" ).
                oWriter:write( "<title>Service Status</title>" ).
                oWriter:write( '<meta http-equiv="Cache-Control" content="no-store"/>' ).
                oWriter:write( "</head>" ).
                oWriter:write( "<body>" ).

                oWriter:write('<header>').
                oWriter:write('<h2>Progress Application Server</h2>').
                oWriter:write('</header>').

                oWriter:write('<section style="padding:15px">').
                oWriter:write('<h2><b>Status:</b></h2>').
                oWriter:write('<hr height="1">').
                oWriter:write('<table>').
                oWriter:write('<tr> <td><b>Server:</b></td> <td>' + cServer + '</td> </tr>').
                oWriter:write('<tr> <td><b>Client:</b></td> <td>' + cClient + '</td> </tr>').
                oWriter:write('</table>').
                oWriter:write('</section>').

                oWriter:write('<footer>Copyright &copy; ' + string(year(today)) + ' Progress Software Corporation. All rights reserved.</footer>').
                oWriter:write( "</body>" ).
                oWriter:write( "</html>" ).
            end.
            else do:
                /* Return as JSON data. */
                oResponse:ContentType = "application/json".
                oWriter:write('~{ "server-status": "' + cServer + '", ' + '"user-status": "' + cClient + '" ~}').
            end.

            oWriter:close().
        end.

        return iStatus.

        finally:
            delete object oPrincipal no-error.
            delete object oResponse no-error.
            delete object oWriter no-error.
        end finally.
    end method.

end class.
