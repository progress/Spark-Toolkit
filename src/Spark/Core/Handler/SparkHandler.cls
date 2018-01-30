/*------------------------------------------------------------------------
    File        : SparkHandler
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Feb 12 10:56:04 EST 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using OpenEdge.Net.HTTP.StatusCodeHelper from propath.
using Spark.Core.Interface.IServiceFacade from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.IStartupManager from propath.
using Spark.Core.Manager.ServiceLifeCycleEnum from propath.
using Spark.Core.Util.OSTools from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Web.SparkRequest from propath.
using Spark.Core.Web.SparkResponse from propath.

block-level on error undo, throw.
&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW

class Spark.Core.Handler.SparkHandler inherits OpenEdge.Web.WebHandler implements Progress.Web.IWebHandler use-widget-pool abstract:

    /************************ Properties and Class Methods ************************/

    /* Creates an instance of the necessary service facade (Direct/Remote). */
    define protected abstract property oServiceFacade as IServiceFacade no-undo get. set.

    define protected property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.

    define private temp-table ttHandler no-undo serialize-name "Handler"
        field ClassName  as character
        field FacadeType as character
        field ServerName as character
        index ix1 as primary unique ClassName.

    define private temp-table ttMapping no-undo serialize-name "ServerMapping"
        field ServerName as character
        field RemoteProc as character
        index ix1 as primary unique ServerName.

    define private dataset dsHandler serialize-name "Config"
        for ttHandler, ttMapping.

    define protected property miStopAfter as integer init ? no-undo get. protected set.


    constructor public SparkHandler ( ):
        /**
         * Load all managers according to the config files, which will
         * occur automatically by accessing the public Interface. The
         * returned "Stop After" value provides a crucial kill switch
         * to end service execution after a default of 20 seconds.
         */
        miStopAfter = cast(Ccs.Common.Application:StartupManager, IStartupManager):interfaceStopAfter.

        loadConfig(). /* Load handler configuration. */

        catch ep as ProError:
            logError("SparkHandler startup error", ep, "SPARK-WSI", 0).
            undo, throw ep.
        end catch.
    end constructor.


    /*************************** Protected Helper Methods ****************************/


    {Spark/Core/Lib/LogMessage.i &IsClass=true &IsPublic=false}


    method protected void loadConfig():
        define variable cCfgFileName     as character no-undo.
        define variable cFullCfgFileName as character no-undo.

        assign cCfgFileName = "handler.json".
        file-info:file-name = OSTools:sparkConf + cCfgFileName.
        assign cFullCfgFileName = file-info:full-pathname.

        if cFullCfgFileName ne ? then
            dataset dsHandler:read-json("file", cFullCfgFileName, "EMPTY").
    end method. /* loadConfig */


    method final protected character getClassName ( ):
        return this-object:GetClass():TypeName.
    end method. /* getClassName */


    method protected character getHandlerFacadeType ( input pcHandlerClass as character ):
        define variable cFacadeType as character no-undo.

        find first ttHandler no-lock
             where ttHandler.ClassName eq pcHandlerClass no-error.
        if available(ttHandler) then
            assign cFacadeType = ttHandler.FacadeType.

        /* If no value available, assume use of the local server (Direct). */
        if (cFacadeType gt "") ne true then
            assign cFacadeType = "Direct".

        return cFacadeType.
    end method. /* getHandlerFacadeType */


    method protected character getHandlerRemoteServer ( input pcHandlerClass as character ):
        define variable cServerName as character no-undo.

        find first ttHandler no-lock
             where ttHandler.ClassName eq pcHandlerClass no-error.
        if available(ttHandler) then
            assign cServerName = ttHandler.ServerName.

        return cServerName.
    end method. /* getHandlerRemoteServer */


    method protected character getHandlerRemoteProc ( input pcServerName as character ):
        define variable cRemoteProc as character no-undo.

        find first ttMapping no-lock
             where ttMapping.ServerName eq pcServerName no-error.
        if available(ttMapping) then
            assign cRemoteProc = ttMapping.RemoteProc.

        /* If no value available, assume use of the the standard procedure. */
        if (cRemoteProc gt "") ne true then
            assign cRemoteProc = "Spark/Core/ApsvFacade.p".

        return cRemoteProc.
    end method. /* getHandlerRemoteProc */


    method protected void setCustomHeaders ( input poResponse as OpenEdge.Web.WebResponse ):
        /* Override as needed for custom headers in your web handler implementation. */
        /* poResponse:SetHeader("X-CUSTOM", "Sample Custom Header"). */
    end method. /* setCustomHeaders */


    method protected abstract integer runServiceAndRespond ( ).


    method protected void updateLogging ( ):
        /**
         * Force the reset of the logging config object,
         * and update to the latest logging level/types.
         */
        oLoggingManager:updateLoggingLevel().
        oLoggingManager:updateLogEntryTypes().
    end method.


    method protected integer prepareBinaryFile ( input pcFileName as character ):
        /* Prepare the response object with any headers, etc. */
        define variable oResponse as OpenEdge.Web.WebResponse no-undo.
        define variable mFileData as memptr                   no-undo.

        assign oResponse = new OpenEdge.Web.WebResponse(). /* Create response data (headers, etc.). */

        /* Assume 200-OK. */
        oResponse:StatusCode = 200.
        oResponse:StatusReason = "OK".

        set-size(mFileData) = 0.
        file-info:file-name = pcFileName.
        if file-info:full-pathname ne ? then do:
            copy-lob from file file-info:full-pathname to mFileData no-error.
            if error-status:error then
                logMessage(substitute("Error reading file: &1", GenTools:getAblError()), "SPARK-ERR", 1).

            oResponse:Entity = new OpenEdge.Core.Memptr(mFileData).

            case trim(substring(file-info:full-pathname, r-index(file-info:full-pathname, ".") + 1)):
                when "gif" then
                    oResponse:ContentType = "image/gif".
                when "htm" or
                when "html" then
                    oResponse:ContentType = "text/html".
                when "jpg" or
                when "jpeg" then
                    oResponse:ContentType = "image/jpeg".
                when "pdf" then
                    oResponse:ContentType = "application/pdf".
                when "png" then
                    oResponse:ContentType = "image/png".
                when "csv" then
                    oResponse:ContentType = "text/csv".
                when "txt" then
                    oResponse:ContentType = "text/plain".
                otherwise
                    oResponse:ContentType = "application/octet-stream".
            end.
        end. /* Valid File */

        /* Prepare response object to be written to the webstream. */
        this-object:writeResponse(oResponse).

        return 0.

        catch err as Progress.Lang.Error:
            logMessage(substitute("Error preparing response: &1", err:getmessage(1)), "SPARK-ERR", 0).
            logMessage(err:callstack, "SPARK-CALL", 0).
        end catch.
        finally:
            delete object oResponse no-error.
        end finally.
    end method. /* prepareBinaryFile */


    method protected integer prepareResponse ( input plResultValue  as logical,
                                               input piResponseCode as integer,
                                               input pfElapsedTime  as decimal,
                                               input plcHeaders     as longchar,
                                               input plcResponse    as longchar,
                                               input pcContentType  as character ):
        /* Prepare the response object with any headers, etc. */
        define variable oResponse as SparkResponse no-undo.

        assign oResponse = new SparkResponse(). /* Create response data (headers, etc.). */
        oResponse:StatusCode = if piResponseCode gt 0 then piResponseCode else integer(StatusCodeEnum:OK). /* Assume OK. */

        /* Provide standard reasons for typical responses. */
        oResponse:StatusReason = oResponse:GetStatusReason(oResponse:StatusCode).

        /* Prepare a parser that may be needed for headers or the response entity itself. */
        define variable oParser as ObjectModelParser no-undo.
        assign oParser = new ObjectModelParser().

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

        if oResponse:StatusCode ge 200 and oResponse:StatusCode le 299 then
            oResponse:ContentType = if (pcContentType gt "") eq true then pcContentType else "application/json".
        else
            oResponse:ContentType = "text/plain".

        if (plResultValue ne ?) then /* Denotes a successfull response or failure. */
            oResponse:SetHeader("X-RESULT", trim(string(plResultValue, "true/false"))).

        if (pfElapsedTime ge 0) then /* Tracks time for code execution. */
            oResponse:SetHeader("X-REQUEST-ELAPSED", trim(string(pfElapsedTime, ">>>,>>9.999sec."))).

        /* Set any passed headers. */
        if (plcHeaders gt "") eq true and plcHeaders begins "~{" then do {&throw}:
            define variable oHeaders as JsonObject        no-undo.
            define variable cNames   as character extent  no-undo.
            define variable iX       as integer           no-undo.

            assign oHeaders = cast(oParser:Parse(plcHeaders), JsonObject).
            assign cNames = oHeaders:GetNames().
            do iX = 1 to extent(cNames):
                oResponse:SetHeader(cNames[iX], oHeaders:GetCharacter(cNames[iX])).
            end.

            catch pErr as Progress.Json.JsonParserError:
                logMessage(substitute("Error parsing header object at byte &1.", pErr:Offset), "SPARK-ERR", 0).
            end catch.
            finally:
                delete object oHeaders no-error.
            end finally.
        end. /* plcHeaders */

        /* Set entity from JSON content. */
        if not valid-object(oResponse:Entity) and (plcResponse gt "") eq true and plcResponse begins "~{" then do:
             /* Assign the entity content if available and determined to be JSON. */
             oResponse:Entity = cast(oParser:parse(plcResponse), JsonObject).
        end.

        /* Prepare any custom headers for the response. */
        setCustomHeaders(input oResponse).

        /* Prepare response object to be written to the webstream. */
        this-object:writeResponse(oResponse).

        return 0.

        catch err as Progress.Lang.Error:
            logMessage(substitute("Error preparing response: &1", err:getmessage(1)), "SPARK-ERR", 0).
            logMessage(err:callstack, "SPARK-CALL", 0).
        end catch.
        finally:
            delete object oParser no-error.
            delete object oResponse no-error.
            assign
                plcHeaders  = ""
                plcResponse = ""
                .
        end finally.
    end method. /* prepareResponse */


    method protected void writeResponse ( input poResponse as OpenEdge.Web.WebResponse ):
        define variable oWriter as OpenEdge.Web.WebResponseWriter no-undo.
        define variable iBytes  as integer                        no-undo.

        if valid-object(poResponse) then do:
            /* Create a new web writer object using the given response object. */
            assign oWriter = new OpenEdge.Web.WebResponseWriter(poResponse).

            /* If the WebResponse object already has an Entity object then return that as the body. */
            if valid-object(poResponse:Entity) then do:
                oWriter:Open().

                case true:
                    when type-of(poResponse:Entity, OpenEdge.Core.Memptr) then
                        assign iBytes = oWriter:Write(cast(poResponse:Entity, OpenEdge.Core.Memptr):Value,
                                                      1, /* Always start at first byte of mem-pointer. */
                                                      cast(poResponse:Entity, OpenEdge.Core.Memptr):Size).

                    when type-of(poResponse:Entity, OpenEdge.Core.String) then
                        assign iBytes = oWriter:Write(cast(poResponse:Entity, OpenEdge.Core.String):Value).

                    when type-of(poResponse:Entity, JsonObject) then
                        assign iBytes = oWriter:Write(cast(poResponse:Entity, JsonObject):getJsonText()).

                    otherwise
                        undo, throw new AppError(substitute("Unknown type of WebResponse Entity object [&1]",
                                                            poResponse:Entity:GetClass():TypeName), 0).
                end case.

                oWriter:Close().
            end.
            else
                oWriter:Flush(). /* Otherwise just flush whatever we have. */

            /* Final debug message to prove we were here, just before the response is sent. */
            logMessage(substitute("Output &1kb with HTTP-&2",
                                  trim(string((iBytes / 1000), ">>>,>>>,>>9.999")), poResponse:StatusCode), "HANDLE-DBG", 3).
        end. /* valid-object */
        else
            undo, throw new AppError("Invalid or non-existent WebResponse object.", 0).

        finally:
            delete object oWriter no-error.
        end finally.
    end method. /* writeResponse */


    /** Public Methods **/


    method override protected integer HandleNotAllowedMethod ( input poRequest as OpenEdge.Web.IWebRequest ):
        define variable oResponse as OpenEdge.Web.WebResponse       no-undo.
        define variable oWriter   as OpenEdge.Web.WebResponseWriter no-undo.

        assign
            oResponse              = new OpenEdge.Web.WebResponse()
            oResponse:StatusCode   = integer(StatusCodeEnum:MethodNotAllowed)
            oResponse:StatusReason = StatusCodeHelper:GetMessage(StatusCodeEnum:MethodNotAllowed)
            oResponse:ContentType  = "text/plain"
            .

        /* Just return the headers created in the response. */
        oWriter = new OpenEdge.Web.WebResponseWriter(oResponse).
        oWriter:Open().
        oWriter:Close().

        return 0.
    end method. /* HandleNotAllowedMethod */


    method override protected integer HandleNotImplemented ( input poRequest as OpenEdge.Web.IWebRequest ):
        define variable oResponse as OpenEdge.Web.WebResponse       no-undo.
        define variable oWriter   as OpenEdge.Web.WebResponseWriter no-undo.

        assign
            oResponse              = new OpenEdge.Web.WebResponse()
            oResponse:StatusCode   = integer(StatusCodeEnum:NotImplemented)
            oResponse:StatusReason = StatusCodeHelper:GetMessage(StatusCodeEnum:NotImplemented)
            oResponse:ContentType  = "text/plain"
            .

        /* Just return the headers created in the response. */
        oWriter = new OpenEdge.Web.WebResponseWriter(oResponse).
        oWriter:Open().
        oWriter:Close().

        return 0.
    end method. /* HandleNotImplemented */


    method override protected integer HandleGet ( input poRequest as OpenEdge.Web.IWebRequest ):
        updateLogging().
        return runServiceAndRespond().
    end method. /* HandleGet */


    method override protected integer HandlePost ( input poRequest as OpenEdge.Web.IWebRequest ):
        updateLogging().
        return runServiceAndRespond().
    end method. /* HandlePost */


    method override protected integer HandlePut ( input poRequest as OpenEdge.Web.IWebRequest ):
        updateLogging().
        return runServiceAndRespond().
    end method. /* HandlePut */


    method override protected integer HandleDelete ( input poRequest as OpenEdge.Web.IWebRequest ):
        updateLogging().
        return runServiceAndRespond().
    end method. /* HandleDelete */


    method override protected integer HandleHead ( input poRequest as OpenEdge.Web.IWebRequest ):
        undo, throw new AppError("METHOD NOT IMPLEMENTED").
    end method. /* HandleHead */


    method override protected integer HandleOptions ( input poRequest as OpenEdge.Web.IWebRequest ):
        undo, throw new AppError("METHOD NOT IMPLEMENTED").
    end method. /* HandleOptions */


    method override protected integer HandlePatch ( input poRequest as OpenEdge.Web.IWebRequest ):
        undo, throw new AppError("METHOD NOT IMPLEMENTED").
    end method. /* HandlePatch */

end class.