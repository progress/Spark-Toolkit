/*------------------------------------------------------------------------
    File        : UpdateDataRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Thu Jan 10 09:25:10 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class Spark.Core.BusinessLogic.UpdateDataRequest implements Ccs.BusinessLogic.IUpdateDataRequest: 

    define public property CommitScope as Ccs.BusinessLogic.CommitScopeEnum no-undo get. set. 

    define public property CustomRequest as Progress.Lang.Object no-undo get. set. 

end class.