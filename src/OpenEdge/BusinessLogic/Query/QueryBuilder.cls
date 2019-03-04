/* *************************************************************************************************************************
Copyright (c) 2019 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
************************************************************************************************************************** */
/*------------------------------------------------------------------------
    File        : QueryBuilder
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Thu May 10 12:38:00 EDT 2018
    Notes       : ADAS-101
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Ccs.BusinessLogic.IGetDataRequest.
using Ccs.BusinessLogic.IQueryEntry.
using Ccs.BusinessLogic.JoinEnum.
using Ccs.BusinessLogic.QueryOperatorEnum.
using OpenEdge.BusinessLogic.*.
using OpenEdge.BusinessLogic.Filter.*.

class OpenEdge.BusinessLogic.Query.QueryBuilder: 

    method protected handle getFieldBuffer (input phTable     as handle,
                                            input pcFieldName as character):
        define variable bhField as handle  no-undo.
        define variable ix      as integer no-undo.

        /* Return the datatype of the field, if it exists in the table. */
        if valid-handle(phTable) then do:
            do ix = 1 to phTable:num-fields:
                assign bhField = phTable:buffer-field(ix) no-error.
                /* Web-based field matches real name or serialized name. */
                if valid-handle(bhField) then do:
                    if bhField:name eq pcFieldName or
                       bhField:serialize-name eq pcFieldName then
                        return bhField.
                    else
                        delete object bhField no-error.
                end. /* valid-handle */
            end. /* do ix */
        end. /* valid-handle */

        return ?. /* Return ? to indicate field is not in temp-table. */

        finally:
            delete object bhField no-error.
        end finally.
    end method. /* getFieldBuffer */

    method private character mapOperator (input poOperator as QueryOperatorEnum,
                                          input pcDataType as character ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.operator */
        define variable cTemplate as character no-undo.

        case poOperator:
            when QueryOperatorEnum:Eq then
                if pcDataType eq "character" then
                    assign cTemplate = '&1 eq "&2"'.
                else
                    assign cTemplate = '&1 eq &2'.
            when QueryOperatorEnum:Ne then
                if pcDataType eq "character" then
                    assign cTemplate = '&1 ne "&2"'.
                else
                    assign cTemplate = '&1 ne &2'.
            when QueryOperatorEnum:Lt then
                assign cTemplate = '&1 lt &2'.
            when QueryOperatorEnum:Le then
                assign cTemplate = '&1 le &2'.
            when QueryOperatorEnum:Gt then
                assign cTemplate = '&1 gt &2'.
            when QueryOperatorEnum:Ge then
                assign cTemplate = '&1 ge &2'.
            when QueryOperatorEnum:Begins then
                assign cTemplate = '&1 begins "&2"'.
            when QueryOperatorEnum:Contains then
                assign cTemplate = '&1 matches "&2"'. /* Value should already be appended/prepended with '*'. */
            when QueryOperatorEnum:Matches then
                assign cTemplate = '&1 matches "&2"'. /* Value should already be appended/prepended with '*'. */
            otherwise
                undo, throw new Progress.Lang.AppError(substitute("Unknown operator '&1' for filter.", poOperator:ToString()), 0).
        end case.

        return cTemplate.
    end method. /* mapOperator */

    method private character mapJoin (input pcQuery  as character,
                                      input pcClause as character,
                                      input poJoinAs as JoinEnum):
        if pcQuery eq "" then
            /* When query string is blank, only provide negations as needed. */
            case poJoinAs:
                when JoinEnum:AndNot or
                when JoinEnum:OrNot or
                when JoinEnum:Not then
                    assign pcQuery = substitute("(not &1)", pcClause).
                otherwise
                    assign pcQuery = substitute("(&1)", pcClause).
            end case.
        else
            /* Otherwise join clause to query as described by join. */
            case poJoinAs:
                when JoinEnum:And then
                    assign pcQuery = substitute("&1 and (&2)", pcQuery, pcClause).
                when JoinEnum:AndNot then
                    assign pcQuery = substitute("&1 and (not &2)", pcQuery, pcClause).
                when JoinEnum:Or then
                    assign pcQuery = substitute("&1 or (&2)", pcQuery, pcClause).
                when JoinEnum:OrNot then
                    assign pcQuery = substitute("&1 or (not &2)", pcQuery, pcClause).
                when JoinEnum:None then
                    assign pcQuery = substitute("(&1)", pcClause). /* No join operator. */
                when JoinEnum:Not then
                    assign pcQuery = substitute("(not &1)", pcClause). /* Negate only. */
            end case.

        return pcQuery.
    end method. /* mapJoin */

    method private character buildGroup (input phTable  as handle,
                                         input poGroup as QueryGroup):
        define variable cQueryString as character no-undo initial "".
        define variable cClause      as character no-undo.
        define variable iLoop        as integer   no-undo.
        define variable oJoinAs      as JoinEnum  no-undo.

        /**
         * Note: This is a recursive method, as the provided group may consist of either only
         * query predicates (field, operator, value) or an entire group (nested query). For the
         * case of a group the object will be fed into another call to this method which will
         * result in a nested (bracketed) query clause.
         */

        if extent(poGroup:Entries) ne ? and extent(poGroup:Entries) ge 1 then
        do iLoop = 1 to extent(poGroup:Entries):
            if type-of(poGroup:Entries[iLoop], QueryGroup) then
                /* Create a nested query from this child group. */
                assign cClause = this-object:buildGroup(phTable, cast(poGroup:Entries[iLoop], QueryGroup))
                       oJoinAs = poGroup:join /* Use the overall group join. */
                       .
            else
                /* Create a simple clause frmo the given predicate. */
                assign cClause = this-object:buildClause(phTable, cast(poGroup:Entries[iLoop], QueryPredicate))
                       oJoinAs = cast(poGroup:Entries[iLoop], QueryPredicate):Join
                       .

            /* Continue with joining the clause (single or nested) to the query if non-blank. */
            if (cClause gt "") eq true then
                assign cQueryString = this-object:mapJoin(cQueryString, cClause, oJoinAs).
        end. /* Looping Entries */

        return cQueryString.
    end method. /* buildGroup */

    method private character buildClause (input phTable  as handle,
                                          input poClause as QueryPredicate):
        define variable hField   as handle     no-undo.
        define variable cClause  as character  no-undo.
        define variable cField   as character  no-undo.
        define variable cOper    as character  no-undo.
        define variable cType    as character  no-undo.

        /**
         * This should be the raw (public) field as provided by the front-end and must be mapped to a
         * valid internal temp-table field. This may be a serialized name, though the resulting field
         * buffer should be used to extract the real field name. Additionally, it may be impossible to
         * determine the correct datatype without assistance from the field buffer, so that too will be
         * used to convert the value appropriately for the resulting query phrase. 
         */
        assign hField = this-object:getFieldBuffer(phTable, poClause:FieldName) no-error.

        if not valid-handle(hField) then return "".

        assign
            cField = hField:name
            cType  = hField:data-type
            .

        /* Based on the datatype, convert the value and obtain a valid operation string. */
        case cType:
            when "character" then
                assign cClause = substitute(this-object:mapOperator(poClause:Operator, cType),
                                            cField, string(poClause:Value)).
            when "date" then
                assign cClause = substitute(this-object:mapOperator(poClause:Operator, cType),
                                            cField, date(string(poClause:Value))).
            when "datetime" then
                assign cClause = substitute(this-object:mapOperator(poClause:Operator, cType),
                                            cField, datetime(string(poClause:Value))).
            when "datetime-tz" then
                assign cClause = substitute(this-object:mapOperator(poClause:Operator, cType),
                                            cField, datetime-tz(string(poClause:Value))).
            when "decimal" then
                assign cClause = substitute(this-object:mapOperator(poClause:Operator, cType),
                                            cField, decimal(poClause:Value)).
            when "integer" then
                assign cClause = substitute(this-object:mapOperator(poClause:Operator, cType),
                                            cField, integer(poClause:Value)).
            when "logical" then
                assign cClause = substitute(this-object:mapOperator(poClause:Operator, cType),
                                            cField, logical(poClause:Value)).
        end.

        return cClause.
    end method. /* buildClause */

    /* Builds a query handle (object) from a IGetDataRequest object. This method maps
       the input names to the input handle's SERIALIZE-NAMEs and uses the 'real'
       names to build the where clause
       
       @param IGetDataRequest A valid queryn definition
       @param handle a Dataset or buffer (TT or DB) handle 
       @return handle A valid QUERY handle */
    method public handle BuildQuery (input pFilter as IGetDataRequest,
                                     input pSchema as handle):
    end method.
    
    /* Builds a query string from a IGetDataRequest object. This method does
       no name conversions - just takes the names from the input object.
       
       @param IGetDataRequest A valid queryn definition
       @return character A complete WHERE clause , with no name conversions */
    method public character BuildQueryString (input pFilter as IGetDataRequest):
        return BuildQueryString(pFilter, ?).
    end method.
    
    /* Builds a query string from a IGetDataRequest object. This method maps
       the input names to the input handle's SERIALIZE-NAMEs and uses the 'real'
       names to build the where clause
       
       @param IGetDataRequest A valid queryn definition
       @param handle a Dataset or buffer (TT or DB) handle 
       @return character A complete WHERE clause */
    method public character BuildQueryString (input pFilter as IGetDataRequest,
                                              input pSchema as handle):
        define variable oQueryDef     as QueryDefinition no-undo.
        define variable cQueryString  as character       no-undo initial "".
        define variable oSortList     as QuerySortEntry  no-undo extent.
        define variable bhTable       as handle          no-undo.
        define variable bhField       as handle          no-undo.
        define variable iLoop         as integer         no-undo.
        define variable cSortBy       as character       no-undo.

        if valid-handle(pSchema) then
            assign bhTable = pSchema:get-buffer-handle(1) no-error. /* Get the top table. */
        else
            undo, throw new Progress.Lang.AppError("Invalid or unset handle to ProDataSet.").

        assign oQueryDef = cast(pFilter:TableRequests[1]:QueryDefinition, QueryDefinition).
        assign oSortList = cast(oQueryDef:QuerySort, QuerySortEntry).

        /* Build either a nested query or a simple clause, depending on the object available. */
        if type-of(oQueryDef:QuerySelection, QueryGroup) then
            assign cQueryString = this-object:buildGroup(bhTable, cast(oQueryDef:QuerySelection, QueryGroup)).
        else if type-of(oQueryDef:QuerySelection, QueryPredicate) then
            assign cQueryString = this-object:buildClause(bhTable, cast(oQueryDef:QuerySelection, QueryPredicate)).

        if extent(oSortList) ne ? then
        do iLoop = 1 to extent(oSortList):
            if valid-object(oSortList[iLoop]) then do:
                /* Create the sort clause based on the real field information. */
                assign bhField = getFieldBuffer(bhTable, oSortList[iLoop]:FieldName).
                if valid-object(bhField) then
                    assign cSortBy = trim(substitute("&1 by &2 &3", cSortBy, bhField:name,
                                                     if oSortList[iLoop]:SortOrder eq Ccs.BusinessLogic.SortOrderEnum:Ascending
                                                     then "" else oSortList[iLoop]:SortOrder:ToString())).
            end. /* Valid Sort Entry*/
        end. /* do iLoop */

        if trim(cQueryString) eq "" then
            assign cQueryString = "where true".

        if not cQueryString begins "where" then
            assign cQueryString = substitute("where &1", cQueryString).

        assign cQueryString = substitute("&1 &2", cQueryString, cSortBy).

message "QueryString:" cQueryString.

        return trim(cQueryString).
    end method.
    
end class.