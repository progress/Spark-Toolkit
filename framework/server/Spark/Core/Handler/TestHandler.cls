/*------------------------------------------------------------------------
    File        : TestHandler
    Purpose     : Custom WebHandler to validate input/output operations.
    Description :
    Author(s)   : Progress
    Created     : Thu Feb 11 10:24:51 EST 2016
    Notes       : Can support any HTTP verb as needed.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Spark.Core.Interface.IServiceFacade from propath.
using Spark.Core.Web.SparkRequest from propath.

block-level on error undo, throw.

class Spark.Core.Handler.TestHandler inherits Spark.Core.Handler.SparkHandler use-widget-pool:

    define private variable iStart as integer no-undo.

    define override protected property oServiceFacade as IServiceFacade no-undo get. set.


    method private JsonObject getStandardParams ( ):
        define variable oSparkRequest as SparkRequest no-undo.
        define variable oJsonParams   as JsonObject   no-undo.

        assign oSparkRequest = new SparkRequest(). /* Create object with extra properties. */
        assign oJsonParams = new JsonObject().  /* Object to hold our returned parameters. */

        oJsonParams:add("Timestamp", now).
        oJsonParams:add("Adapter", session:current-request-info:AdapterType:toString()).
        oJsonParams:add("Session", session:current-request-info:SessionId).
        oJsonParams:add("ContentType", oSparkRequest:ContentType).
        oJsonParams:add("ContentLength", oSparkRequest:ContentLength).
        oJsonParams:add("AcceptEncoding", oSparkRequest:GetContextValue("HTTP_ACCEPT_ENCODING")).
        oJsonParams:add("Language", oSparkRequest:GetContextValue("HTTP_ACCEPT_LANGUAGE")).
        oJsonParams:add("Agent", oSparkRequest:GetContextValue("HTTP_USER_AGENT")).
        oJsonParams:add("Referer", oSparkRequest:GetContextValue("HTTP_REFERER")).
        oJsonParams:add("URI", oSparkRequest:URI:toString()).
        oJsonParams:add("WebAppPath", oSparkRequest:WebAppPath).
        oJsonParams:add("TransportPath", oSparkRequest:TransportPath).
        oJsonParams:add("PathInfo", string(oSparkRequest:SparkPathArray:GetJsonText())).
        oJsonParams:add("QueryString", string(oSparkRequest:SparkQueryData:GetJsonText())).
        oJsonParams:add("Body", string(oSparkRequest:getJsonBody())).

        return oJsonParams.

        finally:
            delete object oSparkRequest no-error.
        end finally.
    end method. /* getStandardParams */


    method protected override integer runServiceAndRespond ( ):
        define variable oSparkRequest as SparkRequest no-undo.
        define variable oJsonResp     as JsonObject   no-undo.

        assign iStart = mtime. /* Reset timer. */
        assign oSparkRequest = new SparkRequest(). /* Create object with extra properties. */
        assign oJsonResp = getStandardParams().

        return prepareResponse(true, 200, ((mtime - iStart) / 1000), "",
                               oJsonResp:GetJsonText(), oSparkRequest:ContentType).

        catch err as Progress.Lang.Error:
            logMessage(substitute("Test Handler Error: &1", err:GetMessage(1)), "SPARK-ERR", 0).
            logMessage(err:CallStack, "SPARK-CALL", 0).
        end catch.
        finally:
            delete object oJsonResp no-error.
            delete object oSparkRequest no-error.
        end finally.
    end method. /* runServiceAndRespond */


    method override protected integer HandleGet ( input poRequest as OpenEdge.Web.IWebRequest ):
        define variable oSparkRequest as SparkRequest no-undo.
        define variable oJsonResp     as JsonObject   no-undo.

        assign oSparkRequest = new SparkRequest(). /* Create object with extra properties. */

        assign iStart = mtime. /* Reset timer. */

        if oSparkRequest:SparkPathArray:Length ge 2 and
           oSparkRequest:SparkPathArray:GetCharacter(2) eq "binary" then do:
            /* Test the ability to return a binary file, if found in the PROPATH. */
            return prepareBinaryFile(oSparkRequest:GetPathParameter("filename")).
        end.
        else do:
            assign oJsonResp = getStandardParams().
            return prepareResponse(true, 200, ((mtime - iStart) / 1000), "",
                                   oJsonResp:GetJsonText(), poRequest:ContentType).
        end.

        catch err as Progress.Lang.Error:
            logMessage(substitute("Test Handler Error: &1", err:GetMessage(1)), "SPARK-ERR", 0).
            logMessage(err:CallStack, "SPARK-CALL", 0).
        end catch.
        finally:
            delete object oJsonResp no-error.
            delete object oSparkRequest no-error.
        end finally.
    end method. /* HandleGet */

end class.