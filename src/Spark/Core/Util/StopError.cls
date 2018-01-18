using Progress.Lang.* from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Util.ApplicationError from propath.
using Spark.Core.Message.ErrorTypeEnum from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.

block-level on error undo, throw.

class Spark.Core.Util.StopError inherits ApplicationError:

    constructor public StopError ( ):

        super().

        createAppError("A STOP or QUIT condition occured [&1]", integer(StatusCodeEnum:InternalServerError) * -1, GenTools:getLastAblError(),"","","","","","","","").

        errorType = ErrorTypeEnum:fatal.

    end constructor.

end class.