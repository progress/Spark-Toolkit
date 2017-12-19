using Spark.Core.Util.ApplicationError from propath.
using Spark.Core.Util.CryptoEncryptAlgorithmEnum from propath.
using Spark.Core.Util.CryptoPbeHashAlgorithmEnum from propath.
using Spark.Core.Util.FormatTools from propath.

block-level on error undo, throw.

/**
 * A static class with cryptology helper methods
 */
class Spark.Core.Util.CryptoTools:

    /**
     * Returns a base64 encoded encrypted string of a supplied character string
     *
     * @param pcValue Data to be encrypted
     * @param pcPasswordKey the password used to generate the encryption key
     * @param prInitVector An optional expression that evaluates to an initialization vector value
     * @param poCryptoEncryptAlgorithmEnum the name of the symmetric cryptographic algorithm to use
     * @param poCryptoPbeHashAlgorithmEnum the name of the pbe hash algorithm to use
     */
    method public static longchar encryptCode( input pcValue as longchar, input pcPasswordKey as character, input prInitVector as raw, input poCryptoEncryptAlgorithmEnum as CryptoEncryptAlgorithmEnum, input poCryptoPbeHashAlgorithmEnum as CryptoPbeHashAlgorithmEnum ):

        define variable cReturn as longchar no-undo.

        if length(pcValue, "RAW") eq 0 then
            return "".

        pcValue = FormatTools:convertToUTF8(pcValue).

        cReturn = base64-encode(encrypt(pcValue, getEncryptKey(pcPasswordKey, poCryptoEncryptAlgorithmEnum, poCryptoPbeHashAlgorithmEnum), prInitVector, poCryptoEncryptAlgorithmEnum:name)).

        cReturn = FormatTools:convertToUTF8(cReturn).

        return cReturn.

    end method.

    /**
     * Returns the base64 encoded encrypted string of a supplied character string
     *
     * @param pcValue Data to be encrypted
     * @param prKey the encryption key
     * @param prInitVector An optional expression that evaluates to an initialization vector value
     * @param poCryptoEncryptAlgorithmEnum the name of the symmetric cryptographic algorithm to use
     */
    method public static longchar encryptCode( input pcValue as longchar, input prKey as raw, input prInitVector as raw, input poCryptoEncryptAlgorithmEnum as CryptoEncryptAlgorithmEnum ):

        define variable cReturn as longchar no-undo.

        if length(pcValue, "RAW") eq 0 then
            return "".

        pcValue = FormatTools:convertToUTF8(pcValue).

        cReturn = base64-encode(encrypt(pcValue, prKey, prInitVector, poCryptoEncryptAlgorithmEnum:name)).

        cReturn = FormatTools:convertToUTF8(cReturn).

        return cReturn.

    end method.

    /**
     * Returns encrypted memptr of a supplied memptr
     *
     * @param pcValue Data to be encrypted
     * @param prKey the encryption key
     * @param prInitVector An optional expression that evaluates to an initialization vector value
     * @param poCryptoEncryptAlgorithmEnum the name of the symmetric cryptographic algorithm to use
     */
    method public static memptr encryptValue( input pmValue as memptr, input prKey as raw, input prInitVector as raw, input poCryptoEncryptAlgorithmEnum as CryptoEncryptAlgorithmEnum ):

        return encrypt(pmValue, prKey, prInitVector, poCryptoEncryptAlgorithmEnum:name).

    end method.

    /**
     * Returns the decrypted string of a supplied encrypted character string
     *
     * @param pcValue The base64 encoded encrypted data to be decrypted
     * @param pcPasswordKey the password used to generate the encryption key used when the data was encrypted by encryptCode()
     * @param prInitVector An optional expression that evaluates to an initialization vector value
     * @param poCryptoEncryptAlgorithmEnum the name of the symmetric cryptographic algorithm used by encryptCode()
     * @param poCryptoPbeHashAlgorithmEnum the name of the pbe hash algorithm to use
     */
    method public static longchar decryptCode( input pcValue as longchar, input pcPasswordKey as character, input prInitVector as raw, input poCryptoEncryptAlgorithmEnum as CryptoEncryptAlgorithmEnum, input poCryptoPbeHashAlgorithmEnum as CryptoPbeHashAlgorithmEnum ):

        define variable cReturn  as longchar no-undo.
        define variable mDecrypt as memptr   no-undo.

        if length(pcValue, "RAW") eq 0 then
            return "".

        pcValue = FormatTools:convertToUTF8(pcValue).

        mDecrypt = decrypt(base64-decode(pcValue), getEncryptKey(pcPasswordKey, poCryptoEncryptAlgorithmEnum, poCryptoPbeHashAlgorithmEnum), prInitVector, poCryptoEncryptAlgorithmEnum:name).

        copy-lob from mDecrypt to cReturn convert source codepage session:cpinternal target codepage "UTF-8".

        return cReturn.

        finally:
            set-size(mDecrypt) = 0.
        end finally.

    end method.

    /**
     * Returns the decrypted string of a supplied encrypted character string
     *
     * @param pcValue The base64 encoded encrypted data to be decrypted
     * @param prKey the encryption key used when the data was encrypted by encryptCode()
     * @param prInitVector An optional expression that evaluates to an initialization vector value
     * @param poCryptoEncryptAlgorithmEnum the name of the symmetric cryptographic algorithm used by encryptCode()
     */
    method public static longchar decryptCode( input pcValue as longchar, input prKey as raw, input prInitVector as raw, input poCryptoEncryptAlgorithmEnum as CryptoEncryptAlgorithmEnum ):

        define variable cReturn  as longchar no-undo.
        define variable mDecrypt as memptr   no-undo.

        if length(pcValue, "RAW") eq 0 then
            return "".

        pcValue = FormatTools:convertToUTF8(pcValue).

        mDecrypt = decrypt(base64-decode(pcValue), prKey, prInitVector, poCryptoEncryptAlgorithmEnum:name).

        copy-lob from mDecrypt to cReturn convert source codepage session:cpinternal target codepage "UTF-8".

        return cReturn.

        finally:
            set-size(mDecrypt) = 0.
        end finally.

    end method.

    /**
     * Returns decrypted memptr of a supplied encrypted memptr
     *
     * @param pcValue encrypted data to be decrypted
     * @param prKey the encryption key used when the data was encrypted by encryptValue()
     * @param prInitVector An optional expression that evaluates to an initialization vector value
     * @param poCryptoEncryptAlgorithmEnum the name of the symmetric cryptographic algorithm to use
     */
    method public static memptr decryptValue( input pmValue as memptr, input prKey as raw, input prInitVector as raw, input poCryptoEncryptAlgorithmEnum as CryptoEncryptAlgorithmEnum ):

        return decrypt(pmValue, prKey, prInitVector, poCryptoEncryptAlgorithmEnum:name).

    end method.

    /**
     * Returns a RAW encryption key that can be passed to encryptCode()
     *
     * @param pcPassword The password to use in generating the encryption key.
     * @param poCryptoEncryptAlgorithmEnum the name of the symmetric cryptographic algorithm that this key will be used with
     * @param poCryptoPbeHashAlgorithmEnum the name of the pbe hash algorithm to use
     */
    method public static raw getEncryptKey( input pcPassword as character, input poCryptoEncryptAlgorithmEnum as CryptoEncryptAlgorithmEnum, input poCryptoPbeHashAlgorithmEnum as CryptoPbeHashAlgorithmEnum ):

        define variable rReturn              as raw       no-undo.
        define variable cEncryptionAlgorithm as character no-undo.
        define variable cPbeHashAlgorithm    as character no-undo.
        define variable rSalt                as raw       no-undo.
        define variable iKeyRounds           as integer   no-undo.

        cEncryptionAlgorithm = security-policy:symmetric-encryption-algorithm.
        cPbeHashAlgorithm = security-policy:pbe-hash-algorithm.
        rSalt = security-policy:encryption-salt.
        iKeyRounds = security-policy:pbe-key-rounds.

        if poCryptoEncryptAlgorithmEnum ne ? then
            security-policy:symmetric-encryption-algorithm = poCryptoEncryptAlgorithmEnum:name.

        if poCryptoPbeHashAlgorithmEnum ne ? then
            security-policy:pbe-hash-algorithm = poCryptoPbeHashAlgorithmEnum:name.

        security-policy:encryption-salt = ?.
        security-policy:pbe-key-rounds = 1000.

        rReturn = generate-pbe-key(pcPassword).

        return rReturn.

        finally:
            security-policy:symmetric-encryption-algorithm = cEncryptionAlgorithm.
            security-policy:pbe-hash-algorithm = cPbeHashAlgorithm.
            security-policy:encryption-salt = rSalt.
            security-policy:pbe-key-rounds = iKeyRounds.
        end finally.

    end method.

    /**
     * Returns a RAW encryption key that can be passed to encryptCode()
     *
     * @param pcPassword The password to use in generating the encryption key.
     * @param poCryptoEncryptAlgorithmEnum the name of the symmetric cryptographic algorithm that this key will be used with
     * @param poCryptoPbeHashAlgorithmEnum the name of the pbe hash algorithm to use
     * @param prSalt the Raw salt value (Use GENERATE-PBE-SALT to generate a sale value)
     */
    method public static raw getEncryptKey( input pcPassword as character, input poCryptoEncryptAlgorithmEnum as CryptoEncryptAlgorithmEnum, input poCryptoPbeHashAlgorithmEnum as CryptoPbeHashAlgorithmEnum, input prSalt as raw ):

        define variable rReturn              as raw       no-undo.
        define variable cEncryptionAlgorithm as character no-undo.
        define variable cPbeHashAlgorithm    as character no-undo.
        define variable rSalt                as raw       no-undo.
        define variable iKeyRounds           as integer   no-undo.

        cEncryptionAlgorithm = security-policy:symmetric-encryption-algorithm.
        cPbeHashAlgorithm = security-policy:pbe-hash-algorithm.
        rSalt = security-policy:encryption-salt.
        iKeyRounds = security-policy:pbe-key-rounds.

        if poCryptoEncryptAlgorithmEnum ne ? then
            security-policy:symmetric-encryption-algorithm = poCryptoEncryptAlgorithmEnum:name.

        if poCryptoPbeHashAlgorithmEnum ne ? then
            security-policy:pbe-hash-algorithm = poCryptoPbeHashAlgorithmEnum:name.

        security-policy:encryption-salt = ?.
        security-policy:pbe-key-rounds = 1000.

        rReturn = generate-pbe-key(pcPassword, prSalt).

        return rReturn.

        finally:
            security-policy:symmetric-encryption-algorithm = cEncryptionAlgorithm.
            security-policy:pbe-hash-algorithm = cPbeHashAlgorithm.
            security-policy:encryption-salt = rSalt.
            security-policy:pbe-key-rounds = iKeyRounds.
        end finally.

    end method.

    /**
     * Returns a RAW encryption key that can be passed to encryptCode()
     *
     * @param poCryptoEncryptAlgorithmEnum the name of the symmetric cryptographic algorithm that this key will be used with
     */
    method public static raw getRandomEncryptKey( input poCryptoEncryptAlgorithmEnum as CryptoEncryptAlgorithmEnum):

        define variable rReturn              as raw       no-undo.
        define variable cEncryptionAlgorithm as character no-undo.

        cEncryptionAlgorithm = security-policy:symmetric-encryption-algorithm.

        if poCryptoEncryptAlgorithmEnum ne ? then
            security-policy:symmetric-encryption-algorithm = poCryptoEncryptAlgorithmEnum:name.

        rReturn = generate-random-key.

        return rReturn.

        finally:
            security-policy:symmetric-encryption-algorithm = cEncryptionAlgorithm.
        end finally.

    end method.

    /**
     * Returns RAW initialization vector that can be passed to encryptCode()
     *
     * @param pcInitVector A string to generate a initialization vector for encryptCode()
     */
    method public static raw getEncryptInitVector( input pcInitVector as character ):

        define variable rInitVector as raw no-undo.

        /*it must be of legth at least 16*/
        pcInitVector = pcInitVector + fill(" ", 16 - length(pcInitVector,"CHARACTER")).
        put-string(rInitVector, 1, length(pcInitVector, "CHARACTER")) = pcInitVector.

        return rInitVector.

    end method.

    /**
     * Returns a base64 encoded string value of a string value
     *
     * @param pcValue The value to be encoded
     */
    method public static longchar base64Encode( input pcValue as longchar ):

        define variable mVar  as memptr  no-undo.
        define variable iLoop as integer no-undo.
        define variable cReturn as longchar no-undo.

        copy-lob from pcValue to mVar.

        cReturn = base64-encode(mVar).

        cReturn = FormatTools:convertToUTF8(cReturn).

        return cReturn.

        finally:
            set-size(mVar) = 0.
        end finally.

    end method.

    /**
     * Returns a decoded string value of a base64 encoded string value
     *
     * @param pcValue The value to be decoded
     */
    method public static longchar base64Decode( input pcValue as longchar ):

        define variable mVar   as memptr   no-undo.
        define variable cValue as longchar no-undo.

        mVar = base64-decode (pcValue).

        copy-lob from mVar to cValue convert source codepage session:cpinternal target codepage "UTF-8".

        return cValue.

        finally:
            set-size(mVar) = 0.
        end finally.

    end method.

end class.