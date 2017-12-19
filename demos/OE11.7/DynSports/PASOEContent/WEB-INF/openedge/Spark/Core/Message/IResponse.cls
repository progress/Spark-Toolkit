using Spark.Core.Message.ErrorTypeEnum from propath.
using Spark.Core.Message.IAbstractMessage from propath.

/**
 * A Response Service Message
 */
interface Spark.Core.Message.IResponse inherits IAbstractMessage:

    /** set to true by the service interface once the request C-P has been asserted and session established without error */
    define public property validContextID as logical no-undo get. set.

    /**
     * Add an Error message to this Response Message
     *
     * The Error message is translated during this function
     *
     * @param pcErrField The name of the field that has an error
     * @param poErrType The type of error (ERROR, WARNING, INFO, etc)
     * @param pcErrMsg The Error Message
     */
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character, input pcSub9 as character ).
    method public void addError( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character, input pcSub9 as character ).

    method public void addAppError ( input poAppError as Progress.Lang.AppError ).

    method public void addProError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input poProError as Progress.Lang.Error ).

    /**
     * Log any Errors in the response Message
     */
    method public void logErrors ().

    /**
     * Get a JSON string from the error temp-table
     */
    method public longchar getErrorJSON ( ).

    /**
     * Get the first error
     *
     * @param pcErrField The field this error relates to
     * @param poErrType The error type as a ErrorTypeEnum
     * @param pcErrMsg The error message
     */
    method public logical getFirstError ( output pcErrField as character, output poErrType as ErrorTypeEnum, output pcErrMsg as character ).

    /**
     * Get the next error
     *
     * @param pcErrField The field this error relates to
     * @param poErrType The error type as a ErrorTypeEnum
     * @param pcErrMsg The error message
     */
    method public logical getNextError ( output pcErrField as character, output poErrType as ErrorTypeEnum, output pcErrMsg as character ).

    /**
     * Get the previous error
     *
     * @param pcErrField The field this error relates to
     * @param poErrType The error type as a ErrorTypeEnum
     * @param pcErrMsg The error message
     */
    method public logical getPrevError ( output pcErrField as character, output poErrType as ErrorTypeEnum, output pcErrMsg as character ).

    /**
     * Get the last error
     *
     * @param pcErrField The field this error relates to
     * @param poErrType The error type as a ErrorTypeEnum
     * @param pcErrMsg The error message
     */
    method public logical getLastError ( output pcErrField as character, output poErrType as ErrorTypeEnum, output pcErrMsg as character ).

    /**
     * Has this response got any Warning or Information messages
     *
     * @return The response contains Warning messages
     */
    method public logical hasWarnings ( ).

    /**
     * Has this response got any Warning or Information messages for a particular field
     *
     * @return The response contains Warning messages
     */
    method public logical hasWarnings ( input pcErrField as character ).

    /**
      * Has this response got any messages at all
      *
      * @return The response contains messages
      */
    method public logical hasAnyErrors ( ).

    /**
      * Has this response got any messages at all for a particular field
      *
      * @return The response contains messages
      */
    method public logical hasAnyErrors ( input pcErrField as character ).

    /**
     * Has this response got any Error messages
     *
     * @return The response contains Error messages
     */
    method public logical hasErrors ( ).

    /**
     * Has this response got any Error messages for a particular field
     *
     * @return The response contains Error messages
     */
    method public logical hasErrors ( input pcErrField as character ).

    /**
     * Has this response got any Information messages
     *
     * @return The response contains Information messages
     */
    method public logical hasInformation ( ).

    /**
     * Has this response got any Information messages for a particular field
     *
     * @return The response contains Information messages
     */
    method public logical hasInformation ( input pcErrField as character ).

    /**
     * Remove all Warning and Information (Non STOP) type messages
     */
    method public void removeWarningMessages ( ).

    /**
     * Remove Error messages by type
     */
    method public void removeErrorMessages ( input poErrType as ErrorTypeEnum ).

    /**
     *  Remove Error messages by type for a particular field
     */
    method public void removeErrorMessages ( input pcErrField as character, input poErrType as ErrorTypeEnum ).

    /**
     *  Remove all Error messages for a particular field
     */
    method public void removeErrorMessages ( input pcErrField as character ).


    /**
     * Reset the ErrorType on all errors in this message object
     *
     * @param poErrType The error type as a ErrorTypeEnum
     */
    method public void resetAllErrors (input poErrType as ErrorTypeEnum).

    /**
     * Reset the ErrorType on all errors in this message object
     *
     * @param pcErrField The field the errors relates to
     */
    method public void resetAllErrors (input pcErrField as character).

end interface.