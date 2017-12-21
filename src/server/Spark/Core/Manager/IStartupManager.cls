/*------------------------------------------------------------------------
    File        : IStartupManager
    Purpose     : Implement a customized CCS Startup Manager
    Description : Startup Manager (Interface)
    Author(s)   : progress
    Created     : Tue Mar 03 13:55:33 EST 2015
    Notes       : An instance is to be created and set in the StartupManager
                  property of Ccs.Common.Application and accessed from there.
  ----------------------------------------------------------------------*/

interface Spark.Core.Manager.IStartupManager inherits Ccs.Common.IStartupManager:

    /** The STOP-AFTER value used to set a time-out value for each interface request. */
    define public property interfaceStopAfter as integer no-undo get.

    method public void stopManagers ( ).

end interface.
