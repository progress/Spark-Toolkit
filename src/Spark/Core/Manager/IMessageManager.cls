using Ccs.Common.IManager from propath.
using Spark.Core.Message.IAbstractMessage from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Spark.Core.Web.IWebRequest from propath.
using Spark.Core.Web.IWebResponse from propath.

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
interface Spark.Core.Manager.IMessageManager inherits IManager:

    /* Spark Messages */
    define public property RequestMessage  as IAbstractMessage no-undo get.
    define public property ResponseMessage as IAbstractMessage no-undo get.

    /* Statistics */
    define public property ElapsedTime as decimal     no-undo get. set.
    define public property RequestTime as datetime-tz no-undo get. set.
    define public property SessionID   as character   no-undo get. set.

    /* HTTP Properties */
    define public property HttpMethod  as character no-undo get.
    define public property StatusCode  as integer   no-undo get.

    /* ABL Web Objects */
    define public property WebRequest  as IWebRequest  no-undo get. set.
    define public property WebResponse as IWebResponse no-undo get. set.

    method public longchar serializeHeaders ( input plClearData as logical ).

    method public void setRequestVerb ( input pcHttpMethod as character ).
    method public void setRequestMessage ( input pcResource as character, input pcMethodName as character, input pcRequestString as longchar ).
    method public void setResponseCode ( input piHttpCode as integer ).
    method public void setResponseHeader ( input pcHeaderName as character, input pcHeaderValue as character ).
    method public void setResponseMessage ( input pcResource as character, input pcMethodName as character, input pcResponseString as longchar ).

    method public void resetMessages().

    method public IAbstractMessage getNewMessage ( input poMessageInterface as Progress.Lang.Class, input pcMessageString as longchar ).

end interface.