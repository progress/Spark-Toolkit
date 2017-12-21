using Progress.Json.ObjectModel.* from propath.

interface Spark.Core.Util.IClientParse:

    method public JsonArray getRawCriteria ( input poFilter as JsonObject ).
    method public character buildSortPhrase ( input pcOrderBy as character ).
    method public character buildSortPhrase ( input poOptions as JsonArray ).
    method public character buildWherePhrase ( input poFilter as JsonObject ).

end interface.