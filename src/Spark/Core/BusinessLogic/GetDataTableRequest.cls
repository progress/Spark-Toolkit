/*------------------------------------------------------------------------
    File        : GetDataTableRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Thu Jan 10 10:40:26 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class Spark.Core.BusinessLogic.GetDataTableRequest implements Ccs.BusinessLogic.IGetDataTableRequest: 

    define public property NumRecords as int64 no-undo get. set. 

    define public property PagingContext as character no-undo get. set. 

    define public property QueryDefinition as Ccs.BusinessLogic.IQueryDefinition no-undo get. set. 

    define public property QueryString as character no-undo get. set. 

    define public property Skip as int64 no-undo get. set. 

    define public property TableName as character no-undo get. set. 

end class.