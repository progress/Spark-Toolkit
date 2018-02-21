/*------------------------------------------------------------------------
    File        : DOHEventHandler
    Purpose     : Provide event listeners for the OpenEdge DOH class
    Description :
    Author(s)   : Peter Judge (pjudge) and Dustin Grau (dgrau)
    Created     : Thu Jul 21 16:06:27 EDT 2016
    Notes       : Create new instance in startup.p
                  Can only be used with 11.6.3 or later.
  ----------------------------------------------------------------------*/

&GLOBAL-DEFINE MIN_LOGGING_LEVEL 3
&GLOBAL-DEFINE MIN_VERSION_11_7_2 (lookup(substring(proversion(1), 1, 6), "11.6.3,11.6.4,11.6.5,11.7.0,11.7.1") = 0)

block-level on error undo, throw.

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Net.HTTP.HttpHeader from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using OpenEdge.Net.HTTP.StatusCodeHelper from propath.
using Spark.Core.Manager.ServiceLifeCycleEnum from propath.
using Spark.Core.Service.ISparkEntity from propath.

class Spark.Core.Handler.DOHEventHandler use-widget-pool final:

    /* Circular dependency to cheat death (aka GC). */
    define private variable oCheat as Spark.Core.Handler.DOHEventHandler no-undo.

    /* Used to track the start of execution for a request. */
    define private variable dInvokeTime as datetime no-undo.

    /* Contains the current Client-Principal token for this request. */
    define private variable oPrincipal as OpenEdge.Security.Principal no-undo.

    /* Access the standard logging manager for PMFO. */
    define protected property oLoggingManager as Spark.Core.Manager.ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then do:
                define variable oManager as Ccs.Common.IManager no-undo.
                assign oManager = Ccs.Common.Application:StartupManager:getManager(get-class(Spark.Core.Manager.ILoggingManager)).
                if valid-object(oManager) then
                    assign oLoggingManager = cast(oManager, Spark.Core.Manager.ILoggingManager).
            end.
            return oLoggingManager.
        end get.
        set.

    constructor public DOHEventHandler():
        assign oCheat = this-object.

        OpenEdge.Web.DataObject.DataObjectHandler:LoadEntity:Subscribe(this-object:LoadEntityHandler).
        OpenEdge.Web.DataObject.DataObjectHandler:Invoking:Subscribe(this-object:InvokingHandler).
        OpenEdge.Web.DataObject.DataObjectHandler:Invoked:Subscribe(this-object:InvokedHandler).
        OpenEdge.Web.DataObject.DataObjectHandler:OperationError:Subscribe(this-object:OperationErrorHandler).
        &IF {&MIN_VERSION_11_7_2} &THEN
        /* Only available for 11.7.2 and later. */
        OpenEdge.Web.DataObject.DataObjectHandler:DiscoverService:Subscribe(this-object:DiscoverServiceHandler).
        OpenEdge.Web.DataObject.DataObjectHandler:UnloadEntity:Subscribe(this-object:UnloadEntityHandler).
        &ENDIF
    end constructor.

    destructor DOHEventHandler():
        OpenEdge.Web.DataObject.DataObjectHandler:LoadEntity:Unsubscribe(this-object:LoadEntityHandler).
        OpenEdge.Web.DataObject.DataObjectHandler:Invoking:Unsubscribe(this-object:InvokingHandler).
        OpenEdge.Web.DataObject.DataObjectHandler:Invoked:Unsubscribe(this-object:InvokedHandler).
        OpenEdge.Web.DataObject.DataObjectHandler:OperationError:Unsubscribe(this-object:OperationErrorHandler).
        &IF {&MIN_VERSION_11_7_2} &THEN
        /* Only available for 11.7.2 and later. */
        OpenEdge.Web.DataObject.DataObjectHandler:DiscoverService:Unsubscribe(this-object:DiscoverServiceHandler).
        OpenEdge.Web.DataObject.DataObjectHandler:UnloadEntity:Unsubscribe(this-object:UnloadEntityHandler).
        &ENDIF
    end destructor.


    /***** Helper Methods *****/


    method private void SessionCleanup ( ):
        /* Always end this session for the current user (apply "reset" CP token). */
        Ccs.Common.Application:SessionManager:endRequestEnvironment().
        delete object oPrincipal no-error. /* Delete the CP token. */
    end method. /* SessionCleanup */

    method private character GetStatusReason ( input piStatusCode as integer ).
        define variable cReason as character no-undo.

        case piStatusCode: /* Provide standard or custom reasons for an HTTP status. */
            when 200 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:OK).
            when 201 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:Created).
            when 204 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:NoContent).
            when 404 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:NotFound).
            when 409 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:Conflict).
            when 418 then cReason = "I'm a teapot". /* Legit status, per RFC2324 ;) */
            when 429 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:TooManyRequests).
            when 500 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:InternalServerError).
            when 502 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:BadGateway).
            when 503 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:ServiceUnavailable).
        end case.

        return cReason.
    end method. /* GetStatusReason */


    /***** Event Methods *****/


    /* Event published to discover information about an available service.
     * eg. Determine the API version based on URL or header information.
     * @param Progress.Lang.Object The handler publishing the event
     * @param ServiceDiscoveryEventArgs Event args for this event
     */
    method private void DiscoverServiceHandler ( input poSender    as Progress.Lang.Object,
                                                 input poEventArgs as OpenEdge.Web.DataObject.ServiceDiscoveryEventArgs):
        /* Existing pattern uses the URL path to determine the name and URI of the current service being requested,
         * essentially the part after the /pdo/ segment of our request. Once the name and URI of the service has been
         * isolated, use either poEventArgs:Registry or ServiceRegistry object instance is consulted via HasService()
         * and GetService() by poEventArgs:Name and poEventArgs:Version and assigned to poEventArgs:Service.
         * The default pattern is /pdo/{version}/{service} but could be adjusted to meet your needs.
         */
        oLoggingManager:logMessage(substitute("&1 &2 : &3 v&4",
                                              poEventArgs:Request:WebAppPath, poEventArgs:Request:PathInfo,
                                              poEventArgs:Name, poEventArgs:Version), "DISCOVER", {&MIN_LOGGING_LEVEL}).

        catch err as Progress.Lang.Error:
            oLoggingManager:logError(string(poEventArgs:ServiceURI), err, "DISCOVER", 0).
        end catch.
    end method. /* DiscoverServiceHandler */

    /* Event published to invoke/load a piece of business logic (aka Business Entity).
     * If none exists, we try a simple DYNAMIC-NEW.
     * @param Progress.Lang.Object The handler publishing the event
     * @param HandlerLoadEntityEventArgs Event args for this event
     */
    method private void LoadEntityHandler ( input poSender    as Progress.Lang.Object,
                                            input poEventArgs as OpenEdge.Web.DataObject.HandlerLoadEntityEventArgs ):
        if valid-object(oLoggingManager) then do:
            /* Check if there has been a change to the logging options (logging.json). */
            oLoggingManager:updateLoggingLevel().
            oLoggingManager:updateLogEntryTypes().

            /* Leave a log message that the DOH event handler is being loaded. */
            oLoggingManager:logMessage(substitute("Requested Entity '&1'", poEventArgs:Operation:TargetName), "DOH-LOAD", {&MIN_LOGGING_LEVEL}).
        end. /* valid-object */

        /* Attempt to load the requested service for this business entity. */
        define variable oServiceClass as Progress.Lang.Class no-undo.
        assign oServiceClass = Progress.Lang.Class:GetClass(poEventArgs:Operation:TargetName) no-error.
        if valid-object(oServiceClass) then do:
            /* Start and obtain a service class instance from the local CCS ServiceManager implementation. */
            assign poEventArgs:BusinessEntity = Ccs.Common.Application:ServiceManager:getService(oServiceClass).

            /* Leave a log message that the DOH event handler has been loaded. */
            if valid-object(oLoggingManager) then
                oLoggingManager:logMessage(substitute("Located Entity '&1'", oServiceClass:TypeName), "DOH-LOAD", {&MIN_LOGGING_LEVEL}).
        end. /* valid-object */
    end method. /* LoadEntityHandler */

    /* Event published before the business logic function is called by the handler.
     * @param Progress.Lang.Object The handler publishing the event
     * @param OperationInvocationEventArgs Event args for this event
     */
    method private void InvokingHandler ( input poSender    as Progress.Lang.Object,
                                          input poEventArgs as OpenEdge.Web.DataObject.OperationInvocationEventArgs ):
        assign dInvokeTime = now. /* Remember when we start execution. */

        if poEventArgs:Operation:ServiceURI eq "/" then
            oLoggingManager:logMessage(substitute("&1 /&2 (&3)",
                                                  string(poEventArgs:Operation:Method),
                                                  poEventArgs:Operation:ServiceName,
                                                  poEventArgs:Operation:TargetName), "INVOKING", {&MIN_LOGGING_LEVEL}).
        else
            oLoggingManager:logMessage(substitute("&1 /&2/&3 -> &4:&5",
                                                  string(poEventArgs:Operation:Method),
                                                  poEventArgs:Operation:ServiceName,
                                                  poEventArgs:Operation:ServiceURI,
                                                  poEventArgs:Operation:TargetName,
                                                  poEventArgs:Operation:TargetFunction), "INVOKING", {&MIN_LOGGING_LEVEL}).

        /**
         * Assert the current user's identity for this session request.
         *
         * Note: For working with anonymous security, ensure the following are set:
         *  OEClientPrincipalFilter.anonymous=true
         *  OEClientPrincipalFilter.sealAnonymous=true
         *  OEClientPrincipalFilter.passthru=true
         */
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).
        Ccs.Common.Application:SessionManager:establishRequestEnvironment(oPrincipal:Token).

        catch err as Progress.Lang.Error:
            oLoggingManager:logError(string(poEventArgs:Operation:TargetName), err, "INVOKING", 0).
        end catch.
    end method. /* InvokingHandler */

    /* Event published after the business logic function was called by the handler.
     * @param Progress.Lang.Object The handler publishing the event
     * @param OperationInvocationEventArgs Event args for this event
     */
    method private void InvokedHandler ( input poSender    as Progress.Lang.Object,
                                         input poEventArgs as OpenEdge.Web.DataObject.OperationInvocationEventArgs ):
        if poEventArgs:Operation:ServiceURI eq "/" then
            oLoggingManager:logMessage(substitute("&1 /&2 (&3)",
                                                  string(poEventArgs:Operation:Method),
                                                  poEventArgs:Operation:ServiceName,
                                                  poEventArgs:Operation:TargetName), "INVOKED", {&MIN_LOGGING_LEVEL}).
        else
            oLoggingManager:logMessage(substitute("&1 /&2/&3 -> &4:&5",
                                                  string(poEventArgs:Operation:Method),
                                                  poEventArgs:Operation:ServiceName,
                                                  poEventArgs:Operation:ServiceURI,
                                                  poEventArgs:Operation:TargetName,
                                                  poEventArgs:Operation:TargetFunction), "INVOKED", {&MIN_LOGGING_LEVEL}).

        /* If dealing with a READ operation from an ISparkEntity class, attempt to get
         * the last-known number of records read and return as part of the response object.
         */
        if poEventArgs:BusinessEntity:GetClass():IsA(get-class(ISparkEntity)) and
           poEventArgs:Operation:Method eq OpenEdge.Net.HTTP.MethodEnum:get and
           poEventArgs:Operation:TargetFunction matches "Read*" then do on error undo, throw:
            define variable oData   as JsonObject   no-undo.
            define variable oEntity as ISparkEntity no-undo.

            /* Cast to JSON object if found to be of valid type. */
            if valid-object(poEventArgs:Response:Entity) and
               type-of(poEventArgs:Response:Entity, JsonObject) then do:
                assign oData = cast(poEventArgs:Response:Entity, JsonObject).

                /* Append a record count property to the outbound object. */
                if valid-object(oData) and not oData:Has("numRecs") then do:
                    assign oEntity = cast(poEventArgs:BusinessEntity, ISparkEntity).
                    if valid-object(oEntity) then
                        oData:Add("numRecs", oEntity:LastCount).
                    poEventArgs:Response:Entity = cast(oData:Clone(), JsonObject).
                end. /* Valid JSON */
            end. /* Valid Entity */

            finally:
                delete object oData no-error.
                /* Note: Do not delete oEntity here, as that removes the cached BusinessEntity instance from the DOH. */
            end finally.
        end. /* Read Operation */

        if dInvokeTime ne ? then do on error undo, throw:
            define variable fElapsed as decimal    no-undo initial 0.
            define variable oHeader  as HttpHeader no-undo.

            /* Add the elapsed time for this request as a header value. */
            assign fElapsed = interval(now, dInvokeTime, string(OpenEdge.Core.DateTimeAddIntervalEnum:Milliseconds)) / 1000.

            assign oHeader = new HttpHeader("X-Elapsed", trim(string(fElapsed, ">>>9.99")) + "sec.").
            poEventArgs:Response:SetHeader(oHeader).
        end. /* iStart gt 0 */

        catch err as Progress.Lang.Error:
            oLoggingManager:logError(string(poEventArgs:Operation:TargetName), err, "INVOKED", 0).
        end catch.
        finally:
            this-object:SessionCleanup(). /* Perform any necessary cleanup. */
        end finally.
    end method. /* InvokedHandler */

    /* Event published when an error is encountered.
     * @param Progress.Lang.Object The handler publishing the event
     * @param HandlerErrorEventArgs Event args for this event
     */
    method private void OperationErrorHandler ( input poSender    as Progress.Lang.Object,
                                                input poEventArgs as OpenEdge.Web.DataObject.HandlerErrorEventArgs ):
        oLoggingManager:logError(string(poEventArgs:Operation:TargetName), poEventArgs:Error, "OP-ERROR", 0).

        define variable iCode as integer no-undo.
        assign iCode = poEventArgs:Error:GetMessageNum(1).
        if iCode lt 0 then
            assign iCode = iCode * -1. /* Flip negative numbers. */

        if iCode ge 200 and iCode le 599 then do:
            /* Use code as HTTP response code. */
            poEventArgs:Response:StatusCode = iCode.
            poEventArgs:Response:StatusReason = this-object:GetStatusReason(iCode).
        end.
        else do:
            /* Default to an HTTP 500/Error. */
            poEventArgs:Response:StatusCode = integer(StatusCodeEnum:InternalServerError).
            poEventArgs:Response:StatusReason = StatusCodeHelper:GetMessage(StatusCodeEnum:InternalServerError).
        end.
        poEventArgs:ReturnStatusCode = 0. /* Use event args as response. */

        finally:
            this-object:SessionCleanup(). /* Perform any necessary cleanup. */
        end finally.
    end method. /* OperationErrorHandler */

    /* Event published to unload a piece of business logic (aka Business Entity).
     * @param Progress.Lang.Object The handler publishing the event
     * @param HandlerLoadEntityEventArgs Event args for this event
     */
    method private void UnloadEntityHandler ( input poSender    as Progress.Lang.Object,
                                              input poEventArgs as OpenEdge.Web.DataObject.HandlerLoadEntityEventArgs ):
        if valid-object(oLoggingManager) then do:
            /* Leave a log message that the DOH event handler has been loaded. */
            Ccs.Common.Application:ServiceManager:stopServices(ServiceLifeCycleEnum:request).
            oLoggingManager:logMessage(poEventArgs:Operation:TargetName, "DOH-UNLD", {&MIN_LOGGING_LEVEL}).
        end. /* valid-object */
    end method. /* UnloadEntityHandler */

end class.