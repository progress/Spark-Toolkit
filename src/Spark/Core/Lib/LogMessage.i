/**
 * LogMessage.i - Provide standard logMessage function/method
 * Syntax: {Spark/Core/Lib/LogMessage.i &IsClass=[true|false]}
 */

/* ***************************  Main Block  *************************** */

&if ({&IsPublic} eq true) &then
    &scoped-define ClassProtected public
    &scoped-define FunctionPrivate
&else
    &scoped-define ClassProtected protected
    &scoped-define FunctionPrivate private
&endif

&if ({&IsClass} eq true) &then
method {&ClassProtected} void logMessage
&else
function logMessage returns logical {&FunctionPrivate}
&endif
    ( pcMessage as character, pcSubSystem as character, piLogLevel as integer ):
    /* Obtain the current request object, which we will use to determine the logging solution. */
    define variable oRequest as Progress.Lang.OERequestInfo no-undo.
    assign oRequest = cast(session:current-request-info, Progress.Lang.OERequestInfo).

    /* Determine which logging solution to use as based on presence of a PAS Agent ID. */
    if valid-object(oRequest) and oRequest:AgentId ne ? then do:
        /* Prepare a logger using a custom name for the Spark Toolkit overall. */
        define variable oLogger as OpenEdge.Logging.ILogWriter no-undo.
        assign oLogger = OpenEdge.Logging.LoggerBuilder:GetLogger("SparkToolkit").

        /**
         * The legacy use case of the log level is to output certain messages when a certain value is met.
         * Examples:
         * -For messages at level 0 these should be treated as FATAL, and always output.
         * -For messages at level 1 treat as an Error condition which must be output.
         * -For messages at level 2 treat as Informational, level 3 as Debugging.
         * -For all other message levels these should be treated as Trace output.
         */
        case piLogLevel:
            when 0 then
                oLogger:Fatal(pcSubSystem, pcMessage).
            when 1 then
                oLogger:Error(pcSubSystem, pcMessage).
            when 2 then
                oLogger:Info(pcSubSystem, pcMessage).
            when 3 then
                oLogger:Debug(pcSubSystem, pcMessage).
            otherwise
                oLogger:Trace(pcSubSystem, pcMessage).
        end case.
    end. /* Has Agent/Session */
    else do:
        /* 0 (None), 1 (Errors), 2 (Basic), 3 (Verbose), 4 (Extended) */
        if piLogLevel eq ? then assign piLogLevel = 2.

        if valid-handle(log-manager) and log-manager:logfile-name ne ? and log-manager:logging-level ge piLogLevel then
            log-manager:write-message(pcMessage, caps(pcSubSystem)).
    end. /* No Agent/Session */

    finally:
        if valid-object(oRequest) then
            delete object oRequest no-error.
    end finally.
&if ({&IsClass} eq true) &then
end method.
&else
end function.
&endif

&if ({&IsClass} eq true) &then
method {&ClassProtected} void logError
&else
function logError returns logical {&FunctionPrivate}
&endif
    ( input pcContextMessage as character, input poErr as Progress.Lang.Error, input pcSubSystem as character, input piLogLevel as integer ):
    define variable iLoop      as integer                      no-undo.
    define variable cMessage   as character                    no-undo.
    define variable oAppError  as Progress.Lang.AppError       no-undo.
    define variable oSoapError as Progress.Lang.SoapFaultError no-undo.

    do on error undo, leave:
        if poErr:GetClass():IsA(get-class(Progress.Lang.AppError)) then
        do:
            oAppError = cast(poErr, Progress.Lang.AppError).
            if (oAppError:ReturnValue gt "") eq true then
                cMessage = trim(substitute("&1 &2", cMessage, oAppError:ReturnValue)).
        end.

        do iLoop = 1 to poErr:NumMessages:
            cMessage = trim(substitute("&1 &2", cMessage, poErr:GetMessage(iLoop))).
        end.

        if poErr:GetClass():IsA(get-class(Progress.Lang.SoapFaultError)) then
        do:
            oSoapError = cast(poErr,Progress.Lang.SoapFaultError).
            if valid-handle(oSoapError:SoapFault:soap-fault-detail) then
                cMessage = trim(substitute("&1 Soap Error: &2", cMessage, string(oSoapError:SoapFault:soap-fault-detail:get-serialized()))).
            cMessage = trim(substitute("&1 Soap Fault Code: &2", cMessage, oSoapError:SoapFault:soap-fault-code)).
            cMessage = trim(substitute("&1 Soap Fault String: &2", cMessage, oSoapError:SoapFault:soap-fault-string)).
            cMessage = trim(substitute("&1 Soap Fault Actor: &2", cMessage, oSoapError:SoapFault:soap-fault-actor)).
        end.

        /* if Stack Trace on then add to the message
           You can also set this session attribute using the -errorstack startup parameter. */
        if session:error-stack-trace then
            cMessage = trim(substitute(("&1~nStack Trace:~n&2"), cMessage, poErr:CallStack)).

        /* Append contect message to message */
        cMessage = trim(substitute("&1 &2", pcContextMessage, cMessage)).

        logMessage(cMessage, pcSubSystem, piLogLevel).
    end.
&if ({&IsClass} eq true) &then
end method.
&else
end function.
&endif
