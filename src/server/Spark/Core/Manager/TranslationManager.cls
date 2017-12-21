using Spark.Core.Manager.ITranslationManager from propath.
using Spark.Core.Manager.Manager from propath.

block-level on error undo, throw.

/**
 * Translation Manager
 */
class Spark.Core.Manager.TranslationManager inherits Spark.Core.Manager.Manager implements ITranslationManager:

    constructor public TranslationManager (  ):
        super ().
    end constructor.

    method override public void initialize(  ):
    end method.

    method override public void dispose ( ):
    end method.

    method public character getTranslatedMessage ( input pcMessage as character  ):
        /* TODO: */
        return pcMessage.
    end method.

    method public character getTranslatedMessage ( input pcMsgGroup as character, input piMsgNumber as integer ):
        /* TODO: */
        return substitute("&1:&2",pcMsgGroup,piMsgNumber).
    end method.

end class.
