/*------------------------------------------------------------------------
    File        : Token
    Purpose     : Test harness for Two-Factor tokens
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Oct 13 13:17:53 EDT 2017
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Security.HOTP from propath.
using Spark.Core.Security.TOTP from propath.

block-level on error undo, throw.

block-level on error undo, throw.

class Business.UnitTest.Token inherits Spark.Core.Service.DynamicResource: 

    define public override property serviceURI as character
        initial "/web/pdo/tests" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "token" no-undo get.
        protected set.

    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "testTokens", "tokens", "put").
    end method. /* initialize */

    method public void testTokens ( input  base32Secret as character,
                                    output systemTime   as datetime-tz,
                                    output hashToken    as character,
                                    output timeToken    as character ):
        /**
         * Note: JBSWY3DPEHPK3PXP is a default secret used by the reference
         * implementation at http://jsfiddle.net/russau/ch8PK/
         */
        define variable oHOTP as HOTP      no-undo.
        define variable oTOTP as TOTP      no-undo.
        define variable cCode as character no-undo.

        assign oHOTP = new HOTP(base32Secret, 30, 6).
        assign oTOTP = new TOTP(base32Secret).

        assign systemTime = now.
        assign hashToken = oHOTP:Token.
        assign timeToken = oTOTP:Token.

        finally:
            delete object oHOTP no-error.
            delete object oTOTP no-error.
        end finally.
    end method.

end class.