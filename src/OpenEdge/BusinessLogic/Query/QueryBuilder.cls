/* *************************************************************************************************************************
Copyright (c) 2019 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
************************************************************************************************************************** */
/*------------------------------------------------------------------------
    File        : QueryBuilder
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge & dugrau
    Created     : Thu May 10 12:38:00 EDT 2018
    Notes       : ADAS-101
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Ccs.Common.Support.*.
using Ccs.BusinessLogic.IGetDataRequest.
using Ccs.BusinessLogic.JoinEnum.
using Ccs.BusinessLogic.QueryOperatorEnum.
using OpenEdge.BusinessLogic.GetDataTableRequest.
using OpenEdge.BusinessLogic.QueryDefinition.
using OpenEdge.BusinessLogic.QueryGroup.
using OpenEdge.BusinessLogic.QueryPredicate.
using OpenEdge.BusinessLogic.QuerySortEntry.
using OpenEdge.BusinessLogic.Query.QueryBuilder.

class OpenEdge.BusinessLogic.Query.QueryBuilder: 

    /***** Begin Protected Methods *****/

    method protected static handle GetTableBuffer (input phDataSet as handle,
                                                   input piTable   as integer):
        return phDataSet:get-buffer-handle(piTable). /* Get the requested table by number. */.
    end method. /* GetTableBuffer */

    method protected static handle GetFieldBuffer (input phTable     as handle,
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

        return ?. /* Return unknown value to indicate field is not in the temp-table. */

        finally:
            delete object bhField no-error.
        end finally.
    end method. /* GetFieldBuffer */

    method protected static character MapOperator (input poOperator as QueryOperatorEnum,
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
    end method. /* MapOperator */

    method protected static character MapJoin (input pcQuery  as character,
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
    end method. /* MapJoin */

    method protected static character BuildGroup (input phTable as handle,
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
                assign cClause = QueryBuilder:BuildGroup(phTable, cast(poGroup:Entries[iLoop], QueryGroup))
                       oJoinAs = poGroup:join /* Use the overall group join. */
                       .
            else
                /* Create a simple clause frmo the given predicate. */
                assign cClause = QueryBuilder:BuildClause(phTable, cast(poGroup:Entries[iLoop], QueryPredicate))
                       oJoinAs = cast(poGroup:Entries[iLoop], QueryPredicate):Join
                       .

            /* Continue with joining the clause (single or nested) to the query if non-blank. */
            if (cClause gt "") eq true then
                assign cQueryString = QueryBuilder:MapJoin(cQueryString, cClause, oJoinAs).
        end. /* Looping Entries */

        return cQueryString.
    end method. /* BuildGroup */

    method protected static character BuildClause (input phTable  as handle,
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
        assign hField = QueryBuilder:GetFieldBuffer(phTable, poClause:FieldName) no-error.

        if valid-handle(hField) then
            assign
                cField = hField:name
                cType  = hField:data-type
                .
        else
        do:
            assign cField = poClause:FieldName.

            /**
             * Note: There is no expectation that JSON data will map to RowID, Memptr,
             * or Handle datatypes so those are omitted from detection.
             */

            case true:
                when not valid-object(poClause:Value) and
                     not valid-object(poClause:Values) then
                    assign cType = "character".

                when type-of(poClause:Value, ILongcharHolder) or
                when type-of(poClause:Value, ILongcharArrayHolder) or
                when type-of(poClause:Value, ICharacterHolder) or
                when type-of(poClause:Value, ICharacterArrayHolder) then
                    assign cType = "character".

                when type-of(poClause:Value, IDateHolder) or
                when type-of(poClause:Value, IDateArrayHolder) then
                    assign cType = "date".

                when type-of(poClause:Value, IDateTimeHolder) or
                when type-of(poClause:Value, IDateTimeArrayHolder) then
                    assign cType = "datetime".

                when type-of(poClause:Value, IDateTimeTzHolder) or
                when type-of(poClause:Value, IDateTimeTzArrayHolder) then
                    assign cType = "datetime-tz".

                when type-of(poClause:Value, IDecimalHolder) or
                when type-of(poClause:Value, IDecimalArrayHolder) then
                    assign cType = "decimal".

                when type-of(poClause:Value, IInt64Holder) or
                when type-of(poClause:Value, IInt64arrayHolder) or
                when type-of(poClause:Value, IIntegerHolder) or
                when type-of(poClause:Value, IIntegerArrayHolder) then
                    assign cType = "integer".

                when type-of(poClause:Value, ILogicalHolder) or
                when type-of(poClause:Value, ILogicalArrayHolder) then
                    assign cType = "logical".
            
                otherwise
                    assign cType = "character".
            end case.
        end.


        /* Based on the datatype, convert the value and obtain a valid operation string. */
        /* Note: This currently assumes the incoming value is an OpenEdge.Core.String. */
        case cType:
            when "character" then
                assign cClause = substitute(QueryBuilder:MapOperator(poClause:Operator, cType),
                                            cField, poClause:Value:ToString()).
            when "date" then
                assign cClause = substitute(QueryBuilder:MapOperator(poClause:Operator, cType),
                                            cField, date(poClause:Value:ToString())).
            when "datetime" then
                assign cClause = substitute(QueryBuilder:MapOperator(poClause:Operator, cType),
                                            cField, datetime(poClause:Value:ToString())).
            when "datetime-tz" then
                assign cClause = substitute(QueryBuilder:MapOperator(poClause:Operator, cType),
                                            cField, datetime-tz(poClause:Value:ToString())).
            when "decimal" then
                assign cClause = substitute(QueryBuilder:MapOperator(poClause:Operator, cType),
                                            cField, decimal(poClause:Value:ToString())).
            when "integer" then
                assign cClause = substitute(QueryBuilder:MapOperator(poClause:Operator, cType),
                                            cField, integer(poClause:Value:ToString())).
            when "logical" then
                assign cClause = substitute(QueryBuilder:MapOperator(poClause:Operator, cType),
                                            cField, logical(poClause:Value:ToString())).
        end.

        return cClause.
    end method. /* BuildClause */

    /***** End Protected / Begin Public *****/

    /* Builds a query handle (object) from a IGetDataRequest object. This method maps
       the input names to the input handle's SERIALIZE-NAMEs and uses the 'real'
       names to build the where clause
       
       @param IGetDataRequest A valid queryn definition
       @param handle a Dataset or buffer (TT or DB) handle 
       @return handle A valid QUERY handle */
    method public static handle BuildQuery (input pFilter as IGetDataRequest,
                                            input pSchema as handle):
        define variable hQuery as handle no-undo.

        create query hQuery.
        hQuery:set-buffers(pSchema).
        hQuery:query-prepare(substitute("for each &1 &2", pSchema:name, QueryBuilder:BuildQueryString(pFilter, pSchema))).
        hQuery:query-open.

        return hQuery.
    end method. /* BuildQueryString */

    /* Builds a query string from a IGetDataRequest object. This method does
       no name conversions - just takes the names from the input object.
       
       @param IGetDataRequest A valid queryn definition
       @return character A complete WHERE clause , with no name conversions */
    method public static character BuildQueryString (input pFilter as IGetDataRequest):
        /**
         * Call internal method with filter but no schema. However, due to the
         * need to utilize schema for detecting real field names (from public,
         * serialized names) and field datatypes this will likely result in a
         * thrown error. It is far better to call this method directly with a
         * dataset or temp-table handle.
         */
        return BuildQueryString(pFilter, ?).
    end method. /* BuildQueryString */

    /* Builds a query string from a IGetDataRequest object. This method maps
       the input names to the input handle's SERIALIZE-NAMEs and uses the 'real'
       names to build the where clause
       
       @param IGetDataRequest A valid queryn definition
       @param handle a Dataset or buffer (TT or DB) handle 
       @return character A complete WHERE clause */
    method public static character BuildQueryString (input pFilter as IGetDataRequest,
                                                     input pSchema as handle):
        define variable oQueryDef    as QueryDefinition no-undo.
        define variable oSortList    as QuerySortEntry  no-undo extent.
        define variable cQueryString as character       no-undo initial "".
        define variable bhTable      as handle          no-undo.
        define variable bhField      as handle          no-undo.
        define variable iLoop        as integer         no-undo.
        define variable cSortBy      as character       no-undo.

        if valid-handle(pSchema) and pSchema:type eq "dataset" then
            assign bhTable = QueryBuilder:GetTableBuffer(pSchema, 1). /* Get the top table. */
        else if valid-handle(pSchema) and pSchema:type eq "temp-table" then
            assign bhTable = pSchema. /* Use given temp-table handle as-is. */

        assign oQueryDef = cast(pFilter:TableRequests[1]:QueryDefinition, QueryDefinition).
        assign oSortList = cast(oQueryDef:QuerySort, QuerySortEntry).

        /* Build either a nested query or a simple clause, depending on the object available. */
        if type-of(oQueryDef:QuerySelection, QueryGroup) then
            assign cQueryString = QueryBuilder:BuildGroup(bhTable, cast(oQueryDef:QuerySelection, QueryGroup)).
        else if type-of(oQueryDef:QuerySelection, QueryPredicate) then
            assign cQueryString = QueryBuilder:BuildClause(bhTable, cast(oQueryDef:QuerySelection, QueryPredicate)).

        if extent(oSortList) ne ? then
        do iLoop = 1 to extent(oSortList):
            if valid-object(oSortList[iLoop]) then do:
                /* Create the sort clause based on the real field information. */
                assign bhField = QueryBuilder:GetFieldBuffer(bhTable, oSortList[iLoop]:FieldName).
                if valid-object(bhField) then
                    assign cSortBy = trim(substitute("&1 by &2 &3", cSortBy, bhField:name,
                                                     if oSortList[iLoop]:SortOrder eq Ccs.BusinessLogic.SortOrderEnum:Ascending
                                                     then "" else oSortList[iLoop]:SortOrder:ToString())).
                else /* Otherwise use the given field name. */
                    assign cSortBy = trim(substitute("&1 by &2 &3", cSortBy, oSortList[iLoop]:FieldName,
                                                     if oSortList[iLoop]:SortOrder eq Ccs.BusinessLogic.SortOrderEnum:Ascending
                                                     then "" else oSortList[iLoop]:SortOrder:ToString())).
            end. /* Valid Sort Entry*/
        end. /* do iLoop */

        /* Ensure a blank string becomes a valid query phrase. */
        if trim(cQueryString) eq "" then
            assign cQueryString = "where true".

        /* Add a "where" as necessary to the constructed string. */
        if not cQueryString begins "where" then
            assign cQueryString = substitute("where &1", cQueryString).

        /* Add the sort phrase to the string. */
        assign cQueryString = substitute("&1 &2", cQueryString, cSortBy).

        /* If the QueryString property is empty, provide the derived query string. */
        if (pFilter:TableRequests[1]:QueryString gt "") ne true then
            cast(pFilter:TableRequests[1], GetDataTableRequest):QueryString = cQueryString.

        finally:
            return trim(cQueryString).
        end finally.
    end method. /* BuildQueryString */
    
end class.