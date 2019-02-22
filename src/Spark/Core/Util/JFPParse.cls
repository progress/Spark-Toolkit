using Progress.Json.ObjectModel.* from propath.
using OpenEdge.BusinessLogic.QuerySortEntry from propath.
using Spark.Core.Util.ClientParse from propath.

block-level on error undo, throw.

/**
 * A static class to parse JFP data constructs
 */
class Spark.Core.Util.JFPParse inherits ClientParse:

    constructor public JFPParse ( input phDataset as handle ):
        super(input phDataset).
    end constructor.

    /***** Public Methods *****/

    method public override character buildSortPhrase ( input pcOrderBy as character ):
        if pcOrderBy gt "" then do:
            assign pcOrderBy = replace(pcOrderBy, ",", " by ").
            assign pcOrderBy = "by " + pcOrderBy + " ".
            /* NOTE: id and seq fields should be removed from cWhere and cOrderBy */
            assign pcOrderBy = replace(pcOrderBy, "by id desc", "").
            assign pcOrderBy = replace(pcOrderBy, "by id ", "").
            assign pcOrderBy = replace(pcOrderBy, "by seq desc", "").
            assign pcOrderBy = replace(pcOrderBy, "by seq ", "").
        end.

        return pcOrderBy.
    end method. /* buildOrderPhrase */

    method public override QuerySortEntry extent buildSortEntries ( input pcOrderBy as character ):
        define variable oSortList as QuerySortEntry extent no-undo.

        if pcOrderBy gt "" then do:
            extent(oSortList) = 1.

            /* @TODO: This needs to be tested more fully. */
            assign pcOrderBy = this-object:buildSortPhrase(pcOrderBy).
            if index(pcOrderBy, " desc") gt 0 then
                oSortList[1] = new QuerySortEntry(entry(1, pcOrderBy, " "), Ccs.BusinessLogic.SortOrderEnum:Descending).
            else
                oSortList[1] = new QuerySortEntry(pcOrderBy, Ccs.BusinessLogic.SortOrderEnum:Ascending).
        end.

        return oSortList.
    end method. /* buildSortPhrase */

end class.