/*------------------------------------------------------------------------
    File        : Messages
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Dustin Grau (dgrau@progress.com)
    Created     : Fri Jan 06 09:45:59 EST 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Message.ErrorTypeEnum from propath.
using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

class Business.UnitTest.Messages inherits Spark.Core.Service.DynamicResource:

    define public override property serviceURI as character
        initial "/web/pdo/tests" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "message" no-undo get.
        protected set.

    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "testMessage", "test", "put").
    end method. /* initialize */

    method public void testMessage ( input  messageType as character,
                                     output messageText as character ):
        assign messageText = "no type".

        if (messageType gt "") eq true then do on error undo, throw:
            assign messageText = messageType.

            case messageType:
                when "Teapot" then
                    undo, throw new AppError("I'm a teapot", -418).
                when "AppError" then
                    undo, throw new AppError("This is an AppError", -500).
                when "ApplicationError" then
                    undo, throw new ApplicationError("This is an ApplicationError", -500).
                when "info" then do:
                    this-object:oResponse:addError("Field", ErrorTypeEnum:information, "This is information 1").
                    this-object:oResponse:addError("Field", ErrorTypeEnum:information, "This is information 2").
                end.
                when "success" then
                    this-object:oResponse:addError("Field", ErrorTypeEnum:success, "This was successful").
                when "warn" then
                    this-object:oResponse:addError("Field", ErrorTypeEnum:warning, "This is a warning").
                when "error" then
                    this-object:oResponse:addError("Field", ErrorTypeEnum:error, "This is an error").
                when "fatal" then
                    this-object:oResponse:addError("Field", ErrorTypeEnum:fatal, "This is a fatal error").
                when "internal" then
                    this-object:oLoggingManager:logMessage("This is an internal message", "INTERNAL", 0).
            end case.

            if this-object:oResponse:hasErrors() then
                this-object:oResponse:logErrors().
        end.
    end method.

end class.