using Spark.Core.Message.* from propath.

block-level on error undo, throw.

/**
 * A Configuration Message (or a Service Message loaded from a JSON file or JSON text)
 */
interface Spark.Core.Message.IConfigMessage inherits IAbstractMessage:

    method public void deserializeMessageFromFile (input pcFile as character  ).

    method public void deserializeMessage (input pcMessage as longchar  ).

end interface.