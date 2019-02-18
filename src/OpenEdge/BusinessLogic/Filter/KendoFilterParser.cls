/* *************************************************************************************************************************
Copyright (c) 2019 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
************************************************************************************************************************** */
/*------------------------------------------------------------------------
    File        : KendoFilterParser
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Wed Dec 07 14:11:10 EST 2016
    Notes       :         
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Ccs.BusinessLogic.IGetDataRequest.
using Ccs.BusinessLogic.IQueryEntry.
using Ccs.BusinessLogic.IQuerySortEntry.
using Ccs.BusinessLogic.JoinEnum.
using Ccs.BusinessLogic.QueryOperatorEnum.
using Ccs.Common.Support.IPrimitiveArrayHolder.
using OpenEdge.BusinessLogic.Filter.FilterParser.
using OpenEdge.BusinessLogic.GetDataRequest.
using OpenEdge.BusinessLogic.GetDataTableRequest.
using OpenEdge.BusinessLogic.QueryDefinition.
using OpenEdge.BusinessLogic.QueryGroup.
using OpenEdge.BusinessLogic.QueryOperatorHelper.
using OpenEdge.BusinessLogic.QueryPredicate.
using OpenEdge.Core.String.
using OpenEdge.Core.StringConstant.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonConstruct.
using Progress.Json.ObjectModel.JsonDataType.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.AppError.

class OpenEdge.BusinessLogic.Filter.KendoFilterParser inherits FilterParser:
    constructor public KendoFilterParser(): 
        super().
    end constructor.
    
    /* Constructor.
       
       @param character (mandatory) A table name for which to construct the filter */
    constructor public KendoFilterParser(input pTable as character):
        super(pTable).
    end constructor.
    
    /* Constructor.
       
       @param character[] (mandatory) An array of table name for which to construct the filter */
    constructor public KendoFilterParser(input pTable as character extent):
        super(pTable).
    end constructor.
    
    /* Parses where/filter phrase and returns an IQueryEntry object for a single table
       
       @param P.L.Object The filter/where clause data
       @return IQueryEntry The query entry.We return one of an IQueryPredicate (single clause) 
                           or an IQueryGroup (many clauses) */
    method override public IQueryEntry ParseWhere(input pWhere as Progress.Lang.Object):
    end method.
    
    /* Parses an SORT-BY phrase and returns an array of IQuerySortEntry objects.
       
       @param P.L.Object The SORT-BY data
       @return IQuerySortEntry[] An array of sort phrases. An indeterminate array is returned if the input phrase is empty */
    method override public IQuerySortEntry extent ParseSortBy(input pSortBy as Progress.Lang.Object):
    end method.
    
    /* Reads and processes (parses) the filter.  
       
       @param P.L.Object The filter data
       @param IGetDataRequest A new filter object */
    method override public IGetDataRequest Parse(input pData as Progress.Lang.Object):
        define variable filters as JsonArray no-undo.
        define variable jsonFilter as JsonObject no-undo.
        define variable dataRequest as GetDataRequest no-undo.
        define variable tableRequest as GetDataTableRequest no-undo.
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.
        define variable qryDef as QueryDefinition no-undo.
        define variable qryPredicate as QueryPredicate no-undo.
        define variable qryGroup as QueryGroup no-undo.
        define variable operator as QueryOperatorEnum no-undo.
        define variable fieldValue as class String no-undo.
        define variable arrayValues as IPrimitiveArrayHolder no-undo.
        define variable charValue as character no-undo.
        define variable groupJoin as JoinEnum no-undo.
        define variable joinAs as JoinEnum no-undo.
        
        if    not valid-object(pData)
           or not type-of(pData, JsonConstruct) 
        then
            return dataRequest.
    

/*
sort: { field: "age", dir: "desc" }
sort: [
    // sort by "category" in descending order and then by "name" in ascending order
    { field: "category", dir: "desc" },
    { field: "name", dir: "asc" }
  ]
*/

/* 
filter: { field: "name", operator: "startswith", value: "Jane" } 
filter: {
    // leave data items which are "Food" or "Tea"
    logic: "or",
    filters: [
      { field: "category", operator: "eq", value: "Food" },
      { field: "name", operator: "eq", value: "Tea" }
    ]
  }      
filter: [
    // leave data items which are "Beverage" and not "Coffee"
    { field: "category", operator: "eq", value: "Beverages" },
    { field: "name", operator: "neq", value: "Coffee" }
  ]
*/  
        if type-of(pData, JsonObject) then
        do:
            assign jsonFilter = cast(pData, JsonObject).
            if     jsonFilter:Has('filters':u)
               and jsonFilter:GetType('filters':u) eq JsonDataType:ARRAY
            then
                assign filters   = jsonFilter:GetJsonArray('filters':u)
                       //default join
                       groupJoin = JoinEnum:And
                       .
            else
            do:
                assign filters = new JsonArray().
                filters:Add(cast(pData, JsonObject)).
            end.
            
            if     jsonFilter:Has('logic':u)
               and jsonFilter:GetType('logic':u) eq JsonDataType:STRING
            then
                assign groupJoin = JoinEnum:GetEnum(jsonFilter:GetCharacter('logic':u)).
        end.
        else
            assign filters = cast(pData, JsonArray).
        
        // for all kinds
        // this is a single-table object for now
        assign dataRequest                  = new GetDataRequest(1)
               tableRequest                 = new GetDataTableRequest(FilterTable[1])
               dataRequest:TableRequests[1] = tableRequest
               
               cnt                          = filters:Length
               qryDef                       = new QueryDefinition()
               tableRequest:QueryDefinition = qryDef
               .
        // more than one filter is a group
        if cnt gt 1 then
            assign qryGroup              = new QueryGroup(cnt)
                   qryDef:QuerySelection = qryGroup 
                   .
        do loop = 1 to cnt:
            if not filters:GetType(loop) eq JsonDataType:OBJECT then
                next.
            assign jsonFilter = filters:GetJsonObject(loop)
                   joinAs     = groupJoin
                   .
            // we need a name
            if    not jsonFilter:Has('name':u)
               or not jsonFilter:GetType('name':u) eq JsonDataType:STRING
            then
                next.
            
            //value
            case jsonFilter:GetType('value':u):
                when JsonDataType:ARRAY  or
                when JsonDataType:OBJECT then
                    undo, throw new AppError(substitute('Unsupported filter value type of JsonObject/JsonArray for field &1',
                                                jsonFilter:GetCharacter('name':u)), 0).
                
                when JsonDataType:NULL then
                    assign fieldValue = new OpenEdge.Core.String(StringConstant:UNKNOWN).
                
                // we don't at this point know what the underlying schmema and data type are, so stringify it all
                otherwise
                    assign fieldValue = new OpenEdge.Core.String(jsonFilter:GetJsonText('value':u)).
            end case.
            
            //operator
            if    not jsonFilter:Has('operator':u)
               or not jsonFilter:GetType('operator':u) eq JsonDataType:STRING
            then
                next.
            
            assign charValue = jsonFilter:GetCharacter('operator':u).
            case charValue:
                when 'isnull':u then
                    assign operator   = QueryOperatorEnum:Eq
                           fieldValue = new OpenEdge.Core.String(StringConstant:UNKNOWN)  
                           .
                when 'isnotnull':u then
                    assign operator   = QueryOperatorEnum:Ne
                           fieldValue = new OpenEdge.Core.String(StringConstant:UNKNOWN)
                           .
                when 'isempty':u then
                    assign operator   = QueryOperatorEnum:Eq
                           fieldValue = new OpenEdge.Core.String('':u)  
                           .
                when 'isnotempty':u then
                    assign operator   = QueryOperatorEnum:Ne
                           fieldValue = new OpenEdge.Core.String('':u)
                           .
                when 'endswith':u then
                do:
                    assign operator = QueryOperatorEnum:Matches.
                    fieldValue:Prepend('*':u).
                end.
                when 'doesnotcontain':u then
                do:
                    assign operator = QueryOperatorEnum:Contains.
                    if groupJoin eq JoinEnum:And then
                        assign joinAs = JoinEnum:AndNot.
                    else
                        assign joinAs = JoinEnum:OrNot.
                end.
                
                //Simpler things are just mapped (EQ, NEQ, LTE etc)
                otherwise
                    assign operator = QueryOperatorHelper:ToEnum(charValue).
            end case.
            
            assign qryPredicate      = new QueryPredicate(jsonFilter:GetCharacter('name':u), operator, fieldValue)
                   // nulls are ok here
                   qryPredicate:Join = joinAs
                   .
            if valid-object(qryGroup) then
                qryGroup:Entries[loop] = qryPredicate.
            else
                assign qryDef:QuerySelection = qryPredicate.
        end.
        
        return dataRequest.
    end method.

end class.