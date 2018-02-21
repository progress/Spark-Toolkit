/*------------------------------------------------------------------------
    File        : UploadHandler
    Purpose     : Accept multipart form data and store as files on server
    Description : Simple binary file upload handler
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Mon Sep 18 14:04:31 EDT 2017
    Notes       : Tested with KendoUI file upload widget
  ----------------------------------------------------------------------*/

&GLOBAL-DEFINE MIN_LOGGING_LEVEL 2
&GLOBAL-DEFINE UPLOAD_PARENT_DIR "upload"

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using OpenEdge.Net.HTTP.StatusCodeHelper from propath.
using Spark.Core.Manager.ILoggingManager from propath.

block-level on error undo, throw.

class Spark.Core.Handler.FileUpload inherits OpenEdge.Web.WebHandler use-widget-pool:

    define protected property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.

    /***** Helper Methods *****/

    method private OpenEdge.Net.MultipartEntity getMultipartEntity ( input poRequest as OpenEdge.Web.IWebRequest ):
        if OpenEdge.Net.MimeTypeHelper:IsMultipart(poRequest:ContentType) then do:
            define variable oEntityWriter as OpenEdge.Net.HTTP.Filter.Payload.MessageWriter no-undo.
            define variable oHeader       as OpenEdge.Net.HTTP.HttpHeader                   no-undo.

            oEntityWriter = OpenEdge.Net.HTTP.Filter.Writer.EntityWriterBuilder:Build(poRequest):Writer.
            oEntityWriter:Open().
            oEntityWriter:Write(poRequest:Entity).
            oEntityWriter:Close().

            return cast(oEntityWriter:Entity, OpenEdge.Net.MultipartEntity).
        end.

        return new OpenEdge.Net.MultipartEntity().
    end method. /* getMultipartEntity */

    /***** Override Methods *****/

    method override protected integer HandleNotAllowedMethod( input poRequest as OpenEdge.Web.IWebRequest ):
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").
    end method.

    method override protected integer HandleNotImplemented( input poRequest as OpenEdge.Web.IWebRequest ):
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").
    end method.

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
            oLoggingManager:logMessage(substitute("Output &1kb with HTTP-&2",
                                       trim(string((iBytes / 1000), ">>>,>>>,>>9.999")), poResponse:StatusCode), "UPLOAD", {&MIN_LOGGING_LEVEL}).
        end. /* valid-object */
        else
            undo, throw new AppError("Invalid or non-existent WebResponse object.", 0).

        finally:
            delete object oWriter no-error.
        end finally.
    end method. /* writeResponse */

    method override protected integer HandleGet ( input poRequest as OpenEdge.Web.IWebRequest ):
        undo, throw new AppError("METHOD NOT IMPLEMENTED").
    end method. /* HandleGet */

    method override protected integer HandlePut ( input poRequest as OpenEdge.Web.IWebRequest ):
        undo, throw new AppError("METHOD NOT IMPLEMENTED").
    end method. /* HandlePut */

    method override protected integer HandleDelete ( input poRequest as OpenEdge.Web.IWebRequest ):
        undo, throw new AppError("METHOD NOT IMPLEMENTED").
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

    method override protected integer HandlePost ( input poRequest as OpenEdge.Web.IWebRequest ):
        define variable cUploadDir as character                    no-undo.
        define variable cFileType  as character                    no-undo.
        define variable cFileName  as character                    no-undo.
        define variable cOutFile   as character                    no-undo.
        define variable iPart      as integer                      no-undo.
        define variable iTime      as integer                      no-undo.
        define variable oEntity    as OpenEdge.Net.MultipartEntity no-undo.
        define variable oPart      as OpenEdge.Net.MessagePart     no-undo.
        define variable oHeader    as OpenEdge.Net.HTTP.HttpHeader no-undo.
        define variable oMemptr    as OpenEdge.Core.Memptr         no-undo.
        define variable oResponse  as OpenEdge.Web.WebResponse     no-undo.
        define variable oUploadLog as JsonObject                   no-undo.

        /**
         * Assert the current user's identity for this session request.
         *
         * Note: For working with anonymous security, ensure the following are set:
         *  OEClientPrincipalFilter.anonymous=true
         *  OEClientPrincipalFilter.sealAnonymous=true
         *  OEClientPrincipalFilter.passthru=true
         */
        define variable oPrincipal as OpenEdge.Security.Principal no-undo.
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).
        Ccs.Common.Application:SessionManager:establishRequestEnvironment(oPrincipal:Token).

        if not OpenEdge.Net.MimeTypeHelper:IsMultipart(poRequest:ContentType) then
            undo, throw new AppError("Uploaded content is not multipart.", 0).

        assign
            oUploadLog = new JsonObject() /* A list of files that were uploaded. */
            iTime      = mtime /* Mark the current time for this upload attempt. */
            .

        /* Make sure a main directory exists for uploads. */
        assign cUploadDir = substitute("&1/&2", os-getenv("CATALINA_BASE"), {&UPLOAD_PARENT_DIR}).
        file-info:file-name = cUploadDir.
        if file-info:full-pathname eq ? then
            os-create-dir value(cUploadDir).

        /* Make sure a user directory exists for user. */
        assign cUploadDir = substitute("&1/&2", cUploadDir, oPrincipal:Token:user-id)
        file-info:file-name = cUploadDir.
        if file-info:full-pathname eq ? then
            os-create-dir value(cUploadDir).

        /* Make sure a directory exists for the time. */
        assign cUploadDir = substitute("&1/&2", cUploadDir, iTime)
        file-info:file-name = cUploadDir.
        if file-info:full-pathname eq ? then
            os-create-dir value(cUploadDir).

        /* Determine boundary for multipart data, pass request and boundary to extract entity. */
        assign oEntity = getMultipartEntity(poRequest).
        if valid-object(oEntity) then do iPart = 1 to oEntity:Size:
            assign oPart = oEntity:GetPart(iPart).
            if valid-object(oPart) then do:
                /* Extract file information from multipart entity. */
                assign cFileType = oPart:ContentType.
                if oPart:Headers:Has("Content-Disposition") then
                    assign oHeader = oPart:Headers:Get("Content-Disposition").

                if valid-object(oHeader) then
                    assign cFileName = replace(oHeader:GetParameterValue("filename"), '~"', "").
                else
                    undo, throw new AppError("Unable to extract header information for file. ", 0).

                /* Construct a unique destination for each file, by uploading user, by upload time. */
                assign cOutFile = substitute("&1/&2", cUploadDir, cFileName).

                /* Send all of the data to the output file. */
                assign oMemptr = cast(oPart:Body, OpenEdge.Core.ByteBucket):GetBytes().
                copy-lob from oMemptr:Value to file cOutFile no-convert no-error.

                /* Log reciept of this uploaded file by this user. */
                oLoggingManager:logMessage(substitute("&1 bytes as &2 to &3",
                                                      cast(oPart:Body, OpenEdge.Core.ByteBucket):Size,
                                                      cFileType, cOutFile), "UPLOAD", {&MIN_LOGGING_LEVEL}).

                oUploadLog:Add(string(iPart), cOutFile). /* Add each uploaded file to response. */
            end. /* valid part */
        end. /* valid entity */

        /* Prepare standard response object (JSON) with list of files. */
        assign oResponse = new OpenEdge.Web.WebResponse().
        oResponse:StatusCode = integer(StatusCodeEnum:ok).
        oResponse:StatusReason = StatusCodeHelper:GetMessage(StatusCodeEnum:OK).
        oResponse:ContentType = "application/json".
        oResponse:Entity = oUploadLog.
        writeResponse(oResponse).

        catch err as Progress.Lang.Error:
            /* Prepare error response with a simple string. */
            assign oResponse = new OpenEdge.Web.WebResponse().
            oResponse:StatusCode = integer(StatusCodeEnum:InternalServerError).
            oResponse:StatusReason = StatusCodeHelper:GetMessage(StatusCodeEnum:InternalServerError).
            oResponse:ContentType = "text/plain". /* Just return plain text. */
            oResponse:Entity = new OpenEdge.Core.String(err:GetMessage(1)).
            writeResponse(oResponse).
        end catch.
        finally:
            /* Flush the session data and downgrade to the reset CP token. */
            Ccs.Common.Application:SessionManager:endRequestEnvironment().

            delete object oEntity    no-error.
            delete object oHeader    no-error.
            delete object oPart      no-error.
            delete object oPrincipal no-error.
            delete object oResponse  no-error.

            return 0. /* Always return 0. */
        end finally.
    end method. /* HandlePost */

end class.