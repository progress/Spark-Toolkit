/*------------------------------------------------------------------------
  This Software is licensed by Progress Software Corporation (licensor)
  under the Progress Software Common Component Specification Project
  Release License Agreement available at
  https://community.progress.com/products/directions/common_component/p/releaselicenseagreement

  The Interface definition is part of the Common Component Specification [CCSBE01]. The
  file is considered as a Specification Implementation Condition as described
  in section 2.1.1.1: If Licensor has made Specification Implementation
  Conditions available as of the date Licensee completes its Independent
  Implementation, then Licensee must, prior to making any claim that its
  Independent Implementation complies with the Specification, ensure that
  the Independent Implementation satisfies all of the Specification
  Implementation Conditions. If Licensor subsequently makes available or
  updates, from time to time, the Specification Implementation Conditions,
  then Licensee will verify that its Independent Implementation satisfies the
  latest version of the Specification Implementation Conditions within ninety
  (90) days following Licensor's release thereof.

  Contributors:
    Robin Smith, Progress Software Corp [2016]
  ----------------------------------------------------------------------*/
/*------------------------------------------------------------------------
    File        : Application
    Purpose     : Provides a well-known point to find references to specific CCS Manager components 
    Author(s)   : rosmith@progress.com
    Created     : 2016-11-02 
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Ccs.Common.IServiceManager from propath.
using Ccs.Common.ISessionManager from propath.
using Ccs.Common.IStartupManager from propath.

class Ccs.Common.Application final:

    /*------------------------------------------------------------------------------
     Purpose: Provides access to the injected IStartupManager.
     Notes:
    ------------------------------------------------------------------------------*/
    define static public property StartupManager as IStartupManager no-undo get. set.

    /*------------------------------------------------------------------------------
     Purpose: Provides access to the injected IServiceManager.
     Notes:
    ------------------------------------------------------------------------------*/
    define static public property ServiceManager as IServiceManager no-undo get. set.

    /*------------------------------------------------------------------------------
     Purpose: Provides access to the injected ISessionManager.
     Notes:
    ------------------------------------------------------------------------------*/
    define static public property SessionManager as ISessionManager no-undo get. set.

    /*------------------------------------------------------------------------------
     Purpose: Version of the Common Component Specification implementation.
     Notes:
    ------------------------------------------------------------------------------*/
    define static public property Version as character no-undo
        initial '1.0.0':u
        get.

    /*------------------------------------------------------------------------------
     Purpose: Prevent creation of instances.
     Notes:
    ------------------------------------------------------------------------------*/
    constructor private Application ():
        super ().
    end constructor.

end class.