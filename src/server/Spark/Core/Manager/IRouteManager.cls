/*------------------------------------------------------------------------
    File        : IRouteManager
    Purpose     : Interface for dynamic service routing and execution
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Thu Apr 28 08:45:38 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Ccs.Common.IManager from propath.

interface Spark.Core.Manager.IRouteManager inherits IManager:

    method public void invokeServiceFunction ( input  pcService  as character,
                                               input  pcResource as character,
                                               input  pcMethod   as character ).

end interface.