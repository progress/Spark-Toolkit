/**
 * Custom version of IWebResponse interface
 */
interface Spark.Core.Web.IWebResponse inherits OpenEdge.Net.HTTP.IHttpResponse:

    method public void SetHeader ( input pcName as character, input pcValue as character ).

    method public character GetStatusReason ( input piStatusCode as integer ).

end interface.