/*------------------------------------------------------------------------
    File        : Base32
    Purpose     : Implement encode/decode for Base32 standard (RFC 4648)
    Description : https://en.wikipedia.org/wiki/Base32
    Author(s)   : Dustin Grau
    Created     : Mon Oct 16 10:02:54 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using OpenEdge.Core.Collections.StringKeyedMap from propath.
using OpenEdge.Core.Collections.StringStringMap from propath.

block-level on error undo, throw.

class Spark.Core.Util.Base32 use-widget-pool:

    define private static variable oEncodeMap as StringStringMap no-undo.
    define private static variable oDecodeMap as StringKeyedMap  no-undo.
    define private static variable cPad       as character       no-undo initial "=".

    constructor static Base32 ( ):
        assign oEncodeMap = new StringStringMap().
        assign oDecodeMap = new StringKeyedMap().

        oEncodeMap:Put("0", "A").
        oEncodeMap:Put("1", "B").
        oEncodeMap:Put("2", "C").
        oEncodeMap:Put("3", "D").
        oEncodeMap:Put("4", "E").
        oEncodeMap:Put("5", "F").
        oEncodeMap:Put("6", "G").
        oEncodeMap:Put("7", "H").
        oEncodeMap:Put("8", "I").
        oEncodeMap:Put("9", "J").
        oEncodeMap:Put("10", "K").
        oEncodeMap:Put("11", "L").
        oEncodeMap:Put("12", "M").
        oEncodeMap:Put("13", "N").
        oEncodeMap:Put("14", "O").
        oEncodeMap:Put("15", "P").
        oEncodeMap:Put("16", "Q").
        oEncodeMap:Put("17", "R").
        oEncodeMap:Put("18", "S").
        oEncodeMap:Put("19", "T").
        oEncodeMap:Put("20", "U").
        oEncodeMap:Put("21", "V").
        oEncodeMap:Put("22", "W").
        oEncodeMap:Put("23", "X").
        oEncodeMap:Put("24", "Y").
        oEncodeMap:Put("25", "Z").
        oEncodeMap:Put("26", "2").
        oEncodeMap:Put("27", "3").
        oEncodeMap:Put("28", "4").
        oEncodeMap:Put("29", "5").
        oEncodeMap:Put("30", "6").
        oEncodeMap:Put("31", "7").

        oDecodeMap:Put("A", new OpenEdge.Core.Integer(0)).
        oDecodeMap:Put("B", new OpenEdge.Core.Integer(1)).
        oDecodeMap:Put("C", new OpenEdge.Core.Integer(2)).
        oDecodeMap:Put("D", new OpenEdge.Core.Integer(3)).
        oDecodeMap:Put("E", new OpenEdge.Core.Integer(4)).
        oDecodeMap:Put("F", new OpenEdge.Core.Integer(5)).
        oDecodeMap:Put("G", new OpenEdge.Core.Integer(6)).
        oDecodeMap:Put("H", new OpenEdge.Core.Integer(7)).
        oDecodeMap:Put("I", new OpenEdge.Core.Integer(8)).
        oDecodeMap:Put("J", new OpenEdge.Core.Integer(9)).
        oDecodeMap:Put("K", new OpenEdge.Core.Integer(10)).
        oDecodeMap:Put("L", new OpenEdge.Core.Integer(11)).
        oDecodeMap:Put("M", new OpenEdge.Core.Integer(12)).
        oDecodeMap:Put("N", new OpenEdge.Core.Integer(13)).
        oDecodeMap:Put("O", new OpenEdge.Core.Integer(14)).
        oDecodeMap:Put("P", new OpenEdge.Core.Integer(15)).
        oDecodeMap:Put("Q", new OpenEdge.Core.Integer(16)).
        oDecodeMap:Put("R", new OpenEdge.Core.Integer(17)).
        oDecodeMap:Put("S", new OpenEdge.Core.Integer(18)).
        oDecodeMap:Put("T", new OpenEdge.Core.Integer(19)).
        oDecodeMap:Put("U", new OpenEdge.Core.Integer(20)).
        oDecodeMap:Put("V", new OpenEdge.Core.Integer(21)).
        oDecodeMap:Put("W", new OpenEdge.Core.Integer(22)).
        oDecodeMap:Put("X", new OpenEdge.Core.Integer(23)).
        oDecodeMap:Put("Y", new OpenEdge.Core.Integer(24)).
        oDecodeMap:Put("Z", new OpenEdge.Core.Integer(25)).
        oDecodeMap:Put("2", new OpenEdge.Core.Integer(26)).
        oDecodeMap:Put("3", new OpenEdge.Core.Integer(27)).
        oDecodeMap:Put("4", new OpenEdge.Core.Integer(28)).
        oDecodeMap:Put("5", new OpenEdge.Core.Integer(29)).
        oDecodeMap:Put("6", new OpenEdge.Core.Integer(30)).
        oDecodeMap:Put("7", new OpenEdge.Core.Integer(31)).
    end constructor.


    method private static character DecodeToBinary ( input pcString as character ):
        define variable cKey     as character no-undo.
        define variable cBinary  as character no-undo.
        define variable cConvert as character no-undo.
        define variable iCount   as integer   no-undo.
        define variable iValue   as int64     no-undo.

        /* Convert encoded string into binary. */
        do iCount = 1 to length(pcString):
            assign cKey = caps(substring(pcString, iCount, 1)).
            if cKey eq cPad then next. /* Skip the pad character. */

            if oDecodeMap:ContainsKey(cKey) then do:
                assign iValue = cast(oDecodeMap:Get(cKey), OpenEdge.Core.Integer):Value.
                assign cConvert = Spark.Core.Util.Convert:IntToBin(integer(iValue)).

                /* Converted value must be a left-zero-padded 5-bit string. */
                assign cConvert = Spark.Core.Util.Strings:leftPad(cConvert, "0", 5).

                assign cBinary = substitute("&1&2", cBinary, cConvert).
            end.
        end. /* do iCount */

        return cBinary.
    end method. /* DecodeToBinary */


    method public static character ConvertToHex ( input pcString as character ):
        define variable cBinary as character no-undo.
        define variable cChunk  as character no-undo.
        define variable cHex    as character no-undo.
        define variable ix      as integer   no-undo.

        /* First decode the Base32 string to binary (5-bits per character). */
        assign cBinary = DecodeToBinary(pcString).

        /* Convert 4-bit binary into hexadecimal. */
        do ix = 1 to length(cBinary) by 4:
            assign cChunk = substring(cBinary, ix, 4).
            assign cHex = substitute("&1&2", cHex, Spark.Core.Util.Convert:BinToHex(cChunk)).
        end. /* do ix */

        if (length(cHex) modulo 2) eq 1 then
            assign cHex = "0" + cHex. /* Left-pad with zero to make length even. */

        return cHex.
    end method. /* ConvertToHex */


    method public static character EncodeData ( input pcString as character ):
        define variable cBlock   as character no-undo.
        define variable cBinary  as character no-undo.
        define variable cConvert as character no-undo.
        define variable cEncoded as character no-undo.
        define variable cGroup   as character no-undo.
        define variable iBlock   as integer   no-undo.
        define variable iCount   as integer   no-undo.
        define variable iGroup   as integer   no-undo.
        define variable iValue   as integer   no-undo.

        /* Convert string into ASCII decimal, then convert to 8-bit binary. */
        do iCount = 1 to length(pcString):
            assign iValue = asc(substring(pcString, iCount, 1)).
            assign cConvert = Spark.Core.Util.Convert:IntToBin(iValue).
            assign cConvert = Spark.Core.Util.Strings:leftPad(cConvert, "0", 8).
            assign cBinary = substitute("&1&2", cBinary, cConvert).
        end. /* do iCount */

        /* Parse binary data by 40-bit blocks. */
        do iBlock = 1 to length(cBinary) by 40:
            assign cBlock = substring(cBinary, iBlock, 40).

            /* Parse block data by 5-bit groups (max value: 31). */
            do iGroup = 1 to length(cBlock) by 5:
                assign cGroup = substring(cBlock, iGroup, 5).

                /* Right-pad group with 0's if less than 5 bits. */
                assign cGroup = Spark.Core.Util.Strings:rightPad(cGroup, "0", 5).

                /* Convert group into decimal value, and find encoded base32 value. */
                assign iValue = Spark.Core.Util.Convert:BinToInt(cGroup).
                if oEncodeMap:ContainsKey(string(iValue)) then
                    assign cEncoded = substitute("&1&2", cEncoded, oEncodeMap:Get(string(iValue))).
            end. /* do iGroup */

            /* When a block is less than 40-bits, use pad character for remaining 5-bit groups. */
            if length(cBlock) lt 40 then
                assign cEncoded = substitute("&1&2", cEncoded, fill(cPad, integer(truncate((40 - length(cBlock)) / 5, 0)))).
        end. /* do iBlock */

        return cEncoded.
    end method. /* EncodeData */


    method public static character DecodeData ( input pcString as character ):
        define variable cBinary  as character no-undo.
        define variable cDecoded as character no-undo.
        define variable cChunk   as character no-undo.
        define variable ix       as integer   no-undo.

        /* First decode the Base32 string to binary (5-bits per character). */
        assign cBinary = DecodeToBinary(pcString).

        /* Convert 8-bit binary into ASCII characters. */
        do ix = 1 to length(cBinary) by 8:
            assign cChunk = substring(cBinary, ix, 8).
            assign cDecoded = substitute("&1&2", cDecoded, chr(Spark.Core.Util.Convert:BinToInt(cChunk))).
        end. /* do ix */

        return cDecoded.
    end method. /* DecodeData */

end class.