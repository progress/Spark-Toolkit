/*------------------------------------------------------------------------
    File        : Strings.cls
    Purpose     : Define simple string manipulation functions.
    Description :
    Author(s)   : Dustin
    Created     : Tue Nov 26 10:42:59 EST 2013
    Notes       :
  ----------------------------------------------------------------------*/

&GLOBAL-DEFINE DIGITS "1,2,3,4,5,6,7,8,9,0"

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.

block-level on error undo, throw.
&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW

class Spark.Core.Util.Strings use-widget-pool:

    define private static temp-table tSort no-undo
        field aValue as character
        .


    /*************************** Protected Helper Methods ****************************/


    method protected static integer doXOR ( input piP1 as integer,
                                            input piP2 as integer ):
        define variable iR  as integer no-undo initial 0.
        define variable iX  as integer no-undo initial 1.
        define variable iB1 as integer no-undo.
        define variable iB2 as integer no-undo.

        do while (piP1 > 0) or (piP2 > 0) {&THROW}:
            assign
                iB1 = piP1
                iB2 = piP2
                piP1 = truncate(piP1 / 2, 0)
                piP2 = truncate(piP2 / 2, 0)
                iB1 = iB1 - piP1 * 2
                iB2 = iB2 - piP2 * 2
                .

            if iB1 ne iB2 then
                assign iR = iR + iX.

            assign iX = iX + iX.
        end. /* DO WHILE */

        return iR.
    end method. /* XOR */


    /**************************** Public Helper Methods ****************************/


    method public static character getXOR ( input pcInput as character,
                                            input piKey   as integer ):
        define variable cString1 as longchar  no-undo.
        define variable cString2 as longchar  no-undo.
        define variable iLength  as integer   no-undo.
        define variable cOutput  as character no-undo.
        define variable cChar1   as character no-undo.
        define variable cChar2   as character no-undo.
        define variable iCode1   as integer   no-undo.
        define variable iCode2   as integer   no-undo.
        define variable iPos     as integer   no-undo.

        /* Attempt to convert from unicode to local character set. */
        fix-codepage(cString1) = "UTF-8".
        fix-codepage(cString2) = "UTF-8".

        assign
            cString1 = trim(pcInput)
            cString2 = codepage-convert(trim(pcInput), session:charset, "UTF-8")
            iLength  = length(cString2, "CHARACTER")
            .

        /* Use the original string if the conversion results in an empty or null value.
         * Or use the original if the length is less than half the size (double-byte).
         */
        if iLength eq 0 or cString2 eq "?" or (iLength lt (length(cString1, "CHARACTER") / 2)) then
            assign cString2 = cString1.

        /* Perform XOR conversion on a per-character basis. */
        do iPos = 1 to length(cString2, "CHARACTER") {&THROW}:
            /* Perform an XOR on the character code. */
            assign
                cChar1 = substring(cString2, iPos, 1)
                iCode1 = asc(cChar1)
                iCode2 = doXOR(iCode1, piKey)
                .

            /* Convert the XOR'd code back to a character. */
            assign
                cChar2  = chr(iCode2)
                cOutput = cOutput + cChar2
                .
        end.

        return cOutput.
    end method. /* getXOR */


    method public static character getDigitsOnly ( input pcString as character ):
        define variable ix      as integer   no-undo.
        define variable cString as character no-undo.

        do ix = 1 to length(pcString) {&THROW}:
            if can-do({&DIGITS}, substring(pcString, ix, 1)) then
                assign cString = cString + SUBSTRING(pcString, ix, 1).
        end.

        return cString.
    end method. /* getDigitsOnly */


    method public static character camelCaseWord ( input pcString as character ):
        assign pcString = trim(pcString).
        return caps(substring(pcString, 1, 1)) + LC(substring(pcString, 2)).
    end method. /* camelCaseWord */


    method public static character properWords ( input pcString as character ):
        define variable ix      as integer   no-undo.
        define variable cString as character no-undo.

        assign pcString = trim(pcString).
        do ix = 1 to num-entries(pcString, " "):
            assign cString = substitute("&1 &2", cString, camelCaseWord(entry(ix, pcString, " "))).
        end.

        return trim(cString).
    end method. /* properWords */


    method public static character stripKeywords ( input pcString as character ):
        /* Compare concatinated string to internal keywords. */
        if keyword(replace(pcString, " ", "")) ne ? then
            assign pcString = pcString + "val".
        return pcString.
    end method. /* stripKeywords */


    method public static logical containsBadChar ( input pcString as character ):
      return pcString matches "*#*" or
             pcString matches "*&*" or
             pcString matches "*%*" or
             pcString matches "*$*" or
             pcString matches "*-*".
    end method. /* containsBadChar */


    method public static character stripBadChars ( input pcString as character ):
        assign
            pcString = replace(pcString, "#", "num")
            pcString = replace(pcString, "&", "and")
            pcString = replace(pcString, "%", "pct")
            pcString = replace(pcString, "$", "amt")
            pcString = replace(pcString, "-", "")
            pcString = stripKeywords(pcString)
            .
        return pcString.
    end method. /* stripBadChars */


    method public static character stripBadLabel ( input pcString as character ):
        assign
            pcString = replace(pcString, "#", " Number ")
            pcString = replace(pcString, "%", " Percent ")
            pcString = replace(pcString, "$", " Amount ")
            pcString = replace(pcString, "&", " And ")
            pcString = replace(pcString, "-", " ")
            .
        return trim(pcString).
    end method. /* stripBadLabel */


    method public static character stripOperators ( input pcString as character ):
        pcString = replace(pcString," or "," ").
        pcString = replace(pcString," ^ "," ").
        pcString = replace(pcString," ! "," ").
        pcString = replace(pcString," | "," ").
        pcString = replace(pcString," and "," ").
        pcString = replace(pcString," + "," ").
        return pcString.
    end method. /* stripOperators */


    method public static character stripPunctuation ( input pcString as character ):
        assign
            pcString = replace(pcString, "-", " ")
            pcString = replace(pcString, ".", "")
            pcString = replace(pcString, ",", "")
            pcString = replace(pcString, ";", "")
            pcString = replace(pcString, ":", "")
            pcString = replace(pcString, "!", "")
            pcString = replace(pcString, "&", "")
            pcString = replace(pcString, "(", "")
            pcString = replace(pcString, ")", "")
            pcString = replace(pcString, "[", "")
            pcString = replace(pcString, "]", "")
            pcString = replace(pcString, "~"", "")
            pcString = replace(pcString, "~t", " ")
            .
        return trim(pcString).
    end method. /* stripPunctuation */


    method public static character getUniqueWords ( input pcString as character ):
        define variable ix         as integer   no-undo.
        define variable cExclude   as character no-undo.
        define variable cNewString as character no-undo.
        define variable cWord      as character no-undo.
        define variable iWord      as integer   no-undo.

        assign /* Clean up whitespace. */
            pcString = trim(pcString)
            pcString = replace(pcString, "~t", " ")
            pcString = replace(pcString, "  ", " ")
            pcString = replace(pcString, "   ", " ")
            pcString = replace(pcString, "    ", " ")
            .

        /* Set ignore list for "noise" words. */
        assign cExclude = "a,all,am,an,and,any,are,as,at,be,but,can,did,do,does,for,from,had,has,have,here,how,i,if,in,is,it,no,not,of,on,or,so,that,the,then,they*,there,this,to,too,up,use,what,when,where,who,why,you".

        /* Create a new, unique list of words. */
        WORDBLK:
        do ix = 1 to num-entries(pcString, " ") {&THROW}:
            assign cWord = trim(entry(ix, pcString, " ")).

            /* Skip words that are too common. */
            if can-do(cExclude, cWord) then next WORDBLK.

            /* Skip words that are too short. */
            if length(cWord) le 2 then next WORDBLK.

            /* Skip words already in the list. */
            if can-do(cNewString, cWord) then next WORDBLK.

            /* Skip words that are actually numbers. */
            assign iWord = decimal(cWord) NO-ERROR.
            if not error-status:error then next WORDBLK.

            assign cNewString = substitute("&1 &2", cNewString, cWord).
        end. /* NUM-ENTRIES */

        return trim(cNewString).
    end method. /* getUniqueWords */


    method public static character booleanConvert ( input pcString   as character,
                                                    input plOrSearch as logical):
        define variable ix as integer no-undo.

        /* Compress white space */
        pcString = replace(pcString,"( ","("). /* around parenthesis */
        pcString = replace(pcString,") ",")").
        pcString = replace(pcString," (","(").
        pcString = replace(pcString," )",")").

        pcString = replace(pcString,'" ','"'). /* around quotes */
        pcString = replace(pcString,' "','"').

        pcString = " " + pcString + " ".       /* temporarily pad with spaces */

        pcString = replace(pcString,"~t"," "). /* eliminate redundant space */
        pcString = replace(pcString,"  "," ").

        /* Things to do only OUTSIDE of quotes */
        do ix = 1 to num-entries(pcString,'"') {&THROW}:
            if ix modulo 2 eq 1 then do {&THROW}:
                /* Convert "and" and "or" to operators */
                entry(ix,pcString,'"') = replace(entry(ix,pcString,'"')," or ","%|%").
                entry(ix,pcString,'"') = replace(entry(ix,pcString,'"')," ^ ","%|%").
                entry(ix,pcString,'"') = replace(entry(ix,pcString,'"')," ! ","%|%").
                entry(ix,pcString,'"') = replace(entry(ix,pcString,'"')," | ","%|%").
                entry(ix,pcString,'"') = replace(entry(ix,pcString,'"')," and ","%&%").
                entry(ix,pcString,'"') = replace(entry(ix,pcString,'"')," +", "%&%").

                if plOrSearch then do {&THROW}:
                    /* Progress default is "and".  We want "or". */
                    entry(ix,pcString,'"') = replace(entry(ix,pcString,'"')," ", "%|%").
                end.

                /* Now clean up our % signs */
                entry(ix,pcString,'"') = replace(entry(ix,pcString,'"'),"%&%"," & ").
                entry(ix,pcString,'"') = replace(entry(ix,pcString,'"'),"%|%"," | ").
            end.
        end.

        /* Wildcards are not allowed at the beginning of words */
        pcString = replace(pcString," *"," ").
        pcString = replace(pcString,"(*","(").
        pcString = replace(pcString,'"*','"').

        /* No boolean operators without operands on both sides */
        pcString = trim(pcString," &|^!").

        /* Get rid of operators without operands */
        pcString = replace(pcString,"| |","|").
        pcString = replace(pcString,"& &","&").
        pcString = replace(pcString,"& |","|").

        return pcString. /* METHOD PUBLIC CHARACTERreturn value. */

        catch err as Progress.Lang.Error:
           undo, throw new Progress.Lang.AppError(substitute("Error while converting search terms: &1", err:GetMessage(1))).
        end catch.
    end method. /* booleanConvert */


    method public static character unixSafe ( input pcString as character ):
        pcString = replace(pcString, ",", "").
        pcString = replace(pcString, ";", "").
        pcString = replace(pcString, ":", "").
        pcString = replace(pcString, "!", "").
        pcString = replace(pcString, "&", "").
        pcString = replace(pcString, "(", "").
        pcString = replace(pcString, ")", "").
        pcString = replace(pcString, "[", "").
        pcString = replace(pcString, "]", "").
        pcString = replace(pcString,"'","").
        pcString = replace(pcString,'"',"-").
        pcString = replace(pcString,'*',".").
        pcString = replace(pcString,'~{',"-").
        pcString = replace(pcString,'~}',"-").
        pcString = replace(pcString,'^',"").
        pcString = replace(pcString,'|',"").
        pcString = replace(pcString,'`',"").
        return pcString.
    end method. /* unixSafe */


    method public static character maskString ( input pcString as character,
                                         input piUnmask as integer,
                                         input pcMask   as character ):
        define variable cNewString as character no-undo.
        define variable ix         as integer   no-undo.

        do ix = 1 to length(pcString) {&THROW}:
            if ix le piUnmask then
                assign cNewString = substitute("&1&2", cNewString, substring(pcString, ix, 1)).
            else
                assign cNewString = substitute("&1&2", cNewString, pcMask).
        end.

        return cNewString.
    end method. /* maskString */


    method public static logical inArray ( input poArrayData as JsonArray,
                                           input pcSearchVal as character ):
        define variable iX as integer no-undo.

        if poArrayData:GetClass():IsA("Progress.Json.ObjectModel.JsonArray") then
        do iX = 1 to poArrayData:length:
            if poArrayData:GetType(iX) eq JsonDataType:String and
               poArrayData:GetCharacter(iX) eq pcSearchVal then return true.
        end.

        return false.
    end method. /* inArray */


    method public static JsonArray sortArray ( input poArrayData as JsonArray ):
        define variable iX      as integer no-undo.
        define variable oSorted as JsonArray no-undo.

        empty temp-table tSort.

        if poArrayData:GetClass():IsA("Progress.Json.ObjectModel.JsonArray") then
        do iX = 1 to poArrayData:length:
            create tSort.
            assign tSort.aValue = poArrayData:GetCharacter(iX).
        end.
        if can-find(first tSort) then do:
            assign oSorted = new JsonArray().
            for each tSort by aValue:
                oSorted:Add(tSort.aValue).
            end. /* for each tSort */
            empty temp-table tSort.
            return oSorted.
        end. /* can-find */

        return poArrayData.
    end method. /* sortArray */


    method public static JsonObject mergeProperties ( input poOriginalObj as JsonObject,
                                                      input poNewMergeObj as JsonObject ):
        define variable cNames as character extent no-undo.
        define variable iType  as integer          no-undo.
        define variable iX     as integer          no-undo.

        if not valid-object(poOriginalObj) or
           not poOriginalObj:GetClass():IsA("Progress.Json.ObjectModel.JsonObject") then return poOriginalObj.

        if valid-object(poNewMergeObj) then
            assign cNames = poNewMergeObj:GetNames().

        do iX = 1 to extent(cNames):
            assign iType = poNewMergeObj:GetType(cNames[iX]).
            if poOriginalObj:Has(cNames[iX]) then do:
                case iType:
                    when JsonDataType:Array then
                        poOriginalObj:Set(cNames[iX], poNewMergeObj:GetJsonArray(cNames[iX])).
                    when JsonDataType:Object then
                        poOriginalObj:Set(cNames[iX], poNewMergeObj:GetJsonObject(cNames[iX])).
                    when JsonDataType:Boolean then
                        poOriginalObj:Set(cNames[iX], poNewMergeObj:GetLogical(cNames[iX])).
                    when JsonDataType:String then
                        poOriginalObj:Set(cNames[iX], poNewMergeObj:GetCharacter(cNames[iX])).
                    when JsonDataType:Number then
                        poOriginalObj:SetNumber(cNames[iX], poNewMergeObj:GetCharacter(cNames[iX])).
                    when JsonDataType:Null then
                        poOriginalObj:SetNull(cNames[iX]).
                end case.
            end.
            else do:
                case iType:
                    when JsonDataType:Array then
                        poOriginalObj:Add(cNames[iX], poNewMergeObj:GetJsonArray(cNames[iX])).
                    when JsonDataType:Object then
                        poOriginalObj:Add(cNames[iX], poNewMergeObj:GetJsonObject(cNames[iX])).
                    when JsonDataType:Boolean then
                        poOriginalObj:Add(cNames[iX], poNewMergeObj:GetLogical(cNames[iX])).
                    when JsonDataType:String then
                        poOriginalObj:Add(cNames[iX], poNewMergeObj:GetCharacter(cNames[iX])).
                    when JsonDataType:Number then
                        poOriginalObj:AddNumber(cNames[iX], poNewMergeObj:GetCharacter(cNames[iX])).
                    when JsonDataType:Null then
                        poOriginalObj:AddNull(cNames[iX]).
                end case.
            end.
        end.

        return poOriginalObj.
    end method. /* mergeProperties */


    method public static character reverse ( input pcString as character ):
        define variable iPos      as integer no-undo.
        define variable cReversed as character no-undo.

        do iPos = 1 to length(pcString):
            assign cReversed = substitute("&1&2", substring(pcString, iPos, 1), cReversed).
        end.

        return cReversed.
    end method. /* reverse */


    method public static character leftPad ( input pcString as character,
                                             input pcPad    as character,
                                             input piLength as integer ):
        if length(pcString) ge piLength then return pcString.

        if length(pcString) lt piLength then
            return substitute("&1&2", fill(pcPad, piLength - length(pcString)), pcString).
    end method. /* leftPad */


    method public static character rightPad ( input pcString as character,
                                              input pcPad    as character,
                                              input piLength as integer ):
        if length(pcString) ge piLength then return pcString.

        if length(pcString) lt piLength then
            return substitute("&1&2", pcString, fill(pcPad, piLength - length(pcString))).
    end method. /* rightPad */


    method public static character appendWithComma ( input pcExisting   as character,
                                                     input pcNewMessage as character ):
        if (pcExisting gt "") eq true then
            return trim(trim(substitute("&1, &2", pcExisting, pcNewMessage), ",")).

        return pcNewMessage.
    end method. /* appendWithComma */

end class.