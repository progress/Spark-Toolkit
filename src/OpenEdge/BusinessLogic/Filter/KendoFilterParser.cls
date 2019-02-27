/* *************************************************************************************************************************
Copyright (c) 2019 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
************************************************************************************************************************** */
/*------------------------------------------------------------------------
    File        : KendoFilterParser
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : pjudge & dgrau
    Created     : Wed Dec 07 14:11:10 EST 2016
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Ccs.BusinessLogic.IGetDataRequest.
using Ccs.BusinessLogic.IGetDataTableRequest.
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

    define public property ProDataSet as handle no-undo
        get.
        set.

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

    method private handle getFieldBuffer ( input pcWebFieldName as character ):
        define variable bhTable as handle  no-undo.
        define variable bhField as handle  no-undo.
        define variable ix      as integer no-undo.

        /* Return the datatype of the field, if it exists. */
        if valid-handle(ProDataSet) then
            assign bhTable = ProDataSet:get-buffer-handle(1) no-error. /* Get top table. */
        else
            undo, throw new Progress.Lang.AppError("Invalid or unset handle to ProDataSet.").

        if valid-handle(bhTable) then do:
            do ix = 1 to bhTable:num-fields:
                assign bhField = bhTable:buffer-field(ix) no-error.
                /* Web-based field matches real name or serialized name. */
                if valid-handle(bhField) then do:
                    if bhField:name eq pcWebFieldName or
                       bhField:serialize-name eq pcWebFieldName then
                        return bhField.
                    else
                        delete object bhField no-error.
                end. /* valid-handle */
            end. /* do ix */
        end. /* valid-handle */

        return ?. /* Return ? to indicate field is not in temp-table. */

        finally:
            delete object bhTable no-error.
            delete object bhField no-error.
        end finally.
    end method. /* getFieldBuffer */

    method private character getMapping ( input pcKendoOperator as character,
                                          input pcFieldDataType as character ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.operator */
        define variable cTemplate as character no-undo.

        case pcKendoOperator:
            when "equals":u or
            when "eq":u then
                if pcFieldDataType eq "character" then
                    assign cTemplate = '&1 eq "&2"':u.
                else
                    assign cTemplate = '&1 eq &2':u.
            when "ne":u or
            when "neq":u then
                if pcFieldDataType eq "character" then
                    assign cTemplate = '&1 ne "&2"':u.
                else
                    assign cTemplate = '&1 ne &2':u.
            when "lt":u then
                assign cTemplate = '&1 lt &2':u.
            when "lte":u then
                assign cTemplate = '&1 le &2':u.
            when "gt":u then
                assign cTemplate = '&1 gt &2':u.
            when "gte":u then
                assign cTemplate = '&1 ge &2':u.
            when "startswith":u then
                assign cTemplate = '&1 begins "&2"':u.
            when "contains":u then
                assign cTemplate = '&1 matches "*&2*"':u.
            when "doesnotcontain":u then
                assign cTemplate = 'not (&1 matches "*&2*")':u.
            when "endswith":u then
                assign cTemplate = '&1 matches "*&2"':u.
            otherwise
                undo, throw new Progress.Lang.AppError("Unknown operator for filter.":u, 0).
        end.

        return cTemplate.
    end method. /* getMapping */

    method private JsonArray getFilters ( input poFilter as JsonObject ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.filters */
        if valid-object(poFilter) and poFilter:Has("filters") and
           poFilter:GetType("filters") eq JsonDataType:array then
            return poFilter:GetJsonArray("filters").

        return (new JsonArray()).
    end method. /* getFilters */

    method private character buildClause ( input poClause as JsonObject ):
        define variable hField   as handle     no-undo.
        define variable cClause  as character  no-undo.
        define variable cMapping as character  no-undo.
        define variable cField   as character  no-undo.
        define variable cOper    as character  no-undo.
        define variable cType    as character  no-undo.

        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.field */
        assign
            hField  = this-object:getFieldBuffer(poClause:GetCharacter("field"))
            cOper   = poClause:GetCharacter("operator")
            no-error.

        if not valid-handle(hField) then return "".

        assign
            cField = hField:name
            cType  = hField:data-type
            no-error.

        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.value */
        assign cMapping = this-object:getMapping(cOper, cType) no-error.
        case cType:
            when "character":u then
                assign cClause = substitute(cMapping, cField, poClause:GetCharacter("value")).
            when "date":u then
                assign cClause = substitute(cMapping, cField, poClause:GetDate("value")).
            when "datetime":u then
                assign cClause = substitute(cMapping, cField, poClause:GetDatetime("value")).
            when "datetime-tz":u then
                assign cClause = substitute(cMapping, cField, poClause:GetDatetimeTZ("value")).
            when "decimal":u then
                assign cClause = substitute(cMapping, cField, poClause:GetDecimal("value")).
            when "integer":u then
                assign cClause = substitute(cMapping, cField, poClause:GetInteger("value")).
            when "logical":u then
                assign cClause = substitute(cMapping, cField, poClause:GetLogical("value")).
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

        assign oFilters = getFilters(poFilter). /* Obtain initial filters array. */

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
                assign cClause = this-object:buildWherePhrase("", oClause).
            else
                assign cClause = this-object:buildClause(oClause).

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

    /***** End Carry-Over from Spark KendoParse *****/

    method protected IQueryEntry ParsePredicate (input pJoin as JoinEnum,
                                                 input pFilter as JsonObject):
        define variable oClause     as QueryPredicate    no-undo.
        define variable oFieldValue as class String      no-undo.
        define variable oJoinAs     as JoinEnum          no-undo.
        define variable oOperator   as QueryOperatorEnum no-undo.
        define variable cOperator   as character         no-undo.

        /* Field name must be present, otherwise we must skip. */
        if    not pFilter:Has("field":u)
           or not pFilter:GetType("field":u) eq JsonDataType:STRING
        then
            return ?.

        /* Field operator must be present, otherwise we must skip. */
        if    not pFilter:Has("operator":u)
           or not pFilter:GetType("operator":u) eq JsonDataType:STRING
        then
            return ?.

        /* Field Value */
        case pFilter:GetType("value":u):
            when JsonDataType:ARRAY  or
            when JsonDataType:OBJECT then
                undo, throw new AppError(substitute("Unsupported filter value type of JsonObject/JsonArray for field &1",
                                            pFilter:GetCharacter("field":u)), 0).

            when JsonDataType:NULL then
                assign oFieldValue = new OpenEdge.Core.String(StringConstant:UNKNOWN).

            // we don"t at this point know what the underlying schmema and data type are, so stringify it all
            otherwise
                assign oFieldValue = new OpenEdge.Core.String(pFilter:GetJsonText("value":u)).
        end case.

        assign cOperator = pFilter:GetCharacter("operator":u).
        case cOperator:
            /* First map complex operators. */

            when "isnull":u then
                assign oOperator   = QueryOperatorEnum:Eq
                       oFieldValue = new OpenEdge.Core.String(StringConstant:UNKNOWN)
                       .
            when "isnotnull":u then
                assign oOperator   = QueryOperatorEnum:Ne
                       oFieldValue = new OpenEdge.Core.String(StringConstant:UNKNOWN)
                       .
            when "isempty":u then
                assign oOperator   = QueryOperatorEnum:Eq
                       oFieldValue = new OpenEdge.Core.String("":u)
                       .
            when "isnotempty":u then
                assign oOperator   = QueryOperatorEnum:Ne
                       oFieldValue = new OpenEdge.Core.String("":u)
                       .
            when "endswith":u then
            do:
                assign oOperator = QueryOperatorEnum:Matches.
                oFieldValue:Prepend("*":u).
            end.
            when "doesnotcontain":u then
            do:
                assign oOperator = QueryOperatorEnum:Contains.
                if pJoin eq JoinEnum:And then
                    assign oJoinAs = JoinEnum:AndNot.
                else
                    assign oJoinAs = JoinEnum:OrNot.
            end.

            /* Simpler things are just mapped (EQ, NEQ, LTE, etc.) */
            otherwise
                assign oOperator = QueryOperatorHelper:ToEnum(cOperator).
        end case.

        assign oClause      = new QueryPredicate(pFilter:GetCharacter("field":u), oOperator, oFieldValue)
               oClause:Join = oJoinAs /* nulls are ok here */
               .

        return oClause.
    end method.

    method protected IQueryEntry ParseWhere (input pGroup  as QueryGroup,
                                             input pFilter as JsonObject):
        define variable iLoop       as integer           no-undo.
        define variable oFilters    as JsonArray         no-undo.
        define variable oFilter     as JsonObject        no-undo.

        if     pFilter:Has("logic":u)
           and pFilter:GetType("logic":u) eq JsonDataType:STRING
        then
            assign pGroup:join = JoinEnum:GetEnum(pFilter:GetCharacter("logic":u)).

        if     pFilter:Has("filters":u)
           and pFilter:GetType("filters":u) eq JsonDataType:ARRAY
        then
            assign oFilters = pFilter:GetJsonArray("filters":u).

        /* Set extent of QueryGroup entries equal to number of filters at this level. */
        extent(pGroup:Entries) = oFilters:length.

        /* Iterate over the filters as provided. */
        do iLoop = 1 to oFilters:length:
            if not oFilters:GetType(iLoop) eq JsonDataType:OBJECT then next.

            assign oFilter = oFilters:GetJsonObject(iLoop).
            if oFilter:Has("logic") then
                /* If the current object contains a "logic" property then this entry is a new group. */
                assign pGroup:Entries[iLoop] = this-object:ParseWhere(new QueryGroup(), oFilter).
            else
                /* Otherwise, the current object is destined to become a new QueryPredicate entry. */
                assign pGroup:Entries[iLoop] = this-object:ParsePredicate(pGroup:join, oFilter).
        end. /* iLoop */

        return pGroup.
    end method.

    /* Parses where/filter phrase and returns an IQueryEntry object for a single table
       http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter

       @param P.L.Object The filter/where clause data
       @return IQueryEntry The query entry. We return one of an IQueryPredicate (single clause)
                           or an IQueryGroup (many clauses) */
    method override public IQueryEntry ParseWhere (input pWhere as Progress.Lang.Object):
        define variable oJsonFilter as JsonObject no-undo.

        if not valid-object(pWhere) or not type-of(pWhere, JsonConstruct) then
            return new QueryGroup().

        /* Normalize the incoming filter data as a JSON object with a join logic. */
        if type-of(pWhere, JsonArray) then
        do:
            assign oJsonFilter = new JsonObject().
            oJsonFilter:Add("logic":u, JoinEnum:And:ToString()).
            oJsonFilter:Add("filters":u, cast(pWhere, JsonArray)).
        end.
        else if type-of(pWhere, JsonObject) then
            assign oJsonFilter = cast(pWhere, JsonObject).

        /* Return the final QueryGroup (IQueryEntry) as built by the expanded parser. */
        return this-object:ParseWhere(new QueryGroup(), oJsonFilter).
    end method.

    /* Parses an SORT-BY phrase and returns an array of IQuerySortEntry objects.
       http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-sort

       @param P.L.Object The SORT-BY data
       @return IQuerySortEntry[] An array of sort phrases. An indeterminate array is returned if the input phrase is empty */
    method override public IQuerySortEntry extent ParseSortBy (input pSortBy as Progress.Lang.Object):
        define variable oSortEntry as QuerySortEntry no-undo extent.
        define variable oSortObj   as JsonObject     no-undo.
        define variable hField     as handle         no-undo.
        define variable iX         as integer        no-undo.

        if not valid-object(pSortBy) or not type-of(pSortBy, JsonConstruct) then
            return oSortEntry.

        if type-of(pSortBy, JsonArray) and cast(pSortBy, JsonArray):Length gt 0 then do:
            /**
             * An extent must be specified, even if some of the fields are not valid for sorting.
             * Since we shouldn't have more sort entries than items in the array, use that count.
             */
            extent(oSortEntry) = cast(pSortBy, JsonArray):length.

            do iX = 1 to cast(pSortBy, JsonArray):length:
                assign oSortObj = cast(pSortBy, JsonArray):GetJsonObject(iX).
                assign hField = this-object:getFieldBuffer(oSortObj:GetCharacter("field":u)).
                if valid-handle(hField) then do:
                    /* Add a new sort entry object with field and direction. */
                    oSortEntry[iX] = new QuerySortEntry(hField:name, if oSortObj:GetCharacter("dir":u) eq "asc":u
                                                                     then Ccs.BusinessLogic.SortOrderEnum:Ascending
                                                                     else Ccs.BusinessLogic.SortOrderEnum:Descending).
                end. /* valid-handle */
            end. /* do iX */
        end. /* valid-object */

        return oSortEntry.
    end method.

    /* Reads and processes (parses) the filter.

       @param P.L.Object The filter data
       @param IGetDataRequest A new filter object */
    method override public IGetDataRequest Parse (input pData as Progress.Lang.Object):
        define variable dataRequest as GetDataRequest no-undo.

        assign dataRequest = new GetDataRequest().

        /*
         * {
         *   "mappingType": "kendo",
         *   "filter": ~{"logic": "and", "filters": []},
         *   "sort": [],
         *   "skip": 40,
         *   "top": 20
         * }
         */

        if    not valid-object(pData)
           or not type-of(pData, JsonConstruct)
        then
            return dataRequest.

        if type-of(pData, JsonObject) then
        do:
            /* There should be only 1 table and filter data should be a JsonObject. */
            assign extent(dataRequest:TableRequests) = 1
                   dataRequest:TableRequests[1]      = ParseTableRequest(this-object:FilterTable[1],
                                                                         cast(pData, JsonObject))
                   .
        end.

        return dataRequest.
    end method.

    /* Reads a single table's request.

       This method knows which properties in the input JSON are for the where clause, for the sort-by etc

       @param character The table name to which this filter applies
       @param JsonObject The input filter
       @return IGetDataTableRequest A single table Get Request */
    method protected IGetDataTableRequest ParseTableRequest (input pTable as character,
                                                             input pData as JsonObject):
        define variable tableRequest as GetDataTableRequest no-undo.
        define variable qryDef as QueryDefinition no-undo.

        assign tableRequest = new GetDataTableRequest(pTable). // we don't know the table name here

        if not valid-object(pData) then
            return tableRequest.

        assign qryDef                       = new QueryDefinition()
               tableRequest:QueryDefinition = qryDef
               .

        /* Should be "sort" though for backwards compatibility look for "orderBy" just in case. */
        if     pData:Has("sort":u)
           and pData:GetType("sort":u) eq JsonDataType:ARRAY
        then
            assign qryDef:QuerySort = this-object:ParseSortBy(pData:GetJsonArray("sort":u)).
        else if     pData:Has("orderBy":u)
                and pData:GetType("orderBy":u) eq JsonDataType:ARRAY
        then
            assign qryDef:QuerySort = this-object:ParseSortBy(pData:GetJsonArray("orderBy":u)).

        /* Should have either a "filter" object or "filters" array. */
        if    pData:Has("filter":u)
          and pData:GetType("filter":u) eq JsonDataType:OBJECT
        then
            assign qryDef:QuerySelection = this-object:ParseWhere(pData:GetJsonObject("filter":u)).
        else if    pData:Has("filters":u)
               and pData:GetType("filters":u) eq JsonDataType:ARRAY
        then
            assign qryDef:QuerySelection = this-object:ParseWhere(pData:GetJsonArray("filters":u)).

        if     pData:Has("id":u)
           and pData:GetType("id":u) eq JsonDataType:STRING
        then
            assign tableRequest:PagingContext = pData:GetCharacter("id":u).

        if     pData:Has("top":u)
           and pData:GetType("top":u) eq JsonDataType:NUMBER
        then
            assign tableRequest:NumRecords = pData:GetInt64("top":u).

        if     pData:Has("skip":u)
           and pData:GetType("skip":u) eq JsonDataType:NUMBER
        then
            assign tableRequest:Skip = pData:GetInt64("skip":u).

        return cast(tableRequest, IGetDataTableRequest).
    end method.

end class.