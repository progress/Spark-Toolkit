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
using OpenEdge.BusinessLogic.QuerySortEntry.
using OpenEdge.Core.String.
using OpenEdge.Core.StringConstant.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonConstruct.
using Progress.Json.ObjectModel.JsonDataType.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.AppError.

class OpenEdge.BusinessLogic.Filter.KendoFilterParser inherits FilterParser:

    /* Default constructor */
    constructor public KendoFilterParser (): 
        super().
    end constructor.
    
    /* Constructor.
       
       @param character (mandatory) A table name for which to construct the filter */
    constructor public KendoFilterParser (input pTable as character):
        super(pTable).
    end constructor.
    
    /* Constructor.
       
       @param character[] (mandatory) An array of table name for which to construct the filter */
    constructor public KendoFilterParser (input pTable as character extent):
        super(pTable).
    end constructor.

    /***** Start Carry-Over from Spark KendoParse *****/

    method private character getMapping ( input pcKendoOperator as character,
                                          input pcFieldDataType as character ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.operator */
        define variable cTemplate as character no-undo.

        case pcKendoOperator:
            when "equals":u or
            when "eq":u then
                if pcFieldDataType eq "character" then
                    assign cTemplate = '&1 eq "&2"'.
                else
                    assign cTemplate = '&1 eq &2'.
            when "neq":u then
                if pcFieldDataType eq "character" then
                    assign cTemplate = '&1 ne "&2"'.
                else
                    assign cTemplate = '&1 ne &2'.
            when "lt":u then
                assign cTemplate = '&1 lt &2'.
            when "lte":u then
                assign cTemplate = '&1 le &2'.
            when "gt":u then
                assign cTemplate = '&1 gt &2'.
            when "gte":u then
                assign cTemplate = '&1 ge &2'.
            when "startswith":u then
                assign cTemplate = '&1 begins "&2"'.
            when "contains":u then
                assign cTemplate = '&1 matches "*&2*"'.
            when "doesnotcontain":u then
                assign cTemplate = 'not (&1 matches "*&2*")'.
            when "endswith":u then
                assign cTemplate = '&1 matches "*&2"'.
            otherwise
                undo, throw new Progress.Lang.AppError("Unknown operator for filter.", 0).
        end.

        return cTemplate.
    end method. /* getMapping */

    method private character buildClause ( input poClause as JsonObject ):
        define variable cClause  as character  no-undo.
        define variable cField   as character  no-undo.
        define variable cOper    as character  no-undo.
        define variable cType    as character  no-undo.

        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.field */
        assign cOper = poClause:GetCharacter("operator").

        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.value */
        case cType:
            when "date":u then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetDate("value")).
            when "datetime":u then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetDatetime("value")).
            when "datetime-tz":u then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetDatetimeTZ("value")).
            when "decimal":u then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetDecimal("value")).
            when "integer":u then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetInteger("value")).
            when "logical":u then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetLogical("value")).
            otherwise
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetCharacter("value")).
        end.

        return cClause.
    end method. /* buildClause */

    method private character buildWherePhrase ( input pcWhere  as character,
                                                input poFilter as JsonObject ):
        define variable oFilters as JsonArray  no-undo.
        define variable oClause  as JsonObject no-undo.
        define variable cClause  as character  no-undo initial "".
        define variable cLogic   as character  no-undo initial "and".
        define variable ix       as integer    no-undo.

        if poFilter eq ? or not valid-object(poFilter) then return "".

        assign oFilters = getRawCriteria(poFilter). /* Obtain initial filters array. */

        if not valid-object(oFilters) or oFilters:length eq 0 then return pcWhere.

        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.logic */
        if poFilter:Has("logic") then
            assign cLogic = poFilter:GetCharacter("logic").

        filterblk:
        do ix = 1 to oFilters:Length:
            oClause = oFilters:GetJsonObject(ix).

            /* No point in creating a group for a single-clause filter, just promote object. */
            if oClause:Has("logic") and oClause:Has("filters") and
               oClause:GetType("filters") eq JsonDataType:array and
               oClause:GetJsonArray("filters"):length eq 1 then
                oClause = oClause:GetJsonArray("filters"):GetJsonObject(1).

            if oClause:Has("logic") then
                assign cClause = buildWherePhrase("", oClause).
            else
                assign cClause = buildClause(oClause).

            if (cClause gt "") eq true then do:
                if (pcWhere gt "") eq true then
                    assign pcWhere = substitute("&1 &2 &3",
                                                pcWhere, cLogic, cClause).
                else
                    assign pcWhere = cClause.
            end.
        end.

        return substitute("(&1)", trim(pcWhere)).

        finally:
            delete object oFilters no-error.
            delete object oClause  no-error.
        end finally.
    end method. /* buildWherePhrase */

    method private JsonArray getRawCriteria ( input poFilter as JsonObject ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.filters */
        if valid-object(poFilter) and poFilter:Has("filters") and
           poFilter:GetType("filters") eq JsonDataType:array then
            return poFilter:GetJsonArray("filters").

        return (new JsonArray()).
    end method. /* getRawCriteria */

    method private character buildWherePhrase ( input poFilter as JsonObject ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter */
        return buildWherePhrase("", poFilter).
    end method. /* buildWherePhrase */

    method private character buildSortPhrase ( input poOptions as JsonArray ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-sort */
        define variable oSortObj as JsonObject no-undo.
        define variable cSortBy  as character  no-undo.
        define variable iX       as integer    no-undo.

        if valid-object(poOptions) and poOptions:Length gt 0 then do:
            do iX = 1 to poOptions:length:
                assign oSortObj = poOptions:GetJsonObject(iX).
                assign cSortBy = substitute("&1 by &2 &3",
                                            cSortBy,
                                            oSortObj:GetCharacter("field"),
                                            if oSortObj:GetCharacter("dir") eq "asc":u
                                            then "" else "descending").
            end. /* do iX */
            assign cSortBy = trim(cSortBy).
        end. /* valid-object */

        return cSortBy.
    end method. /* buildOrderPhrase */

    /***** End Carry-Over from Spark KendoParse *****/

    /* Parses where/filter phrase and returns an IQueryEntry object for a single table
       
       @param P.L.Object The filter/where clause data
       @return IQueryEntry The query entry. We return one of an IQueryPredicate (single clause) 
                           or an IQueryGroup (many clauses) */
    method override public IQueryEntry ParseWhere (input pWhere as Progress.Lang.Object):
        if    not valid-object(pWhere)
           or not type-of(pWhere, JsonConstruct) 
        then
            return ?.
    end method.

    /* Parses an SORT-BY phrase and returns an array of IQuerySortEntry objects.
       
       @param P.L.Object The SORT-BY data
       @return IQuerySortEntry[] An array of sort phrases. An indeterminate array is returned if the input phrase is empty */
    method override public IQuerySortEntry extent ParseSortBy (input pSortBy as Progress.Lang.Object):
        define variable querySortEntry as QuerySortEntry no-undo extent.
        define variable oSortObj       as JsonObject     no-undo.
        define variable iX             as integer        no-undo.

        if    not valid-object(pSortBy)
           or not type-of(pSortBy, JsonConstruct) 
        then
            return querySortEntry.

        if type-of(pSortBy, JsonArray) and cast(pSortBy, JsonArray):Length gt 0 then do:
            /**
             * An extent must be specified, even if some of the fields are not valid for sorting.
             * Since we shouldn't have more sort entries than items in the array, use that count.
             */
            extent(querySortEntry) = cast(pSortBy, JsonArray):length.

            do iX = 1 to cast(pSortBy, JsonArray):length:
                assign oSortObj = cast(pSortBy, JsonArray):GetJsonObject(iX).
                /* Add a new sort entry object with field and direction. */
                querySortEntry[iX] = new QuerySortEntry(oSortObj:GetCharacter("field"), if oSortObj:GetCharacter("dir") eq "asc":u
                                                                                        then Ccs.BusinessLogic.SortOrderEnum:Ascending
                                                                                        else Ccs.BusinessLogic.SortOrderEnum:Descending).
            end. /* do iX */
        end. /* valid-object */

        return querySortEntry.
    end method.
    
    /* Reads and processes (parses) the filter.  
       
       @param P.L.Object The filter data
       @param IGetDataRequest A new filter object */
    method override public IGetDataRequest Parse (input pData as Progress.Lang.Object):
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