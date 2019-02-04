/*------------------------------------------------------------------------
    File        : GetDataResponse
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Thu Jan 10 09:11:29 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class Spark.Core.BusinessLogic.GetDataResponse implements Ccs.BusinessLogic.IGetDataResponse: 

    define public property CustomResponse as Progress.Lang.Object no-undo
    get.

    define public property TableResponses as Ccs.BusinessLogic.IGetDataTableResponse extent no-undo
    get.

end class.