/*------------------------------------------------------------------------
    File        : tokens.p
    Purpose     : Generate a 6-digit, Time-based, One-Time-Password
    Description : By default uses a specific WebProfile account for secret
    Author(s)   :
    Created     : Mon Oct 16 15:00:20 EDT 2017
    Notes       : Change code as necessary to select a different user or
                  to specify a particular secret Base32 passcode.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

define variable oTOTP   as Spark.Core.Security.TOTP no-undo.
define variable cSecret as character                no-undo initial "JBSWY3DPEHPK3PXP".

/**
 * Note: JBSWY3DPEHPK3PXP is a default secret used by the reference
 * implementation at http://jsfiddle.net/russau/ch8PK/
 */

/* ***************************  Main Block  *************************** */

/* Generate a code in context of a specific user. This also illustrates
 * how easy it is to compromise 2FA if you have the user's secret key.
 */
/*for first WebProfile no-lock                  */
/*     where WebProfile.Username eq "dugrau":   */
/*    if WebProfile.TFASecret gt "" then        */
/*        assign cSecret = WebProfile.TFASecret.*/
/*end. /* for first WebProfile */               */

/* Default is 30-second interval with 6-digit code. */
assign oTOTP = new Spark.Core.Security.TOTP(cSecret, 30, 6).
message cSecret ":" oTOTP:Token view-as alert-box.

catch err as Progress.Lang.Error:
    message err:GetMessage(1).
end catch.
finally:
    delete object oTOTP no-error.
end finally.