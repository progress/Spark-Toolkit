/*------------------------------------------------------------------------
    File        : GetTableResultCountResponse
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Thu Jan 10 10:25:09 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class Spark.Core.BusinessLogic.GetTableResultCountResponse implements Ccs.BusinessLogic.IGetTableResultCountResponse: 

    define public property Exact as logical no-undo get. set. 

    define public property NumResults as int64 no-undo get. set. 

    define public property TableName as character no-undo get. set. 

end class.