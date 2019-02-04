/*------------------------------------------------------------------------
    File        : QueryDefinition
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Thu Jan 10 12:01:04 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class Spark.Core.BusinessLogic.QueryDefinition implements Ccs.BusinessLogic.IQueryDefinition: 

    define public property QuerySelection as Ccs.BusinessLogic.IQueryEntry no-undo get. set. 

    define public property QuerySort as Ccs.BusinessLogic.IQuerySortEntry extent no-undo get. set. 

end class.