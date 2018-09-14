/*------------------------------------------------------------------------
    File        : ICatalog
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Wed Aug 29 11:06:12 EDT 2018
    Notes       : 
  ----------------------------------------------------------------------*/

interface Spark.Core.Service.ICatalog inherits Ccs.Common.IService:  

    method public void getCatalog ( output catalog as Progress.Json.ObjectModel.JsonObject ).

end interface.