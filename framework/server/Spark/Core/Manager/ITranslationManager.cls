using Ccs.Common.IManager from propath.

/**
 * Translation Manager Interface
 */
interface Spark.Core.Manager.ITranslationManager inherits IManager:

    method public character getTranslatedMessage( input pcMsgGroup as character, input piMsgNumber as integer).

    method public character getTranslatedMessage( input pcMessage as character ).

end interface.