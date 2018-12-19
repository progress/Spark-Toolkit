using Progress.Json.ObjectModel.JsonArray from propath.
using Progress.Json.ObjectModel.JsonDataType from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Progress.Json.ObjectModel.ObjectModelParser from propath.
using Progress.Lang.AppError from propath.
using Spark.Core.Message.IAbstractMessage from propath.
using Spark.Core.Util.ApplicationError from propath.
using Spark.Core.Util.FormatTools from propath.

block-level on error undo, throw.

/**
 * An abstract message class used to pass request and response messages in and out of a service request
 */
class Spark.Core.Message.AbstractMessage implements IAbstractMessage abstract:

    define private variable moMsgParams as JsonObject no-undo.

    define public property messageKeyPin as character initial ? no-undo get. set.

    constructor public AbstractMessage ( ):

        super().
        moMsgParams = new JsonObject().

    end constructor.

    /**
     * Used when recreating the Service Message from the serialized JSON string
     * @param pcMessage The serialized JSON string of this Service Message
     */
    constructor public AbstractMessage ( input pcMessage as longchar ):

        super().
        deserializeMessage(pcMessage).

    end constructor.

    /**
     * Should explicitly delete the message params when finished.
     */
    destructor public AbstractMessage ( ):

        delete object moMsgParams no-error.

    end destructor.

    method protected void deserializeMessage ( input pcMessage as longchar ):

        define variable oParser as ObjectModelParser no-undo.

        if pcMessage ne "" and pcMessage ne ? then
        do:
            /* SmartGWT JSON is passing "null" instead of null for empty dates. */
            pcMessage = replace(pcMessage, ':"null"', ':null').

            pcMessage = FormatTools:convertToUTF8(pcMessage).

            oParser = new ObjectModelParser().
            moMsgParams = cast(oParser:Parse(pcMessage), JsonObject).

            messageKeyPin = getParamAsChar("_messageKeyPin", true).
        end.

    end method.

    method protected void deserializeMessageFromFile ( input pcFile as character ):

        define variable cFile as longchar no-undo.

        file-info:file-name = pcFile.
        if file-info:full-pathname eq ? then
            undo, throw new AppError(substitute("Unknown file name [&1] to deserialize message from", pcFile), 0).

        copy-lob from file file-info:full-pathname to cFile.

        deserializeMessage(cFile).

    end method.

    method public final void promoteObject( input pcParam as character ):

        define variable oNewMsg as JsonObject no-undo.
        if moMsgParams:Has(pcParam) then
        do:
            /* Make the given property the new top-level object. */
            oNewMsg = moMsgParams:GetJsonObject(pcParam).
            moMsgParams = oNewMsg.
        end.

    end method.

    method public final void demoteObject( input pcParam as character ):

        define variable oNewMsg as JsonObject no-undo.

        /* Make the given property the new top-level object. */
        oNewMsg = new JsonObject().
        oNewMsg:Add(pcParam, moMsgParams).
        moMsgParams = oNewMsg.

    end method.

    method public final void setNullParam( input pcParam as character ):

        if hasParam(pcParam) then
            moMsgParams:SetNull(pcParam).
        else
            moMsgParams:AddNull(pcParam).

    end method.

    method public final void setParam( input pcParam as character, input pcValue as character ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, pcValue).
        else
            moMsgParams:Add(pcParam, pcValue).

    end method.

    method public final void setParam( input pcParam as character, input pcValue as character extent ):

        setParam(pcParam,new JsonArray(pcValue)).

    end method.

    method public final void setParam( input pcParam as character, input pcValue as longchar ):

        pcValue = FormatTools:convertToUTF8(pcValue).

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, pcValue).
        else
            moMsgParams:Add(pcParam, pcValue).

    end method.

    method public final void setParam( input pcParam as character, input pcValue as longchar extent ):

        define variable iExtent as integer no-undo.
        define variable iLoop   as integer no-undo.

        iExtent = extent(pcValue).
        do iLoop = 1 to iExtent:
            pcValue[iLoop] = FormatTools:convertToUTF8(pcValue[iLoop]).
        end.
        setParam(pcParam, new JsonArray(pcValue)).

    end method.


    method public final void setParam( input pcParam as character, input piValue as integer ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, piValue).
        else
            moMsgParams:Add(pcParam, piValue).

    end method.

    method public final void setParam( input pcParam as character, input piValue as integer extent ):

        setParam(pcParam, new JsonArray(piValue)).

    end method.

    method public final void setParam( input pcParam as character, input piValue as int64 ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, piValue).
        else
            moMsgParams:Add(pcParam, piValue).

    end method.

    method public final void setParam( input pcParam as character, input piValue as int64 extent ):

        setParam(pcParam,new JsonArray(piValue)).

    end method.

    method public final void setParam( input pcParam as character, input plValue as logical ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, plValue).
        else
            moMsgParams:Add(pcParam, plValue).

    end method.

    method public final void setParam( input pcParam as character, input plValue as logical extent ):

        setParam(pcParam,new JsonArray(plValue)).

    end method.

    method public final void setParam( input pcParam as character, input pdValue as decimal ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, pdValue).
        else
            moMsgParams:Add(pcParam, pdValue).

    end method.

    method public final void setParam( input pcParam as character, input pdValue as decimal extent ):

        setParam(pcParam,new JsonArray(pdValue)).

    end method.

    method public final void setParam( input pcParam as character, input ptValue as date ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, ptValue).
        else
            moMsgParams:Add(pcParam, ptValue).

    end method.

    method public final void setParam( input pcParam as character, input ptValue as date extent ):

        setParam(pcParam,new JsonArray(ptValue)).

    end method.

    method public final void setParam( input pcParam as character, input ptValue as datetime ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, ptValue).
        else
            moMsgParams:Add(pcParam, ptValue).

    end method.

    method public final void setParam( input pcParam as character, input ptValue as datetime extent ):

        setParam(pcParam, new JsonArray(ptValue)).

    end method.

    method public final void setParam( input pcParam as character, input ptValue as datetime-tz ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, ptValue).
        else
            moMsgParams:Add(pcParam, ptValue).

    end method.

    method public final void setParam( input pcParam as character, input ptValue as datetime-tz extent ):

        setParam(pcParam, new JsonArray(ptValue)).

    end method.

    method public final void setParam( input pcParam as character, input prValue as rowid ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, prValue).
        else
            moMsgParams:Add(pcParam, prValue).

    end method.

    method public final void setParam( input pcParam as character, input prValue as rowid extent ):

        setParam(pcParam, new JsonArray(prValue)).

    end method.

    method public final void setParam( input pcParam as character, input prValue as recid ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, prValue).
        else
            moMsgParams:Add(pcParam, prValue).

    end method.

    method public final void setParam( input pcParam as character, input prValue as recid extent ):

        setParam(pcParam, new JsonArray(prValue)).

    end method.

    method public final void setParam( input pcParam as character, input pmValue as memptr ):

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, pmValue).
        else
            moMsgParams:Add(pcParam, pmValue).

    end method.

    method public final void setParam( input pcParam as character, input pmValue as memptr extent ):

        setParam(pcParam, new JsonArray(pmValue)).

    end method.

    method public final void setParam( input pcParam as character, input poValue as JsonObject ):

        if not valid-object(poValue) then
            poValue = new JsonObject().

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, cast(poValue:Clone(), JsonObject)).
        else
            moMsgParams:Add(pcParam, cast(poValue:Clone(), JsonObject)).

    end method.

    method public final void setParam( input pcParam as character, input poValue as JsonArray ):

        if not valid-object(poValue) then
            poValue = new JsonArray().

        if hasParam(pcParam) then
            moMsgParams:Set(pcParam, cast(poValue:Clone(), JsonArray)).
        else
            moMsgParams:Add(pcParam, cast(poValue:Clone(), JsonArray)).

    end method.

    method public final void setParam( input pcParam as character, input phValue as handle ):
        setParam( input pcParam, input phValue, input false ).
    end method.

    method public final void setParam( input pcParam as character, input phValue as handle, input plUseBeforeImage as logical ):

        define variable oParser as ObjectModelParser no-undo.
        define variable cJson   as longchar          no-undo.

        assign oParser = new ObjectModelParser().

        if phValue:type eq "DATASET" then
        do:
            phValue:write-json("LONGCHAR", cJson, false, ?, false, true, plUseBeforeImage).
            setParam(pcParam, cast(oParser:Parse(cJson), JsonObject)).
        end.
        else if phValue:type eq "TEMP-TABLE" then
        do:
            phValue:write-json("LONGCHAR", cJson, false, ?, false, true).
            setParam(pcParam, cast(oParser:Parse(cJson), JsonArray)).
        end.
        else
            undo, throw new ApplicationError("[&1] must be a DATASET or TEMP-TABLE", pcParam).

        finally:
            delete object oParser no-error.
        end finally.

    end method.

    /**
     * Returns an extent of parameters on the request object.
     */
    method public character extent getParams( ):

        define variable cParams as character extent no-undo.

        assign
            cParams = moMsgParams:GetNames().
        return cParams.

    end method.

    /**
     * Returns a count of parameters on the request object.
     */
    method public integer getParamCount( ):

        define variable cParams as character extent no-undo.

        assign
            cParams = moMsgParams:GetNames().
        return extent(cParams).

    end method.

    /**
     * Returns a logical indicating if this message object contains the named parameter.
     * @param pcParam The name of the param
     */
    method public final logical hasParam(input pcParam as character) :

        return moMsgParams:Has(pcParam).

    end.

    /** Remove a parameter from the message object
     *  @param pcParam The name of the param to be removed
     */
    method public final void removeParam(input pcParam as character ):

        if hasParam(pcParam) then
            moMsgParams:Remove(pcParam).

        return.

    end method.

    /** Return the actual message object
     *  @return The Message object
     */
    method public JsonObject getParamObject ( ):

        return moMsgParams.

    end method.

    /**
     * Gets JSON data type for the named property.
     * The returned integer corresponds to the static integer properties defined in the Progress.Json.ObjectModel.JsonDataType class.
     * @param pcParam The name of the Parameter to get
     * @return The Parameter type
     */
    method public integer getParamType( input pcParam as character ):

        return moMsgParams:GetType(pcParam).

    end method.

    /**
     * Get the Parameter value as plain JSON text
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as JSON text
     */
    method public longchar getParamAsJsonText( input pcParam as character ):

        return getParamAsJsonText(pcParam, false).

    end method.

    /**
    * Get the Parameter value as plain JSON text
    * @param pcParam The name of the Parameter to get
    * @param plOptionalParam if true then don't throw an error if the parameter does not exits
    * @return The Parameter value as JSON text or undefined in not found
    */
    method public longchar getParamAsJsonText(input pcParam as character, input plOptionalParam as logical ):

        define variable cReturn as longchar init ? no-undo.

        if hasParam(pcParam) then
        do:
            cReturn = moMsgParams:GetJsonText(pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cReturn.

    end method.

    /**
     * Get the Parameter value as a character string
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a character string
     */
    method public character getParamAsChar(input pcParam as character  ):

        return getParamAsChar(pcParam, false).

    end method.

    /**
    * Get the Parameter value as a character string
    * @param pcParam The name of the Parameter to get
    * @param plOptionalParam if true then don't throw an error if the parameter does not exits
    * @return The Parameter value as a character string or undefined in not found
    */
    method public character getParamAsChar(input pcParam as character, input plOptionalParam as logical ):

        define variable cReturn as character init ? no-undo.

        if hasParam(pcParam) then
        do:
            cReturn = moMsgParams:GetCharacter(pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set", pcParam).

        return cReturn.

    end method.

    /**
     * Get the Parameter value as a character extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a character extent
     */
    method public character extent getParamAsCharEx( input pcParam as character ):

        return getParamAsCharEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a character extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exist
     * @return The Parameter value as a character extent
     */
    method public character extent getParamAsCharEx( input pcParam as character, input plOptionalParam as logical ):

        define variable cResult as character extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            cResult = oTempA:GetCharacter(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cResult.

    end method.

    /**
     * Get the Parameter value as a longchar string
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a longchar string
     */
    method public longchar getParamAsLongChar(input pcParam as character  ):

        return getParamAsLongChar(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a longchar string
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a longchar string or undefined in not found
     */
    method public longchar getParamAsLongChar(input pcParam as character, input plOptionalParam as logical ):

        define variable cReturn as longchar init ? no-undo.

        if hasParam(pcParam) then
        do:
            cReturn = moMsgParams:GetLongchar(pcParam,"UTF-8").
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cReturn.

    end method.

    /**
     * Get the Parameter value as a longchar extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a longchar extent
     */
    method public longchar extent getParamAsLongCharEx( input pcParam as character ):

        return getParamAsLongCharEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a longchar extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a longchar extent
     */
    method public longchar extent getParamAsLongCharEx( input pcParam as character, input plOptionalParam as logical ):

        define variable cResult as longchar  extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            cResult = oTempA:GetLongchar(1,iExtent,"UTF-8").
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cResult.

    end method.

    /**
     * Get the Parameter value as a integer
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an integer
     */
    method public integer getParamAsInt(input pcParam as character  ):

        return getParamAsInt(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a integer
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an integer or undefined in not found
     */
    method public integer getParamAsInt(input pcParam as character, input plOptionalParam as logical ):

        define variable cReturn as integer init ? no-undo.

        if hasParam(pcParam) then
        do:
            cReturn = moMsgParams:GetInteger(pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cReturn.

    end method.

    /**
     * Get the Parameter value as a integer extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a integer extent
     */
    method public integer extent getParamAsIntEx( input pcParam as character ):

        return getParamAsIntEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a integer extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a integer extent
     */
    method public integer extent getParamAsIntEx( input pcParam as character, input plOptionalParam as logical ):

        define variable cResult as integer   extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            cResult = oTempA:GetInteger(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cResult.

    end method.

    /**
     * Get the Parameter value as a int64
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an int64
     */
    method public int64 getParamAsInt64(input pcParam as character  ):

        return getParamAsInt64(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a int64
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an int64 or undefined in not found
     */
    method public int64 getParamAsInt64(input pcParam as character, input plOptionalParam as logical ):

        define variable cReturn as int64 init ? no-undo.

        if hasParam(pcParam) then
        do:
            cReturn = moMsgParams:GetInt64(pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cReturn.

    end method.

    /**
     * Get the Parameter value as a int64 extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a int64 extent
     */
    method public int64 extent getParamAsInt64Ex( input pcParam as character ):

        return getParamAsInt64Ex(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a int64 extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a int64 extent
     */
    method public int64 extent getParamAsInt64Ex( input pcParam as character, input plOptionalParam as logical ):

        define variable cResult as int64     extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            cResult = oTempA:GetInt64(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cResult.

    end method.

    /**
     * Get the Parameter value as a decimal
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an decimal
     */
    method public decimal getParamAsDec(input pcParam as character  ):

        return getParamAsDec(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a decimal
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an decimal or undefined in not found
     */
    method public decimal getParamAsDec(input pcParam as character, input plOptionalParam as logical ):

        define variable cReturn as decimal init ? no-undo.

        if hasParam(pcParam) then
        do:
            cReturn = moMsgParams:GetDecimal(pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cReturn.

    end method.

    /**
     * Get the Parameter value as a decimal extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a decimal extent
     */
    method public decimal extent getParamAsDecEx( input pcParam as character ):

        return getParamAsDecEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a decimal extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a decimal extent
     */
    method public decimal extent getParamAsDecEx( input pcParam as character, input plOptionalParam as logical ):

        define variable cResult as decimal   extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            cResult = oTempA:GetDecimal(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cResult.

    end method.

    /**
     * Get the Parameter value as a date
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an date
     */
    method public date getParamAsDate(input pcParam as character  ):

        return getParamAsDate(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a date
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an date or undefined in not found
     */
    method public date getParamAsDate(input pcParam as character, input plOptionalParam as logical ):

        define variable cReturn as date init ? no-undo.

        if hasParam(pcParam) then
        do:
            cReturn = moMsgParams:GetDate(pcParam).

        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cReturn.

    end method.

    /**
     * Get the Parameter value as a date extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a date extent
     */
    method public date extent getParamAsDateEx( input pcParam as character ):

        return getParamAsDateEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a date extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a date extent
     */
    method public date extent getParamAsDateEx( input pcParam as character, input plOptionalParam as logical ):

        define variable cResult as date      extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            cResult = oTempA:GetDate(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cResult.

    end method.

    /**
     * Get the Parameter value as a datetime
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an datetime
     */
    method public datetime getParamAsDatetime(input pcParam as character  ):

        return getParamAsDatetime(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a datetime
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an datetime or undefined in not found
     */
    method public datetime getParamAsDatetime(input pcParam as character, input plOptionalParam as logical ):

        define variable cReturn as datetime init ? no-undo.

        if hasParam(pcParam) then
        do:
            cReturn = moMsgParams:GetDatetime(pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cReturn.

    end method.

    /**
     * Get the Parameter value as a datetime extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a datetime extent
     */
    method public datetime extent getParamAsDatetimeEx( input pcParam as character ):

        return getParamAsDatetimeEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a datetime extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a datetime extent
     */
    method public datetime extent getParamAsDatetimeEx( input pcParam as character, input plOptionalParam as logical ):

        define variable cResult as datetime  extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            cResult = oTempA:GetDatetime(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cResult.

    end method.

    /**
     * Get the Parameter value as a datetime-tz
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an datetime-tz
     */
    method public datetime-tz getParamAsDatetimeTZ(input pcParam as character  ):

        return getParamAsDatetimeTZ(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a datetime-tz
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an datetime-tz or undefined in not found
     */
    method public datetime-tz getParamAsDatetimeTZ(input pcParam as character, input plOptionalParam as logical ):

        define variable cReturn as datetime-tz init ? no-undo.

        if hasParam(pcParam) then
        do:
            cReturn = moMsgParams:GetDatetimeTZ(pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cReturn.

    end method.

    /**
     * Get the Parameter value as a datetime-tz extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a datetime-tz extent
     */
    method public datetime-tz extent getParamAsDatetimeTZEx( input pcParam as character ):

        return getParamAsDatetimeTZEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a datetime-tz extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a datetime-tz extent
     */
    method public datetime-tz extent getParamAsDatetimeTZEx( input pcParam as character, input plOptionalParam as logical ):

        define variable cResult as datetime-tz extent no-undo.
        define variable oTempA  as JsonArray   no-undo.
        define variable iExtent as integer     no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            cResult = oTempA:GetDatetimeTZ(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return cResult.

    end method.

    /**
     * Get the Parameter value as a logical
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an logical
     */
    method public logical getParamAsLog( input pcParam as character ):

        return getParamAsLog(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a logical
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an logical or undefined in not found
     */
    method public logical getParamAsLog( input pcParam as character, input plOptionalParam as logical ):

        define variable lReturn as logical   init ? no-undo.
        define variable cTemp   as character no-undo.

        if hasParam(pcParam) then
        do:
            if moMsgParams:GetType(pcParam) eq JsonDataType:STRING then
            do:
                cTemp = moMsgParams:GetCharacter(pcParam).
                if cTemp eq ? then
                    lReturn = ?.
                else if can-do("True,Yes,Y",string(cTemp)) then
                    lReturn = true.
                else if can-do("False,No,N",string(cTemp)) then
                    lReturn = false.
                else
                    lReturn = ?.
            end.
            else
                lReturn = moMsgParams:GetLogical(pcParam).

        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return lReturn.

    end method.

    /**
     * Get the Parameter value as a logical extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a logical extent
     */
    method public logical extent getParamAsLogEx( input pcParam as character ):

        return getParamAsLogEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a logical extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a logical extent
     */
    method public logical extent getParamAsLogEx( input pcParam as character, input plOptionalParam as logical ):

        define variable lReturn as logical   extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.
        define variable iLoop   as integer   no-undo.
        define variable cTemp   as character extent no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            if iExtent ge 1 and oTempA:GetType(1) eq JsonDataType:STRING then
            do:
                cTemp = oTempA:GetCharacter(1,iExtent).
                extent(lReturn) = iExtent.
                do iLoop = 1 to iExtent:
                    if cTemp[iLoop] eq ? then
                        lReturn[iLoop] = ?.
                    else if can-do("True,Yes,Y",cTemp[iLoop]) then
                            lReturn[iLoop] = true.
                    else if can-do("False,No,N",cTemp[iLoop]) then
                        lReturn[iLoop] = false.
                    else
                        lReturn[iLoop] = ?.
                end.
            end.
            else
                lReturn = oTempA:GetLogical(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return lReturn.

    end method.

    /**
     * Get the Parameter value as a rowid
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an rowid
     */
    method public rowid getParamAsRowid(input pcParam as character  ):

        return getParamAsRowid(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a rowid
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an rowid or undefined in not found
     */
    method public rowid getParamAsRowid(input pcParam as character, input plOptionalParam as logical ):

        define variable rReturn as rowid no-undo.

        if hasParam(pcParam) then
        do:
            rReturn = moMsgParams:GetRowid(pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return rReturn.

    end method.

    /**
     * Get the Parameter value as a rowid extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a rowid extent
     */
    method public rowid extent getParamAsRowidEx( input pcParam as character ):

        return getParamAsRowidEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a rowid extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a rowid extent
     */
    method public rowid extent getParamAsRowidEx( input pcParam as character, input plOptionalParam as logical ):

        define variable rResult as rowid     extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            rResult = oTempA:GetRowid(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return rResult.

    end method.

    /**
     * Get the Parameter value as a recid
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an recid
     */
    method public recid getParamAsRecid(input pcParam as character  ):

        return getParamAsRecid(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a recid
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an recid or undefined in not found
     */
    method public recid getParamAsRecid(input pcParam as character, input plOptionalParam as logical ):

        define variable rReturn as recid no-undo.

        if hasParam(pcParam) then
        do:
            rReturn = moMsgParams:GetRecid(pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return rReturn.

    end method.

    /**
     * Get the Parameter value as a recid extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a recid extent
     */
    method public recid extent getParamAsRecidEx( input pcParam as character ):

        return getParamAsRecidEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a recid extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a recid extent
     */
    method public recid extent getParamAsRecidEx( input pcParam as character, input plOptionalParam as logical ):

        define variable rResult as recid     extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            rResult = oTempA:GetRecid(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return rResult.

    end method.

    /**
     * Get the Parameter value as a memptr
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an memptr
     */
    method public memptr getParamAsMemptr(input pcParam as character  ):

        return getParamAsMemptr(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a memptr
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an memptr or undefined in not found
     */
    method public memptr getParamAsMemptr(input pcParam as character, input plOptionalParam as logical ):

        define variable mReturn as memptr no-undo.

        if hasParam(pcParam) then
        do:
            mReturn = moMsgParams:GetMemptr(pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam ).

        return mReturn.

    end method.

    /**
     * Get the Parameter value as a memptr extent
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as a memptr extent
     */
    method public memptr extent getParamAsMemptrEx( input pcParam as character ):

        return getParamAsMemptrEx(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a memptr extent
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam If true then don't throw an error if the parameter does not exits
     * @return The Parameter value as a memptr extent
     */
    method public memptr extent getParamAsMemptrEx( input pcParam as character, input plOptionalParam as logical ):

        define variable mResult as memptr    extent no-undo.
        define variable oTempA  as JsonArray no-undo.
        define variable iExtent as integer   no-undo.

        if hasParam(pcParam) then
        do:
            oTempA = moMsgParams:GetJsonArray(pcParam).
            iExtent = oTempA:Length.
            mResult = oTempA:GetMemptr(1,iExtent).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam).

        return mResult.

    end method.

    /**
     * Get the Parameter value as a JsonObject
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an JsonObject
     */
    method public JsonObject getParamAsJsonObject( input pcParam as character ):

        return getParamAsJsonObject(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a JsonObject
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an JsonObject or undefined in not found
     */
    method public JsonObject getParamAsJsonObject( input pcParam as character, input plOptionalParam as logical ):

        define variable oReturn as JsonObject no-undo.

        if hasParam(pcParam) then
        do:
            if moMsgParams:GetType(pcParam) eq JsonDataType:object then
                oReturn = moMsgParams:GetJsonObject(pcParam).
            else
                undo, throw new ApplicationError("Message Parameter [&1] is not an object",pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam).

        return oReturn.

    end method.

    /**
     * Get the Parameter value as a JsonArray
     * @param pcParam The name of the Parameter to get
     * @return The Parameter value as an JsonArray
     */
    method public JsonArray getParamAsJsonArray( input pcParam as character ):

        return getParamAsJsonArray(pcParam, false).

    end method.

    /**
     * Get the Parameter value as a JsonArray
     * @param pcParam The name of the Parameter to get
     * @param plOptionalParam if true then don't throw an error if the parameter does not exits
     * @return The Parameter value as an JsonArray or undefined in not found
     */
    method public JsonArray getParamAsJsonArray( input pcParam as character, input plOptionalParam as logical ):

        define variable oReturn as JsonArray no-undo.

        if hasParam(pcParam) then
        do:
            if moMsgParams:GetType(pcParam) eq JsonDataType:ARRAY then
                oReturn = moMsgParams:GetJsonArray(pcParam).
            else
                undo, throw new ApplicationError("Message Parameter [&1] is not an array",pcParam).
        end.
        else if not plOptionalParam then
            undo, throw new ApplicationError("Message Parameter [&1] is not set",pcParam).

        return oReturn.

    end method.

    /** Get the Parameter value as a dataset/temp-table
       * @param pcParam The name of the Parameter to get
       * @param pcMode The mode of the dataset/temp-table (ie. Whether to empty first)
       * @param phDataSet The handle of the dataset/temp-table to populate
       * @return The Parameter value as a dataset/temp-table
       */
    method public void getParamAsHandle( input pcParam as character, input pcMode as character, input phData as handle ):

        if phData:type eq 'DATASET' then do:
            define variable oJsonObj as JsonObject no-undo.

            if pcMode eq 'EMPTY' then
                phData:empty-dataset().

            oJsonObj = getParamAsJsonObject(pcParam).
            if valid-object(oJsonObj) then
                phData:read-json('JsonObject', oJsonObj, pcMode).
        end.
        else if phData:type eq 'TEMP-TABLE' then do:
            define variable oJsonArr as JsonArray no-undo.

            if pcMode eq 'EMPTY' then
                phData:default-buffer-handle:empty-temp-table().

            oJsonArr = getParamAsJsonArray(pcParam).
            if valid-object(oJsonArr) then
                phData:read-json('JsonArray', oJsonArr, pcMode).
        end.

    end method.

    /**
     * Serialize the message for passing through the service interface
     * @return A longchar JSON string
     */
    method public longchar serializeMessage ( ):

        define variable lcResult as longchar no-undo.

        /*Call StoreProperties in all inherited classes*/
        storeProperties().

        if messageKeyPin ne ? then
            setParam("_messageKeyPin",messageKeyPin).

        fix-codepage(lcResult) = "UTF-8".
        moMsgParams:Write(input-output lcResult, false).

        return lcResult.

    end method.

    /** An abstract method to be implemeted by the concrete Message classes
      *
      * This method must save any local Properties or DataSets using setParam() methods
      * so that they can be serialized and de-serialized.
      * This method is called from the serializeMessage method.
      * Whist all static members could store and retrieve their values directly via setParam/GetParam methods
      * a dataset's or temp-table's handle can be set at any point durning the service request.  At the end of the service
      * request, the dataset needs to be serialized and stored in the message object and not before as the data would be changing.
      */
    method protected abstract void storeProperties(  ).

end class.