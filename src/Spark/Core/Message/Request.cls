block-level on error undo, throw.

/**
 * A Request Service Message
 */
class Spark.Core.Message.Request inherits Spark.Core.Message.AbstractMessage implements Spark.Core.Message.IRequest:

    constructor public Request ( ):
        super().
    end constructor.

    constructor public Request ( input pcRequest as longchar ):
        super(input pcRequest).
    end constructor.

    method override protected void storeProperties ( ):

    end method.

end class.