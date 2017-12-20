using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

/**
 * A static class with general helper methods
 */
class Spark.Core.Util.GenTools:

    /**
     * Returns a concatenated error message associated with a specified error currently recorded by error-status system handle.
     */
    method public static character getAblError():

        define variable cErrMsg as character no-undo.
        define variable iLoop   as integer   no-undo.

        if error-status:error then
        do:
            do iLoop = 1 to error-status:num-messages:
                cErrMsg = cErrMsg + (if cErrMsg eq "" then "" else chr(10)) +
                    error-status:get-message (iLoop).
            end.

            if valid-handle(error-status:error-object-detail) then
            do:
                if valid-handle(error-status:error-object-detail:soap-fault-detail) then
                    cErrMsg = cErrMsg + (if cErrMsg eq "" then "" else chr(10))
                        + string(error-status:error-object-detail:soap-fault-detail:get-serialized()).
                cErrMsg = cErrMsg + (if cErrMsg eq "" then "" else chr(10))
                    + "Fault Code:" + error-status:error-object-detail:soap-fault-code + chr(10)
                    + "Fault String:" + error-status:error-object-detail:soap-fault-string + chr(10)
                    + "Fault Actor:" + error-status:error-object-detail:soap-fault-actor.
            end.
        end.

        return cErrMsg.

    end method.

    /**
     * Return the last ABL runtime error message and number
     * See: http://knowledgebase.progress.com/articles/Article/P82729
     * The _MSG function returns the error/warning message specified by its integer parameter
     * from the current Progress session's error/warning message stack
     */
    method public static character getLastAblError():

        define variable iLcv        as integer   no-undo.
        define variable iFileNumber as integer   no-undo.
        define variable cMsgFile    as character no-undo.
        define variable iMsgNbr     as integer   no-undo.
        define variable cMsgNumber  as character no-undo.
        define variable iPosition   as integer   initial 0 no-undo.
        define variable cMsgText    as character no-undo.

        assign
            iMsgNbr     = _msg(1)
            iFileNumber = (truncate((iMsgNbr - 1) / 50, 0) + 1)
            cMsgFile    = search("prohelp/msgdata/msg" + string(iFileNumber)).

        if cMsgFile = ? then
            return substitute("An OpenEdge runtime error occurred. See the appserver log file for details. [&1]",iMsgNbr).
        else
        do:

            input from value(cMsgFile) no-echo.
            IN-BLOCK:
            do on endkey undo IN-BLOCK, leave IN-BLOCK:

                assign
                    iPosition = (iMsgNbr - 1) modulo 50.

                do iLcv = 1 to iPosition:
                    import cMsgNumber cMsgText.
                end.

                import cMsgNumber cMsgText.

            end.
            input close.

            if integer( cMsgNumber) <> iMsgNbr then
                return substitute("An OpenEdge runtime error occurred. See the appserver log file for details. [&1]",iMsgNbr).
            else
                return substitute("An OpenEdge runtime error occurred. See the appserver log file for details. [&1]",cMsgText).

        end.

    end method.

    /**
     * Convert separate date and time values into a single datetime value
     * @param pdDate Standard date in ABL (eg. TODAY)
     * @param piTime Time since midnight, in seconds (eg. TIME)
     */
    method public static datetime getDateTime (input pdDate as date, input piTime as integer):

        /* Simply change date to datetime type, and add time as seconds. */
        return add-interval(datetime(pdDate), piTime, "seconds").

    end method.

    /**
     * Get the timezone offset for a region including the daylight saveings offset
     * @param pcTZ Timezone region e.g. Australia/Sydney
     */
    method public static integer getLocalTimeZoneOffset (input pcTZ as character):

        return getLocalTimeZoneOffset(pcTZ,now).

    end method.

    /**
     * Get the timezone offset for a region including the daylight savings offset
     * @param pcTZ Timezone region e.g. Australia/Sydney
     * @param ptAsAtDatetime Datetime to return the offset for
     */
    method public static integer getLocalTimeZoneOffset (input pcTZ as character, input ptAsAtDatetime as datetime-tz):

        define variable iTimezone as integer     no-undo.
        define variable iYear     as integer     no-undo.
        define variable tDSTStart as datetime-tz no-undo.
        define variable tDSTEnd   as datetime-tz no-undo.

        if ptAsAtDatetime eq ? then
            ptAsAtDatetime = now.

        if lookup(pcTZ,"Australia/Canberra,Australia/Brisbane,Australia/Hobart,Australia/Sydney,Australia/Melbourne") ne 0 then
        do:
            iTimezone = timezone("+10:00").
            if lookup(pcTZ,"Australia/Canberra,Australia/Hobart,Australia/Sydney,Australia/Melbourne") ne 0 then
            do:
                /*DST starts at 2am 1st sunday Oct ends at 2am 1st sunday Apr*/
                /*find 1st Sunday in Oct*/
                iYear = year(datetime-tz(ptAsAtDatetime,iTimezone)).
                tDSTStart = datetime-tz(10,1,iYear,2,0,0,0,iTimezone).
                do while weekday(tDSTStart) ne 1:
                    tDSTStart = add-interval(tDSTStart,1,"day").
                end.
                /*find 1st Sunday in Apr*/
                iYear = year(datetime-tz(ptAsAtDatetime,iTimezone)).
                tDSTEnd = datetime-tz(4,1,iYear,2,0,0,0,iTimezone).
                do while weekday(tDSTEnd) ne 1:
                    tDSTEnd = add-interval(tDSTEnd,1,"day").
                end.

                if datetime-tz(ptAsAtDatetime,iTimezone) gt tDSTStart or
                    datetime-tz(ptAsAtDatetime,iTimezone) lt tDSTEnd then
                    iTimezone = timezone("+11:00").
            end.
        end.
        else if lookup(pcTZ,"Australia/Adelaide,Australia/Darwin") ne 0 then
            do:
                iTimezone = timezone("+09:30").
                if lookup(pcTZ,"Australia/Adelaide") ne 0 then
                do:
                    /*DST starts at 2am 1st sunday Oct ends at 2am 1st sunday Apr*/
                    /*find 1st Sunday in Oct*/
                    iYear = year(datetime-tz(ptAsAtDatetime,iTimezone)).
                    tDSTStart = datetime-tz(10,1,iYear,2,0,0,0,iTimezone).
                    do while weekday(tDSTStart) ne 1:
                        tDSTStart = add-interval(tDSTStart,1,"day").
                    end.
                    /*find 1st Sunday in Apr*/
                    iYear = year(datetime-tz(ptAsAtDatetime,iTimezone)).
                    tDSTEnd = datetime-tz(4,1,iYear,2,0,0,0,iTimezone).
                    do while weekday(tDSTEnd) ne 1:
                        tDSTEnd = add-interval(tDSTEnd,1,"day").
                    end.

                    if datetime-tz(ptAsAtDatetime,iTimezone) gt tDSTStart or
                        datetime-tz(ptAsAtDatetime,iTimezone) lt tDSTEnd then
                        iTimezone = timezone("+10:30").
                end.
            end.
            else if lookup(pcTZ,"Australia/Perth") ne 0 then
                do:
                    iTimezone = timezone("+08:00").
                end.
                else
                do:
                    /*other timezones to be added as required*/
                    undo, throw new ApplicationError("Timezone [&1] not yet catered for",pcTZ).
                end.

        return iTimezone.

    end method.

    /**
     * Encodes unsafe characters in a URL as per RFC 1738 section 2.2.
     * <URL:http://ds.internic.net/rfc/rfc1738.txt>, 2.2
     * The following code is derived from the URL-ENCODE function in src/web/method/cgi-utils.
     *
     * @param pcValue The value to encode
     * @return Encoded string (unkown value is returned as blank)
     */
    method public static character encodeURL (input pcValue as character):

        return encodeURL(pcValue,"").

    end method.

    /**
     * Encodes unsafe characters in a URL as per RFC 1738 section 2.2.
     * <URL:http://ds.internic.net/rfc/rfc1738.txt>, 2.2
     * The following code is derived from the URL-ENCODE function in src/web/method/cgi-utils.
     *
     * @param pcValue The value to encode
     * @param pcEncodeType The encoding option where "query", "cookie", "default" or any specified string of characters are valid.
     * @return Encoded string (unkown value is returned as blank)
     */
    method public static character encodeURL (input pcValue as character, input pcEncodeType as character):

        /*In addition, all characters specified in the variable cUnsafe plus ASCII values 0 <= x <= 31 and 127 <= x <= 255 are considered unsafe.*/

        define variable cHex        as character no-undo initial "0123456789ABCDEF":U.
        define variable cEncodeList as character no-undo initial "query".

        define variable iCounter    as integer   no-undo.
        define variable cChar       as integer   no-undo.

        /* Unsafe characters that must be encoded in URL's.  See RFC 1738 Sect 2.2. */
        define variable cUnsafe     as character no-undo
            initial " <>~"#%~{}|~\^~~[]`":U.

        /* Reserved characters that normally are not encoded in URL's */
        define variable cReserved   as character no-undo
            initial "~;/?:@=&":U.

        /* Don't bother with blank or unknown */
        if length(pcValue) eq 0 or
            pcValue         eq ? then
            return "".

        /* What kind of encoding should be used? */
        case pcEncodeType:
            when "query":U then /* QUERY_STRING name=value parts */
                cEncodeList = cUnsafe + cReserved + "+":U.
            when "cookie":U then /* Persistent Cookies */
                cEncodeList = cUnsafe + " ,~;":U.
            when "default":U or
            when "" then /* Standard URL encoding */
                cEncodeList = cUnsafe.
            otherwise
            cEncodeList = cUnsafe + pcEncodeType. /* user specified ... */
        end case.

        /* Loop through entire input string */
        iCounter = 0.
        do while true:
            assign
                iCounter = iCounter + 1
                /* ASCII value of character using single byte codepage */
                cChar    = asc(substring(pcValue, iCounter, 1, "RAW":U),
                     "1252":U,
                     "1252":U).
            if cChar le 31  or
                cChar ge 127 or
            index(cEncodeList, chr(cChar)) gt 0 then
            do:
                /* Replace character with %hh hexidecimal triplet */
                substring(pcValue, iCounter, 1, "RAW":U) = "%":U +
                    substring(cHex, integer(truncate(cChar / 16, 0)) + 1, 1, "RAW":U) + /* high */
                    substring(cHex, cChar modulo 16 + 1, 1, "RAW":U). /* low digit */

                iCounter = iCounter + 2. /* skip over hex triplet just inserted */
            end.
            if iCounter eq length(pcValue,"RAW":U) then leave.
        end.

        return pcValue.

    end method.

end class.