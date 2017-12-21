
block-level on error undo, throw.

/**
 * A static class with helper methods for manipulating DataSets
 */
class Spark.Core.Util.DataSetTools:

    /**
     * Turns tracking-changes off and then empties the DataSet
     *
     * @param phDataSet The handle to the DataSet
     */
    method public static void emptyDataSet ( input phDataSet as handle ):

        setTrackingChanges(phDataSet,false).
        phDataSet:empty-dataset ().

    end method.

    /**
     * Reset the DataSet to simulate a new set of records getting created
     * Could be used in load data when copying an existing record as a template for a new one.  Removes the changed recorded in the DataSet.  Marks all the records in the tables as new
     *
     * @param phDataSet The handle the the DataSet
     */
    method public static void resetAsNew ( input phDataSet as handle ):

        define variable iBuff   as integer no-undo.
        define variable hBuffer as handle  no-undo.

        phDataSet:accept-changes().
        do iBuff = 1 to phDataSet:num-buffers:
            hBuffer = phDataSet:get-buffer-handle(iBuff) no-error.
            if valid-handle(hBuffer) then
            do:
                hBuffer:mark-new().
            end.
        end.

    end method.

    /**
     * Set tracking-changes for each temp-table in the DataSet
     *
     * @param phDataSet The handle to the DataSet
     * @param plTrackingChanges The value to set tracking-changes
     */
    method public static void setTrackingChanges ( input phDataSet as handle, input plTrackingChanges as logical ):

        define variable iBuff   as integer no-undo.
        define variable hBuffer as handle  no-undo.

        do iBuff = 1 to phDataSet:num-buffers:
            hBuffer = phDataSet:get-buffer-handle(iBuff) no-error.
            if valid-handle(hBuffer) then
            do:
                hBuffer:table-handle:tracking-changes = plTrackingChanges no-error.
            end.
        end.

    end method.

end class.