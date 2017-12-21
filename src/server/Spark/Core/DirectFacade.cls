/*------------------------------------------------------------------------
    File        : Spark.Core.DirectFacade
    Purpose     : Provide a simple facade for testing and direct access.
    Description : This exists behind WEB handlers for PASOE.
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Dec 12 10:14:53 EST 2014
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.JsonObject from propath.
using Spark.Core.Manager.ISessionManager from propath.
using Spark.Core.Web.IWebRequest from propath.
using Spark.Core.Web.IWebResponse from propath.

block-level on error undo, throw.

class Spark.Core.DirectFacade inherits Spark.Core.Interface.ServiceInterface implements Spark.Core.Interface.IServiceFacade use-widget-pool final:

    /* Provides a crucial kill switch to end service execution after a default of 20 seconds. */
    define public property requestStopAfter as integer no-undo
        get():
            return miStopAfter.
        end get.
        public set(input piStopAfter as integer):
            assign miStopAfter = piStopAfter.
        end set.


    method public logical userLogin ( input  pcUserID          as character,
                                      input  pcDomain          as character,
                                      input  pcPassword        as character,
                                      input  pcExtra           as character,
                                      output prClientPrincipal as raw,
                                      output pcMessage         as character ):
        define variable lResult as logical no-undo initial false.
        define variable iLoop   as integer no-undo.

        prClientPrincipal = cast(Ccs.Common.Application:SessionManager, ISessionManager):userLogin(pcUserID, pcDomain, pcPassword, pcExtra).
        lResult = true.

        return lResult.

        catch ea as AppError:
            do iLoop = 1 to ea:NumMessages:
                pcMessage = pcMessage + (if iLoop gt 1 then chr(10) else "") + ea:GetMessage(iLoop).
            end.
            if ea:ReturnValue ne "" then
                pcMessage = pcMessage + (if pcMessage ne "" then chr(10) else "") + ea:ReturnValue.
        end catch.

        catch es as SysError:
            do iLoop = 1 to es:NumMessages:
                pcMessage = pcMessage + (if iLoop gt 1 then chr(10) else "") + es:GetMessage(iLoop).
            end.
        end catch.
    end method. /* userLogin */


    method public override logical userLogout ( input  pcContextId as character,
                                                output pcMessage   as character ):
        return super:userLogout(pcContextId, pcMessage).
    end method. /* userLogout */


    method public override logical userLogout ( input  phCPO       as handle,
                                                output pcMessage   as character ):
        return super:userLogout(phCPO, pcMessage).
    end method. /* userLogout */


    method public override logical userLogout ( output pcMessage   as character ):
        return super:userLogout(pcMessage).
    end method. /* userLogout */


    method public override logical runService ( input  phCPO          as handle,
                                                input  pcResourceName as character,
                                                input  pcMethodName   as character,
                                                input  pcHttpMethod   as character,
                                                input  pcService      as character,
                                                input  pcJsonRequest  as longchar,
                                                output pfElapsedTime  as decimal,
                                                output piResponseCode as integer,
                                                output pcJsonHeaders  as longchar,
                                                output pcJsonResponse as longchar ):
        /* Run service with data as longchars and specific CP handle. */
        return super:runService( input  phCPO,
                                 input  pcResourceName,
                                 input  pcMethodName,
                                 input  pcHttpMethod,
                                 input  pcService,
                                 input  pcJsonRequest,
                                 output pfElapsedTime,
                                 output piResponseCode,
                                 output pcJsonHeaders,
                                 output pcJsonResponse ).

        finally:
            logMessage(substitute("DirectFacade: &1 &2/&3/&4: HTTP-&5 &6s &7kb",
                                  pcHttpMethod, pcService, pcResourceName, pcMethodName, piResponseCode,
                                  trim(string(pfElapsedTime, ">>>,>>9.999")),
                                  trim(string((length(pcJsonResponse, "raw") / 1000), ">>>,>>>,>>9.999"))), "FACADE-DBG", 3) no-error.
        end finally.
    end method. /* runService */


    method public override logical runService ( input  pcResourceName as character,
                                                input  pcMethodName   as character,
                                                input  pcHttpMethod   as character,
                                                input  pcService      as character,
                                                input  pcJsonRequest  as longchar,
                                                output pfElapsedTime  as decimal,
                                                output piResponseCode as integer,
                                                output pcJsonHeaders  as longchar,
                                                output pcJsonResponse as longchar ):
        /* Run service with data as longchars, will obtain CP handle. */
        return super:runService( input  pcResourceName,
                                 input  pcMethodName,
                                 input  pcHttpMethod,
                                 input  pcService,
                                 input  pcJsonRequest,
                                 output pfElapsedTime,
                                 output piResponseCode,
                                 output pcJsonHeaders,
                                 output pcJsonResponse ).

        finally:
            logMessage(substitute("DirectFacade: &1 &2/&3/&4: HTTP-&5 &6s &7kb",
                                  pcHttpMethod, pcService, pcResourceName, pcMethodName, piResponseCode,
                                  trim(string(pfElapsedTime, ">>>,>>9.999")),
                                  trim(string((length(pcJsonResponse, "raw") / 1000), ">>>,>>>,>>9.999"))), "FACADE-DBG", 3) no-error.
        end finally.
    end method. /* runService */


    method public override void runService ( input  pcResourceName as character,
                                             input  pcMethodName   as character,
                                             input  pcHttpMethod   as character,
                                             input  pcService      as character,
                                             input  pcJsonRequest  as longchar,
                                             input  poWebRequest   as IWebRequest,
                                             input  poWebResponse  as IWebResponse,
                                             input  pdApiVersion   as decimal,
                                             input  piStopAfter    as integer ):
        /* Run service with data as objects, will obtain CP handle. */
        super:runService( input pcResourceName,
                          input pcMethodName,
                          input pcHttpMethod,
                          input pcService,
                          input pcJsonRequest,
                          input poWebRequest,
                          input poWebResponse,
                          input pdApiVersion,
                          input piStopAfter ).

        finally:
            logMessage(substitute("DirectFacade: &1 &2/&3/&4",
                                  pcHttpMethod, pcService, pcResourceName, pcMethodName), "FACADE-DBG", 3) no-error.
        end finally.
    end method. /* runService */

end class.
