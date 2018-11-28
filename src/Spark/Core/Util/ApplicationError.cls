using Progress.Lang.AppError from propath.
using Spark.Core.Manager.ITranslationManager from propath.
using Spark.Core.Util.ErrorTypeEnum from propath.

block-level on error undo, throw.

/**
 * An Application Error object
 * The Error message will be translated to the users language or context approprate message
 */
class Spark.Core.Util.ApplicationError inherits AppError:

    define public property errorField as character no-undo get. set.

    define public property errorType as ErrorTypeEnum no-undo
        get():
            if not valid-object (errorType) then
                setErrorType().
            return errorType.
        end get.
        set.

    define public property originalErrorMessage as character no-undo get.
        private set.

    constructor public ApplicationError ( ):
        super ().
    end constructor.

    constructor public ApplicationError ( input pcMessage as character ):
        super().
        createAppError(pcMessage,0,"","","","","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input piErrorNumber as integer ):
        super().
        createAppError(pcMessage,piErrorNumber,"","","","","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer ):
        super().
        createAppError(pcMsgGroup,piMsgNumber,piErrorNumber,"","","","","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input pcSub1 as character ):
        super().
        createAppError(pcMessage,0,pcSub1,"","","","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input piErrorNumber as integer, input pcSub1 as character ):
        super().
        createAppError(pcMessage,piErrorNumber,pcSub1,"","","","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer, input pcSub1 as character ):
        super().
        createAppError(pcMsgGroup,piMsgNumber,piErrorNumber,pcSub1,"","","","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input pcSub1 as character, input pcSub2 as character ):
        super().
        createAppError(pcMessage,0,pcSub1,pcSub2,"","","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character ):
        super().
        createAppError(pcMessage,piErrorNumber,pcSub1,pcSub2,"","","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character ):
        super().
        createAppError(pcMsgGroup,piMsgNumber,piErrorNumber,pcSub1,pcSub2,"","","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character ):
        super().
        createAppError(pcMessage,0,pcSub1,pcSub2,pcSub3,"","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character ):
        super().
        createAppError(pcMessage,piErrorNumber,pcSub1,pcSub2,pcSub3,"","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character ):
        super().
        createAppError(pcMsgGroup,piMsgNumber,piErrorNumber,pcSub1,pcSub2,pcSub3,"","","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character ):
        super().
        createAppError(pcMessage,0,pcSub1,pcSub2,pcSub3,pcSub4,"","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character ):
        super().
        createAppError(pcMessage,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,"","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character ):
        super().
        createAppError(pcMsgGroup,piMsgNumber,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,"","","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character ):
        super().
        createAppError(pcMessage,0,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,"","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character ):
        super().
        createAppError(pcMessage,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,"","","","").
    end constructor.

    constructor public ApplicationError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character ):
        super().
        createAppError(pcMsgGroup,piMsgNumber,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,"","","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character ):
        super().
        createAppError(pcMessage,0,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,"","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character ):
        super().
        createAppError(pcMessage,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,"","","").
    end constructor.

    constructor public ApplicationError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character ):
        super().
        createAppError(pcMsgGroup,piMsgNumber,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,"","","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character ):
        super().
        createAppError(pcMessage,0,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,"","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character ):
        super().
        createAppError(pcMessage,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,"","").
    end constructor.

    constructor public ApplicationError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character ):
        super().
        createAppError(pcMsgGroup,piMsgNumber,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,"","").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character ):
        super().
        createAppError(pcMessage,0,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,pcSub8,"").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character ):
        super().
        createAppError(pcMessage,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,pcSub8,"").
    end constructor.

    constructor public ApplicationError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character ):
        super().
        createAppError(pcMsgGroup,piMsgNumber,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,pcSub8,"").
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character, input pcSub9 as character ):
        super().
        createAppError(pcMessage,0,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,pcSub8,pcSub9).
    end constructor.

    constructor public ApplicationError ( input pcMessage as character, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character, input pcSub9 as character ):
        super().
        createAppError(pcMessage,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,pcSub8,pcSub9).
    end constructor.

    constructor public ApplicationError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character, input pcSub9 as character ):
        super().
        createAppError(pcMsgGroup,piMsgNumber,piErrorNumber,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,pcSub8,pcSub9).
    end constructor.

    method protected void createAppError ( input pcMessage as character, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character, input pcSub9 as character ):
        addMessage(substitute(cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                    :getTranslatedMessage(pcMessage),pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,pcSub8,pcSub9),piErrorNumber).
        originalErrorMessage = substitute(pcMessage,pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,pcSub8,pcSub9).
    end method.

    method protected void createAppError ( input pcMsgGroup as character, input piMsgNumber as integer, input piErrorNumber as integer, input pcSub1 as character, input pcSub2 as character, input pcSub3 as character, input pcSub4 as character, input pcSub5 as character, input pcSub6 as character, input pcSub7 as character, input pcSub8 as character, input pcSub9 as character ):
        addMessage(substitute(cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)
                                :getTranslatedMessage(pcMsgGroup, piMsgNumber),pcSub1,pcSub2,pcSub3,pcSub4,pcSub5,pcSub6,pcSub7,pcSub8,pcSub9),piErrorNumber).
        originalErrorMessage = substitute("&1:&2", pcMsgGroup, piMsgNumber).
    end method.

    /**
     * An override method that sets the default errorType
     */
    method protected void setErrorType ():
        errorType = ErrorTypeEnum:error.
    end method.

end class.