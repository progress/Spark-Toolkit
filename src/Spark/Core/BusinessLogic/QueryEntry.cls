/*------------------------------------------------------------------------
    File        : QueryEntry
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Thu Jan 10 12:01:44 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class Spark.Core.BusinessLogic.QueryEntry implements Ccs.BusinessLogic.IQueryEntry: 

    define public property Join as Ccs.BusinessLogic.JoinEnum no-undo get. set. 

end class.