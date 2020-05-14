/*------------------------------------------------------------------------
    File        : ICatalogManager
    Purpose     :
    Description : Catalog Manager (Interface)
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Mar 03 13:55:51 EST 2015
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.JsonObject from propath.
using OpenEdge.Web.DataObject.DataObjectService from propath.

interface Spark.Core.Manager.ICatalogManager inherits Ccs.Common.IManager:

    define public property ApiVersion    as decimal   no-undo get.
    define public property IdProperty    as character no-undo get.
    define public property ReadFilter    as character no-undo get.
    define public property ServicePrefix as character no-undo get.
    define public property UseRequestObj as logical   no-undo get.

    method public void loadResources ( ).

    method public void addProperty ( input pcServiceURI    as character,
                                     input pcClassPath     as character,
                                     input pcOperationType as character,
                                     input pcPropertyName  as character,
                                     input pcPropertyType  as character,
                                     input pcPropertyValue as character ).

    method public void describeEntity ( input pcServiceURI   as character,
                                        input pcResourceName as character,
                                        input pcEntityName   as character,
                                        input pcPrimaryKeys  as character,
                                        input pcForeignKeys  as character ).

    method public void describeFields ( input pcEntityName as character,
                                        input pcTableName  as character,
                                        input poFieldData  as JsonObject ).

    method public void describeResource ( input pcServiceURI    as character,
                                          input pcResourceName  as character,
                                          input pcMethodName    as character,
                                          input pcPublicName    as character,
                                          input pcOperationType as character,
                                          input pcOperationVerb as character ).

    method public JsonObject getCatalog ( input pcServiceURI   as character,
                                          input pcResourceName as character ).

    method public void stopProcedures ( ).

    method public void registerAllServices ( input poRegistry as OpenEdge.Web.DataObject.IServiceRegistry ).

    method public DataObjectService registerService ( input poRegistry       as OpenEdge.Web.DataObject.IServiceRegistry,
                                                      input pcServiceName    as character,
                                                      input poServiceVersion as OpenEdge.Core.SemanticVersion ).

end interface.