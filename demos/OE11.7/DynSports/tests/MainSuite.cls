/*------------------------------------------------------------------------
    File        : MainSuite
    Syntax      :
    Author(s)   : dugrau@progress.com
    Created     : Tue May 30 10:49:59 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

@TestSuite(classes="tests.StartupTests").
@TestSuite(classes="tests.ParameterTests").
@TestSuite(classes="tests.UtilityTests").
class tests.MainSuite:

end class.