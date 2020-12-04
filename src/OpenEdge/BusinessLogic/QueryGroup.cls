/* *************************************************************************************************************************
Copyright (c) 2018-2020 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
************************************************************************************************************************** */
/*------------------------------------------------------------------------
    File        : QueryGroup
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : 2018-06-15
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Ccs.BusinessLogic.IQueryEntry.
using Ccs.BusinessLogic.IQueryGroup.
using Ccs.BusinessLogic.JoinEnum.
using OpenEdge.BusinessLogic.IO.JsonPropertyNameEnum.
using OpenEdge.BusinessLogic.IO.QueryEntryDeserializer.
using OpenEdge.Core.Assert.
using OpenEdge.Core.Json.IJsonSerializer.
using OpenEdge.Core.Json.JsonConverter.
using OpenEdge.Core.Json.JsonPropertyHelper.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonConstruct.
using Progress.Json.ObjectModel.JsonDataType.
using Progress.Json.ObjectModel.JsonObject.

class OpenEdge.BusinessLogic.QueryGroup implements IQueryGroup, IJsonSerializer:
    
    /* Returns the array of query predicates and nested query groups */
    define public property Entries as IQueryEntry extent no-undo get. set.
    
    /* Returns the logical operator that shold be used to join this query entry to its predecessor in the current list */
    define public property Join as JoinEnum no-undo
        get.
        set(input pJoin as JoinEnum):
            Assert:NotNull(pJoin, 'Join operator').
            
            assign this-object:Join = pJoin.
        end set.
    
    /* Default constructor */
    constructor public QueryGroup():
        super().
        // set a default value
        assign this-object:Join = JoinEnum:None. 
    end constructor.
    
    /* Constructor
       
       @param integer The number of query entries in this group */
    constructor public QueryGroup(input pNumEntries as integer):
        super ().
        
        Assert:IsPositive(pNumEntries, 'Num query entries '). 
        assign extent(Entries) = pNumEntries.
    end constructor.

    method override public character ToString():
        define variable queryString as character no-undo.
        define variable cnt as integer no-undo.
        define variable loop as integer no-undo.
        
        assign cnt = extent(this-object:Entries).
        
        do loop = 1 to cnt:
            queryString = substitute('&1 &2 (&3)',
                                     trim(queryString),
                                     if queryString eq "" then "" else this-object:Join:ToString(),
                                     trim(this-object:Entries[loop]:ToString())).
        end.
    
        return trim(queryString).
    end method.
    
    /* SERIALIZATION METHOD:returns a JsonConstruct (JsonDataType:OBJECT or JsonDataType:ARRAY) representation 
       of this object.
       
       @return JsonConstruct A JSON representation of this object. May be unknown (JsonDataType:NULL). */
    method public JsonConstruct ToJsonConstruct():
        define variable data as JsonObject no-undo.
        
        assign data = new JsonObject().
            
        data:Add(string(JsonPropertyNameEnum:entries), JsonConverter:ToArray(this-object:Entries)).
        data:Add(string(JsonPropertyNameEnum:join),    string(this-object:Join)). 
        
        return data.
    end method.
    
    /* DESERIALIZATION METHOD: populates this object with data from the JSON representation.
       
       @param JsonConstruct A JSON representation of this object. May be unknown (JsonDataType:NULL). */
    method public void FromJson(input pJson as JsonConstruct):
        define variable data as JsonObject no-undo.
        define variable ja as JsonArray no-undo.
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.
        
        if    not valid-object(pJson)
           or not type-of(pJson, JsonObject) 
        then
            return.
        
        assign data = cast(pJson, JsonObject).
        
        // GROUP ENTRIES
        if JsonPropertyHelper:HasTypedProperty(data, string(JsonPropertyNameEnum:entries), JsonDataType:ARRAY) then
        do:
            assign ja     = data:GetJsonArray(string(JsonPropertyNameEnum:responses))
                   cnt    = ja:Length
                   extent(Entries) = cnt
                   .
            ARRAY-LOOP:
            do loop = 1 to cnt:
                if ja:GetType(loop) eq JsonDataType:OBJECT then
                    assign Entries[loop] = QueryEntryDeserializer:QueryEntryFromJson(ja:GetJsonObject(loop)).
            end.
        end.
        
        // JOIN
        if JsonPropertyHelper:HasTypedProperty(data, string(JsonPropertyNameEnum:join), JsonDataType:STRING) then
            assign this-object:Join = JoinEnum:GetEnum(data:GetCharacter(string(JsonPropertyNameEnum:join))).
    end method.

end class.