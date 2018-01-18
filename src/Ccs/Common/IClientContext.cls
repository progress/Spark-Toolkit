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
    File        : IClientContext
    Purpose     : Base CCS Client Context definition 
    Author(s)   : rosmith@progress.com
    Created     : 2016-11-02 
    Notes       : 
  ----------------------------------------------------------------------*/
interface Ccs.Common.IClientContext:  

    /* A unique ID for the Client Context object */
    define public property contextID as character no-undo get.

    /* The handle to the client's Client Principal object */
    define public property clientPrincipal as handle no-undo get.

    /* Initialize the context data for the Client Context object 
       @param handle The Client Principal object for the client request */
    method public void initializeContext( input phClientPrincipal as handle ).

    /* Initialize the context data for the Client Context object 
       @param character The known Session ID for the client request */
    method public void initializeContext( input pcSessionID as character ).

    /* Save the context data to a persistent store */
    method public void saveContext( ).

end interface.
