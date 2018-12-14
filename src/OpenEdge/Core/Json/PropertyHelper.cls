/* *************************************************************************************************************************
Copyright (c) 2018 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
************************************************************************************************************************** */
/*------------------------------------------------------------------------
    File        : PropertyHelper
    Purpose     : General JSON property value helper
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : 2018-12-13
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.Assert.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonDataType.
using Progress.Json.ObjectModel.JsonObject.

class OpenEdge.Core.Json.PropertyHelper abstract:
    
    /* 'Upserts' an JSON array for a named property
       
       @param JsonObject The JSON object into which to upsert the property
       @param character The property name
       @return JsonArray The 'upserted' object */
    method static public JsonArray GetArrayValue(input pParent as JsonObject,
                                                 input pProperty as character):
        define variable propVal as JsonArray no-undo.
        
        Assert:NotNull(pParent, 'Parent JSON').
        Assert:NotNullOrEmpty(pProperty, 'Property name').
        
        if pParent:Has(pProperty) then
        do:
            if pParent:GetType(pProperty) eq JsonDataType:ARRAY then
                assign propVal = pParent:GetJsonArray(pProperty).
            else
            do:
                assign propVal = new JsonArray(). 
                pParent:Set(pProperty, propVal).
            end.
        end.
        else
        do:
            assign propVal = new JsonArray(). 
            pParent:Add(pProperty, propVal).
        end.
        
        return propVal.
    end method.
    
    /* 'Upserts' a JSON object for a named property
       
       @param JsonObject The JSON object into which to upsert the property
       @param character The property name
       @return JsonObject The 'upserted' object */
    method static public JsonObject GetObjectValue(input pParent as JsonObject,
                                                   input pProperty as character):
        define variable propVal as JsonObject no-undo.
        
        Assert:NotNull(pParent, 'Parent JSON').
        Assert:NotNullOrEmpty(pProperty, 'Property name').
        
        if pParent:Has(pProperty) then
        do:
            if pParent:GetType(pProperty) eq JsonDataType:OBJECT then
                assign propVal = pParent:GetJsonObject(pProperty).
            else
            do:
                assign propVal = new JsonObject(). 
                pParent:Set(pProperty, propVal).
            end.
        end.
        else
        do:
            assign propVal = new JsonObject(). 
            pParent:Add(pProperty, propVal).
        end.
        
        return propVal.
    end method.
         
end class.