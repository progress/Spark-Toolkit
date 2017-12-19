using Progress.Json.ObjectModel.JsonArray from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.IMessageManager from propath.
using Spark.Core.Manager.ITranslationManager from propath.
using Spark.Core.Message.ErrorTypeEnum from propath.
using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

/**
 * A Request Service Message
 */
class Spark.Core.Message.Response inherits Spark.Core.Message.AbstractMessage implements Spark.Core.Message.IResponse:

    define protected property mcValidationErrorTableName as character initial "errorTable" no-undo get. private set.
    define protected property mcErrorPropName as character no-undo initial  "_errors" get. private set.
    define protected property mcReturnValName as character no-undo initial "_retVal" get. private set.

    define private variable mhErrQuery as handle  no-undo.
    define private variable miErrSeq   as integer initial 0 no-undo.

    define protected temp-table ttError no-undo serialize-name "error"
        field errField   as character serialize-name 'field'
        field errType    as character serialize-name 'type'
        field errMsg     as character serialize-name 'msg'
        field errRow     as character serialize-name 'id'
        field errSeq     as integer   serialize-hidden
        field origErrMsg as character serialize-hidden
        index ix1 as primary errSeq
        index ix2            errType  errField
        index ix3            errField errType.

    define public property validContextID as logical no-undo get. set.

    define public property returnValue as logical initial ? no-undo get. set.

    constructor public Response ( ):
        super().
    end constructor.

    constructor public Response ( input pcMessage as longchar ):

        super(input pcMessage).

        deserializeError().

    end constructor.

    method protected logical deserializeError ( ):

        define variable oJsonArr as JsonArray  no-undo.
        define variable oError   as JsonObject no-undo.
        define variable iLoop    as integer    no-undo.
        define variable iLength  as integer    no-undo.
        define variable cTemp    as longchar   no-undo.

        oJsonArr = getParamAsJsonArray(mcValidationErrorTableName, true).
        if valid-object(oJsonArr) then
        do:
            oJsonArr:Write(input-output cTemp).
            if cTemp ne '' and cTemp ne '~{~}' and trim(trim(cTemp,'['),']') ne '' then
                temp-table ttError:read-json('JsonArray', oJsonArr, 'EMPTY').
        end.

        oJsonArr = getParamAsJsonArray(mcErrorPropName, true).
        if valid-object(oJsonArr) then do:
            iLength = oJsonArr:Length.
            do iloop = 1 to iLength:
                oError = oJsonArr:GetJsonObject(iLoop).
                create ttError.
                assign
                    ttError.errSeq     = oError:GetInteger("_errorNum") + 1 /* By default Progress uses zero-based numbers for error counting. */
                    ttError.errMsg     = oError:GetCharacter("_errorMsg")
                    ttError.errType    = oError:GetCharacter("_errorType")
                    ttError.errRow     = oError:GetCharacter("_errorRow") when oError:Has("_errorRow")
                    ttError.origErrMsg = ttError.errMsg
                    .
            end.
        end.

        return getParamAsLog(mcReturnValName, true).

    end method.

    /**
     * Add an Error message to this Response Message
     *
     * The Error message is translated during this function
     *
     * @param pcErrField The name of the field that has an error
     * @param poErrType The type of error (ERROR, WARNING, INFO, etc)
     * @param pcErrMsg The Error Message
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character ):

        createError(pcErrField, poErrType:name, translateMessage(pcErrMsg), pcErrMsg).

    end method.

    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer ):

        createError(pcErrField, poErrType:name, translateMessage(pcMsgGroup, piMsgNumber), pcMsgGroup, piMsgNumber).

    end method.

    /**
     * Add an Error message to this Response Message
     *
     * The Error message is translated during this function
     *
     * @param pcErrField The name of the field that has an error
     * @param pcErrType The type of error (ERROR, WARNING, INFO, etc)
     * @param pcErrMsg The Error Message containing one substitute e.g "Invalid Customer [&1]
     * @param pcSub1 A substitute string for the error message  e.g "Joe's Service"
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcErrMsg), pcSub1),
            substitute(pcErrMsg, pcSub1)).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcMsgGroup, piMsgNumber), pcSub1),
            pcMsgGroup, piMsgNumber).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcErrMsg), pcSub1, pcSub2),
            substitute(pcErrMsg, pcSub1, pcSub2)).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcMsgGroup, piMsgNumber), pcSub1, pcSub2),
                       pcMsgGroup, piMsgNumber).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcErrMsg), pcSub1, pcSub2, pcSub3),
            substitute(pcErrMsg, pcSub1, pcSub2, pcSub3)).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcMsgGroup, piMsgNumber), pcSub1, pcSub2, pcSub3),
                       pcMsgGroup, piMsgNumber).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcErrMsg), pcSub1, pcSub2, pcSub3, pcSub4),
            substitute(pcErrMsg, pcSub1, pcSub2, pcSub3, pcSub4)).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcMsgGroup, piMsgNumber), pcSub1, pcSub2, pcSub3, pcSub4),
                       pcMsgGroup, piMsgNumber).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcErrMsg), pcSub1, pcSub2, pcSub3, pcSub4, pcSub5),
            substitute(pcErrMsg, pcSub1, pcSub2, pcSub3, pcSub4, pcSub5)).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcMsgGroup, piMsgNumber), pcSub1, pcSub2, pcSub3, pcSub4, pcSub5),
                       pcMsgGroup, piMsgNumber).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcErrMsg), pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6),
            substitute(pcErrMsg, pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6)).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcMsgGroup, piMsgNumber), pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6),
            pcMsgGroup, piMsgNumber).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcErrMsg), pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6, pcSub7),
            substitute(pcErrMsg, pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6, pcSub7)).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcMsgGroup, piMsgNumber), pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6, pcSub7),
                       pcMsgGroup, piMsgNumber).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcErrMsg), pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6, pcSub7, pcSub8),
            substitute(pcErrMsg, pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6, pcSub7, pcSub8)).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcMsgGroup, piMsgNumber), pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6, pcSub7, pcSub8),
                       pcMsgGroup, piMsgNumber).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcErrMsg as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character, input pcSub9 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcErrMsg), pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6, pcSub7, pcSub8, pcSub9),
            substitute(pcErrMsg, pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6, pcSub7, pcSub8, pcSub9)).

    end method.

    /**
     * @see addError()
     */
    method public void addError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input pcMsgGroup as character, input piMsgNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character, input pcSub9 as character ):

        createError(pcErrField, poErrType:name,
            substitute(translateMessage(pcMsgGroup, piMsgNumber), pcSub1, pcSub2, pcSub3, pcSub4, pcSub5, pcSub6, pcSub7, pcSub8, pcSub9),
                       pcMsgGroup, piMsgNumber).

    end method.

    /**
     * Add a thrown ApplicationError message to this Response Message
     *
     * The Error message has already been translated by the ApplicationError object
     *
     * @param poAppError The ApplicationError Object
     */
    method public void addAppError ( input poAppError as Progress.Lang.AppError ):

        define variable iLoop             as integer          no-undo.
        define variable cErrorField       as character        no-undo.
        define variable cErrorType        as character        no-undo.
        define variable cOrigErrMsg       as character        no-undo.

        define variable oApplicationError as ApplicationError no-undo.

        if poAppError:GetClass():IsA(get-class(ApplicationError)) then
        do:
            oApplicationError = cast(poAppError,ApplicationError).
            assign
                cErrorField = oApplicationError:errorField
                cErrorType  = oApplicationError:errorType:name
                cOrigErrMsg = oApplicationError:originalErrorMessage.
        end.
        else
            assign
                cErrorField = ""
                cErrorType  = ErrorTypeEnum:error:name
                cOrigErrMsg = "".

        do iLoop = 1 to poAppError:NumMessages:
            if poAppError:GetMessageNum(iLoop) lt 0 then
                cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager)
                    :setResponseCode(poAppError:GetMessageNum(iLoop) * -1).
            if iLoop gt 1 then
                cOrigErrMsg = poAppError:GetMessage(iLoop).
            createError(cErrorField, cErrorType, poAppError:GetMessage(iLoop), cOrigErrMsg).
        end.

        if poAppError:ReturnValue ne "" then
            createError(cErrorField, cErrorType, poAppError:ReturnValue, poAppError:ReturnValue).

        /* If debug is on then add Stack Trace to the message
           You can also set this session attribute using the -errorstack startup parameter. */
        if session:error-stack-trace then
            createError(cErrorField, ErrorTypeEnum:trace:name, poAppError:CallStack, poAppError:CallStack).

    end method.

    /**
     * Add a thrown ProError (SysError or ProError) message to this Response Message
     *
     * @param pcErrField The name of the field that has an error
     * @param poErrType The type of error (ERROR, WARNING, INFO, etc)
     * @param poProError The ABL Error Object
     */
    method public void addProError ( input pcErrField as character, input poErrType as ErrorTypeEnum, input poProError as Progress.Lang.Error ):

        define variable iLoop      as integer                      no-undo.
        define variable oSoapError as Progress.Lang.SoapFaultError no-undo.

        do iLoop = 1 to poProError:NumMessages:
            addError(pcErrField, poErrType, poProError:GetMessage(iLoop)).
        end.

        if poProError:GetClass():IsA(get-class(Progress.Lang.SoapFaultError)) then
        do:
            oSoapError = cast(poProError,Progress.Lang.SoapFaultError).
            if valid-handle(oSoapError:SoapFault:soap-fault-detail) then
                addError(pcErrField, poErrType, "Soap Error: &1", string(oSoapError:SoapFault:soap-fault-detail:get-serialized())).
            addError(pcErrField, poErrType, "Soap Fault Code: &1", oSoapError:SoapFault:soap-fault-code).
            addError(pcErrField, poErrType, "Soap Fault String: &1", oSoapError:SoapFault:soap-fault-string).
            addError(pcErrField, poErrType, "Soap Fault Actor: &1", oSoapError:SoapFault:soap-fault-actor).
        end.

        /* if debug is on then add Stack Trace to the message
           You can also set this session attribute using the -errorstack startup parameter. */
        if session:error-stack-trace then
            createError(pcErrField, ErrorTypeEnum:trace:name, poProError:CallStack, poProError:CallStack).

    end method.

    /**
     * A private method used to create the Error Message Temp-Table
     *
     * @param pcErrField The Name of the field in error
     * @param pcErrType The Error Type
     * @param pcErrMsg The already translated Message
     */
    method private void createError ( input pcErrField as character, input pcErrType as character, input pcErrMsg as character, input pcOrigErrMsg as character ):

        find first ttError
             where ttError.errField eq pcErrField
               and ttError.errType eq pcErrType
               and ttError.errMsg eq pcErrMsg no-error.
        if available ttError then
            delete ttError.

        create ttError.
        assign
            miErrSeq           = miErrSeq + 1
            ttError.errSeq     = miErrSeq
            ttError.errField   = pcErrField
            ttError.errMsg     = pcErrMsg
            ttError.origErrMsg = pcOrigErrMsg
            ttError.errType    = pcErrType
            .

    end method.

    method private void createError ( input pcErrField as character, input pcErrType as character, input pcErrMsg as character, input pcMsgGroup as character, input piMsgNumber as integer ):

        createError(pcErrField, pcErrType, pcErrMsg, substitute("&1:&2", pcMsgGroup, piMsgNumber)).

    end method.

    /**
     * Log any Errors in the response Message
     */
    method public void logErrors ( ):
        define variable cMessage as character no-undo.

        /*log FATAL error to app server log*/
        for each ttError no-lock
            where ttError.errType eq ErrorTypeEnum:fatal:name:
                cMessage = ttError.origErrMsg.
                if ttError.errField gt "" then
                    cMessage = substitute("&1: &2", ttError.errField, cMessage).
                if ttError.errRow gt "" then
                    cMessage = substitute("&1 (&2)", cMessage, ttError.errRow).
            cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager):logMessage(cMessage, "FATAL", 0).
        end.

    end method.

    /**
     * A private method used to return the Error contents
     *
     * @param pcErrField The Name of the field in error
     * @param pcErrType The type of error
     * @param pcErrField The Message
     */
    method private logical getError ( output pcErrField as character, output oErrType as ErrorTypeEnum, output pcErrMsg as character ):

        if not mhErrQuery:query-off-end then
        do:
            assign
                pcErrField = ttError.errField
                oErrType   = ErrorTypeEnum:EnumFromString(ttError.errType)
                pcErrMsg   = ttError.errMsg.
            return true.
        end.
        else return false.

    end method.

    /**
     * Get a JSON string from the error temp-table
     */
    method public longchar getErrorJSON ( ):

        return getResponseErrorArray():GetJsonText().

    end method.

    /**
     * Get a JSON array from the error temp-table in standard OpenEdge format
     */
    method protected JsonArray getResponseErrorArray ():

        define variable oArray as JsonArray  no-undo.
        define variable oError as JsonObject no-undo.

        assign oArray = new JsonArray().
        for each ttError:
            assign oError = new JsonObject().
            oError:Add("_errorNum", ttError.errSeq - 1). /* By default Progress uses zero-based numbers for error counting. */
            if (ttError.errField gt "") eq true then
                oError:Add("_errorField", ttError.errField).
            oError:Add("_errorMsg", ttError.errMsg).
            oError:Add("_errorType", ttError.errType).
            if (ttError.errRow gt "") eq true then
                oError:Add("_errorRow", ttError.errRow).
            oArray:Add(oError).
        end.
        return oArray.

    end method.

    /**
     * Get a JSON array from the error temp-table in ValidationResponse format
     */
    method protected JsonArray getValidationErrorArray ():

        define variable oArray as JsonArray no-undo.

        oArray = new JsonArray().
        if can-find(first ttError) then
            oArray:Read(temp-table ttError:handle, false).

        return oArray.

    end method.

    /**
     * Get a copy of the Error temp-table
     *
     * @param phErrorSet The handle to the target temp-table
     * @param plAppend Append to the target temp-table
     */
    method public void getErrorSet ( input phErrorSet as handle, input plAppend as logical ):

        phErrorSet:copy-temp-table(temp-table ttError:handle, plAppend).

    end method.

    /**
     * Get the handle to the internal Error temp-table
     * This method should only be used by appendErrorSetFrom()
     */
    method public handle getErrorSetHandle ( ):

        return temp-table ttError:handle.

    end method.

    /**
     * Append the errors from another ValidationResponse message into this one
     *
     * @param poValRes The ValidationResponse Message to get the errors to append from
     */
    method public void appendErrorSetFrom ( input poValRes as Spark.Core.Message.Response ):

        define variable hErrQuery as handle no-undo.
        define variable hErrorTT  as handle no-undo.

        hErrorTT = poValRes:getErrorSetHandle():default-buffer-handle.

        create query hErrQuery.
        hErrQuery:set-buffers(hErrorTT).
        hErrQuery:query-prepare("for each ttError no-lock").
        hErrQuery:query-open().
        hErrQuery:get-first().

        repeat while not hErrQuery:query-off-end:
            createError(hErrorTT::errField,
                hErrorTT::errType,
                hErrorTT::errMsg,
                hErrorTT::origErrMsg).
            hErrQuery:get-next().
        end.

        finally:
            hErrQuery:query-close() no-error.
            delete object hErrQuery no-error.
        end finally.

    end method.

    /**
     * Get the first error
     *
     * @param pcErrField The field this error relates to
     * @param poErrType The error type as a ErrorTypeEnum
     * @param pcErrMsg The error message
     */
    method public logical getFirstError ( output pcErrField as character, output poErrType as ErrorTypeEnum, output pcErrMsg as character ):

        openErrorQuery().
        mhErrQuery:get-first().
        return getError(output pcErrField,output poErrType,output pcErrMsg).

    end method.

    /**
     * Get the next error
     *
     * @param pcErrField The field this error relates to
     * @param poErrType The error type as a ErrorTypeEnum
     * @param pcErrMsg The error message
     */
    method public logical getNextError ( output pcErrField as character, output poErrType as ErrorTypeEnum, output pcErrMsg as character ):

        openErrorQuery().
        mhErrQuery:get-next().
        return getError(output pcErrField,output poErrType,output pcErrMsg).

    end method.

    /**
     * Get the previous error
     *
     * @param pcErrField The field this error relates to
     * @param poErrType The error type as a ErrorTypeEnum
     * @param pcErrMsg The error message
     */
    method public logical getPrevError ( output pcErrField as character, output poErrType as ErrorTypeEnum, output pcErrMsg as character ):

        openErrorQuery().
        mhErrQuery:get-prev().
        return getError(output pcErrField,output poErrType,output pcErrMsg).

    end method.

    /**
     * Get the last error
     *
     * @param pcErrField The field this error relates to
     * @param poErrType The error type as a ErrorTypeEnum
     * @param pcErrMsg The error message
     */
    method public logical getLastError ( output pcErrField as character, output poErrType as ErrorTypeEnum, output pcErrMsg as character ):

        openErrorQuery().
        mhErrQuery:get-last().
        return getError(output pcErrField,output poErrType,output pcErrMsg).

    end method.

    /**
     * Has this response got any Warning or Information messages
     *
     * @return The response contains Warning messages
     */
    method public logical hasWarnings ( ):

        return can-find(first ttError
            where (ttError.errType eq ErrorTypeEnum:warning:name or
            ttError.errType eq ErrorTypeEnum:information:name)
            and ttError.errMsg ne "").

    end method.

    /**
     * Has this response got any Warning or Information messages for a particular field
     *
     * @return The response contains Warning messages
     */
    method public logical hasWarnings ( input pcErrField as character ):

        return can-find(first ttError
            where ttError.errField eq pcErrField
            and (ttError.errType eq ErrorTypeEnum:warning:name or
            ttError.errType eq ErrorTypeEnum:information:name)
            and ttError.errMsg ne "").

    end method.

    /**
     * Has this response got any messages at all
     *
     * @return The response contains messages
     */
    method public logical hasAnyErrors ( ):

        return can-find(first ttError).

    end method.

    /**
      * Has this response got any messages at all for a particular field
      *
      * @return The response contains messages
      */
    method public logical hasAnyErrors ( input pcErrField as character ):

        return can-find(first ttError where ttError.errField eq pcErrField).

    end method.

    /**
     * Has this response got any Error messages
     *
     * @return The response contains Error messages
     */
    method public logical hasErrors ( ):

        return can-find(first ttError
            where (ttError.errType eq ErrorTypeEnum:error:name or
            ttError.errType eq ErrorTypeEnum:fatal:name)
            and ttError.errMsg ne "").
    /* A record with a blank errMsg is a valid record and is used to indicate
       that a previous error message is no longer an error and can be cleared by the client
     */
    end method.

    /**
     * Has this response got any Error messages for a particular Field
     *
     * @return The response contains Error messages
     */
    method public logical hasErrors ( input pcErrField as character ):

        return can-find(first ttError
            where ttError.errField eq pcErrField
              and (ttError.errType eq ErrorTypeEnum:error:name or
                   ttError.errType eq ErrorTypeEnum:fatal:name)
              and ttError.errMsg ne "").
    /* A record with a blank errMsg is a valid record and is used to indicate
       that a previous error message is no longer an error and can be cleared by the client
     */
    end method.

    /**
     * Has this response got any Information messages
     *
     * @return The response contains Information messages
     */
    method public logical hasInformation ( ):

        return can-find(first ttError
            where ttError.errType eq ErrorTypeEnum:information:name).

    end method.

    /**
     * Has this response got any Information messages for a particular Field
     *
     * @return The response contains Information messages
     */
    method public logical hasInformation ( input pcErrField as character ):

        return can-find(first ttError
            where ttError.errField eq pcErrField
              and ttError.errType eq ErrorTypeEnum:information:name).

    end method.

    /**
     * Remove all Warning and Information (Non STOP) type messages
     */
    method public void removeWarningMessages ( ):

        for each ttError:
            if ttError.errType eq ErrorTypeEnum:warning:name or
                ttError.errType eq ErrorTypeEnum:information:name then
                delete ttError.
        end.

    end method.

    /**
     * Remove Error messages by type
     */
    method public void removeErrorMessages ( input poErrType as ErrorTypeEnum ):

        for each ttError where ttError.errType eq poErrType:name:
            delete ttError.
        end.

    end method.

    /**
     *  Remove Error messages by type for a particular field
     */
    method public void removeErrorMessages ( input pcErrField as character, input poErrType as ErrorTypeEnum ):

        for each ttError where ttError.errField eq pcErrField and ttError.errType eq poErrType:name:
            delete ttError.
        end.

    end method.

     /**
     *  Remove all Error messages for a particular field
     */
    method public void removeErrorMessages ( input pcErrField as character ):

        for each ttError where ttError.errField eq pcErrField:
            delete ttError.
        end.

    end method.

    /**
     * Reset the ErrorType on all errors in this message object
     *
     * @param poErrType The error type as a ErrorTypeEnum
     */
    method public void resetAllErrors ( input poErrType as ErrorTypeEnum ):

        for each ttError:
            ttError.errType = poErrType:name.
        end.

    end method.

    /**
     * Reset the ErrorType on all errors in this message object
     *
     * @param pcErrField The field the errors relates to
     */
    method public void resetAllErrors ( input pcErrField as character ):

        for each ttError:
            ttError.errField = pcErrField.
        end.

    end method.

    method private character translateMessage ( input pcMessage as character ):

        return cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager):getTranslatedMessage(pcMessage).

    end method.

    method private character translateMessage ( input pcMsgGroup as character, input piMsgNumber as integer ):

        return cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager):getTranslatedMessage(pcMsgGroup, piMsgNumber).

    end method.

    method private void openErrorQuery ( ):

        if valid-handle(mhErrQuery) then return.

        create query mhErrQuery.
        mhErrQuery:set-buffers (buffer ttError:handle).
        mhErrQuery:query-prepare ("for each ttError no-lock").
        mhErrQuery:query-open().

    end method.

    method protected void storeErrors ( ):

        if can-find(first ttError) then
        do:
            returnValue = false.
            if hasParam("response") then do:
                /* If a response property exists, add errors to that object. */
                define variable oResponse as JsonObject no-undo.
                assign oResponse = getParamAsJsonObject("response").
                oResponse:Add(mcErrorPropName, getResponseErrorArray()).
                if returnValue ne ? then
                    oResponse:Add(mcReturnValName, returnValue).
                setParam("response", oResponse).
            end.
            else do:
                /* Otherwise, simply append errors to the main object. */
                setParam(mcErrorPropName, getResponseErrorArray()).
                if returnValue ne ? then
                    setParam(mcReturnValName, returnValue).
            end.
        end.
        else if returnValue ne ? then
            setParam(mcReturnValName, returnValue).

    end method.

    method override protected void storeProperties ( ):

        storeErrors().

    end method.

    destructor public Response ( ):

        if valid-handle(mhErrQuery) then
        do:
            mhErrQuery:query-close() no-error.
            delete object mhErrQuery no-error.
        end.

    end destructor.

end class.