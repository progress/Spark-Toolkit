using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

class Spark.Core.Util.ClientParse implements Spark.Core.Util.IClientParse:

    define protected property ProDataSet as handle no-undo
        get.
        set.

    constructor public ClientParse ( input phDataset as handle ):
        ProDataSet = phDataset.
    end constructor.

    method protected handle getFieldBuffer ( input pcWebFieldName as character ):
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

    /***** Public Methods *****/

    method public JsonArray getRawCriteria ( input poFilter as JsonObject ):
        return (new JsonArray()).
    end method. /* getRawCriteria */

    method public character buildSortPhrase ( input pcOrderBy as character ):
        return substitute(" by &1", pcOrderBy).
    end method. /* buildSortPhrase */

    method public character buildSortPhrase ( input poOptions as JsonArray ):
        return string(poOptions:GetJsonText()).
    end method. /* buildSortPhrase */

    method public character buildWherePhrase ( input poFilter as JsonObject ):
        return string(poFilter:GetJsonText()).
    end method. /* buildWherePhrase */

end class.