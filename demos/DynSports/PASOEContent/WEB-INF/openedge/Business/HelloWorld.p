/*------------------------------------------------------------------------
    File        : HelloWorld.p
    Purpose     :
    Description :
    Author(s)   :
    Created     : Fri Apr 29 08:32:24 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ***************************  Main Block  *************************** */

procedure sayHello:
    define input  parameter toWhom   as character no-undo.
    define output parameter greeting as character no-undo.

    assign greeting = substitute("Hello &1", toWhom).
end procedure.
