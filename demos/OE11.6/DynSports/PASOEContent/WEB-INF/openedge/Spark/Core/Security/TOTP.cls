/*------------------------------------------------------------------------
    File        : Sports.Spark.Core.Security.TOTP
    Purpose     : Generate a TOTP code for two-factor authentication
    Description : Implementation according to Google Authenticator
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Oct 13 11:09:53 EST 2017
    Notes       :
    Time-based One-Time-Password (TOTP): https://tools.ietf.org/html/rfc6238
    Shared Secret + Moving Factor (Time)
    https://en.wikipedia.org/wiki/Time-based_One-time_Password_Algorithm
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Spark.Core.Security.TOTP use-widget-pool final:

    define private variable cTokenValue  as character no-undo initial "".
    define private variable iTokenStep   as integer   no-undo initial 30.
    define private variable iTokenLength as integer   no-undo initial 6.

    define public property Token as character no-undo
        get:
            return cTokenValue.
        end get.
        private set.

    define public property UnixEpoch as int64 no-undo
        get:
            /* Return time elapsed since Unix epoch (midnigh, 1/1/1970, UTC), in seconds. */
            return interval(now, datetime-tz(date(1/1/1970), 0, 0), "seconds").
        end get.
        private set.

    define public property EpochCounter as int64 no-undo
        get:
            /* Return number of intervals since Unix epoch (default: 30 seconds). */
            if iTokenStep le 0 then assign iTokenStep = 30.
            return int64(truncate((this-object:UnixEpoch / iTokenStep), 0)).
        end get.
        private set.

    constructor public TOTP ( input pcClientSecret as character,
                              input piTokenStep    as integer,
                              input piTokenLength  as integer ):
        super().

        /* Generate a new TOTP token using a specific Step and Length parameter. */
        this-object:newToken(pcClientSecret, piTokenStep, piTokenLength).
    end constructor.

    constructor public TOTP ( input pcClientSecret as character,
                              input piTokenLength  as integer ):
        super().

        /* Generate a new TOTP token using a specific Length parameter. */
        this-object:newToken(pcClientSecret, iTokenStep, piTokenLength).
    end constructor.

    constructor public TOTP ( input pcClientSecret as character ):
        super().

        /* Generate a new TOTP token using a default Length parameter. */
        this-object:newToken(pcClientSecret, iTokenStep, iTokenLength).
    end constructor.

    destructor public TOTP ( ):
        /* Default destructor to overwrite any OTP string value. */
        if (length(cTokenValue) gt 0) then
            assign cTokenValue = fill("x", iTokenLength).
    end destructor.

    method private void newToken ( input pcClientSecret as character,
                                   input piTokenStep    as integer,
                                   input piTokenLength  as integer ):
        define variable cCountHex  as character no-undo.
        define variable cSecretHex as character no-undo.
        define variable cTokenHex  as character no-undo.
        define variable cFormat    as character no-undo.
        define variable iOTPValue  as integer   no-undo.

        if piTokenStep gt 0 and piTokenStep ne iTokenStep then
            assign iTokenStep = piTokenStep. /* Override standard step before requesting counter. */

        /* Obtain secret for hashing via HMAC. */
        assign pcClientSecret = caps(replace(pcClientSecret, " ", "")).
        assign cSecretHex = lc(Spark.Core.Util.Base32:ConvertToHex(pcClientSecret)).

        /* Left-pad with zeroes if less than 16 characters. */
        assign cSecretHex = Spark.Core.Util.Strings:leftPad(cSecretHex, "0", 16).

        /* Obtain counter for hashing via HMAC. */
        assign cCountHex = lc(Spark.Core.Util.Convert:IntToHex(this-object:EpochCounter)).

        /* Left-pad with zeroes if less than 16 characters. */
        assign cCountHex = Spark.Core.Util.Strings:leftPad(cCountHex, "0", 16).

        /* Hash the registered client's secret value and the counter (both as hexadecimal). */
        assign cTokenHex = Spark.Core.Security.HMAC:GenHash("SHA-1", cSecretHex, cCountHex).

        /* Perform truncation to obtain an integer from the hash as our OTP value. */
        assign iOTPValue = Spark.Core.Security.HMAC:TruncateHMAC(cTokenHex).

        /* Turn the integer OTP value into digits for human consumption. */
        if (piTokenLength lt 6) then
            assign piTokenLength = 6.
        if (piTokenLength gt 10) then
            assign piTokenLength = 10.
        assign iTokenLength = piTokenLength.
        assign cTokenValue = string(iOTPValue modulo exp(10, iTokenLength)).
        assign cTokenValue = Spark.Core.Util.Strings:leftPad(cTokenValue, "0", iTokenLength).

        catch err as Progress.Lang.Error:
            if log-manager:logfile-name ne ? then
                log-manager:write-message("newToken: " + err:getMessage(1), "ERROR-OTP").
        end catch.
    end method. /* newToken */

end class.