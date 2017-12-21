 /*------------------------------------------------------------------------
    File        : DynamicResource
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Mar 17 09:31:42 EDT 2015
    Notes       :
  ----------------------------------------------------------------------*/

using Spark.Core.Manager.IClientContext from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.IMessageManager from propath.
using Spark.Core.Message.IRequest from propath.
using Spark.Core.Message.IResponse from propath.

/* Default options for class. */
block-level on error undo, throw.

class Spark.Core.Service.DynamicResource implements Spark.Core.Service.IDynamicResource use-widget-pool abstract:

    /* Required property on instance class, denotes a known service path. */
    define public abstract property serviceURI as character no-undo
        get. protected set.

    /* Required property on instance class, denotes public name for resource. */
    define public abstract property resourceName as character no-undo
        get. protected set.

    /* Direct access to the request object. */
    define protected property oRequest as IRequest no-undo
        get:
            return cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):RequestMessage, IRequest).
        end get.
        private set.

    /* Direct access to the response object. */
    define protected property oResponse as IResponse no-undo
        get:
            return cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage, IResponse).
        end get.
        private set.

    /***** Protected *****/

    define protected property oClientContext as IClientContext no-undo
        get:
            if not valid-object(oClientContext) then
                assign oClientContext = cast(Ccs.Common.Application:SessionManager:CurrentClientContext, IClientContext).
            return oClientContext.
        end get.
        set.

    define protected property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.

    method final protected character getClassName ( ):
        return this-object:GetClass():TypeName.
    end method. /* getClassName */

    /******* Public *******/

    method public void initialize ( ):
    end method. /* initialize */

    method public void dispose ( ):
    end method. /* dispose */

end class.
