block-level on error undo, throw.

/**
 * Abstract service class to be inherited by all services
 */
class Spark.Core.Service.Service implements Ccs.Common.IService abstract:

    constructor public Service ( ):
        super().
    end constructor.

    /**
     * Initializer/Startup
     */
    method public abstract void initialize ( ).

    /**
     * Destroy/Shutdown/Anti-Initializer
     */
    method public abstract void dispose ( ).

end class.
