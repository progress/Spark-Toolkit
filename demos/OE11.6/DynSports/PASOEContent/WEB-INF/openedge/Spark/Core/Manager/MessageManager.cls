using Progress.Lang.* from propath.
using Spark.Core.Manager.Manager from propath.
using Spark.Core.Manager.IMessageManager from propath.
using Spark.Core.Message.* from propath.
using Spark.Core.Util.OSTools from propath.
using Spark.Core.Web.IWebRequest from propath.
using Spark.Core.Web.IWebResponse from propath.
using Progress.Json.ObjectModel.JsonObject from propath.

block-level on error undo, throw.

/**
 * Message Manager Interface
 *
 * To set the Message Manager's Request object:
 *   cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):setRequestMessage("commitData",cRequestString).
 *
 * To retrieve the Request object:
 *   oReq = cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):RequestMessage, IRequest).
 *
 * To create a new request object:
 *   oReq = cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager)
 *                                                         :getNewMessage(get-class(IRequest),cRequestString),IRequest).
 */
class Spark.Core.Manager.MessageManager inherits Spark.Core.Manager.Manager implements IMessageManager:

    define private temp-table ttImplMapping no-undo serialize-name "MessageMapping"
        field IMessageTypeName       as character            serialize-name "Message"
        field IMessageClass          as Progress.Lang.Object serialize-hidden
        field ImplementationTypeName as character            serialize-name "Implementation"
        field ImplementationClass    as Progress.Lang.Object serialize-hidden
        index ix1 as primary unique IMessageTypeName.

    define private dataset dsConfig serialize-name "Config"
        for ttImplMapping.

    define private variable iUserResponse as integer no-undo initial ?.

    define public property RequestMessage as IAbstractMessage no-undo get.
        protected set.

    define public property ResponseMessage as IAbstractMessage no-undo get.
        protected set.

    define public property WebRequest as IWebRequest no-undo get. set.

    define public property WebResponse as IWebResponse no-undo get. set.

    define protected property HttpHeaders as JsonObject no-undo
        get():
            if not valid-object(HttpHeaders) then
                assign HttpHeaders = new JsonObject().
            return HttpHeaders.
        end.
        private set.

    define public property HttpMethod as character no-undo get.
        protected set.

    define public property StatusCode as integer no-undo initial 200
        get():
            /* Default the code as based on the verb. */
            case HttpMethod:
                when "post" then
                    assign StatusCode = 201. /* Created */
                when "delete" then
                    assign StatusCode = 204. /* No Content */
                otherwise
                    assign StatusCode = 200. /* OK */
            end case.

            /* Override with a custom user-defined code. */
            if iUserResponse ne ? then
                assign StatusCode = iUserResponse.

            return StatusCode.
        end.
        protected set.

    define public property ElapsedTime as decimal no-undo get. set.

    define public property RequestTime as datetime-tz no-undo get. set.

    define public property SessionID as character no-undo get. set.

    constructor public MessageManager ( ):
        super().
    end constructor.

    method override public void initialize ( ):
        loadConfig().
    end method.

    method override public void dispose ( ):
    end method.

    method protected void loadConfig ( ):

        define variable cFullCfgFileName as character no-undo.

        file-info:file-name = OSTools:sparkConf + "message.json".
        cFullCfgFileName = file-info:full-pathname.

        if cFullCfgFileName ne ? then
            dataset dsConfig:read-json ("FILE", cFullCfgFileName, "EMPTY").
        else
            undo, throw new AppError(substitute("Message config file [message.json] not found in [&1]", OSTools:sparkConf), 0).

        checkAllMessagesAreListed().

        for each ttImplMapping:
            assign
                ttImplMapping.IMessageClass       = Progress.Lang.Class:GetClass(ttImplMapping.IMessageTypeName)
                ttImplMapping.ImplementationClass = Progress.Lang.Class:GetClass(ttImplMapping.ImplementationTypeName) no-error.
            if not valid-object(ttImplMapping.IMessageClass) then
                log-manager:write-message(substitute("Invalid Message Interface [&1]", ttImplMapping.IMessageTypeName), "MSG-MGR").
            if not valid-object(ttImplMapping.ImplementationClass) then
                log-manager:write-message(substitute("Invalid Message Implementation [&1]", ttImplMapping.ImplementationTypeName), "MSG-MGR").
        end.

    end method.

    method protected void checkAllMessagesAreListed ( ):

        checkMessageIsListed(get-class(IConfigMessage):TypeName,get-class(ConfigMessage):TypeName).
        checkMessageIsListed(get-class(IRequest):TypeName,get-class(Request):TypeName).
        checkMessageIsListed(get-class(IResponse):TypeName,get-class(Response):TypeName).

    end method.

    method protected void checkMessageIsListed ( input pcMessageTypeName as character, input pcImplementationTypeName as character ):

        find first ttImplMapping
            where ttImplMapping.IMessageTypeName = pcMessageTypeName
            no-error.
        if not available ttImplMapping then
        do:
            create ttImplMapping.
            assign
                ttImplMapping.IMessageTypeName       = pcMessageTypeName
                ttImplMapping.ImplementationTypeName = pcImplementationTypeName.
        end.

    end method.

    method public longchar serializeHeaders ( input plClearData as logical ):

        if valid-object(HttpHeaders) then
            return HttpHeaders:GetJsonText().

        return "".

        finally:
            if plClearData then
                assign HttpHeaders = new JsonObject().
        end finally.

    end method.

    method public void setRequestVerb ( input pcHttpMethod as character ):

        assign iUserResponse = ?. /* Always reset the user-defined response code. */

        if not can-do("get,put,post,delete", pcHttpMethod) then
            undo, throw new AppError(substitute("HTTP Verb [&1] is not supported", pcHttpMethod), 0).

        HttpMethod = pcHttpMethod.

    end method.

    method public void setRequestMessage ( input pcResource as character, input pcMethodName as character, input pcRequestString as longchar ):

        /* Hardcoded here for performance. */
        RequestMessage = getMessageObject("Spark.Core.Message.IRequest", pcRequestString).
        if not valid-object(RequestMessage) then do:
            message "@RESEARCH: Could not get request message, trying again.".
            RequestMessage = getMessageObject("Spark.Core.Message.IRequest", pcRequestString).
        end. /* valid-object */

    end method.

    method public void setResponseCode ( input piHttpCode as integer ):

        if piHttpCode ge 100 and piHttpCode le 599 then
            assign iUserResponse = piHttpCode.

    end method.

    method public void setResponseHeader ( input pcHeaderName as character, input pcHeaderValue as character ):

        if (pcHeaderName gt "") eq true and pcHeaderValue ne ? then do:
            if HttpHeaders:Has(pcHeaderName) then
                HttpHeaders:Set(pcHeaderName, pcHeaderValue).
            else
                HttpHeaders:Add(pcHeaderName, pcHeaderValue).
        end.

    end method.

    method public void setResponseMessage ( input pcResource as character, input pcMethodName as character, input pcResponseString as longchar ):

        /* Hardcoded here for performance. */
        ResponseMessage = getMessageObject("Spark.Core.Message.IResponse", pcResponseString).
        if not valid-object(ResponseMessage) then do:
            message "@RESEARCH: Could not get response message, trying again.".
            ResponseMessage = getMessageObject("Spark.Core.Message.IResponse", pcResponseString).
        end. /* valid-object */

    end method.

    method public IAbstractMessage getNewMessage ( input poMessageInterface as Progress.Lang.Class, input pcMessageString as longchar ):

        return getMessageObject(poMessageInterface:TypeName, pcMessageString).

    end method.

    method public void resetMessages():
        assign
            RequestMessage = ?
            ResponseMessage = ?
            HttpHeaders = ?
            WebRequest = ?
            WebResponse = ?
            .
    end method.

    method protected IAbstractMessage getMessageObject ( input pcIMessageTypeName as character, input pcSerializedMessage as longchar ):

        define variable oParam               as Progress.Lang.ParameterList no-undo.
        define variable oImplementationClass as Progress.Lang.Class         no-undo.

        oImplementationClass = getImplementationClass(pcIMessageTypeName).

        if pcSerializedMessage eq "null" then
            assign pcSerializedMessage = ?. /* Treat "null" as null (?). */

        if pcSerializedMessage eq ? or pcSerializedMessage eq "" then
            oParam = new Progress.Lang.ParameterList(0).
        else
        do:
            oParam = new Progress.Lang.ParameterList(1).
            oParam:SetParameter(1, "LONGCHAR", "INPUT", pcSerializedMessage).
        end.

        return cast(oImplementationClass:New(oParam), IAbstractMessage).

    end method.

    method protected Progress.Lang.Class getImplementationClass ( input pcIMessageTypeName as character ):

        define variable oImplementationClass as Progress.Lang.Class no-undo.

        find first ttImplMapping no-lock
             where ttImplMapping.IMessageTypeName eq pcIMessageTypeName no-error.
        if available(ttImplMapping) then
            oImplementationClass = cast(ttImplMapping.ImplementationClass, Progress.Lang.Class).
        else do:
            log-manager:write-message(substitute("Message Type [&1] not defined", pcIMessageTypeName), "MSG-MGR").
            return ?. /* Return unknown instead of throwing error. */
        end.

        return oImplementationClass.

    end method.

end class.
