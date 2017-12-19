class Spark.Core.Util.LifecycleScope implements Ccs.ServiceManager.ILifecycleScope:

    define private variable Value as character no-undo.

    constructor LifecycleScope ( input pcScope as character ):
        assign this-object:Value = pcScope.
    end constructor.

    method public Progress.Lang.Object getScope ( ):
        return this-object.
    end method.

    method public override character ToString ( ):
        return this-object:Value.
    end method.

end class.
