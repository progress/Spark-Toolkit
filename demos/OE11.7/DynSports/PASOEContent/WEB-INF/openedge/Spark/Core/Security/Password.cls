/*------------------------------------------------------------------------
    File        : Password
    Purpose     : Provide common methods for comparing/encoding passwords
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed Aug 16 16:19:44 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Spark.Core.Security.Password use-widget-pool final:

    /**************************** Public Helper Methods ******************************/

    method public static character createCode ( input piLength as integer ):
        define variable rSalt   as raw       no-undo.
        define variable cHexKey as character no-undo.
        define variable cIntKey as character no-undo.
        define variable ix      as integer   no-undo.

        assign /* Generate a random key, converting to hexidecimal. */
            rSalt   = generate-random-key
            cHexKey = string(hex-encode(rSalt))
            .

        /* Ensure hex key is an event number of values, padding if necessary. */
        if length(cHexKey) mod 2 eq 1 then
            assign cHexKey = "0" + cHexKey.

        /* Convert every 2 hexidecimal numbers to an integer, adding to a string. */
        do ix = 1 to length(cHexKey) by 2:
            assign cIntKey = substitute("&1&2", cIntKey, OpenEdge.Core.Util.MathUtil:HexToInt(substring(cHexKey, ix, 2))).
        end.

        /* If length is specified, return the first X digits. */
        if piLength ne ? and piLength gt 0 then
            return substring(cIntKey, 1, piLength).
        else
            return cIntKey.
    end method. /* createCode */


    method public static logical checkPassword ( input pcRawPassword  as character,
                                                 input pcOrigPassword as character ):
        define variable rInputPasswd  as raw no-undo.
        define variable rStoredPasswd as raw no-undo.

        assign /* Encode the given password using the SHA1 salt from the original password. */
            rInputPasswd  = sha1-digest(pcRawPassword, hex-decode(substring(pcOrigPassword, 41)))
            rStoredPasswd = hex-decode(substring(pcOrigPassword, 1, 40))
            no-error.
        if error-status:error then
            return false.

        return (rInputPasswd eq rStoredPasswd).
    end method. /* checkPassword */


    method public static character encodePassword ( input pcPassword as character ):
        define variable rSalt as raw no-undo.

        /* Encrypt the password in a manner understood by the UserRealm class for OERealm security. */
        assign rSalt = generate-random-key. /* Prepare sald for hash. */
        return string(hex-encode(sha1-digest(trim(pcPassword), rSalt)) + hex-encode(rSalt)).
    end method. /* encodePassword */

end class.