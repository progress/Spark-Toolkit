/*------------------------------------------------------------------------
    File        : IAbstractMessage
    Purpose     : A Service Message Interface
    Description : Service Message (Interface)
    Author(s)   : rosmith
    Created     : Nov 02 2012
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.JsonArray from propath.
using Progress.Json.ObjectModel.JsonObject from propath.

interface Spark.Core.Message.IAbstractMessage:

    define public property messageKeyPin as character no-undo get. set.

    method public void promoteObject ( input pcParam as character ).
    method public void demoteObject ( input pcParam as character ).

    method public void setNullParam( input pcParam as character ).

    method public void setParam( input pcParam as character, input pcValue as character ).
    method public void setParam( input pcParam as character, input pcValue as character extent ).
    method public void setParam( input pcParam as character, input pcValue as longchar ).
    method public void setParam( input pcParam as character, input pcValue as longchar extent ).
    method public void setParam( input pcParam as character, input piValue as integer ).
    method public void setParam( input pcParam as character, input piValue as integer extent ).
    method public void setParam( input pcParam as character, input piValue as int64 ).
    method public void setParam( input pcParam as character, input piValue as int64 extent ).
    method public void setParam( input pcParam as character, input plValue as logical ).
    method public void setParam( input pcParam as character, input plValue as logical extent ).
    method public void setParam( input pcParam as character, input pdValue as decimal ).
    method public void setParam( input pcParam as character, input pdValue as decimal extent ).
    method public void setParam( input pcParam as character, input ptValue as date ).
    method public void setParam( input pcParam as character, input ptValue as date extent ).
    method public void setParam( input pcParam as character, input ptValue as datetime ).
    method public void setParam( input pcParam as character, input ptValue as datetime extent ).
    method public void setParam( input pcParam as character, input ptValue as datetime-tz ).
    method public void setParam( input pcParam as character, input ptValue as datetime-tz extent ).
    method public void setParam( input pcParam as character, input prValue as rowid ).
    method public void setParam( input pcParam as character, input prValue as rowid extent ).
    method public void setParam( input pcParam as character, input prValue as recid ).
    method public void setParam( input pcParam as character, input prValue as recid extent ).
    method public void setParam( input pcParam as character, input pmValue as memptr ).
    method public void setParam( input pcParam as character, input pmValue as memptr extent ).
    method public void setParam( input pcParam as character, input poValue as JsonObject ).
    method public void setParam( input pcParam as character, input poValue as JsonArray ).
    method public void setParam( input pcParam as character, input phValue as handle ).
    method public void setParam( input pcParam as character, input phValue as handle, input plBefore as logical ).

    method public character extent getParams( ).

    method public integer getParamCount( ).

    method public logical hasParam(input pcParam as character).

    method public void removeParam(input pcParam as character ).

    method public JsonObject getParamObject().
    method public integer getParamType(input pcParam as character ).
    method public longchar getParamAsJsonText(input pcParam as character ).
    method public longchar getParamAsJsonText(input pcParam as character, input plOptionalParam as logical ).
    method public character getParamAsChar(input pcParam as character ).
    method public character getParamAsChar(input pcParam as character, input plOptionalParam as logical ).
    method public character extent getParamAsCharEx( input pcParam as character ).
    method public character extent getParamAsCharEx( input pcParam as character, input plOptionalParam as logical ).
    method public longchar getParamAsLongChar(input pcParam as character ).
    method public longchar getParamAsLongChar(input pcParam as character, input plOptionalParam as logical ).
    method public longchar extent getParamAsLongCharEx( input pcParam as character ).
    method public longchar extent getParamAsLongCharEx( input pcParam as character, input plOptionalParam as logical ).
    method public integer getParamAsInt(input pcParam as character ).
    method public integer getParamAsInt(input pcParam as character, input plOptionalParam as logical ).
    method public integer extent getParamAsIntEx( input pcParam as character ).
    method public integer extent getParamAsIntEx( input pcParam as character, input plOptionalParam as logical ).
    method public int64 getParamAsInt64(input pcParam as character ).
    method public int64 getParamAsInt64(input pcParam as character, input plOptionalParam as logical ).
    method public int64 extent getParamAsInt64Ex( input pcParam as character ).
    method public int64 extent getParamAsInt64Ex( input pcParam as character, input plOptionalParam as logical ).
    method public decimal getParamAsDec(input pcParam as character ).
    method public decimal getParamAsDec(input pcParam as character, input plOptionalParam as logical ).
    method public decimal extent getParamAsDecEx( input pcParam as character ).
    method public decimal extent getParamAsDecEx( input pcParam as character, input plOptionalParam as logical ).
    method public date getParamAsDate(input pcParam as character ).
    method public date getParamAsDate(input pcParam as character, input plOptionalParam as logical ).
    method public date extent getParamAsDateEx( input pcParam as character ).
    method public date extent getParamAsDateEx( input pcParam as character, input plOptionalParam as logical ).
    method public datetime getParamAsDatetime(input pcParam as character ).
    method public datetime getParamAsDatetime(input pcParam as character, input plOptionalParam as logical ).
    method public datetime extent getParamAsDatetimeEx( input pcParam as character ).
    method public datetime extent getParamAsDatetimeEx( input pcParam as character, input plOptionalParam as logical ).
    method public datetime-tz getParamAsDatetimeTZ(input pcParam as character ).
    method public datetime-tz getParamAsDatetimeTZ(input pcParam as character, input plOptionalParam as logical ).
    method public datetime-tz extent getParamAsDatetimeTZEx( input pcParam as character ).
    method public datetime-tz extent getParamAsDatetimeTZEx( input pcParam as character, input plOptionalParam as logical ).
    method public logical getParamAsLog(input pcParam as character ).
    method public logical getParamAsLog(input pcParam as character, input plOptionalParam as logical ).
    method public logical extent getParamAsLogEx( input pcParam as character ).
    method public logical extent getParamAsLogEx( input pcParam as character, input plOptionalParam as logical ).
    method public rowid getParamAsRowid(input pcParam as character ).
    method public rowid getParamAsRowid(input pcParam as character, input plOptionalParam as logical ).
    method public rowid extent getParamAsRowidEx( input pcParam as character ).
    method public rowid extent getParamAsRowidEx( input pcParam as character, input plOptionalParam as logical ).
    method public recid getParamAsRecid(input pcParam as character ).
    method public recid getParamAsRecid(input pcParam as character, input plOptionalParam as logical ).
    method public recid extent getParamAsRecidEx( input pcParam as character ).
    method public recid extent getParamAsRecidEx( input pcParam as character, input plOptionalParam as logical ).
    method public memptr getParamAsMemptr(input pcParam as character ).
    method public memptr getParamAsMemptr(input pcParam as character, input plOptionalParam as logical ).
    method public memptr extent getParamAsMemptrEx( input pcParam as character ).
    method public memptr extent getParamAsMemptrEx( input pcParam as character, input plOptionalParam as logical ).
    method public JsonObject getParamAsJsonObject(input pcParam as character ).
    method public JsonObject getParamAsJsonObject(input pcParam as character, input plOptionalParam as logical ).
    method public JsonArray getParamAsJsonArray(input pcParam as character ).
    method public JsonArray getParamAsJsonArray(input pcParam as character, input plOptionalParam as logical ).
    method public void getParamAsHandle(input pcParam as character, input pcMode as character, input phData as handle ).

    method public longchar serializeMessage( ).

end interface.