/*------------------------------------------------------------------------
    File        : IDynamicResource
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Mar 15 13:29:59 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

interface Spark.Core.Service.IDynamicResource inherits Ccs.Common.IService:

    define public property serviceURI   as character no-undo get.
    define public property resourceName as character no-undo get.

end interface.