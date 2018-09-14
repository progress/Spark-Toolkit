/*------------------------------------------------------------------------
    File        : Catalog
    Purpose     : Service to return all catalogs from the CatalogManager
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Thu Aug 02 18:53:04 EDT 2018
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Manager.ICatalogManager from propath.

block-level on error undo, throw.

class Spark.Core.Service.Catalog implements Spark.Core.Service.ICatalog: 

    method public void initialize ( ):
    end method. /* initialize */

    method public void dispose ( ):
    end method. /* dispose */

    method public void getCatalog ( output catalog as Progress.Json.ObjectModel.JsonObject ):
        define variable oCatalogManager as ICatalogManager no-undo.

        /* Consult the current CatalogManager to obtain catalog data for all available services. */
        assign oCatalogManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager).
        if valid-object(oCatalogManager) then
            assign catalog = oCatalogManager:getCatalog("", ""). /* Obtain a catalog for all available services. */
        else
            assign catalog = new Progress.Json.ObjectModel.JsonObject(). /* Otherwise, return an empty object. */
    end method. /* getCatalog */

end class.