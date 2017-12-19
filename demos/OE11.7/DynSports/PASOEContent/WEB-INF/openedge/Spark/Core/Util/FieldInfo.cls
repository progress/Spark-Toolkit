/*------------------------------------------------------------------------
    File        : FieldInfo
    Purpose     : Create a field info object to enhance table schema
    Description : Provides a single object to extend schema, as stored in
                  the SchemaManager class, and used by the CatalogManager.
    Author(s)   : dugrau@progress.com
    Created     : Mon Aug 07 15:08:13 EDT 2017
    Notes       : Default behavior is meant to implement properties for
                  use with KendoUI as the front-end, in conjunction with
                  the Data Object Service Catalog as used by the JSDO.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Util.FieldInfo from propath.

block-level on error undo, throw.

class Spark.Core.Util.FieldInfo inherits Progress.Json.ObjectModel.JsonObject final:

    define public property DatasetName   as character no-undo get. private set.
    define public property TempTableName as character no-undo get. private set.

    constructor public FieldInfo ( ):
        super().
    end constructor.

    constructor public FieldInfo ( input pcDatasetName   as character,
                                   input pcTempTableName as character ):
        super().
        this-object:DatasetName = pcDatasetName.
        this-object:TempTableName = pcTempTableName.
    end constructor.

    method public FieldInfo getField ( input pcFieldName as character ):
        /* Create field for info object if not already available. */
        if not this-object:Has(pcFieldName) then
            this-object:Add(pcFieldName, new FieldInfo()).

        /* Returns the object when available. */
        if this-object:Has(pcFieldName) then
            return cast(this-object:GetJsonObject(pcFieldName), FieldInfo).
    end method. /* getField */

    method public FieldInfo makeRequired ( input pcField as character ):
        /* Create an object for denoting a required field. */
        define variable oRequired as JsonObject no-undo.
        assign oRequired = new JsonObject().
        oRequired:Add("required", true).

        /* Alters behavior of standard "add" by returning a FieldInfo object. */
        this-object:getField(pcField):Add("validation", oRequired).
        return this-object:getField(pcField).
    end method. /* add Property */

    method public FieldInfo addProperty ( input pcField as character,
                                          input pcName  as character,
                                          input pcValue as character ):
        /* Alters behavior of standard "add" by returning a FieldInfo object. */
        this-object:getField(pcField):Add(pcName, pcValue).
        return this-object:getField(pcField).
    end method. /* add Property */

    method public FieldInfo addProperty ( input pcField as character,
                                          input pcName  as character,
                                          input plValue as logical ):
        /* Alters behavior of standard "add" by returning a FieldInfo object. */
        this-object:getField(pcField):Add(pcName, plValue).
        return this-object:getField(pcField).
    end method. /* add Property */

    method public FieldInfo addProperty ( input pcField as character,
                                          input pcName  as character,
                                          input pfValue as decimal ):
        /* Alters behavior of standard "add" by returning a FieldInfo object. */
        this-object:getField(pcField):Add(pcName, pfValue).
        return this-object:getField(pcField).
    end method. /* add Property */

    method public FieldInfo addProperty ( input pcField as character,
                                          input pcName  as character,
                                          input piValue as integer ):
        /* Alters behavior of standard "add" by returning a FieldInfo object. */
        this-object:getField(pcField):Add(pcName, piValue).
        return this-object:getField(pcField).
    end method. /* add Property */

    method public FieldInfo addProperty ( input pcField as character,
                                          input pcName  as character,
                                          input poValue as JsonObject ):
        /* Alters behavior of standard "add" by returning a FieldInfo object. */
        this-object:getField(pcField):Add(pcName, poValue).
        return this-object:getField(pcField).
    end method. /* add Property */

    method public FieldInfo addProperty ( input pcField as character,
                                          input pcName  as character,
                                          input poValue as JsonArray ):
        /* Alters behavior of standard "add" by returning a FieldInfo object. */
        this-object:getField(pcField):Add(pcName, poValue).
        return this-object:getField(pcField).
    end method. /* add Property */

    method public character serialize ( ):
        return string(this-object:GetJsonText()).
    end method. /* serialize */

end class.