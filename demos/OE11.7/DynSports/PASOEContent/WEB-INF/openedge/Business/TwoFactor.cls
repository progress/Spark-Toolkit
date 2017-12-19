/*------------------------------------------------------------------------
    File        : TwoFactor
    Purpose     : Implement 2FA login/challenge
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Mon Oct 16 08:19:05 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Util.Sendmail from propath.
using Spark.Core.Security.TOTP from propath.

block-level on error undo, throw.

class Business.TwoFactor inherits Spark.Core.Service.DynamicResource:

    define override public property serviceURI as character no-undo
        initial "/web/pdo/common" get. set.

    define override public property resourceName as character
        initial "tfa" no-undo get. set.

    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "clientLogin", "login", "put").
    end method. /* initialize */


    method private logical sendChallenge ( input pcEmail as character,
                                           input pcToken as character ):
        define variable oSendmail as Sendmail no-undo.

        oSendmail = new Sendmail().
        oSendmail:SendFrom = "noreply@progress.com".
        oSendmail:SubjectLine = "Two-Factor Token".
        oSendmail:Recipient = pcEmail.
        oSendmail:EmailBody = substitute("Code: &1", pcToken).
        return oSendmail:SendEmail().

        finally:
            delete object oSendmail no-error.
        end finally.
    end method. /* sendChallenge */


    /***** Public Methods *****/


    method public void clientLogin ( input  username as character,
                                     input  password as character,
                                     output useTFA     as logical ):
        define variable cUsername   as character no-undo.
        define variable cDomainName as character no-undo.
        define variable lSuccess    as logical   no-undo.
        define variable oTOTP       as TOTP      no-undo.

        define buffer bProfile for WebProfile.

        assign useTFA = false. /* Assume user will not use Two-Factor AuthN. */
        assign
            cUsername   = entry(1, username, "@")
            cDomainName = entry(2, username, "@") when num-entries(username, "@") eq 2
            no-error
            .

        find first bProfile exclusive-lock
             where bProfile.Username eq cUsername
               and bProfile.Domain eq cDomainName
               and bProfile.IsActive
               and not bProfile.IsLocked
               and bProfile.UseTFA no-error.
        if available(bProfile) then do:
            if Spark.Core.Security.Password:checkPassword(password, bProfile.Password) then do:
                /* Create a seed value for use as a secret for this user (stored as Base32). */
                if (bProfile.TFASecret gt "") ne true then
                    assign bProfile.TFASecret = replace(Spark.Core.Util.Base32:EncodeData(Spark.Core.Security.Password:createCode(10)), "=", "").

                case bProfile.TFAMethod:
                    when "Email" or
                    when "SMS" then do:
                        /* Create a new 6-digit, time-based (90-second) one-time-password from the secret. */
                        assign oTOTP = new TOTP(bProfile.TFASecret, 90, 6).
                        assign bProfile.TFAToken = oTOTP:Token.

                        /* Send generated code via email to appropriate destination. */
                        if bProfile.TFAMethod eq "SMS" and bProfile.MobilePhone gt "" and bProfile.MobileCarrier gt "" then
                            assign lSuccess = this-object:sendChallenge(substitute("&1@&2", bProfile.MobilePhone, bProfile.MobileCarrier), oTOTP:Token).
                        else if bProfile.Email gt "" then
                            assign lSuccess = this-object:sendChallenge(bProfile.Email, oTOTP:Token).

                        assign useTFA = true.
                    end. /* Email/SMS */
                    when "Device" then do:
                        /* Use of device will mean generation of a TOTP code immediately upon validation. */
                        assign bProfile.TFAToken = "".
                        assign useTFA = true.
                    end. /* Device */
                end case.
            end. /* checkPassword */
        end. /* available(bProfile) */
        release bProfile no-error.

        finally:
            delete object oTOTP no-error.
        end finally.
    end method. /* clientLogin */

end class.