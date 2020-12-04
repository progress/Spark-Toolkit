/************************************************
Copyright (c) 2018, 2020 by Progress Software Corporation. All rights reserved.
*************************************************/
/*------------------------------------------------------------------------
    File        : AblFilterParser
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : pjudge
    Created     : Wed Dec 07 14:11:10 EST 2016
    Notes       : * String with "WHERE"...
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Ccs.BusinessLogic.IGetDataRequest.
using Ccs.BusinessLogic.IGetDataTableRequest.
using Ccs.BusinessLogic.IQueryEntry.
using Ccs.BusinessLogic.IQuerySortEntry.
using Ccs.BusinessLogic.JoinEnum.
using Ccs.BusinessLogic.QueryOperatorEnum.
using Ccs.BusinessLogic.SortOrderEnum.
using Ccs.Common.Support.ICharacterArrayHolder.
using Ccs.Common.Support.ICharacterHolder.
using Ccs.Common.Support.ILongcharArrayHolder.
using Ccs.Common.Support.ILongcharHolder.
using Ccs.Common.Support.IPrimitiveHolder.
using OpenEdge.BusinessLogic.Filter.FilterParser.
using OpenEdge.BusinessLogic.GetDataRequest.
using OpenEdge.BusinessLogic.GetDataTableRequest.
using OpenEdge.BusinessLogic.QueryDefinition.
using OpenEdge.BusinessLogic.QueryGroup.
using OpenEdge.BusinessLogic.QueryOperatorHelper.
using OpenEdge.BusinessLogic.QueryPredicate.
using OpenEdge.BusinessLogic.QuerySortEntry.
using OpenEdge.Core.Assert.
using OpenEdge.Core.Collections.IList.
using OpenEdge.Core.Collections.List.
using OpenEdge.Core.Collections.ObjectStack.
using OpenEdge.Core.String.
using OpenEdge.Core.StringConstant.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonDataType.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.AppError.

class OpenEdge.BusinessLogic.Filter.AblFilterParser inherits FilterParser:

    /* Default constructor */
    constructor public AblFilterParser():
        super().
    end constructor.

    /* Constructor.

       @param longchar (mandatory) A table name for which to construct the filter */
    constructor public AblFilterParser(input pTable as character):
        super(pTable).
    end constructor.

    /* Constructor.

       @param longchar[] (mandatory) An array of table name for which to construct the filter */
    constructor public AblFilterParser(input pTable as character extent):
        super(pTable).
    end constructor.

    /* Parses an ABL BY expression into an array of IQuerySortEntry.

       If the string is malformed (ie can't be used as an ABL sort), then an indeterminate array
       is returned. mallformed might be something like "by eq 21" or "by".

       @param longchar The standard ABL BY expression. This can be a complete WHERE ... BY string or just the BY portion
       @return IQuerySortEntry[] An array of sort entries. Will be indeterminate if the input value is empty or null,
                                 or if the string isn't of the format "BY <field> [BY <field-2>]"       */
    method protected IQuerySortEntry extent ParseSortString(input pSortBy as longchar):
        define variable querySortEntry as IQuerySortEntry extent no-undo.
        define variable sortOrder as SortOrderEnum no-undo.
        define variable elems as integer no-undo.
        define variable endPos as integer no-undo.
        define variable startPos as integer no-undo.
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.
        define variable fieldName as character no-undo.
        define variable sortDirection as character no-undo.
        define variable word as character no-undo.

        if String:IsNullOrEmpty(pSortBy) then
            return querySortEntry.

        // pad the sort phrase with a space to make our calculations easier
        assign pSortBy  = StringConstant:SPACE + pSortBy
               startPos = index(pSortBy, ' by ':u)
               elems     = 0
               .
        EXPR-LOOP:
        do while startPos gt 0:
            // if there are quotes after the " by " then this is a field name
            assign endPos = index(pSortBy, StringConstant:DOUBLE_QUOTE, startPos + 4).
            if endPos eq 0 then
                assign endPos = index(pSortBy, StringConstant:SINGLE_QUOTE, startPos + 4).
            if endPos eq 0 then
                // if there are quotes after the " by " then this is part of some function
                assign endPos = index(pSortBy, ')':u, startPos + 4).
            if not endPos eq 0 then
            do:
                // is there a by clause?
                assign startPos = index(pSortBy, ' by ':u, endPos).
                next EXPR-LOOP.
            end.
            // we're at the start of the 'real' BY expression
            assign pSortBy  = substring(pSortBy, startPos + 1)
                   startPos = 0
                   .
        end.    //EXPR-LOOP

        assign pSortBy = trim(replace(pSortBy, '  ':u, StringConstant:SPACE))
               cnt     = num-entries(pSortBy, StringConstant:SPACE)
               .

        BY-LOOP:
        do loop = 1 to cnt:
            assign word = entry(loop, pSortBy, StringConstant:SPACE).

            // count the occurrences of "by"
            if word eq 'by':u then
                assign elems = elems + 1.
        end. //BY-LOOP

        extent(querySortEntry) = elems.
        elems = 0. /* Reset before running loop again. */

        WORD-LOOP:
        do loop = 1 to cnt:
            assign word = entry(loop, pSortBy, StringConstant:SPACE).

            // if there are double spaces, skip
            if word eq '':u then
                next WORD-LOOP.

            // we want to start at BY and go from there
            // if this is not a BY then we've got a malformed string,
            // and we don't return anything
            if not word eq 'by':u then
            do:
                assign extent(querySortEntry) = ?.
                return querySortEntry.
            end.

            // BY <field> or BY <field> <order>
            assign fieldName = entry(loop + 1, pSortBy, StringConstant:SPACE).
            //is there an order?
            if (loop + 2) le cnt then
                assign sortDirection = entry(loop + 2, pSortBy, StringConstant:SPACE).
            else
                assign sortDirection = '':u.

            // another by or end-of-string
            if sortDirection begins 'desc':u then
                assign sortOrder = SortOrderEnum:Descending
                       loop      = loop + 2
                       .
            else
            if sortDirection begins 'asc':u then
                assign sortOrder = SortOrderEnum:Ascending
                       loop      = loop + 2
                       .
            else
                assign sortOrder = SortOrderEnum:Ascending
                       loop     = loop + 1
                       .

            assign elems                 = elems + 1
                   querySortEntry[elems] = new QuerySortEntry(fieldName, sortOrder)
                   .
        end. //WORD-LOOP

        return querySortEntry.
    end method.

    /* Parses a where string into a query entry - either a group or a predicate.

       If the parsing runs into problems (eg a malformed string) a null IQueryEntry is returned.
       Splitting of a string into groups using "(<grp-1>)" is not supported.

       @param longchar The WHERE string to parse into parts
       @return IQueryEntry A query group, query predicate or unknown (if the string cannot be parsed) */
    method protected IQueryEntry ParseWhereString(input pWhere as longchar):
        define variable groupStack as ObjectStack no-undo.
        define variable qryPredicate as QueryPredicate no-undo.
        define variable operator as QueryOperatorEnum no-undo.
        define variable fieldValue as IPrimitiveHolder no-undo.
        define variable qryGroup as QueryGroup no-undo.
        define variable haveValue as logical initial no no-undo.
        define variable haveName as logical initial no no-undo.
        define variable haveOperator as logical initial no no-undo.
        define variable inSingleQuotes as logical initial no no-undo.
        define variable inDoubleQuotes as logical initial no no-undo.
        define variable inParens as logical initial no no-undo.
        define variable isQuotedNull as logical initial no no-undo.
        define variable fieldName as character no-undo.
        define variable chrValue as character no-undo.
        define variable strValue as character no-undo.
        define variable nextChr as character no-undo.
        define variable loop as integer no-undo.
        define variable len as integer no-undo.
        define variable numPred as integer no-undo.

        // WHERE table.field<operator><value> {and|or|,}
        assign pWhere = trim(pWhere).
        // don't use TRIM since it doesn't always do what you think
        if pWhere begins 'where ':u then
            assign pWhere = substring(pWhere, 7).

        assign len = length(pWhere).
        if String:IsNullOrEmpty(pWhere) then
            return qryPredicate.

        CHR-LOOP:
        do loop = 1 to len:
            // read chars until we hit a space or an operator.
            assign chrValue  = substring(pWhere, loop, 1).

            // complete the string, since we'll process it below
            if loop eq len then
            do:
                // are we quoted? Close quotes if necessary
                if chrValue eq StringConstant:SINGLE_QUOTE then
                do:
                    if inSingleQuotes then
                        assign inSingleQuotes = no
                               isQuotedNull   = (strValue eq '?':u)
                               .
                    else
                    if not inDoubleQuotes then
                        assign inSingleQuotes = yes
                               strValue       = strValue + chrValue
                               .
                end.
                else
                if chrValue eq StringConstant:DOUBLE_QUOTE then
                do:
                    if inDoubleQuotes then
                        assign inDoubleQuotes = no
                               isQuotedNull   = (strValue eq '?':u)
                               .
                    else
                    if not inSingleQuotes then
                        assign inDoubleQuotes = yes
                               strValue       = strValue + chrValue
                               .
                end.
                else
                if chrValue eq ')':u then
                do:
                    if inParens then
                        assign inParens = no.
                end.
                else
                    assign strValue = strValue + chrValue.
            end.

            // we're at the end of a 'word'; strValue (usually) contains the word
            if chrValue eq StringConstant:SPACE
            or loop eq len
            then
            do:
                // we're in a quoted value
                if inParens
                or inDoubleQuotes
                or inSingleQuotes
                then
                do:
                    assign strValue = strValue + chrValue.
                    next CHR-LOOP.
                end.
                else
                // if this is the second space in a row, it's meaningless. skip
                if strValue eq StringConstant:SPACE then
                    next CHR-LOOP.
                else
                // if we hit a BY phrase, or we're at a new stanza, we're done with this WHERE
                if strValue eq 'by':u
                or strValue eq ',':u
                then
                do:
                    // if the word "by" is a field value then continue
                    if valid-object(qryPredicate)
                    or valid-object(qryGroup)
                    then
                    do:
                        assign strValue = '':u.
                        leave CHR-LOOP.
                    end.
                end.
                else
                if strValue eq 'and':u
                or strValue eq 'or':u
                then
                do:
                    if valid-object(qryPredicate) then
                        assign qryPredicate:Join = JoinEnum:GetEnum(strValue).

                    //build a group and add the existing predicate
                    if not valid-object(qryGroup) then
                        assign qryGroup      = new QueryGroup()
                               qryGroup:Join = JoinEnum:GetEnum(strValue)
                               numPred       = 1
                               strValue      = '':u

                               extent(qryGroup:Entries)  = numPred
                               qryGroup:Entries[numPred] = qryPredicate
                               qryPredicate              = ?
                               .
                    //nothing more to do here
                    next CHR-LOOP.
                end.    // AND|OR

                //else

                // deal with words
                if not haveName then
                    assign fieldName = strValue
                           haveName  = yes
                           strValue  = '':u
                           .
                else
                if not haveOperator then
                    assign operator     = QueryOperatorHelper:ToEnum(strValue)
                           haveOperator = yes
                           strValue     = '':u
                           .
                else
                if not haveValue then
                do:
                    if strValue eq '?':u
                    and not isQuotedNull
                    then
                        assign fieldValue = String:Unknown().
                    else
                        assign fieldValue = new String(strValue).

                    assign haveValue    = yes
                           strValue     = '':u
                           isQuotedNull = no
                           .
                end.
            end.    // SPACE or end of loop
            else
            do:
                // are we quoted?
                if chrValue eq StringConstant:SINGLE_QUOTE then
                do:
                    if inSingleQuotes then
                        assign inSingleQuotes = no
                               isQuotedNull   = (strValue eq '?':u)
                               .
                    else
                    if not inDoubleQuotes then
                        assign inSingleQuotes = yes
                               isQuotedNull   = no
                               .
                    else
                        assign strValue = strValue + chrValue.
                end.
                else
                if chrValue eq StringConstant:DOUBLE_QUOTE then
                do:
                    if inDoubleQuotes then
                        assign inDoubleQuotes = no
                               isQuotedNull   = (strValue eq '?':u)
                               .
                    else
                    if not inSingleQuotes then
                        assign inDoubleQuotes = yes
                               isQuotedNull   = no
                               .
                    else
                        assign strValue = strValue + chrValue.
                end.
                else
                if chrValue eq '(':u then
                do:
                    if not inParens then
                        assign inParens = true.
                    assign strValue = strValue + chrValue.
                end.
                else
                if chrValue eq ')':u then
                do:
                    if inParens then
                        assign inParens = false.
                    assign strValue = strValue + chrValue.
                end.
                else
                // deal with custnum>23
                if not haveName
                and not inSingleQuotes
                and not inDoubleQuotes
                and not inParens
                then
                case chrValue:
                    // allowed: <, >, =, <=, >=, <>
                    when '<':u or
                    when '=':u or
                    when '>':u then
                    do:
                        assign fieldName = strValue
                               haveName  = yes
                               strValue  = '':u
                               .
                        if loop eq len then
                            assign nextChr = '':u.
                        else
                            assign nextChr = substring(pWhere, loop + 1, 1).

                        if nextChr eq '=':u
                        or nextChr eq '>':u
                        then
                            assign operator = QueryOperatorHelper:ToEnum(chrValue + nextChr)
                                   loop     = loop + 1
                                   .
                        else
                            assign operator = QueryOperatorHelper:ToEnum(chrValue).

                        assign haveOperator = yes.

                        // if this is table.field= 20 (space after oprator) then skip the space,
                        // since we're dealing with it here
                        if loop eq len then
                            assign nextChr = '':u.
                        else
                            assign nextChr = substring(pWhere, loop + 1, 1).

                        if nextChr eq StringConstant:SPACE then
                            assign loop = loop + 1.
                    end.
                    otherwise
                        assign strValue = strValue + chrValue.
                end case.
                else
                    assign strValue = strValue + chrValue.
            end.

            if  haveName
            and haveOperator
            and haveValue
            then
            do:
                assign haveName     = no
                       haveOperator = no
                       haveValue    = no
                       qryPredicate = new QueryPredicate(fieldName, operator, fieldValue)
                       .
                // for the end of the loop
                if valid-object(qryGroup) then
                    assign numPred                   = numPred + 1
                           extent(qryGroup:Entries)  = numPred
                           qryGroup:Entries[numPred] = qryPredicate
                           qryPredicate              = ?
                           .
            end.
        end.    //CHR-LOOP

        // we return one of an IQueryPredicate (single clause) or an IQueryGroup (many clauses)
        if valid-object(qryGroup) then
        do:
            if valid-object(qryPredicate) then
                assign numPred                   = numPred + 1
                       extent(qryGroup:Entries)  = numPred
                       qryGroup:Entries[numPred] = qryPredicate
                       .
            return qryGroup.
        end.
        else
        // we've been able to parse the whole where clause
        if strValue eq '':u then
            return qryPredicate.
        else
            return ?.

        // if there's an error parsing the string, assume it's rubbish and return null.
        catch e as Progress.Lang.Error:
            return ?.
        end catch.
    end method.

    /* Parses an SORT-BY phrase and returns an array of IQuerySortEntry objects.

       @param character The SORT-BY phrase
       @return IQuerySortEntry[] An array of sort phrases. An indeterminate array is returned if the input phrase is empty */
    method override public IQuerySortEntry extent ParseSortBy(input pSortBy as Progress.Lang.Object):
        define variable qrySort as IQuerySortEntry extent no-undo.
        define variable sortByString as character no-undo.
        define variable sortByArray as character extent no-undo.
        define variable cnt as integer no-undo.
        define variable loop as integer no-undo.

        case true:
            when not valid-object(pSortBy) then
                return qrySort.

            when type-of(pSortBy, ILongcharHolder)  or
            when type-of(pSortBy, ICharacterHolder) then
                assign sortByString = dynamic-property(pSortBy, 'Value':u)
                       qrySort      = ParseSortString(sortByString)
                       .

            when type-of(pSortBy, ICharacterArrayHolder) or
            when type-of(pSortBy, ILongcharArrayHolder) then
            do:
                assign sortByArray = dynamic-property(pSortBy, 'Value':u).
                if     not cnt eq ?
                   and cnt ge 1
                then
                    assign cnt = extent(sortByArray).

                do loop = 1 to cnt:
                    assign sortByString = sortByString + StringConstant:SPACE + sortByArray[loop].
                end.
                assign qrySort = ParseSortString(sortByString).
            end.

            otherwise
                return qrySort.
        end case.

        return qrySort.
    end method.

    /* Parses where/filter phrase and returns an IQueryEntry object for a single table

       @param P.L.Object The filter/where clause phrase
       @return IQueryEntry The query entry.We return one of an IQueryPredicate (single clause)
                           or an IQueryGroup (many clauses) */
    method override public IQueryEntry ParseWhere(input pWhere as Progress.Lang.Object):
        define variable whereString as character no-undo.
        define variable qryEntry as IQueryEntry no-undo.
        define variable qryGrp as QueryGroup no-undo.
        define variable cnt as integer no-undo.
        define variable loop as integer no-undo.
        define variable stringData as longchar extent no-undo.

        case true:
            when not valid-object(pWhere) then
                return qryEntry.

            when type-of(pWhere, ILongcharHolder)  or
            when type-of(pWhere, ICharacterHolder) then
                assign whereString  = dynamic-property(pWhere, 'Value':u)
                       qryEntry     = ParseWhereString(whereString)
                       .

            when type-of(pWhere, ICharacterArrayHolder) or
            when type-of(pWhere, ILongcharArrayHolder) then
            do:
                assign stringData = dynamic-property(pWhere, 'Value':u)
                       cnt        = extent(stringData)
                       .
                if cnt eq 1 then
                    assign qryEntry = ParseWhereString(string(stringData[1])).
                else
                if not cnt eq ? then
                do:
                    assign qryGrp = new QueryGroup(cnt).
                    do loop = 1 to cnt:
                        assign qryEntry = ParseWhereString(string(stringData[loop])).
                        //yuk, but the interfaces are defined READ-ONLY
                        if type-of(qryEntry, QueryPredicate) then
                            assign cast(qryEntry, QueryPredicate):Join = JoinEnum:And.
                        else
                        if type-of(qryEntry, QueryGroup) then
                            assign cast(qryEntry, QueryGroup):Join = JoinEnum:And.
                    end.
                    // return the groyup, not the predicate
                    assign qryEntry = qryGrp.
                end.
            end.

            otherwise
                return qryEntry.
        end case.

        return qryEntry.
    end method.

    /* Reads and processes (parses) the filter.

       @param P.L.Object The filter data
       @param IGetDataRequest A new filter object */
    method override public IGetDataRequest Parse(input pData as Progress.Lang.Object):
        define variable dataRequest as GetDataRequest no-undo.
        define variable qryDef as QueryDefinition no-undo.
        define variable tableRequest as GetDataTableRequest no-undo.
        define variable cnt as integer no-undo.
        define variable loop as integer no-undo.
        define variable stringData as longchar extent no-undo.

        assign dataRequest = new GetDataRequest().

        case true:
            when not valid-object(pData) then
                return dataRequest.

            when type-of(pData, ICharacterHolder) or
            when type-of(pData, ILongcharHolder) then
                assign dataRequest                       = new GetDataRequest(1)
                       tableRequest                      = new GetDataTableRequest(FilterTable[1])
                       dataRequest:TableRequests[1]      = tableRequest
                       qryDef                            = new QueryDefinition()
                       tableRequest:QueryDefinition      = qryDef
                       qryDef:QuerySelection             = ParseWhereString(dynamic-property(pData, 'Value':u))
                       .

            when type-of(pData, ICharacterArrayHolder) or
            when type-of(pData, ILongcharArrayHolder)  then
            do:
                assign stringData = dynamic-property(pData, 'Value':u)
                       cnt        = extent(stringData)
                       .
                if     not cnt eq ?
                   and cnt ge 1
                then
                    assign extent(dataRequest:TableRequests) = cnt.

                do loop = 1 to cnt:
                    assign tableRequest                      = new GetDataTableRequest(FilterTable[loop])
                           dataRequest:TableRequests[loop]   = tableRequest
                           qryDef                            = new QueryDefinition()
                           tableRequest:QueryDefinition      = qryDef
                           qryDef:QuerySelection             = ParseWhereString(string(stringData[loop]))
                           .
                end.
            end.

            when type-of(pData, JsonObject) then
                assign extent(dataRequest:TableRequests) = 1
                       dataRequest:TableRequests[1]      = ParseTableRequest(FilterTable[1],
                                                                             cast(pData, JsonObject))
                       .

            when type-of(pData, JsonArray) then
            do:
                assign cnt = cast(pData, JsonArray):Length.
                if     not cnt eq ?
                   and cnt ge 1
                then
                    assign extent(dataRequest:TableRequests) = cnt.

                do loop = 1 to cnt:
                    assign dataRequest:TableRequests[loop] = ParseTableRequest(FilterTable[1],
                                                                               cast(pData, JsonArray):GetJsonObject(loop)).
                end.
            end.

            otherwise
                return error new AppError(
                        substitute('Unsupported object type: &1', pData:GetClass():TypeName)
                        , 0).
        end case.

        return cast(dataRequest, IGetDataRequest).
    end method.

    /* Reads a single table's request

       This method knows which properties in the input JSON are for the where clause, for the sort-by etc

       @param character The table name to which this filter applies
       @param JsonObject The input filter
       @return IGetDataTableRequest A single table Get Request */
    method protected IGetDataTableRequest ParseTableRequest(input pTable as character,
                                                            input pData as JsonObject):
        define variable tableRequest as GetDataTableRequest no-undo.
        define variable qryDef as QueryDefinition no-undo.
        define variable names as character extent no-undo.
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.

        Assert:NotNull(pTable, 'Table name').

        assign tableRequest = new GetDataTableRequest(pTable).

        if not valid-object(pData) then
            return tableRequest.

        assign qryDef                       = new QueryDefinition()
               tableRequest:QueryDefinition = qryDef
               names = pData:GetNames()
               cnt   = extent(names)
               .
        NAMES-LOOP:
        do loop = 1 to cnt:
            // loop-de-loop cos JSON is case sensitive and ABL is not
            if  names[loop] eq 'where':u
            and pData:GetType(names[loop]) eq JsonDataType:STRING
            then
            do:
                assign qryDef:QuerySelection = ParseWhereString(pData:GetCharacter(names[loop])).
                leave NAMES-LOOP.
            end.
        end.

        return cast(tableRequest, IGetDataTableRequest).
    end method.

end class.