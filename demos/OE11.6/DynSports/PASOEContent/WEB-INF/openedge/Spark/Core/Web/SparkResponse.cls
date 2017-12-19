/*------------------------------------------------------------------------
    File        : SparkResponse
    Purpose     : Custom WebResponse object for Spark-based WebHandlers
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Mon Apr 25 16:18:28 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using OpenEdge.Net.HTTP.StatusCodeHelper from propath.

block-level on error undo, throw.

class Spark.Core.Web.SparkResponse inherits OpenEdge.Web.WebResponse implements Spark.Core.Web.IWebResponse use-widget-pool:

    method public character GetStatusReason ( input piStatusCode as integer ).
        define variable cReason as character no-undo.

        case piStatusCode: /* Provide standard or custom reasons for an HTTP status. */
            when 200 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:OK).
            when 201 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:Created).
            when 204 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:NoContent).
            when 404 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:NotFound).
            when 409 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:Conflict).
            when 418 then cReason = "I'm a teapot". /* Legit status, per RFC2324 ;) */
            when 429 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:TooManyRequests).
            when 500 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:InternalServerError).
            when 502 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:BadGateway).
            when 503 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:ServiceUnavailable).
        end case.

        return cReason.
    end method. /* GetStatusReason */

end class.