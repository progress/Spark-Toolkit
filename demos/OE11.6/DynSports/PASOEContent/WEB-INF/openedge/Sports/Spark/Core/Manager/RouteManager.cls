using Progress.Lang.* from propath.
using Spark.Core.Manager.IStateManager from propath.
using Spark.Core.Manager.StateLifeCycleEnum from propath.

block-level on error undo, throw.

class Sports.Spark.Core.Manager.RouteManager inherits Spark.Core.Manager.RouteManager:

    method protected override void preProcessInvokeServiceFunction ( input pcService  as character,
                                                                     input pcResource as character,
                                                                     input pcMethod   as character ):
        message "cID:" Common.Globals:Instance:cID.
        message "dTime:" Common.Globals:Instance:dTime.
        message "iMTime:" Common.Globals:Instance:iMTime.
        message "Record:" Common.Globals:Instance:hasRecord().
    end method. /* preProcessInvokeServiceFunction */


    method protected override void postProcessInvokeServiceFunction ( input pcService  as character,
                                                                      input pcResource as character,
                                                                      input pcMethod   as character ):
        /* Serialize the globals instance object to disk using the proper context ID. */
        define variable lcData as longchar no-undo.
        if Spark.Core.Util.Serialize:serializeClassToJson(Common.Globals:Instance, output lcData) then
            cast(Ccs.Common.Application:StartupManager:getManager(get-class(IStateManager)), IStateManager)
                :writeContextToStore(lcData,
                                     StateLifeCycleEnum:session,
                                     "Common.Globals",
                                     Ccs.Common.Application:SessionManager:CurrentClientContext:contextID).

        /* Destroy the globals instance to prevent reuse. */
        finally:
            delete object Common.Globals:Instance no-error.
        end finally.
    end method. /* postProcessInvokeServiceFunction */

end class.