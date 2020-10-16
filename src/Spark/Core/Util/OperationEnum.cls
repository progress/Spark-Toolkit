/*------------------------------------------------------------------------
    File        : OperationEnum
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Dustin Grau
    Created     : Mon Aug 06 13:42:44 EDT 2018
    Notes       :
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

enum Spark.Core.Util.OperationEnum:

    define enum read
                create
                update
                delete
                submit
                invoke
                count
                .

end enum.