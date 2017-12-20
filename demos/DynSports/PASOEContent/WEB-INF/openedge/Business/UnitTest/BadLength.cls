/*------------------------------------------------------------------------
    File        : BadIndex
    Purpose     : Test harness for bad index (signature mismatch) issue
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Thu Mar 23 08:56:07 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Message.ErrorTypeEnum from propath.

block-level on error undo, throw.

class Business.UnitTest.BadLength inherits Spark.Core.Service.DynamicResource:

    define public override property serviceURI as character
        initial "/web/pdo/tests" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "badlength" no-undo get.
        protected set.

    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "testOutput", "output", "get").
    end method. /* initialize */

    method public void testOutput ( output badLength as JsonArray ):
        define variable oData as JsonObject no-undo.

        badLength = new JsonArray().

        oData = new JsonObject().
        oData:Add("language", "Français").
        badLength:Add(oData).
    end method. /* testOutput */

end class.