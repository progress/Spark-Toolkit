using Progress.Json.ObjectModel.JsonArray from propath.
using Spark.Core.Message.IAbstractMessage from propath.
using Spark.Core.Util.ErrorTypeEnum from propath.

/**
 * A Response Service Message
 */
interface Spark.Core.Message.IContextMessage inherits IAbstractMessage:

    define public property ContextPropName as character no-undo get.
    define public property ReturnValueName as character no-undo get.
    define public property ReturnValue     as logical   no-undo get.

    method public void addMessage ( input poMsgType as ErrorTypeEnum, input pcMessage as character ).
    method public void addMessage ( input poMsgType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer ).

    method public void setContextPropName ( input pcName as character ).
    method public void setReturnValueName ( input pcName as character ).

    /**
     * Get a JSON array from the message temp-table
     */
    method public JsonArray getMessageArray ( ).

    /**
      * Has this response got any messages at all
      *
      * @return The response contains messages
      */
    method public logical hasAnyMessages ( ).

    /**
     * Has this response got any Information messages
     *
     * @return The response contains Information messages
     */
    method public logical hasInformation ( ).

    /**
     * Has this response got any Warning or Information messages
     *
     * @return The response contains Warning messages
     */
    method public logical hasWarnings ( ).

    /**
     * Has this response got any Error messages
     *
     * @return The response contains Error messages
     */
    method public logical hasErrors ( ).

    /**
     * Remove all Warning and Information (Non STOP) type messages
     */
    method public void removeWarningMessages ( ).

    /**
     * Remove messages by type
     */
    method public void removeMessages ( input poMsgType as ErrorTypeEnum ).

end interface.