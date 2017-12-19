
block-level on error undo, throw.

class Spark.Core.Constant.DataRequestDef:

    define public static property BATCH_SIZE       as character initial "batchSize"      no-undo get.
    define public static property BATCH_PAGE       as character initial "batchPage"      no-undo get.
    define public static property BATCH_QUERY      as character initial "batchQuery"     no-undo get.
    define public static property BATCH_LAST_PAGE  as character initial "batchLastPage"  no-undo get.
    define public static property BATCH_EXTRA_INFO as character initial "batchExtraInfo" no-undo get.
    define public static property BATCH_SORT_SPECS as character initial "batchSortSpec"  no-undo get.

end class.