/*------------------------------------------------------------------------
    File        : GetDataRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Dustin Grau
    Created     : Thu Jan 10 09:18:39 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

class Spark.Core.BusinessLogic.GetDataRequest implements Ccs.BusinessLogic.IGetDataRequest: 

    define public property CustomParameter as Progress.Lang.Object no-undo get. set. 

    define public property NamedQuery as Ccs.BusinessLogic.INamedQuery no-undo get. set. 

    define public property TableRequests as Ccs.BusinessLogic.IGetDataTableRequest extent no-undo get. set. 

end class.