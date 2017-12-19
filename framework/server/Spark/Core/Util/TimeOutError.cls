using Progress.Lang.* from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Util.ApplicationError from propath.
using Spark.Core.Message.ErrorTypeEnum from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.

block-level on error undo, throw.

class Spark.Core.Util.TimeOutError inherits ApplicationError:

    constructor public TimeOutError ( input ptStartTime as datetime-tz, input piStopAfter as integer ):

        super().

        if piStopAfter gt 0 and interval(now, ptStartTime, "seconds") ge piStopAfter then
            createAppError("The service request took too long to execute", integer(StatusCodeEnum:RequestTimeOut) * -1, "","","","","","","","","").
        else
            createAppError("A STOP or QUIT condition occured [&1]", integer(StatusCodeEnum:InternalServerError) * -1, GenTools:getLastAblError(),"","","","","","","","").

        errorType = ErrorTypeEnum:fatal.

    end constructor.

end class.