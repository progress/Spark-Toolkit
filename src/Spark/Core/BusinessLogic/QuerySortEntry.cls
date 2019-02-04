/*------------------------------------------------------------------------
    File        : QuerySortEntry
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Thu Jan 10 12:02:08 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class Spark.Core.BusinessLogic.QuerySortEntry implements Ccs.BusinessLogic.IQuerySortEntry: 

    define public property FieldName as character no-undo get. set. 

    define public property SortOrder as Ccs.BusinessLogic.SortOrderEnum no-undo get. set. 

end class.