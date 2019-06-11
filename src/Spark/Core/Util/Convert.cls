/*------------------------------------------------------------------------
    File        : Conversion Utilities
    Purpose     : Convert values between various formats (bin, int, hex, etc.)
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed Oct 18 09:15:16 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class Spark.Core.Util.Convert use-widget-pool:

    method public static character BinToHex ( input pcValue as character ):
        define variable cHex    as character no-undo extent initial ["1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"].
        define variable cHexOut as character no-undo.
        define variable iX      as integer   no-undo.
        define variable iValue  as integer   no-undo initial 0.

        if pcValue eq "" then return "0". /* Blank is zero. */

        /* If length of string is not divisible by 4, left-pad with zeroes. */
        if length(pcValue) mod 4 ne 0 then
            assign pcValue = Spark.Core.Util.Strings:leftPad(pcValue, "0", (4 - length(pcValue) mod 4) + length(pcValue)).

        do iX = 1 to length(pcValue) by 4:
            /* Convert a 4-bit binary value to integer, then get hex value. */
            assign iValue = BinToInt(substring(pcValue, iX, 4)).
            if iValue eq 0 then
                assign cHexOut = substitute("&1&2", cHexOut, "0").
            else
                assign cHexOut = substitute("&1&2", cHexOut, cHex[iValue]).
        end. /* iX */

        return cHexOut. /* Returns a string of [0-9|A-F]. */
    end method. /* BinToHex */


    method public static integer BinToInt ( input pcValue as character ):
        define variable iPos   as integer no-undo.
        define variable iValue as integer no-undo initial 0.

        /* Convert a binary value into an integer. */
        do iPos = length(pcValue) to 1 by -1:
            assign iValue = iValue + (integer(substring(pcValue, iPos, 1)) * exp(2, length(pcValue) - iPos)).
        end.

        return iValue. /* Returns an integer. */
    end method. /* BinToInt */


    method public static character IntToBin ( input piValue as int64 ):
        define variable iVal    as int64     no-undo.
        define variable cBinary as character no-undo initial "".

        assign iVal = piValue.
        do while iVal gt 0:
            /* Basically, keep dividing by 2 until the value is 0. */
            assign
                cBinary = substitute("&1&2", (iVal modulo 2), cBinary)
                iVal    = truncate(iVal / 2, 0)
                .
        end. /* do while */

        if cBinary eq "" then
            assign cBinary = "0".

        return cBinary. /* Returns a string of [0|1]. */
    end method. /* IntToBin */


    method public static character IntToHex ( input piValue as int64 ):
        define variable iVal as int64     no-undo.
        define variable iMod as integer   no-undo.
        define variable cBin as character no-undo initial "".
        define variable cHex as character no-undo initial "".

        if piValue eq 0 then return "0". /* Zero is zero. */

        /* Convert to binary, then convert to hex. */
        assign cBin = IntToBin(piValue).
        assign cHex = BinToHex(cBin).

        return cHex. /* Returns a string of [0-9|A-F]. */
    end method. /* IntToHex */

end class.