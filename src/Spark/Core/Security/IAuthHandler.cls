/*------------------------------------------------------------------------
    File        : IAuthHandler
    Purpose     : Provides specific methods for checking user credentials
    Description : Basic helper methods for authentication by IHybridRealm
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Thu Feb 26 12:54:28 EST 2015
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

interface Spark.Core.Security.IAuthHandler:

    /**
     * The following protected variables are available for use:
     *
     * define protected variable oConfig   as ConfigMessage no-undo.
     * define protected variable useDebugs as logical       no-undo initial false.
     *
     * The following are protected methods that can be overriden, but cannot be included as interface definitions:
     *
     * method protected logical checkPasswordHash ( input pcPassword as character, input pcHashPass as character ).
     * method protected logical checkPasswordHash ( input piUserID   as integer, input pcPassword as character, input pcHashPass as character ).
     * method protected character getPassword ( input piUserID as integer ).
     * method protected void postAuthenticate ( input piUserID as integer, input lRetVal  as logical ).
     */

    method integer getUserID ( input pcUsername   as character,
                               input pcDomainName as character ).

    method logical isActive ( input piUserID as integer ).

    method logical isExpired ( input piUserID as integer ).

    method logical isLocked ( input piUserID as integer ).

    method character getUserRoles ( input piUserID as integer ).

end interface.