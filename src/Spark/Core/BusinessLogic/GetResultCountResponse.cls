/*------------------------------------------------------------------------
    File        : GetResultCountResponse
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Thu Jan 10 09:17:20 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class Spark.Core.BusinessLogic.GetResultCountResponse implements Ccs.BusinessLogic.IGetResultCountResponse: 

    define public property ResultCounts as Ccs.BusinessLogic.IGetTableResultCountResponse extent no-undo get. set. 

end class.