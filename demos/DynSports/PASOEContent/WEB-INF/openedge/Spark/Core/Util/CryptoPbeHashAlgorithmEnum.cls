using Spark.Core.Util.EnumMember from propath.
using Spark.Core.Util.CryptoPbeHashAlgorithmEnum from propath.
using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

/**
 * Enumeration of security-policy:pbe-hash-algorithm
 */
class Spark.Core.Util.CryptoPbeHashAlgorithmEnum inherits EnumMember final:

    define static public property MD5  as CryptoPbeHashAlgorithmEnum no-undo get. private set.
    define static public property SHA-1  as CryptoPbeHashAlgorithmEnum no-undo get. private set.
    define static public property SHA-256  as CryptoPbeHashAlgorithmEnum no-undo get. private set.
    define static public property SHA-512   as CryptoPbeHashAlgorithmEnum no-undo get. private set.

    constructor static CryptoPbeHashAlgorithmEnum():
        CryptoPbeHashAlgorithmEnum:MD5  = new CryptoPbeHashAlgorithmEnum('MD5').
        CryptoPbeHashAlgorithmEnum:SHA-1  = new CryptoPbeHashAlgorithmEnum('SHA-1').
        CryptoPbeHashAlgorithmEnum:SHA-256  = new CryptoPbeHashAlgorithmEnum('SHA-256').
        CryptoPbeHashAlgorithmEnum:SHA-512   = new CryptoPbeHashAlgorithmEnum('SHA-512').
    end constructor.

    constructor private CryptoPbeHashAlgorithmEnum ( input pcName as character ):
        super (input pcName).
    end constructor.


    method public static CryptoPbeHashAlgorithmEnum enumFromString( input pcName as character ):

        define variable oCryptoPbeHashAlgorithmEnum as CryptoPbeHashAlgorithmEnum no-undo.

        case pcName:
            when CryptoPbeHashAlgorithmEnum:MD5:name then oCryptoPbeHashAlgorithmEnum = CryptoPbeHashAlgorithmEnum:MD5.
            when CryptoPbeHashAlgorithmEnum:SHA-1:name then oCryptoPbeHashAlgorithmEnum = CryptoPbeHashAlgorithmEnum:SHA-1.
            when CryptoPbeHashAlgorithmEnum:SHA-256:name then oCryptoPbeHashAlgorithmEnum = CryptoPbeHashAlgorithmEnum:SHA-256.
            when CryptoPbeHashAlgorithmEnum:SHA-512:name then oCryptoPbeHashAlgorithmEnum = CryptoPbeHashAlgorithmEnum:SHA-512.
            otherwise
              undo, throw new ApplicationError("Invalid Encryption Algorithm").
        end case.

        return oCryptoPbeHashAlgorithmEnum.

    end method.

end class.