/*------------------------------------------------------------------------
    File        : ForeignKey
    Purpose     : Create a foreign key info object to enhance table schema
    Description : Provides a properly-formatted JSON object to be used by
                  the CatalogManager to define a foreign key property.
    Author(s)   : dugrau@progress.com
    Created     : Thu Aug 24 09:30:24 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.

block-level on error undo, throw.

class Spark.Core.Util.ForeignKey inherits Progress.Json.ObjectModel.JsonObject final:

    define private variable oForeignFields  as JsonArray  no-undo.
    define private variable oLocalFields    as JsonArray  no-undo.
    define private variable oParentResource as JsonObject no-undo.

    constructor public ForeignKey ( input pcForeignKeyName as character ):
        super().

        /* Set the name for this foreign key. */
        this-object:Add("name", pcForeignKeyName).

        /* Create local variables for properties. */
        oForeignFields = new JsonArray().
        oLocalFields = new JsonArray().
        oParentResource = new JsonObject().

        /* Set default properties on this key. */
        oParentResource:Add("name", "").
        oParentResource:Add("fields", oForeignFields).
        this-object:Add("fields", oLocalFields).
        this-object:Add("parent", oParentResource).
    end constructor.

    method public void setForeignTable ( input pcForeignTable as character ):
        if oParentResource:Has("name") then
            oParentResource:Set("name", pcForeignTable).
        else
            oParentResource:Add("name", pcForeignTable).
        this-object:Set("parent", oParentResource).
    end method. /* setForeignTable */

    method public void addForeignField ( input pcForeignField as character ):
        oForeignFields:Add(pcForeignField).
        oParentResource:Set("fields", oForeignFields).
        this-object:Set("parent", oParentResource).
    end method. /* addForeignField */

    method public void addLocalField ( input pcLocalField as character ):
        oLocalFields:Add(pcLocalField).
        this-object:Set("fields", oLocalFields).
    end method. /* addLocalField */

end class.