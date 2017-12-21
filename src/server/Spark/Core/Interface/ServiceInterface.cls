/*------------------------------------------------------------------------
    File        : ServiceInterface
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Dec 19 10:56:04 EST 2014
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Progress.Json.ObjectModel.ObjectModelParser.* from propath.
using Spark.Core.Manager.ServiceLifeCycleEnum from propath.
using Spark.Core.Manager.IConnectionManager from propath.
using Spark.Core.Manager.ICatalogManager from propath.
using Spark.Core.Manager.IMessageManager from propath.
using Spark.Core.Manager.IRouteManager from propath.
using Spark.Core.Message.IResponse from propath.
using Spark.Core.Manager.ISessionManager from propath.
using Spark.Core.Manager.IStartupManager from propath.
using Spark.Core.Message.ErrorTypeEnum from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Util.OSTools from propath.
using Spark.Core.Util.StopError from propath.
using Spark.Core.Util.TimeOutError from propath.
using Spark.Core.Web.IWebRequest from propath.
using Spark.Core.Web.IWebResponse from propath.

block-level on error undo, throw.

class Spark.Core.Interface.ServiceInterface use-widget-pool abstract:

    /************************ Properties and Class Methods ************************/

    define public static property ApiVersion as decimal init ? no-undo get. private set.

    define protected property miStopAfter as integer init ? no-undo get. protected set.

    define protected property oMessageManager as IMessageManager no-undo
        get:
            if not valid-object(oMessageManager) then
                assign oMessageManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager).
            return oMessageManager.
        end get.
        set.

    constructor public ServiceInterface ( ):
        /**
         * Load all managers according to the config files, which will
         * occur automatically by accessing the public Interface. The
         * returned "Stop After" value provides a crucial kill switch
         * to end service execution after a default of 20 seconds.
         */
        miStopAfter = cast(Ccs.Common.Application:StartupManager, IStartupManager):interfaceStopAfter.

        catch err as Progress.Lang.Error:
            logError("ServiceInterface startup error", err, "SPARK-SI", 0).
            undo, throw err.
        end catch.
    end constructor.


    /*************************** Protected Helper Methods ****************************/


    /* Include the logging methods directly, as this class may not have the LoggingManager available. */
    {Spark/Core/Lib/LogMessage.i &IsClass=true &IsPublic=false}


    /**
     * Log the user out using the CPO from the Session handle as identity
     * This version used by the REST and Web Handlers access
     */
    method protected logical userLogout ( output pcMessage as character ):
        define variable iLoop as integer no-undo.

        cast(Ccs.Common.Application:SessionManager, ISessionManager):invalidateContext().
        return true.

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
    end method. /* userLogout */


    /**
     * Log the user out using the ContextID that is stored in the state manager
     * This version used by batch jobs to logout users
     */
    method protected logical userLogout ( input  pcContextId as character,
                                          output pcMessage   as character ):
        define variable iLoop as integer no-undo.

        cast(Ccs.Common.Application:SessionManager, ISessionManager):invalidateContext(pcContextId).
        return true.

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
    end method. /* userLogout */


    /**
     * Log the user out using an existing CPO as identity
     * This version used by the testing platforms
     */
    method protected logical userLogout ( input  phCPO       as handle,
                                          output pcMessage   as character ):
        define variable iLoop as integer no-undo.

        cast(Ccs.Common.Application:SessionManager, ISessionManager):invalidateContext(phCPO).
        return true.

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
    end method. /* userLogout */


    method protected logical runService ( input  phCPO          as handle,
                                          input  pcResource     as character,
                                          input  pcMethodName   as character,
                                          input  pcHttpMethod   as character,
                                          input  pcService      as character,
                                          input  pcJsonRequest  as longchar,
                                          output pfElapsedTime  as decimal,
                                          output piResponseCode as integer,
                                          output pcJsonHeaders  as longchar,
                                          output pcJsonResponse as longchar ):
        /* Run internal service method (longchar), using passed CP handle. */
        return runServiceInt( input  phCPO,
                              input  pcResource,
                              input  pcMethodName,
                              input  pcHttpMethod,
                              input  pcService,
                              input  pcJsonRequest,
                              input  ?,
                              input  ?,
                              input  ?,
                              input  ?,
                              output pfElapsedTime,
                              output piResponseCode,
                              output pcJsonHeaders,
                              output pcJsonResponse ).
    end method. /* runService */


    method protected logical runService ( input  pcResource     as character,
                                          input  pcMethodName   as character,
                                          input  pcHttpMethod   as character,
                                          input  pcService      as character,
                                          input  pcJsonRequest  as longchar,
                                          output pfElapsedTime  as decimal,
                                          output piResponseCode as integer,
                                          output pcJsonHeaders  as longchar,
                                          output pcJsonResponse as longchar ):
        /**
         * Note: For working with anonymous security, ensure the following are set:
         *  OEClientPrincipalFilter.anonymous=true
         *  OEClientPrincipalFilter.sealAnonymous=true
         *  OEClientPrincipalFilter.passthru=true
         */
        define variable oPrincipal as OpenEdge.Security.Principal no-undo.
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).

        /* Run internal service method (longchar), using obtained CP handle. */
        return runServiceInt( input  oPrincipal:Token,
                              input  pcResource,
                              input  pcMethodName,
                              input  pcHttpMethod,
                              input  pcService,
                              input  pcJsonRequest,
                              input  ?,
                              input  ?,
                              input  ?,
                              input  ?,
                              output pfElapsedTime,
                              output piResponseCode,
                              output pcJsonHeaders,
                              output pcJsonResponse ).

        finally:
            delete object oPrincipal no-error.
        end finally.
    end method. /* runService */


    method protected void runService ( input pcResource    as character,
                                       input pcMethodName  as character,
                                       input pcHttpMethod  as character,
                                       input pcService     as character,
                                       input pcJsonRequest as longchar,
                                       input poWebRequest  as IWebRequest,
                                       input poWebResponse as IWebResponse,
                                       input pfApiVersion  as decimal,
                                       input piStopAfter   as integer ):
        /* This version of runService is used for facade access. */
        define variable fElapsedTime  as decimal  no-undo.
        define variable iResponseCode as integer  no-undo.
        define variable cJsonHeaders  as longchar no-undo.
        define variable cJsonResponse as longchar no-undo.

        /**
         * Note: For working with anonymous security, ensure the following are set:
         *  OEClientPrincipalFilter.anonymous=true
         *  OEClientPrincipalFilter.sealAnonymous=true
         *  OEClientPrincipalFilter.passthru=true
         */
        define variable oPrincipal as OpenEdge.Security.Principal no-undo.
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).

        /* Run internal service method (objects), using obtained CP handle. */
        runServiceInt( input  oPrincipal:Token,
                       input  pcResource,
                       input  pcMethodName,
                       input  pcHttpMethod,
                       input  pcService,
                       input  pcJsonRequest,
                       input  poWebRequest,
                       input  poWebResponse,
                       input  pfApiVersion,
                       input  piStopAfter,
                       output fElapsedTime,
                       output iResponseCode,
                       output cJsonHeaders,
                       output cJsonResponse ).

        finally:
            assign /* Not used, just clean up. */
                cJsonHeaders  = ?
                cJsonResponse = ?
                .
            delete object oPrincipal no-error.
        end finally.
    end method. /* runService */


    method private logical runServiceInt ( input  phCPO          as handle,
                                           input  pcResource     as character,
                                           input  pcMethodName   as character,
                                           input  pcHttpMethod   as character,
                                           input  pcService      as character,
                                           input  pcJsonRequest  as longchar,
                                           input  poWebRequest   as IWebRequest,
                                           input  poWebResponse  as IWebResponse,
                                           input  pfApiVersion   as decimal,
                                           input  piStopAfter    as integer,
                                           output pfElapsedTime  as decimal,
                                           output piResponseCode as integer,
                                           output pcJsonHeaders  as longchar,
                                           output pcJsonResponse as longchar ):
        define variable lResult as logical no-undo initial false.

        /* Store the current API version in use for this request. */
        Spark.Core.Interface.ServiceInterface:ApiVersion = pfApiVersion.

        MainBlock:
        do on error undo, throw
            on quit undo, retry
            on stop undo, retry:

            if retry then
                undo, throw new StopError().

            create widget-pool.

            oMessageManager:RequestTime = now.

            /**
             * To enable "session:error-stack-trace" add -errorstack to agent startup params.
             *    Example: agentStartupParam=-T <TempDir> -errorstack -pf <Startup>.pf
             */
            if session:error-stack-trace or log-manager:logging-level gt 2 then
                logMessage(substitute("&1 | &2: &3@&4 | Exp: &5",
                                      phCPO:session-id, phCPO:login-state,
                                      phCPO:user-id, phCPO:domain-name,
                                      phCPO:login-expiration-timestamp), "RUNSERVICE", 2).

            /* Assign reference to the given web request/response objects to the message manager. */
            oMessageManager:SessionID = phCPO:session-id.
            oMessageManager:WebRequest = poWebRequest.
            oMessageManager:WebResponse = poWebResponse.

            /* Prepare the object properties that will provide the actual request/response data. */
            oMessageManager:setRequestMessage(pcResource, pcMethodName, pcJsonRequest).
            oMessageManager:setRequestVerb(pcHttpMethod).
            oMessageManager:setResponseMessage(pcResource, pcMethodName, "").

            if piStopAfter eq ? or piStopAfter eq 0 then
            assign
                piStopAfter = miStopAfter.
            else
                logMessage(substitute("Request Stop after: &1. Default: &2", piStopAfter, miStopAfter), "SPARK-INFO", 3).

            InterfaceBlock:
            do on error undo, throw
               on stop undo, retry
               stop-after piStopAfter:

                if retry then
                    undo, throw new TimeOutError(oMessageManager:RequestTime, piStopAfter).

                /* Restore context to session user, after asserting identity against any connected databases. */
                Ccs.Common.Application:SessionManager:establishRequestEnvironment(phCPO).

                /* Execute the service request. */
                cast(Ccs.Common.Application:StartupManager:getManager(get-class(IRouteManager)), IRouteManager)
                    :invokeServiceFunction(pcService, pcResource, pcMethodName).
                assign lResult = true.

                /* ----- Catch any thrown errors ----- */
                catch eapp as AppError:
                    cast(oMessageManager:ResponseMessage, IResponse):addAppError(eapp).

                    /* Catch any errors thrown from inside this catch block. */
                    catch epro as ProError:
                        logError("Error while adding error to response", epro, "SPARK-E1", 0).
                        undo, throw epro.
                    end catch.
                end catch.

                catch esys as SysError:
                    /* Set the response code to 500 */
                    oMessageManager:setResponseCode(500).
                    cast(oMessageManager:ResponseMessage, IResponse):addProError("", ErrorTypeEnum:fatal, esys).

                    /* Catch any errors thrown from inside this catch block. */
                    catch epro as ProError:
                        logError("Error while adding error to response", epro, "SPARK-E2", 0).
                        undo, throw epro.
                    end catch.
                end catch.
            end.  /* InterfaceBlock */

            /* Prepare output via the WebResponse object, returning necessary properties to fulfill the service request. */
            prepareResponse(lResult, output piResponseCode, output pcJsonHeaders, output pcJsonResponse).
            assign pfElapsedTime = oMessageManager:ElapsedTime.

            /* Catch any errors thrown from inside MainBlock. */
            catch epro as ProError:
                logError("Error while processing the request", epro, "SPARK-E3", 0).
                undo, throw epro.
            end catch.

            finally:
                /* End the request session and flush context to disk/table. */
                Ccs.Common.Application:ServiceManager:stopServices(ServiceLifeCycleEnum:request).
                cast(Ccs.Common.Application:StartupManager:getManager(get-class(IConnectionManager)), IConnectionManager)
                    :stopLifeCycle(ServiceLifeCycleEnum:request).
                Spark.Core.Interface.ServiceInterface:ApiVersion = ?.
                oMessageManager:resetMessages().

                /* Denote end of request. */
                if session:error-stack-trace or log-manager:logging-level gt 2 then
                    logMessage(substitute("&1 | End of Request", phCPO:session-id), "RUNSERVICE", 2).

                /* Downgrade identity against any connected databases by use of the "reset" token. */
                Ccs.Common.Application:SessionManager:endRequestEnvironment().

                /* Catch any errors thrown from inside this finally block. */
                catch epro as ProError:
                    /* Now this is a realproblem! The End Session was a problem. */
                    logError("Error while 'ending' the session", epro, "SPARK-E4", 0).
                    undo, throw epro.
                end catch.
            end finally.
        end. /* MainBlock */

        return lResult.
    end method. /* runServiceInt */


    method protected void prepareResponse ( input  plResultValue  as logical,
                                            output piResponseCode as integer,
                                            output pcJsonHeaders  as longchar,
                                            output pcJsonResponse as longchar ):
        define variable cNames   as character extent  no-undo.
        define variable iX       as integer           no-undo.
        define variable oParser  as ObjectModelParser no-undo.
        define variable oHeaders as JsonObject        no-undo.

        fix-codepage(pcJsonHeaders) = "UTF-8".
        fix-codepage(pcJsonResponse) = "UTF-8".

        assign
            pcJsonHeaders  = oMessageManager:serializeHeaders(true)
            pcJsonResponse = oMessageManager:ResponseMessage:serializeMessage()
            piResponseCode = oMessageManager:StatusCode
            oParser        = new ObjectModelParser()
            .

        /* If this request originated from a WebHandler then the WebResponse object was created already by the WebHandler. */
        if valid-object(oMessageManager:WebResponse) then
        do:
            oMessageManager:WebResponse:StatusCode = piResponseCode.
            oMessageManager:WebResponse:StatusReason = oMessageManager:WebResponse:GetStatusReason(piResponseCode).

            /**
             * Notes regarding content-length and compression:
             *
             * The Tomcat server configured with PASOE is set to enable compression by default.
             * This is set in the /conf/catalina.properties file under the following options:
             *
             *  psc.as.http.compress=on
             *  psc.as.https.compress=on
             *  psc.as.compress.min=2048
             *  psc.as.compress.types=text/html,text/xml,text/javascript,text/css,application/json
             *
             *
             * The code below will explicitly set the Content-Length header, based on a count of
             * bytes from the body payload, which is to be written out to the webstream. However,
             * if compression is turned on and the size exceeds the compression minimum value AND
             * the content type matches, then the output will automatically be switched to output
             * the "Transfer-Encoding: chunked" header. So, if you intend to output an explicit
             * value for Content-Length, you should set the compression settings accordingly.
             *
             *  oResponse:ContentLength = length(plcResponse, "raw").
             *
             * Alternatively, if the response object's ContentLength property is not set, then Tomcat
             * will default to using "Transfer-Encoding: chunked" and will not send a Content-Length from propath.
             * This is because Tomcat sends the headers before it even knows about what is in the body.
             */

            if (plResultValue ne ?) then /* Denotes a successfull response or failure. */
                oMessageManager:WebResponse:SetHeader("X-RESULT", trim(string(plResultValue, "true/false"))).

            /* If the ContentType not yet set then determine type and set it. */
            if (oMessageManager:WebResponse:ContentType gt "") ne true then do:
                /* If this is a normal REST type request and a valid JSON response has been set. */
                if not valid-object(oMessageManager:WebResponse:Entity) and
                   (pcJsonResponse gt "") eq true and pcJsonResponse begins "~{"
                then
                    oMessageManager:WebResponse:ContentType = "application/json".
                else /* If a Memptr Entity has been set then best guess - this should be set by the object setting the response Entity. */

                /* If entity property is an object, set a proper content type. */
                if valid-object(oMessageManager:WebResponse:Entity) and
                   type-of(oMessageManager:WebResponse:Entity, OpenEdge.Core.Memptr)
                then
                    oMessageManager:WebResponse:ContentType = "application/octet-stream".
                else
                    oMessageManager:WebResponse:ContentType = "text/plain".
            end.

            /* Set any passed headers. Custom headers for each request can be inserted by
               overriding the RouteManager and implementing a custom pre or post processing method. */
            if (pcJsonHeaders gt "") eq true and pcJsonHeaders begins "~{" then do:
                assign
                    oHeaders = cast(oParser:Parse(pcJsonHeaders), JsonObject)
                    cNames   = oHeaders:GetNames()
                    .

                do iX = 1 to extent(cNames):
                    oMessageManager:WebResponse:SetHeader(cNames[iX], oHeaders:GetCharacter(cNames[iX])).
                end.
            end.
        end.

        oMessageManager:ElapsedTime = interval(now, oMessageManager:RequestTime, "milliseconds") / 1000.

        if valid-object(oMessageManager:WebResponse) then do:
            /* Tracks time for code execution. */
            oMessageManager:WebResponse:SetHeader("X-REQUEST-ELAPSED", trim(string(oMessageManager:ElapsedTime, ">>>,>>9.999sec."))).

            if not valid-object(oMessageManager:WebResponse:Entity) and
               (pcJsonResponse gt "") eq true and pcJsonResponse begins "~{" then do:
                /* Assign the entity content if none available. In this case the content is JSON,
                   so create a clone of the message parameter object, which is a JsonObject already. */
                oMessageManager:WebResponse:Entity = cast(oMessageManager:ResponseMessage:getParamObject():Clone(), JsonObject).
                oMessageManager:WebResponse:ContentLength = length(pcJsonResponse, "raw").
            end. /* No entity, response JSON */
        end. /* valid-object */

        catch epro as ProError:
            logError("Error while processing the response", epro, "SPARK-E5", 0).
            undo, throw epro.
        end catch.
        finally:
            delete object oParser no-error.
            delete object oHeaders no-error.
        end finally.
    end method. /* prepareResponse */

end class.