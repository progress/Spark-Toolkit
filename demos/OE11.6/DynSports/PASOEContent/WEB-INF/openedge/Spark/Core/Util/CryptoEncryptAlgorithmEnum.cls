using Spark.Core.Util.EnumMember from propath.
using Spark.Core.Util.CryptoEncryptAlgorithmEnum from propath.
using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

/**
 * Enumeration of security-policy:symmetric-encryption-algorithm
 */
class Spark.Core.Util.CryptoEncryptAlgorithmEnum inherits EnumMember final:

    define static public property AES_CBC_128  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_OFB_256  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_CBC_192  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property DES_CBC_56   as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_CBC_256  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property DES_CFB_56   as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_CFB_128  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property DES_ECB_56   as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_CFB_192  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property DES_OFB_56   as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_CFB_256  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property DES3_CBC_168 as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_ECB_128  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property DES3_CFB_168 as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_ECB_192  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property DES3_ECB_168 as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_ECB_256  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property DES3_OFB_168 as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_OFB_128  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property RC4_ECB_128  as CryptoEncryptAlgorithmEnum no-undo get. private set.
    define static public property AES_OFB_192  as CryptoEncryptAlgorithmEnum no-undo get. private set.


    constructor static CryptoEncryptAlgorithmEnum():
        CryptoEncryptAlgorithmEnum:AES_CBC_128  = new CryptoEncryptAlgorithmEnum('AES_CBC_128').
        CryptoEncryptAlgorithmEnum:AES_OFB_256  = new CryptoEncryptAlgorithmEnum('AES_OFB_256').
        CryptoEncryptAlgorithmEnum:AES_CBC_192  = new CryptoEncryptAlgorithmEnum('AES_CBC_192').
        CryptoEncryptAlgorithmEnum:DES_CBC_56   = new CryptoEncryptAlgorithmEnum('DES_CBC_56').
        CryptoEncryptAlgorithmEnum:AES_CBC_256  = new CryptoEncryptAlgorithmEnum('AES_CBC_256').
        CryptoEncryptAlgorithmEnum:DES_CFB_56   = new CryptoEncryptAlgorithmEnum('DES_CFB_56').
        CryptoEncryptAlgorithmEnum:AES_CFB_128  = new CryptoEncryptAlgorithmEnum('AES_CFB_128').
        CryptoEncryptAlgorithmEnum:DES_ECB_56   = new CryptoEncryptAlgorithmEnum('DES_ECB_56').
        CryptoEncryptAlgorithmEnum:AES_CFB_192  = new CryptoEncryptAlgorithmEnum('AES_CFB_192').
        CryptoEncryptAlgorithmEnum:DES_OFB_56   = new CryptoEncryptAlgorithmEnum('DES_OFB_56').
        CryptoEncryptAlgorithmEnum:AES_CFB_256  = new CryptoEncryptAlgorithmEnum('AES_CFB_256').
        CryptoEncryptAlgorithmEnum:DES3_CBC_168 = new CryptoEncryptAlgorithmEnum('DES3_CBC_168').
        CryptoEncryptAlgorithmEnum:AES_ECB_128  = new CryptoEncryptAlgorithmEnum('AES_ECB_128').
        CryptoEncryptAlgorithmEnum:DES3_CFB_168 = new CryptoEncryptAlgorithmEnum('DES3_CFB_168').
        CryptoEncryptAlgorithmEnum:AES_ECB_192  = new CryptoEncryptAlgorithmEnum('AES_ECB_192').
        CryptoEncryptAlgorithmEnum:DES3_ECB_168 = new CryptoEncryptAlgorithmEnum('DES3_ECB_168').
        CryptoEncryptAlgorithmEnum:AES_ECB_256  = new CryptoEncryptAlgorithmEnum('AES_ECB_256').
        CryptoEncryptAlgorithmEnum:DES3_OFB_168 = new CryptoEncryptAlgorithmEnum('DES3_OFB_168').
        CryptoEncryptAlgorithmEnum:AES_OFB_128  = new CryptoEncryptAlgorithmEnum('AES_OFB_128').
        CryptoEncryptAlgorithmEnum:RC4_ECB_128  = new CryptoEncryptAlgorithmEnum('RC4_ECB_128').
        CryptoEncryptAlgorithmEnum:AES_OFB_192  = new CryptoEncryptAlgorithmEnum('AES_OFB_192').
    end constructor.

    constructor private CryptoEncryptAlgorithmEnum ( input pcName as character ):
        super (input pcName).
    end constructor.


    method public static CryptoEncryptAlgorithmEnum enumFromString( input pcName as character ):

        define variable oCryptoEncryptAlgorithmEnum as CryptoEncryptAlgorithmEnum no-undo.

        case pcName:
            when CryptoEncryptAlgorithmEnum:AES_CBC_128:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_CBC_128.
            when CryptoEncryptAlgorithmEnum:AES_OFB_256:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_OFB_256.
            when CryptoEncryptAlgorithmEnum:AES_CBC_192:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_CBC_192.
            when CryptoEncryptAlgorithmEnum:DES_CBC_56:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:DES_CBC_56.
            when CryptoEncryptAlgorithmEnum:AES_CBC_256:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_CBC_256.
            when CryptoEncryptAlgorithmEnum:DES_CFB_56:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:DES_CFB_56.
            when CryptoEncryptAlgorithmEnum:AES_CFB_128:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_CFB_128.
            when CryptoEncryptAlgorithmEnum:DES_ECB_56:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:DES_ECB_56.
            when CryptoEncryptAlgorithmEnum:AES_CFB_192:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_CFB_192.
            when CryptoEncryptAlgorithmEnum:DES_OFB_56:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:DES_OFB_56.
            when CryptoEncryptAlgorithmEnum:AES_CFB_256:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_CFB_256.
            when CryptoEncryptAlgorithmEnum:DES3_CBC_168:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:DES3_CBC_168.
            when CryptoEncryptAlgorithmEnum:AES_ECB_128:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_ECB_128.
            when CryptoEncryptAlgorithmEnum:DES3_CFB_168:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:DES3_CFB_168.
            when CryptoEncryptAlgorithmEnum:AES_ECB_192:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_ECB_192.
            when CryptoEncryptAlgorithmEnum:DES3_ECB_168:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:DES3_ECB_168.
            when CryptoEncryptAlgorithmEnum:AES_ECB_256:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_ECB_256.
            when CryptoEncryptAlgorithmEnum:DES3_OFB_168:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:DES3_OFB_168.
            when CryptoEncryptAlgorithmEnum:AES_OFB_128:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_OFB_128.
            when CryptoEncryptAlgorithmEnum:RC4_ECB_128:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:RC4_ECB_128.
            when CryptoEncryptAlgorithmEnum:AES_OFB_192:name then oCryptoEncryptAlgorithmEnum = CryptoEncryptAlgorithmEnum:AES_OFB_192.
            otherwise
              undo, throw new ApplicationError("Invalid Encryption Algorithm").
        end case.

        return oCryptoEncryptAlgorithmEnum.

    end method.

end class.