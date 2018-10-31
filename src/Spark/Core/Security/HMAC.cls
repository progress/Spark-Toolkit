/*------------------------------------------------------------------------
    File        : Simple HMAC function
    Purpose     : Perform a standard HMAC hash of a key and data (as hex)
    Description :
    Author(s)   : James Bowell
    Created     : 6/13/2011
    Notes       : Code obtained from KB000043232 (first via OEHive)
        http://en.wikipedia.org/wiki/HMAC
        http://www.ietf.org/rfc/rfc2104.txt
    HMAC is a hash based MAC algorithm defined in RFC 2104. It can utilize
    any hash function (MD5, SHA1, etc). HMAC also requires a user-supplied
    secret key, which is a string of bytes of any length (up to 64 bytes).
    This version will support SHA1 or SHA256 (default: SHA1).
  ----------------------------------------------------------------------*/

&GLOBAL-DEFINE MIN_VERSION_11_7_4 (lookup(substring(proversion(1), 1, 6), "11.6.0,11.6.1,11.6.2,11.6.2,11.6.3,11.6.4,11.6.5,11.6.6,11.7.0,11.7.1,11.7.2,11.7.3") = 0)

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Spark.Core.Security.HMAC use-widget-pool final:

    method public static character GenHash ( input pcSHA     as character,
                                             input pcHexKey  as character,
                                             input pcHexData as character):
        define variable mKeyIpad       as memptr    no-undo.
        define variable mKeyOpad       as memptr    no-undo.
        define variable mKey           as memptr    no-undo.
        define variable mData          as memptr    no-undo.
        define variable mInnerCombined as memptr    no-undo.
        define variable mOuterCombined as memptr    no-undo.
        define variable iBytePos       as integer   no-undo.
        define variable iIpad          as integer   no-undo.
        define variable iOpad          as integer   no-undo.
        define variable iKey           as integer   no-undo.
        define variable iTimeTaken     as integer   no-undo.
        define variable rDecodedKey    as raw       no-undo.
        define variable rDecodedData   as raw       no-undo.
        define variable rRawDataSHA    as raw       no-undo.
        define variable cHMACSHA       as character no-undo.

        /* If possible, return an HMAC-SHA-* digest value as available in 11.7.4+ */
        if {&MIN_VERSION_11_7_4} then do:
            case pcSHA:
                when "SHA1" then
                    return string(hex-encode(message-digest("HMAC-SHA-1", hex-decode(pcHexData), hex-decode(pcHexKey)))).
                when "SHA-256" then
                    return string(hex-encode(message-digest("HMAC-SHA-256", hex-decode(pcHexData), hex-decode(pcHexKey)))).
                when "SHA-384" then
                    return string(hex-encode(message-digest("HMAC-SHA-384", hex-decode(pcHexData), hex-decode(pcHexKey)))).
                when "SHA-512" then
                    return string(hex-encode(message-digest("HMAC-SHA-512", hex-decode(pcHexData), hex-decode(pcHexKey)))).
                otherwise
                    return string(hex-encode(message-digest("HMAC-SHA-1", hex-decode(pcHexData), hex-decode(pcHexKey)))).
            end case.
        end.

        /* Basic Formula: Hash(Key XOR opad, Hash(Key XOR ipad, text)) */

        &SCOPED-DEFINE xiBlockSize 64

        set-size(mKey)     = 0.
        set-size(mKeyOpad) = 0.
        set-size(mKeyIpad) = 0.
        set-size(mKey)     = {&xiBlockSize}.
        set-size(mKeyOpad) = {&xiBlockSize}.
        set-size(mKeyIpad) = {&xiBlockSize}.

        /* Convert hex values into raw (binary) to produce a proper hash for TOTP (RFC6238). */
        assign rDecodedKey = hex-decode(pcHexKey).
        assign rDecodedData = hex-decode(pcHexData).

        /* Prepare the key pads (inner and outer). */
        do iBytePos = 1 to {&xiBlockSize}:
            put-bytes(mKey,     iBytePos) = hex-decode("00":U). /* 64 bytes of zeros 0x00*/
            put-bytes(mKeyIpad, iBytePos) = hex-decode("36":U). /* 64 bytes of 0x36 (54 dec, "6" ascii)*/
            put-bytes(mKeyOpad, iBytePos) = hex-decode("5C":U). /* 64 bytes of 0x5C (92 dec, "/" ascii) */
        end.

        /* Correction by Valery A.Eliseev, to truncate key if longer than blocksize. */
        if length(rDecodedKey) gt {&xiBlockSize} then do:
            set-size(mData) = length(rDecodedKey).
            mData = rDecodedKey.
            rRawDataSHA = sha1-digest(mData).
            put-bytes(mKey, 1) = rRawDataSHA.
        end. /* end of correction */
        else
            mKey = rDecodedKey.

        do iBytePos = 1 to {&xiBlockSize}:
            assign
                iKey  = get-byte(mKey,     iBytePos)
                iIpad = get-byte(mKeyIpad, iBytePos)
                iOpad = get-byte(mKeyOpad, iBytePos)
                .

            /* The inner key, mKeyIpad is formed from mKey by XORing each byte with 0x36. */
            put-byte(mKeyIpad, iBytePos) = Spark.Core.Util.Binary:BinaryXOR(input iKey, input iIpad).

            /* The inner key, mKeyOpad is formed from mKey by XORing each byte with 0x5C. */
            put-byte(mKeyOpad, iBytePos) = Spark.Core.Util.Binary:BinaryXOR(input iKey, input iOpad).
        end.

        set-size(mKey) = 0.
        set-size(mData) = 0.
        set-size(mData) = length(rDecodedData).
        mData = rDecodedData.

        /* Inner Loop*/
        set-size(mInnerCombined) = get-size(mKeyIpad) + get-size(mData).
        put-bytes(mInnerCombined, 1) = mKeyIpad.
        set-size(mKeyIpad) = 0.

        /*Append the data the end of the block size.*/
        put-bytes(mInnerCombined, {&xiBlockSize} + 1) = mData.

        /* Deallocates any memory. */
        set-size(mData) = 0.

        /* Get the results of the inner SHA Digest. */
        case pcSHA:
            when "SHA1" then
                assign rRawDataSHA = sha1-digest(mInnerCombined).
            when "SHA-256" then
                assign rRawDataSHA = message-digest("SHA-256", mInnerCombined).
            otherwise
                assign rRawDataSHA = sha1-digest(mInnerCombined).
        end case.

        /* Deallocates any memory. */
        set-size(mInnerCombined) = 0.

        /* Outer Loop calculation for SHA. */
        set-size(mOuterCombined)                      = 0.
        set-size(mOuterCombined)                      = get-size(mKeyOpad) + length(rRawDataSHA,"RAW":U).
        put-bytes(mOuterCombined, 1)                  = mKeyOpad.
        put-bytes(mOuterCombined, {&xiBlockSize} + 1) = rRawDataSHA.

        /* Get the results of the outer SHA Digest. */
        case pcSHA:
            when "SHA1" then
                assign rRawDataSHA = sha1-digest(mOuterCombined).
            when "SHA-256" then
                assign rRawDataSHA = message-digest("SHA-256", mOuterCombined).
            otherwise
                assign rRawDataSHA = sha1-digest(mOuterCombined).
        end case.

        /* Deallocates any memory. */
        set-size(mKeyOpad)       = 0.
        set-size(mOuterCombined) = 0.

        /* Should return as a 40-character hex value. */
        assign cHMACSHA = hex-encode(rRawDataSHA).

        &UNDEFINE xiBlockSize

        return cHMACSHA.
    end method. /* GenHash */


    method public static integer TruncateHMAC ( input pcHexHMAC as character ):
        /* Completes the standard for HOTP calculation per RFC 4226. */
        define variable cHexArray as character no-undo extent.
        define variable iIntArray as integer   no-undo extent.
        define variable iOffset   as integer   no-undo.
        define variable iOutput   as integer   no-undo.
        define variable iByte     as integer   no-undo extent 4.
        define variable ix        as integer   no-undo.
        define variable iy        as integer   no-undo.

        /* Convert HMAC into a hex array (40 characters to 20 bytes). */
        assign iy = 0.
        extent(cHexArray) = integer(length(pcHexHMAC) / 2).
        do ix = 1 to length(pcHexHMAC) by 2:
            assign iy = iy + 1.
            assign cHexArray[iy] = substring(pcHexHMAC, ix, 2).
        end. /* do ix */

        /* Convert hex array to integer array for convenience. */
        extent(iIntArray) = extent(cHexArray).
        do ix = 1 to extent(cHexArray):
            assign iIntArray[ix] = OpenEdge.Core.Util.MathUtil:HexToInt(cHexArray[ix]).
        end. /* do ix */

        /* Get offset from last value of array (would be N-1, but ABL uses 1-based arrays). */
        assign iOffset = Spark.Core.Util.Binary:BinaryAND(iIntArray[20], 0xF) + 1.

        /* Extract 4 bytes of the hash, starting at the offset (for 1-based array). */
        assign iByte[1] = Spark.Core.Util.Binary:BinaryAND(iIntArray[iOffset + 0], 0x7F). /* Mask with 127 */
        assign iByte[2] = Spark.Core.Util.Binary:BinaryAND(iIntArray[iOffset + 1], 0xFF). /* Mask with 255 */
        assign iByte[3] = Spark.Core.Util.Binary:BinaryAND(iIntArray[iOffset + 2], 0xFF). /* Mask with 255 */
        assign iByte[4] = Spark.Core.Util.Binary:BinaryAND(iIntArray[iOffset + 3], 0xFF). /* Mask with 255 */

        /* Shift the first 3 values by decreasing powers. */
        assign iByte[1] = Spark.Core.Util.Binary:ShiftLeft(iByte[1], 24).
        assign iByte[2] = Spark.Core.Util.Binary:ShiftLeft(iByte[2], 16).
        assign iByte[3] = Spark.Core.Util.Binary:ShiftLeft(iByte[3], 8).

        /* Perform binary OR of the selected 4 bytes, post-shifting. */
        assign iOutput = Spark.Core.Util.Binary:BinaryOR(iByte[1], iByte[2]).
        assign iOutput = Spark.Core.Util.Binary:BinaryOR(iOutput, iByte[3]).
        assign iOutput = Spark.Core.Util.Binary:BinaryOR(iOutput, iByte[4]).

        return iOutput.
    end method. /* TruncateHMAC */

end class.