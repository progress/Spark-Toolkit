using Spark.Core.Manager.ServiceLifeCycleEnum from propath.

block-level on error undo, throw.

class Spark.Core.Manager.ServiceLifeCycleEnum final:

    define static public property default as Ccs.ServiceManager.IRequestScope   no-undo get. private set.
    define static public property session as Ccs.ServiceManager.ISessionScope   no-undo get. private set.
    define static public property request as Ccs.ServiceManager.IRequestScope   no-undo get. private set.
    define static public property none    as Ccs.ServiceManager.ITransientScope no-undo get. private set.

    constructor static ServiceLifeCycleEnum ( ):
        ServiceLifeCycleEnum:session = new Spark.Core.Util.SessionScope("Session").
        ServiceLifeCycleEnum:request = new Spark.Core.Util.RequestScope("Request").
        ServiceLifeCycleEnum:none    = new Spark.Core.Util.TransientScope("None").
        ServiceLifeCycleEnum:default = ServiceLifeCycleEnum:request.
    end constructor.

    method public static Ccs.ServiceManager.ILifecycleScope enumFromString ( input pcScope as character ):
        define variable oServiceLifeCycle as Ccs.ServiceManager.ILifecycleScope no-undo.

        case pcScope:
            when ServiceLifeCycleEnum:session:ToString() then
                oServiceLifeCycle = ServiceLifeCycleEnum:session.
            when ServiceLifeCycleEnum:request:ToString() then
                oServiceLifeCycle = ServiceLifeCycleEnum:request.
            when ServiceLifeCycleEnum:none:ToString() then
                oServiceLifeCycle = ServiceLifeCycleEnum:none.
            otherwise
                oServiceLifeCycle = ServiceLifeCycleEnum:default.
        end case.

        return oServiceLifeCycle.

    end method.

    method public static character stringFromEnum ( input poScope as Ccs.ServiceManager.ILifecycleScope ):
        define variable cServiceLifeCycle as character no-undo.

        case true:
            when poScope:GetClass():IsA(get-class(Ccs.ServiceManager.ISessionScope)) then
                cServiceLifeCycle = ServiceLifeCycleEnum:session:ToString().
            when poScope:GetClass():IsA(get-class(Ccs.ServiceManager.IRequestScope)) then
                cServiceLifeCycle = ServiceLifeCycleEnum:request:ToString().
            when poScope:GetClass():IsA(get-class(Ccs.ServiceManager.ITransientScope)) then
                cServiceLifeCycle = ServiceLifeCycleEnum:none:ToString().
            otherwise
                cServiceLifeCycle = ServiceLifeCycleEnum:default:ToString().
        end case.

        return cServiceLifeCycle.

    end method.

end class.