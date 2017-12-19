using Spark.Core.Manager.IMessageManager from propath.
using Spark.Core.Manager.ITranslationManager from propath.
using Spark.Core.Message.ErrorTypeEnum from propath.
using Spark.Core.Message.IResponse from propath.

block-level on error undo, throw.

/**
 * A static class with formatting helper methods
 */
class Spark.Core.Util.FormatTools:

    /**
     * Convert a string date value into a date value
     * Note: that the current date-format setting will be used and must be the
     * same as when the date was converted to a string
     *
     * @param pcString The String representation of a date
     * @param pcDate The converted date
     * @return false if the string is not a valid date
     */
    method public static logical screenToDate( input pcString as character, output pcDate as date ):

        error-status:error = false.
        pcDate = date(pcString) no-error.
        return not error-status:error.

    end method.

    /**
     * Convert a string date value into a date value
     * Note: that the current date-format setting will be used and must be the
     * same as when the date was converted to a string
     *
     * @param pcString The String representation of a date
     * @param pcDate The converted date
     * @param pcErrField Field name to assign any error to
     */
    method public static void screenToDate( input pcString as character, output pcDate as date, input pcErrField as character):

        if not screenToDate(pcString,output pcDate) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Date", pcString).
            return.
        end.

    end method.

    /**
     * Convert a string date value into a date value
     * Note: that the current date-format setting will be used and must be the
     * same as when the date was converted to a string
     *
     * @param pcString The String representation of a date
     * @param pcDate The converted date
     * @return false if the string is not a valid date
     */
    method public static logical screenToDatetime( input pcString as character, output pcDate as datetime ):

        error-status:error = false.
        pcDate = datetime(pcString) no-error.
        return not error-status:error.

    end method.

    /**
     * Convert a string date value into a date value
     * Note: that the current date-format setting will be used and must be the
     * same as when the date was converted to a string
     *
     * @param pcString The String representation of a date
     * @param pcDate The converted date
     * @param pcErrField Field name to assign any error to
     */
    method public static void screenToDatetime( input pcString as character, output pcDate as datetime, input pcErrField as character):

        if not screenToDatetime(pcString,output pcDate) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Date", pcString).
            return.
        end.

    end method.


    /**
     * Convert a string date value into a date value
     * Note: that the current date-format setting will be used and must be the
     * same as when the date was converted to a string
     *
     * @param pcString The String representation of a date
     * @param pcDate The converted date
     * @return false if the string is not a valid date
     */
    method public static logical screenToDatetimeTz( input pcString as character, output pcDate as datetime ):

        error-status:error = false.
        pcDate = datetime-tz(pcString) no-error.
        return not error-status:error.

    end method.

    /**
     * Convert a string date value into a date value
     * Note: that the current date-format setting will be used and must be the
     * same as when the date was converted to a string
     *
     * @param pcString The String representation of a date
     * @param pcDate The converted date
     * @param pcErrField Field name to assign any error to
     */
    method public static void screenToDatetimeTz( input pcString as character, output pcDate as datetime-tz, input pcErrField as character):

        if not screenToDatetimeTz(pcString,output pcDate) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Datetime-tz", pcString).
            return.
        end.

    end method.

    /**
     * Convert a string date value into a date value and validate it as part of a range
     * Note: that the current date-format setting will be used and must be the
     * same as when the date was converted to a string
     *
     * @param pcToString The String representation of the end of a date range
     * @param pcFromString The String representation of the start of a date range
     * @param pcDate The converted end date
     * @param pcErrField Field name to assign any error to
     */
    method public static void screenToDateRange( input pcToString as character, input pcFromString as character, output ptDate as date, input  pcErrField as character):

        define variable tFromDate as date no-undo.

        if not screenToDate(pcToString,output ptDate) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Date", pcToString).
            return.
        end.
        else
            if not screenToDate(pcFromString, output tFromDate) or
                ptDate lt tFromDate then
            do:
                cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                    :addError(pcErrField,ErrorTypeEnum:Error, "Invalid date range").
                return.
            end.

    end method.

    /**
    * Convert a string logical value into a logical value
    * Values can be True,Yes,Y,False,No,N
    * "" or ? return ?
    * Any other value is an error
    *
    * @param pcString The String representation of a logical
    * @param pcLog The converted logical
    * @return false if the string is not a valid logical
    */
    method public static logical screenToLog( input pcString as character, output pcLog as logical ):

        case pcString:
            when "True" or
            when "Yes" or
            when "Y" then
                do:
                    pcLog = true.
                    return true.
                end.
            when "False" or
            when "No" or
            when "N" then
                do:
                    pcLog = false.
                    return true.
                end.
            when "" or
            when ? then
                do:
                    pcLog = ?.
                    return true.
                end.
            otherwise
            do:
                pcLog = ?.
                return false.
            end.
        end case.

    end method.

    /**
     * Convert a string logical value into a logical value
     * True can be True,Yes,Y,False,No,N otherwise ?
     *
     * @param pcString The String representation of a logical
     * @param pcLog The converted logical
     * @param pcErrField Field name to assign any error to
     */
    method public static void screenToLog( input pcString as character, output pcLog as logical, input pcErrField as character):

        if not screenToLog(pcString,output pcLog) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Logical", pcString).
            return.
        end.

    end method.

    /**
     * Convert a string integer value into an integer value
     *
     * @param pcString The String representation of a logical
     * @param pcInt The converted integer
     * @return false if the string is not a valid integer
     */
    method public static logical screenToInt( input pcString as character, output pcInt as integer ):

        error-status:error = false.
        pcInt = integer(pcString) no-error.
        return not error-status:error.

    end method.

    /**
     * Convert a string integer value into an integer value
     *
     * @param pcString The String representation of a integer
     * @param pcInt The converted integer
     * @param pcErrField Field name to assign any error to
     */
    method public static void screenToInt( input pcString as character, output pcInt as integer, input pcErrField as character):

        if not screenToInt(pcString,output pcInt) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Integer", pcString).
            return.
        end.

    end method.

    /**
     * Convert a string int64 value into an int64 value
     *
     * @param pcString The String representation of a logical
     * @param pcInt64 The converted int64
     * @return false if the string is not a valid integer
     */
    method public static logical screenToInt64( input pcString as character, output pcInt64 as int64 ):

        error-status:error = false.
        pcInt64 = int64(pcString) no-error.
        return not error-status:error.

    end method.

    /**
     * Convert a string int64 value into an int64 value
     *
     * @param pcString The String representation of a integer
     * @param pcInt64 The converted int64
     * @param pcErrField Field name to assign any error to
     */
    method public static void screenToInt64( input pcString as character, output pcInt64 as int64, input pcErrField as character):

        if not screenToInt64(pcString,output pcInt64) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Int64", pcString).
            return.
        end.

    end method.

    /**
     * Convert a string decimal value into an decimal value
     *
     * @param pcString The String representation of a decimal
     * @param pcInt The converted decimal
     * @return false if the string is not a valid decimal
     */
    method public static logical screenToDec( input pcString as character, output pcDec as decimal ):

        error-status:error = false.
        pcDec = decimal(pcString) no-error.
        return not error-status:error.

    end method.

    /**
     * Convert a string decimal value into an decimal value
     *
     * @param pcString The String representation of a decimal
     * @param pcInt The converted decimal
     * @param pcErrField Field name to assign any error to
     */
    method public static void screenToDec( input pcString as character, output pcDec as decimal, input pcErrField as character):

        if not screenToDec(pcString,output pcDec) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Decimal", pcString).
            return.
        end.

    end method.

    method public static logical screenToRowid( input pcString as character, output prRowid as rowid):

        define variable oJson as Progress.Json.ObjectModel.JsonObject no-undo.

        if pcString eq "" then
            prRowid = ?.
        else
        do:
            oJson = new Progress.Json.ObjectModel.JsonObject().
            oJson:Add("v",pcString).
            prRowid = oJson:GetRowid("v").
        end.

        return true.

        catch e as Progress.Lang.Error :
            return false.
        end catch.

    end method.

    method public static void screenToRowid( input pcString as character, output prRowid as rowid, input pcErrField as character):

        if not screenToRowid(pcString,output prRowid) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Rowid", pcString).
            return.
        end.

    end method.

    /** Converst an ISO date string to a datetime-tz value
        @param pcString Character string representing the ISO date
        @return The datatime-tz conversion
      */
    method public static datetime-tz iso2DateTZ(input pcString as character):

        define variable cDateFormat as character no-undo.

        cDateFormat = session:date-format.
        session:date-format = 'ymd'.

        return datetime-tz(pcString).

        finally:
            session:date-format = cDateFormat.
        end finally.

    end method.

    /** Converts an ISO date string to a date value
      * @param pcString The String representation of a date
      * @param pcDate The converted date
      * @return True/False if there is a format error
      */
    method public static logical iso2DateTZ( input pcString as character, output pcDate as datetime-tz ):

        define variable cDateFormat as character no-undo.

        cDateFormat = session:date-format.
        session:date-format = 'ymd'.

        error-status:error = false.
        pcDate = datetime-tz(pcString) no-error.
        return not error-status:error.

        finally:
            session:date-format = cDateFormat.
        end finally.

    end method.

    /**
     * Convert a string date value into a date value
     * Note: that the current date-format setting will be used and must be the
     * same as when the date was converted to a string
     *
     * @param pcString The String representation of a date
     * @param pcDate The converted date
     * @param pcErrField Field name to assign any error to
     */
    method public static void iso2DateTZ( input pcString as character, output pcDate as datetime-tz, input pcErrField as character):

        if not iso2DateTZ(pcString,output pcDate) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Datetime-TZ", pcString).
            return.
        end.

    end method.

    /** Converst an ISO date string to a datetime value
        @param pcString Character string representing the ISO date
        @return The datatime conversion
      */
    method public static datetime iso2DateTime(input pcString as character):

        define variable cDateFormat as character no-undo.

        cDateFormat = session:date-format.
        session:date-format = 'ymd'.

        return datetime(pcString).

        finally:
            session:date-format = cDateFormat.
        end finally.

    end method.

    /** Converts an ISO date string to a date value
      * @param pcString The String representation of a date
      * @param pcDate The converted date
      * @return True/False if there is a format error
      */
    method public static logical iso2DateTime( input pcString as character, output pcDate as datetime ):

        define variable cDateFormat as character no-undo.

        cDateFormat = session:date-format.
        session:date-format = 'ymd'.

        error-status:error = false.
        pcDate = datetime(pcString) no-error.
        return not error-status:error.

        finally:
            session:date-format = cDateFormat.
        end finally.

    end method.

    /**
     * Convert a string date value into a date value
     * Note: that the current date-format setting will be used and must be the
     * same as when the date was converted to a string
     *
     * @param pcString The String representation of a date
     * @param pcDate The converted date
     * @param pcErrField Field name to assign any error to
     */
    method public static void iso2DateTime( input pcString as character, output pcDate as datetime, input pcErrField as character):

        if not iso2DateTime(pcString,output pcDate) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Datetime", pcString).
            return.
        end.

    end method.

    /** Converts an ISO date string to a date value
        @param pcString Character string representing the ISO date
        @return The date conversion
      */
    method public static date iso2Date(input pcString as character):

        define variable cDateFormat as character no-undo.

        cDateFormat = session:date-format.
        session:date-format = 'ymd'.

        return date(pcString).

        finally:
            session:date-format = cDateFormat.
        end finally.

    end method.

    /** Converts an ISO date string to a date value
      * @param pcString The String representation of a date
      * @param pcDate The converted date
      * @return True/False if there is a format error
      */
    method public static logical iso2Date( input pcString as character, output pcDate as date ):

        define variable cDateFormat as character no-undo.

        cDateFormat = session:date-format.
        session:date-format = 'ymd'.

        error-status:error = false.
        pcDate = date(pcString) no-error.
        return not error-status:error.

        finally:
            session:date-format = cDateFormat.
        end finally.

    end method.

    /**
     * Convert a string date value into a date value
     * Note: that the current date-format setting will be used and must be the
     * same as when the date was converted to a string
     *
     * @param pcString The String representation of a date
     * @param pcDate The converted date
     * @param pcErrField Field name to assign any error to
     */
    method public static void iso2Date( input pcString as character, output pcDate as date, input pcErrField as character):

        if not iso2Date(pcString,output pcDate) then
        do:
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField,ErrorTypeEnum:Error, "[&1] is not a valid Date", pcString).
            return.
        end.

    end method.

    method public static character stringOf( input pdValue as decimal):

        define variable cDec as character no-undo.
        define variable cSep as character no-undo.

        cDec = session:numeric-decimal-point.
        cSep = session:numeric-separator.
        session:set-numeric-format (",",".").

        return string(pdValue).

        finally:
            session:set-numeric-format (cSep,cDec).
        end finally.

    end method.

    method public static decimal decimalOf( input pcString as character):

        define variable cDec as character no-undo.
        define variable cSep as character no-undo.

        cDec = session:numeric-decimal-point.
        cSep = session:numeric-separator.
        session:set-numeric-format (",",".").

        return decimal(pcString).

        finally:
            session:set-numeric-format (cSep,cDec).
        end finally.

    end method.

    method public static character stringOf( input piValue as integer):

        define variable cDec as character no-undo.
        define variable cSep as character no-undo.

        cDec = session:numeric-decimal-point.
        cSep = session:numeric-separator.
        session:set-numeric-format (",",".").

        return string(piValue).

        finally:
            session:set-numeric-format (cSep,cDec).
        end finally.

    end method.

    method public static integer integerOf( input pcString as character):

        define variable cDec as character no-undo.
        define variable cSep as character no-undo.

        cDec = session:numeric-decimal-point.
        cSep = session:numeric-separator.
        session:set-numeric-format (",",".").

        return integer(pcString).

        finally:
            session:set-numeric-format (cSep,cDec).
        end finally.

    end method.

    method public static character stringOf( input piValue as int64):

        define variable cDec as character no-undo.
        define variable cSep as character no-undo.

        cDec = session:numeric-decimal-point.
        cSep = session:numeric-separator.
        session:set-numeric-format (",",".").

        return string(piValue).

        finally:
            session:set-numeric-format (cSep,cDec).
        end finally.

    end method.

    method public static int64 int64Of( input pcString as character):

        define variable cDec as character no-undo.
        define variable cSep as character no-undo.

        cDec = session:numeric-decimal-point.
        cSep = session:numeric-separator.
        session:set-numeric-format (",",".").

        return int64(pcString).

        finally:
            session:set-numeric-format (cSep,cDec).
        end finally.

    end method.

    method public static character stringOf( input plValue as logical):

        return string(plValue,"Yes/No").

    end method.

    method public static logical logicalOf( input pcString as character):

        define variable lReturn as logical no-undo.

        case pcString:
            when "Yes" or
            when "True" then
                lReturn = true.
            when "No" or
            when "False" then
                lReturn = false.
            otherwise
            lReturn = ?.
        end case.

        return lReturn.

    end method.

    method public static character stringOf( input ptValue as date):

        return iso-date(ptValue).

    end method.

    method public static date dateOf( input pcString as character):

        return iso2Date(pcString).

    end method.

    method public static character stringOf( input ptValue as datetime):

        return iso-date(ptValue).

    end method.

    method public static datetime datetimeOf( input pcString as character):

        return iso2DateTime(pcString).

    end method.

    method public static character stringOf( input ptValue as datetime-tz):

        return iso-date(ptValue).

    end method.

    method public static datetime-tz datetime-tzOf( input pcString as character):

        return iso2DateTZ(pcString).

    end method.

    method public static character stringOf( input prValue as rowid):

        define variable oJson as Progress.Json.ObjectModel.JsonObject no-undo.

        oJson = new Progress.Json.ObjectModel.JsonObject().
        oJson:Add("v",prValue).

        return oJson:GetCharacter("v").

    end method.

    method public static rowid rowidOf( input pcString as character ):

        define variable oJson as Progress.Json.ObjectModel.JsonObject no-undo.

        if pcString eq ? or pcString eq "" then return ?.

        oJson = new Progress.Json.ObjectModel.JsonObject().
        oJson:Add("v",pcString).
        return oJson:GetRowid("v").

    end method.

    method public static character stringOf( input prValue as recid):

        define variable oJson as Progress.Json.ObjectModel.JsonObject no-undo.

        oJson = new Progress.Json.ObjectModel.JsonObject().
        oJson:Add("v",prValue).

        return oJson:GetCharacter("v").

    end method.

    method public static recid recidOf( input pcString as character ):

        define variable oJson as Progress.Json.ObjectModel.JsonObject no-undo.

        if pcString eq ? or pcString eq "" then return ?.

        oJson = new Progress.Json.ObjectModel.JsonObject().
        oJson:Add("v",pcString).
        return oJson:GetRecid("v").

    end method.

    method public static longchar stringOf( input prValue as raw):

        define variable oJson as Progress.Json.ObjectModel.JsonObject no-undo.

        oJson = new Progress.Json.ObjectModel.JsonObject().
        oJson:Add("v",prValue).

        return oJson:GetCharacter("v").

    end method.

    method public static raw rawOf( input pcString as longchar ):

        define variable oJson as Progress.Json.ObjectModel.JsonObject no-undo.

        oJson = new Progress.Json.ObjectModel.JsonObject().
        oJson:Add("v",pcString).
        return oJson:GetRaw("v").

    end method.

    method public static longchar stringOf( input pmValue as memptr):

        define variable oJson as Progress.Json.ObjectModel.JsonObject no-undo.

        oJson = new Progress.Json.ObjectModel.JsonObject().
        oJson:Add("v",pmValue).

        return oJson:GetCharacter("v").

    end method.

    method public static memptr memptrOf( input pcString as longchar ):

        define variable oJson as Progress.Json.ObjectModel.JsonObject no-undo.

        oJson = new Progress.Json.ObjectModel.JsonObject().
        oJson:Add("v",pcString).
        return oJson:GetMemptr("v").

    end method.

    /**
     * Return a formated date
     * e.g. Wednesday, 2 October 2013
     *
     * @param ptDate Date to format
     * @param pcWeekDayList List of week day names
     * @param pcMonthList List of month names
     */
    method private static character formatAsLongDate (input ptDate        as date,
        input pcWeekDayList as character,
        input pcMonthList   as character) :

        define variable cDaySuffixList as character no-undo.
        define variable cDaySuffix     as character no-undo.
        define variable cFormat        as character no-undo.

        cDaySuffixList = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("st,nd,rd,th").
        case day(ptDate):
            when 1 or
            when 21 or
            when 31 then
                cDaySuffix = entry(1,cDaySuffixList).
            when 2 or
            when 22            then
                cDaySuffix = entry(2,cDaySuffixList).
            when 3 or
            when 23            then
                cDaySuffix = entry(3,cDaySuffixList).
            otherwise
            cDaySuffix = entry(4,cDaySuffixList).
        end case.

        /* EN "&3, &1 &5 &6"   - Wednesday, 2 October 2013
         *    "&3, &1&2 &5 &6" - Wednesday, 2nd October 2013
         * CH "&6年&5月&1日,&3" - 2013年10月2日,星期三
         */
        cFormat = replace(cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("longdateFormat:&3, &1 &5 &6"), "longdateFormat:", "").
        return substitute(cFormat, day(ptDate), cDaySuffix, entry( weekday(ptDate), pcWeekdayList ),
            month(ptDate), entry (month(ptDate), pcMonthList),
            year(ptDate)).

    end method.

    /**
     * Return a formated date
     * e.g. Wednesday, 2 October 2013
     *
     * @param ptDate Date to format
     * @param pcWeekDayList List of week day names
     * @param pcMonthList List of month names
     */
    method private static character formatAsLongDatetime (input ptDate        as datetime-tz,
                                                          input pcWeekDayList as character,
                                                          input pcMonthList   as character) :

        define variable cDaySuffixList as character no-undo.
        define variable cDaySuffix     as character no-undo.
        define variable cFormat        as character no-undo.

        cDaySuffixList = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("st,nd,rd,th").
        case day(ptDate):
            when 1 or
            when 21 or
            when 31 then
                cDaySuffix = entry(1,cDaySuffixList).
            when 2 or
            when 22            then
                cDaySuffix = entry(2,cDaySuffixList).
            when 3 or
            when 23            then
                cDaySuffix = entry(3,cDaySuffixList).
            otherwise
            cDaySuffix = entry(4,cDaySuffixList).
        end case.

        /* EN "&3, &1 &5 &6 &7 (&8)"   - Wednesday, 2 October 2013 3:56 PM (+11:00)
         *    "&3, &1&2 &5 &6 &7 (&8)" - Wednesday, 2nd October 2013 3:56 PM (+11:00)
         * CH "&6年&5月&1日,&3" - 2013年10月2日,星期三
         */
        cFormat = replace(cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("longDatetimeFormat:&3, &1 &5 &6 &7 (&8)"), "longDatetimeFormat:", "").
        return substitute(cFormat, day(ptDate), cDaySuffix, entry( weekday(ptDate), pcWeekdayList ),
            month(ptDate), entry (month(ptDate), pcMonthList),
            year(ptDate), string(integer(mtime(ptDate) / 1000), "HH:MM AM"), string(timezone(ptDate), "+HH:MM")).

    end method.

    /**
     * Return a formated date
     * e.g. Wednesday, 2 October 2013
     *
     * @param ptDate Date to format
     */
    method public static character formatAsLongDate (input ptDate as date) :

        define variable cWeekDayList as character no-undo.
        define variable cMonthList   as character no-undo.

        assign
            cWeekDayList = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday")
            cMonthList   = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("January,February,March,April,May,June,July,August,September,October,November,December").

        return formatAsLongDate(ptDate,cWeekDayList, cMonthList).

    end method.

    /**
     * Return a formated date
     * e.g. Wed, 2 Oct 2013
     *
     * @param ptDate Date to format
     */
    method public static character formatAsAbbreviatedLongDate (input ptDate as date) :

        define variable cWeekDayList as character no-undo.
        define variable cMonthList   as character no-undo.

        assign
            cWeekDayList = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("Sun,Mon,Tue,Wed,Thur,Fri,Sat")
            cMonthList   = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec").

        return formatAsLongDate(ptDate,cWeekDayList, cMonthList).

    end method.

    /**
     * Return a formated datetime
     * e.g. Wednesday, 2 October 2013 2:45PM (+11:00)
     *
     * @param ptDate Date to format
     */
    method public static character formatAsLongDatetime (input ptDate as datetime-tz) :

        define variable cWeekDayList as character no-undo.
        define variable cMonthList   as character no-undo.

        assign
            cWeekDayList = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday")
            cMonthList   = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("January,February,March,April,May,June,July,August,September,October,November,December").

        return formatAsLongDatetime(ptDate,cWeekDayList, cMonthList).

    end method.

    /**
     * Return a formated date
     * e.g. Wed, 2 Oct 2013 2:45PM (+11:00)
     *
     * @param ptDate Date to format
     */
    method public static character formatAsAbbreviatedLongDatetime (input ptDate as datetime) :

        define variable cWeekDayList as character no-undo.
        define variable cMonthList   as character no-undo.

        assign
            cWeekDayList = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("Sun,Mon,Tue,Wed,Thur,Fri,Sat")
            cMonthList   = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage("Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec").

        return formatAsLongDatetime(ptDate,cWeekDayList, cMonthList).

    end method.

    /**
     * Convert the codepage of a longchar value to UTF-8
     * Note: codepage-convert leaks 4 bytes in 11.6.1 hense the need for this method
     */
    method public static longchar convertToUTF8 (input pcValue as longchar) :

        define variable cReturn as longchar no-undo.

        if get-codepage(pcValue) ne "UTF-8" then
        do:
            /*can't copy to itself - it returns ? */
            copy-lob pcValue to cReturn convert target codepage "UTF-8".
            return cReturn.
        end.
        else
            return pcValue.

    end method.

    /**
     * Return a date value from a meta data string
     * e.g. @TODAY, @TODAY+5, @EOM
     */
    method public static datetime-tz getDateFromMetaData(input pcMetaData as character, input pcErrField as character) :

        define variable tReturn as datetime-tz no-undo.
        define variable cMetaData as character no-undo.
        define variable iNum as integer no-undo.

        do on error undo, leave:

            cMetaData =  trim(pcMetaData).

            if cMetaData eq "@NOW" then
                return now.

            if cMetaData begins "@TODAY" then
                assign
                    tReturn = today
                    cMetaData = trim(substring(cMetaData,7)).
            else if cMetaData begins "@EOM" then /*end of month*/
                assign
                    tReturn   = date(month(today), 28, year(today)) + 4
                    tReturn   = date(month(tReturn), 1, year(tReturn)) - 1
                    cMetaData = trim(substring(cMetaData,5)).
            else if cMetaData begins "@SOM" or cMetaData begins "@BOM" then /*Start/Beginning of month*/
                assign
                    tReturn   = date(month(today), 1, year(today))
                    cMetaData = trim(substring(cMetaData,5)).
            else if cMetaData begins "@EOY" then /*end of Year*/
                assign
                    tReturn   = date(12, 31, year(today))
                    cMetaData = trim(substring(cMetaData,5)).
            else if cMetaData begins "@SOY" or cMetaData begins "@BOY" then /*Start/Beginning of Year*/
                assign
                    tReturn   = date(1, 1, year(today))
                    cMetaData = trim(substring(cMetaData,5)).
            else do:
                assign
                    tReturn = iso2DateTZ(cMetaData) no-error.
                if tReturn eq ? then
                    assign
                        tReturn =  datetime-tz(cMetaData) no-error.
                assign
                    cMetaData = "".
            end.

            if cMetaData begins "-" then
                assign
                    iNum = integer(trim(substring(cMetaData,2))) * -1
                    tReturn = add-interval (tReturn, iNum, "days").
            else if cMetaData begins "+" then
                assign
                    iNum = integer(trim(substring(cMetaData,2)))
                    tReturn = add-interval (tReturn, iNum, "days").

            catch ee as Progress.Lang.Error:
                tReturn = ?.
                if pcErrField ne ? then
                    cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                        :addError(pcErrField, ErrorTypeEnum:Error, "[&1] is not a valid date [&2]", pcMetaData, ee:GetMessage(1)).
                return tReturn.
            end catch.
        end.

        if tReturn eq ? and pcErrField ne ? then
            cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage,IResponse)
                :addError(pcErrField, ErrorTypeEnum:error, "[&1] is not a valid date", pcMetaData).

        return tReturn.

    end method.

end class.