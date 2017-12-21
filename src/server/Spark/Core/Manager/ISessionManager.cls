/*------------------------------------------------------------------------
    File        : ISessionManager
    Purpose     : Implement a customized CCS Session Manager
    Description : Startup Manager (Interface)
    Author(s)   : progress
    Created     : Tue Mar 03 13:55:33 EST 2015
    Notes       : An instance is to be created and set in the SessionManager
                  property of Ccs.Common.Application and accessed from there.
  ----------------------------------------------------------------------*/

interface Spark.Core.Manager.ISessionManager inherits Ccs.Common.ISessionManager:

    method public logical databasesConnected ( ).

    method public void establishRequestEnvironment ( ).

    method public raw userLogin ( pcUserID as character, pcDomain as character, pcPassword as character, pcExtra as character ).

    method public void invalidateContext ( ).
    method public void invalidateContext ( input pcContextId as character ).
    method public void invalidateContext ( input phClientPrincipal as handle ).

    method public void setSessionAttribute ( input oAttribute as Spark.Core.Manager.SessionAttributeEnum, input pcValue as character ).

    method public character getUserSSOToken ( input ptExpiration as datetime-tz ).
    method public character getUserSSOToken ( input pcRawToken as character, input ptExpiration as datetime-tz ).

end interface.
