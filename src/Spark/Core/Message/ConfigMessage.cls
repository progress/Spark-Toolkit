using Spark.Core.Message.* from propath.

block-level on error undo, throw.

/**
 * A Configuration Message (or a Service Message loaded from a JSON file)
 */
class Spark.Core.Message.ConfigMessage inherits AbstractMessage implements IConfigMessage:

   constructor public ConfigMessage (  ):
      super ().
   end constructor.

    method public override void deserializeMessageFromFile (input pcFile as character  ):
      super:deserializeMessageFromFile(pcFile).
   end method.

   method public override void deserializeMessage (input pcMessage as longchar  ):
      super:deserializeMessage(pcMessage).
   end method.

   method override protected void storeProperties(  ):

   end method.

end class.