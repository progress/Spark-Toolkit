/*------------------------------------------------------------------------
    File        : Spark.Core.RemoteFacade
    Purpose     : Provide a simple facade for remote AppServer access.
    Description : This exists behind WEB handlers for PASOE.
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Dec 12 10:14:53 EST 2014
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using OpenEdge.Net.HTTP.StatusCodeHelper from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Json.ObjectModel.ObjectModelParser from propath.
using Spark.Core.Manager.ISessionManager from propath.
using Spark.Core.Manager.ServiceLifeCycleEnum from propath.
using Spark.Core.Manager.IConnectionManager from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Web.IWebRequest from propath.
using Spark.Core.Web.IWebResponse from propath.

block-level on error undo, throw.
&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW

class Spark.Core.RemoteFacade inherits Spark.Core.Interface.ServiceInterface implements Spark.Core.Interface.IServiceFacade use-widget-pool:

    define protected variable hServer  as handle    no-undo.
    define protected variable hFacade  as handle    no-undo.
    define protected variable cSession as character no-undo.

    define protected property oConnectionManager as IConnectionManager no-undo
        get:
            if not valid-object(oConnectionManager) then
                assign oConnectionManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(IConnectionManager)), IConnectionManager).
            return oConnectionManager.
        end get.
        set.

    /* Provides a crucial kill switch to end service execution after a default of 20 seconds. */
    define public property requestStopAfter as integer no-undo
        get():
            return miStopAfter.
        end get.
        public set(input piStopAfter as integer):
            assign miStopAfter = piStopAfter.
        end set.


    define public property serverName as character no-undo get. set.


    define public property serverProc as character no-undo
        get():
            if (serverProc gt "") ne true then
                assign serverProc = "Spark/Core/ApsvFacade.p".
            return serverProc.
        end get.
        set.


    constructor public RemoteFacade ( input pcDefaultServer    as character,
                                      input pcDefaultProcedure as character ):
        super().

        /* Set properties at creation. */
        serverName = pcDefaultServer.
        serverProc = pcDefaultProcedure.
    end constructor.


    method protected void resetServerCP ( ):
        /* Use the Spark reset CP to lower privileges on this connection. */
        Ccs.Common.Application:SessionManager:endRequestEnvironment().

        /* Close any "request" based connections. */
        oConnectionManager:stopLifeCycle(ServiceLifeCycleEnum:request).
    end method. /* resetServerCP */


    method protected logical getServer ( input phCPO as handle ):
        return getServer(phCPO, false).
    end method.


    method protected logical getServer ( input phCPO  as handle,
                                         input lReset as logical ):
        define variable iStart as integer no-undo.

        assign iStart = mtime.

        if (serverName gt "") ne true then do:
            logMessage("No remote server specified.", "SPARK-WARN", 2).
            return false. /* Return false to avoid an error condition. */
        end.

        if lReset then
            assign hServer = oConnectionManager:reconnectServer(serverName).
        else
            assign hServer = oConnectionManager:getServer(serverName).

        if valid-handle(hServer) and hServer:connected() then do:
            /* Update CP for server request. */
            if valid-handle(phCPO) then
                hServer:request-info:SetClientPrincipal(phCPO).
            else
                undo, throw new AppError("Invalid CP handle, unable to determine server config.", 0).

            assign cSession = phCPO:session-id.

            /* Obtain or create handle to specifc remote procedure. */
            if (serverProc gt "") eq true then
                assign hFacade = oConnectionManager:getProcHandle(serverName, serverProc).
            else
                logMessage("No remote procedure specified.", "SPARK-WARN", 2).
        end. /* connected */
        else
            undo, throw new AppError("Failed to connect to AppServer '{&SERVER_NAME}'.", 0).

        if not valid-handle(hFacade) and not lReset then do:
            logMessage("Facade not found; attempting reconnection", "SPARK-WARN", 0).
            getServer(phCPO, true).
        end.

        if not valid-handle(hFacade) then
            undo, throw new AppError("Failed to create AppServer facade handle.", 0).

        logMessage(substitute("Connection Time: &1ms", (mtime - iStart)), "FACADE-DBG", 3).

        return true.
    end method. /* getServer */


    method public logical userLogin ( input  pcUserID          as character,
                                      input  pcDomain          as character,
                                      input  pcPassword        as character,
                                      input  pcExtra           as character,
                                      output prClientPrincipal as raw,
                                      output pcMessage         as character ):
        define variable lResult as logical no-undo initial false.
        define variable iLoop   as integer no-undo.

        prClientPrincipal = cast(Ccs.Common.Application:SessionManager, ISessionManager):userLogin(pcUserID, pcDomain, pcPassword, pcExtra).
        lResult = true.

        return lResult.

        catch ea as AppError:
            do iLoop = 1 to ea:NumMessages:
                pcMessage = pcMessage + (if iLoop gt 1 then chr(10) else "") + ea:GetMessage(iLoop).
            end.
            if ea:ReturnValue ne "" then
                pcMessage = pcMessage + (if pcMessage ne "" then chr(10) else "") + ea:ReturnValue.
        end catch.

        catch es as SysError:
            do iLoop = 1 to es:NumMessages:
                pcMessage = pcMessage + (if iLoop gt 1 then chr(10) else "") + es:GetMessage(iLoop).
            end.
        end catch.
    end method. /* userLogin */


    method public override logical userLogout ( input  pcContextId as character,
                                                output pcMessage   as character ):
        return super:userLogout(pcContextId, pcMessage).
    end method. /* userLogout */


    method public override logical userLogout ( input  phCPO       as handle,
                                                output pcMessage   as character ):
        return super:userLogout(phCPO, pcMessage).
    end method. /* userLogout */


    method public override logical userLogout ( output pcMessage   as character ):
        return super:userLogout(pcMessage).
    end method. /* userLogout */


    method public override logical runService ( input  phCPO          as handle,
                                                input  pcResourceName as character,
                                                input  pcMethodName   as character,
                                                input  pcHttpMethod   as character,
                                                input  pcService      as character,
                                                input  pcJsonRequest  as longchar,
                                                output pfElapsedTime  as decimal,
                                                output piResponseCode as integer,
                                                output pcJsonHeaders  as longchar,
                                                output pcJsonResponse as longchar ):
        /* Run service with data as longchars and specific CP handle. */
        return runServiceRemote ( input  phCPO,
                                  input  pcResourceName,
                                  input  pcMethodName,
                                  input  pcHttpMethod,
                                  input  pcService,
                                  input  pcJsonRequest,
                                  output pfElapsedTime,
                                  output piResponseCode,
                                  output pcJsonHeaders,
                                  output pcJsonResponse).
    end method. /* runService */


    method public override logical runService ( input  pcResourceName as character,
                                                input  pcMethodName   as character,
                                                input  pcHttpMethod   as character,
                                                input  pcService      as character,
                                                input  pcJsonRequest  as longchar,
                                                output pfElapsedTime  as decimal,
                                                output piResponseCode as integer,
                                                output pcJsonHeaders  as longchar,
                                                output pcJsonResponse as longchar ):
        define variable oPrincipal as OpenEdge.Security.Principal no-undo.
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).

        /* Run service with data as longchars and specific CP handle. */
        return runServiceRemote ( input  oPrincipal:Token,
                                  input  pcResourceName,
                                  input  pcMethodName,
                                  input  pcHttpMethod,
                                  input  pcService,
                                  input  pcJsonRequest,
                                  output pfElapsedTime,
                                  output piResponseCode,
                                  output pcJsonHeaders,
                                  output pcJsonResponse).

        finally:
            delete object oPrincipal no-error.
        end finally.
    end method. /* runService */


    method public override void runService ( input pcResourceName as character,
                                             input pcMethodName   as character,
                                             input pcHttpMethod   as character,
                                             input pcService      as character,
                                             input pcJsonRequest  as longchar,
                                             input poWebRequest   as IWebRequest,
                                             input poWebResponse  as IWebResponse,
                                             input pdApiVersion   as decimal,
                                             input piStopAfter    as integer ):
        define variable lResultValue   as logical  no-undo.
        define variable pfElapsedTime  as decimal  no-undo.
        define variable piResponseCode as integer  no-undo.
        define variable pcJsonHeaders  as longchar no-undo.
        define variable pcJsonResponse as longchar no-undo.

        define variable oPrincipal as OpenEdge.Security.Principal no-undo.
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).

        /* Even when called from a WebHandler, we must make the remote call in a way that allows data
         * to be encapsulated within longchar values. When returned, we can then convert the results
         * into the expected values for the WebResponse object.
         */

        /* Run service with data as longchars and specific CP handle. */
        assign lResultValue = runServiceRemote ( input  oPrincipal:Token,
                                                 input  pcResourceName,
                                                 input  pcMethodName,
                                                 input  pcHttpMethod,
                                                 input  pcService,
                                                 input  pcJsonRequest,
                                                 output pfElapsedTime,
                                                 output piResponseCode,
                                                 output pcJsonHeaders,
                                                 output pcJsonResponse).

        if valid-object(poWebResponse) then do on error undo, leave:
            poWebResponse:StatusCode = if piResponseCode gt 0 then piResponseCode else integer(StatusCodeEnum:OK). /* Assume OK. */

            /* Provide standard reasons for typical responses. */
            poWebResponse:StatusReason = poWebResponse:GetStatusReason(poWebResponse:StatusCode).

            if poWebResponse:StatusCode ge 200 and poWebResponse:StatusCode le 299 then
                poWebResponse:ContentType = if (poWebRequest:ContentType gt "") eq true then poWebRequest:ContentType else "application/json".
            else
                poWebResponse:ContentType = "text/plain".

            if (lResultValue ne ?) then /* Denotes a successfull response or failure. */
                poWebResponse:SetHeader("X-RESULT", trim(string(lResultValue, "true/false"))).

            if (pfElapsedTime ge 0) then /* Tracks time for code execution. */
                poWebResponse:SetHeader("X-REQUEST-ELAPSED", trim(string(pfElapsedTime, ">>>,>>9.999sec."))).

            /* Prepare a general JSON parser. */
            define variable oParser as ObjectModelParser no-undo.
            assign oParser = new ObjectModelParser().

            /* Set any passed headers. */
            if (pcJsonHeaders gt "") eq true and pcJsonHeaders begins "~{" then do {&throw}:
                define variable oHeaders as JsonObject        no-undo.
                define variable cNames   as character extent  no-undo.
                define variable iX       as integer           no-undo.

                assign oHeaders = cast(oParser:Parse(pcJsonHeaders), JsonObject).
                assign cNames = oHeaders:GetNames().
                do iX = 1 to extent(cNames):
                    poWebResponse:SetHeader(cNames[iX], oHeaders:GetCharacter(cNames[iX])).
                end.

                catch pErr as Progress.Json.JsonParserError:
                    logMessage(substitute("Error parsing header object at byte &1.", pErr:Offset), "SPARK-ERR", 0).
                end catch.
                finally:
                    delete object oHeaders no-error.
                end finally.
            end. /* plcHeaders */

            /* Assign the entity content JSON data is available. */
            if (pcJsonResponse gt "") eq true and pcJsonResponse begins "~{" then
                poWebResponse:Entity = cast(oParser:parse(pcJsonResponse), JsonObject).

            catch err as Progress.Lang.Error:
                logMessage(substitute("Response Error: &1", err:GetMessage(1)), "FACADE-ERR", 0).
                assign
                    pfElapsedTime  = 0
                    piResponseCode = integer(StatusCodeEnum:BadGateway)
                    pcJsonHeaders  = ""
                    pcJsonResponse = StatusCodeHelper:GetMessage(StatusCodeEnum:BadGateway)
                    .
            end catch.
            finally:
                delete object oParser no-error.
            end finally.
        end. /* valid-object */

        finally:
            assign
                pcJsonHeaders  = ?
                pcJsonResponse = ?
                .
            delete object oPrincipal no-error.
        end finally.
    end method. /* runService */


    method private logical runServiceRemote ( input  phCPO          as handle,
                                              input  pcResourceName as character,
                                              input  pcMethodName   as character,
                                              input  pcHttpMethod   as character,
                                              input  pcService      as character,
                                              input  pcJsonRequest  as longchar,
                                              output pfElapsedTime  as decimal,
                                              output piResponseCode as integer,
                                              output pcJsonHeaders  as longchar,
                                              output pcJsonResponse as longchar ):
        define variable iRetries as integer no-undo initial 1.
        define variable iStart   as integer no-undo.

        assign iStart = mtime.

        /* CP handle will be attached to the request-info of our APSV connection. */
        if getServer(phCPO) then
        do on error undo, throw:
            if retry then do:
                if iRetries gt 0 then
                    assign iRetries = iRetries - 1. /* Decrement the retry count by 1. */
                else
                    undo, throw new AppError("Error attempting to run service on remote APSV connection.", 0).
            end. /* retry */

            /* Run service remotely with data as longchars, CP will be obtained from session info. */
            run runService in hFacade ( input  pcResourceName,
                                        input  pcMethodName,
                                        input  pcHttpMethod,
                                        input  pcService,
                                        input  pcJsonRequest,
                                        output pfElapsedTime,
                                        output piResponseCode,
                                        output pcJsonHeaders,
                                        output pcJsonResponse ) no-error.
            if error-status:error then do:
                if not oConnectionManager:validContext(serverName) then do:
                    logMessage(substitute("APSV context expired, attempting service retry after reconnecting to &1.", serverName), "FACADE-ERR", 1).
                    getServer(phCPO, true). /* Reconnect to server, re-apply CPO, and get facade handle. */
                    undo, retry.
                end.
                else
                    undo, throw new AppError(substitute("Service APSV Error: &1", GenTools:getLastAblError()), -502).
            end. /* error-status:error */

            assign pfElapsedTime = (mtime - iStart) / 1000.

            return true.
        end. /* Server Available */

        return false.

        catch err as Progress.Lang.Error:
            logMessage(substitute("Service Error: &1", err:GetMessage(1)), "FACADE-ERR", 0).
            assign
                pfElapsedTime  = 0
                piResponseCode = integer(StatusCodeEnum:BadGateway)
                pcJsonHeaders  = ""
                pcJsonResponse = StatusCodeHelper:GetMessage(StatusCodeEnum:BadGateway)
                .
            return false.
        end catch.
        finally.
            logMessage(substitute("RemoteFacade: &1 &2/&3/&4: HTTP-&5 &6s &7kb (&8)",
                                  pcHttpMethod, pcService, pcResourceName, pcMethodName, piResponseCode,
                                  trim(string(pfElapsedTime, ">>>,>>9.999")),
                                  trim(string((length(pcJsonResponse, "raw") / 1000), ">>>,>>>,>>9.999")),
                                  cSession), "FACADE-DBG", 3) no-error.
            resetServerCP().
        end finally.
    end method. /* runServiceRemote */

end class.