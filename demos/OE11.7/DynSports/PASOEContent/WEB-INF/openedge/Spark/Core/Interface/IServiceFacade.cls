/*------------------------------------------------------------------------
    File        : IServiceFacade
    Purpose     :
    Description : Generic CRUD Interface for Service Access
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Dec 12 08:34:00 EST 2014
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Web.IWebRequest.
using Spark.Core.Web.IWebResponse.

interface Spark.Core.Interface.IServiceFacade:

    define public property requestStopAfter as integer no-undo get.

    method public logical userLogin ( input  pcUserID          as character,
                                      input  pcDomain          as character,
                                      input  pcPassword        as character,
                                      input  pcExtra           as character,
                                      output prClientPrincipal as raw,
                                      output pcMessage         as character ).

    method public logical userLogout ( input  pcContextId as character,
                                       output pcMessage   as character ).

    method public logical userLogout ( input  phCPO       as handle,
                                       output pcMessage   as character ).

    method public logical userLogout ( output pcMessage   as character ).

    method public logical runService ( input  phCPO          as handle,
                                       input  pcResourceName as character,
                                       input  pcMethodName   as character,
                                       input  pcHttpMethod   as character,
                                       input  pcService      as character,
                                       input  pcJsonRequest  as longchar,
                                       output pfElapsedTime  as decimal,
                                       output piResponseCode as integer,
                                       output pcJsonHeaders  as longchar,
                                       output pcJsonResponse as longchar ).

    method public logical runService ( input  pcResourceName as character,
                                       input  pcMethodName   as character,
                                       input  pcHttpMethod   as character,
                                       input  pcService      as character,
                                       input  pcJsonRequest  as longchar,
                                       output pfElapsedTime  as decimal,
                                       output piResponseCode as integer,
                                       output pcJsonHeaders  as longchar,
                                       output pcJsonResponse as longchar ).

    method public void runService ( input pcResourceName as character,
                                    input pcMethodName   as character,
                                    input pcHttpMethod   as character,
                                    input pcService      as character,
                                    input pcJsonRequest  as longchar,
                                    input poWebRequest   as IWebRequest,
                                    input poWebResponse  as IWebResponse,
                                    input pdApiVersion   as decimal,
                                    input piStopAfter    as integer ).

end interface.