using Progress.Json.ObjectModel.* from propath.
using OpenEdge.BusinessLogic.QuerySortEntry from propath.
using Spark.Core.Util.ClientParse from propath.

block-level on error undo, throw.

/**
 * A static class to parse KendoUI data constructs
 */
class Spark.Core.Util.KendoParse inherits ClientParse:

    constructor public KendoParse ( input phDataset as handle ):
        super(input phDataset).
    end constructor.

    method private character getMapping ( input pcKendoOperator as character,
                                          input pcFieldDataType as character ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.operator */
        define variable cTemplate as character no-undo.

        case pcKendoOperator:
            when "eq" then
                if pcFieldDataType eq "character" then
                    assign cTemplate = '&1 eq "&2"'.
                else
                    assign cTemplate = '&1 eq &2'.
            when "neq" then
                if pcFieldDataType eq "character" then
                    assign cTemplate = '&1 ne "&2"'.
                else
                    assign cTemplate = '&1 ne &2'.
            when "lt" then
                assign cTemplate = '&1 lt &2'.
            when "lte" then
                assign cTemplate = '&1 le &2'.
            when "gt" then
                assign cTemplate = '&1 gt &2'.
            when "gte" then
                assign cTemplate = '&1 ge &2'.
            when "startswith" then
                assign cTemplate = '&1 begins "&2"'.
            when "contains" then
                assign cTemplate = '&1 matches "*&2*"'.
            when "doesnotcontain" then
                assign cTemplate = 'not (&1 matches "*&2*")'.
            when "endswith" then
                assign cTemplate = '&1 matches "*&2"'.
            otherwise
                undo, throw new Progress.Lang.AppError("Unknown operator for filter.", 0).
        end.

        return cTemplate.
    end method. /* getMapping */

    method private character buildClause ( input poClause as JsonObject ):
        define variable hField   as handle     no-undo.
        define variable cClause  as character  no-undo.
        define variable cField   as character  no-undo.
        define variable cOper    as character  no-undo.
        define variable cType    as character  no-undo.

        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.field */
        assign
            hField  = getFieldBuffer(poClause:GetCharacter("field"))
            cOper   = poClause:GetCharacter("operator")
            no-error.

        if not valid-handle(hField) then return "".

        assign
            cField = hField:name
            cType  = hField:data-type
            no-error.

        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.value */
        case cType:
            when "character" then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetCharacter("value")).
            when "date" then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetDate("value")).
            when "datetime" then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetDatetime("value")).
            when "datetime-tz" then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetDatetimeTZ("value")).
            when "decimal" then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetDecimal("value")).
            when "integer" then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetInteger("value")).
            when "logical" then
                assign cClause = substitute(getMapping(cOper, cType),
                                            cField, poClause:GetLogical("value")).
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

    /***** Public Methods *****/

    method public override JsonArray getRawCriteria ( input poFilter as JsonObject ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter.filters */
        if valid-object(poFilter) and poFilter:Has("filters") and
           poFilter:GetType("filters") eq JsonDataType:array then
            return poFilter:GetJsonArray("filters").

        return (new JsonArray()).
    end method. /* getRawCriteria */

    method public override character buildWherePhrase ( input poFilter as JsonObject ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-filter */
        return buildWherePhrase("", poFilter).
    end method. /* buildWherePhrase */

    method public override character buildSortPhrase ( input poOptions as JsonArray ):
        /* http://docs.telerik.com/kendo-ui/api/javascript/data/datasource#configuration-sort */
        define variable oSortObj as JsonObject no-undo.
        define variable cSortBy  as character  no-undo.
        define variable hField   as handle     no-undo.
        define variable iX       as integer    no-undo.

        if valid-object(poOptions) and poOptions:Length gt 0 then do:
            do iX = 1 to poOptions:length:
                assign oSortObj = poOptions:GetJsonObject(iX).
                assign hField = getFieldBuffer(oSortObj:GetCharacter("field")).
                if valid-handle(hField) then
                    assign cSortBy = substitute("&1 by &2 &3",
                                                cSortBy,
                                                hField:name,
                                                if oSortObj:GetCharacter("dir") eq "asc" then "" else "descending").
            end. /* do iX */
            assign cSortBy = trim(cSortBy).
        end. /* valid-object */

        return cSortBy.
    end method. /* buildOrderPhrase */

    method public override QuerySortEntry extent buildSortEntries ( input poOptions as JsonArray ):
        define variable oSortList as QuerySortEntry extent no-undo.
        define variable oSortObj  as JsonObject            no-undo.
        define variable hField    as handle                no-undo.
        define variable iX        as integer               no-undo.

        if valid-object(poOptions) and poOptions:Length gt 0 then do:
            /**
             * An extent must be specified, even if some of the fields are not valid for sorting.
             * Since we shouldn't have more sort entries than items in the array, use that count.
             */
            extent(oSortList) = poOptions:length.

            do iX = 1 to poOptions:length:
                assign oSortObj = poOptions:GetJsonObject(iX).
                assign hField = getFieldBuffer(oSortObj:GetCharacter("field")).
                if valid-handle(hField) then do:
                    /* Add a new sort entry object with field and direction. */
                    oSortList[iX] = new QuerySortEntry(hField:name, if oSortObj:GetCharacter("dir") eq "asc"
                                                                    then Ccs.BusinessLogic.SortOrderEnum:Ascending
                                                                    else Ccs.BusinessLogic.SortOrderEnum:Descending).
                end. /* valid-handle */
            end. /* do iX */
        end. /* valid-object */

        return oSortList.
    end method. /* buildSortPhrase */

end class.