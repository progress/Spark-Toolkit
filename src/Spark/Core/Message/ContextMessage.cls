using Progress.Json.ObjectModel.JsonArray from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.ITranslationManager from propath.
using Spark.Core.Util.ApplicationError from propath.
using Spark.Core.Util.ErrorTypeEnum from propath.

block-level on error undo, throw.

/**
 * A Request Service Message
 */
class Spark.Core.Message.ContextMessage inherits Spark.Core.Message.AbstractMessage implements Spark.Core.Message.IContextMessage:

    define protected property ValidationErrorTableName as character initial "errorTable" no-undo get. private set.

    define public property ContextPropName as character no-undo initial  "_errors" get. private set.
    define public property ReturnValueName as character no-undo initial "_retVal" get. private set.
    define public property ReturnValue as logical initial ? no-undo get. set.

    define private variable mimsgSeq   as integer no-undo initial 0.

    define protected temp-table ttMessage no-undo serialize-name "message"
        field msgSeq     as integer   serialize-hidden
        field msgType    as character serialize-name "type"
        field msgTxt     as character serialize-name "msg"
        field errRow     as character serialize-name "id"
        field origmsgTxt as character serialize-hidden
        index ix1 as primary msgSeq
        index ix2            msgType
        .

    constructor public ContextMessage ( ):

        super().

    end constructor.

    method override protected void storeProperties ( ):
        /* Not implemented here. */
    end method.

    method public void setContextPropName ( input pcName as character ):

        if (pcName gt "") eq true then
            this-object:ContextPropName = pcName.

    end method.

    method public void setReturnValueName ( input pcName as character ):

        if (pcName gt "") eq true then
            this-object:ReturnValueName = pcName.

    end method.

    /**
     * Add a message to this context object
     *
     * The Error message is translated during this function
     *
     * @param poMsgType The type of error (ERROR, WARNING, INFO, etc)
     * @param pcMessage The Error Message
     */
    method public void addMessage ( input poMsgType as ErrorTypeEnum, input pcMessage as character ):

        this-object:createMessage(poMsgType:name, translateMessage(pcMessage), pcMessage).

    end method.

    /**
     * Add a message to this context object
     *
     * The Error message is translated during this function
     *
     * @param poMsgType The type of error (ERROR, WARNING, INFO, etc)
     * @param poMsgGroup The group to associate with this message
     * @param pcMessage The Error Message
     */
    method public void addMessage ( input poMsgType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer ):

        this-object:createMessage(poMsgType:name, translateMessage(pcMsgGroup, piMsgNumber), pcMsgGroup, piMsgNumber).

    end method.

    /**
     * A private method used to create the Error Message Temp-Table
     *
     * @param pcmsgType The Error Type
     * @param pcMessage The already translated Message
     */
    method private void createMessage ( input pcmsgType as character, input pcMessage as character, input pcOrigmsgTxt as character ):

        find first ttMessage
             where ttMessage.msgType eq pcmsgType
               and ttMessage.msgTxt eq pcMessage no-error.
        if available ttMessage then
            delete ttMessage.

        create ttMessage.
        assign
            mimsgSeq           = mimsgSeq + 1
            ttMessage.msgSeq     = mimsgSeq
            ttMessage.msgType    = pcmsgType
            ttMessage.msgTxt     = pcMessage
            ttMessage.origmsgTxt = pcOrigmsgTxt
            .

    end method.

    method private void createMessage ( input pcmsgType as character, input pcMessage as character, input pcMsgGroup as character, input piMsgNumber as integer ):

        this-object:createMessage(pcmsgType, pcMessage, substitute("&1:&2", pcMsgGroup, piMsgNumber)).

    end method.

    /**
     * Get a JSON array from the error temp-table in standard OpenEdge format
     */
    method public JsonArray getMessageArray ( ):

        define variable oArray as JsonArray  no-undo.
        define variable oError as JsonObject no-undo.

        assign oArray = new JsonArray().
        for each ttMessage:
            assign oError = new JsonObject().
            oError:Add("_errorNum", ttMessage.msgSeq - 1). /* By default Progress uses zero-based numbers for error counting. */
            oError:Add("_errorMsg", ttMessage.msgTxt).
            oError:Add("_errorType", ttMessage.msgType).
            if (ttMessage.errRow gt "") eq true then
                oError:Add("_errorRow", ttMessage.errRow).
            oArray:Add(oError).
        end.
        return oArray.

    end method.

    /**
     * Has this response got any messages at all
     *
     * @return The response contains messages
     */
    method public logical hasAnyMessages ( ):

        return can-find(first ttMessage).

    end method.

    /**
     * Has this response got any Information messages
     *
     * @return The response contains Information messages
     */
    method public logical hasInformation ( ):

        return can-find(first ttMessage where ttMessage.msgType eq ErrorTypeEnum:information:name).

    end method.

    /**
     * Has this response got any Warning or Information messages
     *
     * @return The response contains Warning messages
     */
    method public logical hasWarnings ( ):

        return can-find(first ttMessage
                        where ttMessage.msgTxt ne ""
                          and (ttMessage.msgType eq ErrorTypeEnum:warning:name or
                               ttMessage.msgType eq ErrorTypeEnum:information:name)).

    end method.

    /**
     * Has this response got any Error messages
     *
     * @return The response contains Error messages
     */
    method public logical hasErrors ( ):

        return can-find(first ttMessage
            where ttMessage.msgTxt ne ""
              and (ttMessage.msgType eq ErrorTypeEnum:error:name or
                   ttMessage.msgType eq ErrorTypeEnum:fatal:name)).
    /* A record with a blank msgTxt is a valid record and is used to indicate
       that a previous error message is no longer an error and can be cleared by the client
     */
    end method.

    /**
     * Remove all Warning and Information (Non-"STOP") type messages
     */
    method public void removeWarningMessages ( ):

        for each ttMessage:
            if ttMessage.msgType eq ErrorTypeEnum:warning:name or
               ttMessage.msgType eq ErrorTypeEnum:information:name then
                delete ttMessage.
        end.

    end method.

    /**
     * Remove messages by type
     */
    method public void removeMessages ( input poMsgType as ErrorTypeEnum ):

        for each ttMessage where ttMessage.msgType eq poMsgType:name:
            delete ttMessage.
        end.

    end method.

    method private character translateMessage ( input pcMessage as character ):

        return cast(Ccs.Common.Application:StartupManager
                                          :getManager(get-class(ITranslationManager)), ITranslationManager):getTranslatedMessage(pcMessage).

    end method.

    method private character translateMessage ( input pcMsgGroup as character, input piMsgNumber as integer ):

        return cast(Ccs.Common.Application:StartupManager
                                          :getManager(get-class(ITranslationManager)), ITranslationManager):getTranslatedMessage(pcMsgGroup, piMsgNumber).

    end method.

end class.