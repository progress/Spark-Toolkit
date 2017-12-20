/*------------------------------------------------------------------------
    File        : Email
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : dugrau@progress.com
    Created     : Thu Sep 07 13:30:44 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Util.Sendmail from propath.

block-level on error undo, throw.

class Business.UnitTest.Email inherits Spark.Core.Service.DynamicResource:

    define public override property serviceURI as character
        initial "/web/pdo/tests" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "email" no-undo get.
        protected set.

    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "sendEmail", "send", "post").
    end method. /* initialize */

    method public void sendEmail ( input  recipient as character,
                                   output success   as logical ):
        define variable oSendmail as Sendmail no-undo.

        assign oSendmail = new Sendmail().
        oSendmail:SendFrom = "noreply@progress.com".
        oSendmail:SubjectLine = "Testing".
        oSendmail:Recipient = recipient.
        oSendmail:EmailBody = "Greetings,\nThis is only a test.".
        assign success = oSendmail:SendEmail().

        catch err as Progress.Lang.Error:
            message "Error Sending Email:" err:GetMessage(1).
            assign success = false.
        end catch.
        finally:
            delete object oSendmail no-error.
        end.
    end method. /* sendEmail */

end class.