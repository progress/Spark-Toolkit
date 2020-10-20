/*------------------------------------------------------------------------
    File        : DOHEventHandler
    Purpose     : Provide event listeners for the OpenEdge DOH class
    Description :
    Author(s)   : Peter Judge (pjudge) and Dustin Grau (dgrau)
    Created     : Thu Jul 21 16:06:27 EDT 2016
    Notes       : Create new instance in startup.p
                  Can only be used with 11.6.3 or later.
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Core.* from propath.
using OpenEdge.Logging.* from propath.
using OpenEdge.Net.HTTP.Filter.Writer.* from propath.
using OpenEdge.Net.HTTP.HttpHeader from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using OpenEdge.Net.HTTP.StatusCodeHelper from propath.
using OpenEdge.Web.DataObject.* from propath.
using OpenEdge.Web.DataObject.Writer.* from propath.
using OpenEdge.Web.SendExceptionError from propath.
using Spark.Core.Manager.ICatalogManager from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.ServiceLifeCycleEnum from propath.
using Spark.Core.Service.IDynamicResource from propath.
using Spark.Core.Service.ISparkEntity from propath.

class Spark.Core.Handler.DOHEventHandler use-widget-pool final:

    /* Circular dependency to cheat death (aka GC). */
    define private variable oCheat as Spark.Core.Handler.DOHEventHandler no-undo.

    /* Used to track the start of execution for a request. */
    define private variable dInvokeTime as datetime no-undo.

    /* Contains the current Client-Principal token for this request. */
    define private variable oPrincipal as OpenEdge.Security.Principal no-undo.

    /* Access the service-level logging manager. */
    define protected property oLogger as ILogWriter no-undo
        get():
            /* Create single logger instance for this class. */
            if not valid-object(oLogger) then
                assign oLogger = LoggerBuilder:GetLogger(this-object:getClass()).
            return oLogger.
        end get.
        private set.

    /* Access the Spark catalog manager to obtain service metadata. */
    define protected property oCatalogManager as ICatalogManager no-undo
        get():
            if not valid-object(oCatalogManager) then do:
                /* Manager may be optionally created, so check for existence before using. */
                define variable oManager as Ccs.Common.IManager no-undo.
                assign oManager = Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)).
                if valid-object(oManager) then
                    assign oCatalogManager = cast(oManager, ICatalogManager).
            end.
            return oCatalogManager.
        end get.
        private set.

    /* Access the Spark logging manager for consistent message output. */
    define protected property oLoggingManager as ILoggingManager no-undo
        get():
            if not valid-object(oLoggingManager) then do:
                /* Manager may be optionally created, so check for existence before using. */
                define variable oManager as Ccs.Common.IManager no-undo.
                assign oManager = Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)).
                if valid-object(oManager) then
                    assign oLoggingManager = cast(oManager, ILoggingManager).
            end.
            return oLoggingManager.
        end get.
        private set.

    constructor public DOHEventHandler():
        assign oCheat = this-object.

        this-object:UpdateLogging(). /* Refresh logging options for Spark. */

        this-object:DefineEvents(). /* Subscribe to standard DOH events. */

        this-object:InitializeRegistries(). /* Prepare the registries. */
    end constructor.

    destructor DOHEventHandler():
        DataObjectHandler:LoadEntity:Unsubscribe(this-object:LoadEntityHandler).
        DataObjectHandler:Invoking:Unsubscribe(this-object:InvokingHandler).
        DataObjectHandler:Invoked:Unsubscribe(this-object:InvokedHandler).
        DataObjectHandler:OperationError:Unsubscribe(this-object:OperationErrorHandler).
        DataObjectHandler:DiscoverService:Unsubscribe(this-object:DiscoverServiceHandler).
        DataObjectHandler:UnloadEntity:Unsubscribe(this-object:UnloadEntityHandler).
        DataObjectHandler:AuthorizeOperation:Unsubscribe(this-object:AuthorizeOperationHandler).
    end destructor.


    /***** Helper Methods *****/


    method private void SessionCleanup ( ):
        /* Always end this session for the current user (apply "reset" CP token). */
        Ccs.Common.Application:SessionManager:endRequestEnvironment().
        delete object oPrincipal no-error. /* Delete the CP token. */
    end method. /* SessionCleanup */


    method private character GetStatusReason ( input piStatusCode as integer ).
        define variable cReason as character no-undo.

        case piStatusCode: /* Provide known reasons for common HTTP status codes. */
            when 200 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:OK).
            when 201 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:Created).
            when 204 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:NoContent).
            when 400 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:BadRequest).
            when 404 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:NotFound).
            when 409 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:Conflict).
            when 418 then cReason = "I'm a teapot". /* Legit status, per RFC2324 ;) */
            when 429 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:TooManyRequests).
            when 500 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:InternalServerError).
            when 502 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:BadGateway).
            when 503 then cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:ServiceUnavailable).
            otherwise cReason = StatusCodeHelper:GetMessage(StatusCodeEnum:Unknown).
        end case.

        return cReason.
    end method. /* GetStatusReason */


    method private void DefineEvents ( ):
        DataObjectHandler:LoadEntity:Subscribe(this-object:LoadEntityHandler).
        DataObjectHandler:Invoking:Subscribe(this-object:InvokingHandler).
        DataObjectHandler:Invoked:Subscribe(this-object:InvokedHandler).
        DataObjectHandler:OperationError:Subscribe(this-object:OperationErrorHandler).
        DataObjectHandler:DiscoverService:Subscribe(this-object:DiscoverServiceHandler).
        DataObjectHandler:UnloadEntity:Subscribe(this-object:UnloadEntityHandler).
        DataObjectHandler:AuthorizeOperation:Subscribe(this-object:AuthorizeOperationHandler).
    end method. /* Define Events */


    method private void InitializeRegistries ( ):
        define variable dStart as datetime-tz no-undo.
        assign dStart = now. /* Mark start time. */

        /* Confirm whether the necessary OE.BL.BE class exists for the current environment. */
        define variable oBusinessEntity as Progress.Lang.Object no-undo.
        assign oBusinessEntity = Progress.Lang.Class:GetClass("OpenEdge.BusinessLogic.BusinessEntity") no-error.
        if not valid-object(oBusinessEntity) then do:
            /* Provide warnings in the log now, as this event handler class should be common to any standard startup for the Spark Toolkit. */
            oLoggingManager:logMessage("WARNING: Spark-Toolkit is unable to find the required OpenEdge.BusinessLogic.BusinessEntity class.", "SPARK-WARN", 0).
            oLoggingManager:logMessage("WARNING: Any SparkEntity/DynamicEntity classes cannot be loaded without this required super-class.", "SPARK-WARN", 0).
            oLoggingManager:logMessage("SOLUTION: Add OpenEdge.BusinessLogic.pl to PROPATH, available in versions 11.7.5, 12.1, and later.", "SPARK-WARN", 0).
        end. /* not valid-object */

        /* Read business entities from disk and creates method signatures for API requests. */
        if valid-object(oCatalogManager) then do:
            /* Inform the DOH of what portion of the URL is to be ignored. */
            DataObjectHandler:HANDLER_PREFIX = oCatalogManager:ServicePrefix.

            oLoggingManager:logMessage("Discovering resources to load...", "SPARK-STRT", 3).
            oCatalogManager:loadResources(). /* Locates available classes/procedures. */
            oLoggingManager:logMessage("Session Startup Resources Loaded", "SPARK-STRT", 3).
        end. /* valid-object */

        /* Start some of the internal registries by accessing the static properties. */
        ArgumentValueWriterRegistry:Registry.
        BodyWriterRegistry:Registry.
        EntityWriterRegistry:Registry.
        LogFilterBuilderRegistry:Registry.
        LoggerFilterRegistry:Registry.
        OperationHandlerRegistry:Registry.
        ResponseElementWriterRegistry:Registry.
        ServiceRegistry:Registry.

        if valid-object(oCatalogManager) then do:
            /* Register the ROOT service for handling the catalog. */
            oCatalogManager:registerService(ServiceRegistry:Registry, ServiceRegistry:ROOT_SERVICE_NAME, SemanticVersion:Parse("")).

            /* Register all known services for this application. */
            oCatalogManager:registerAllServices(ServiceRegistry:Registry).

            /* Create a master catalog for all services and cache the output. */
            oCatalogManager:getCatalog("", "").
        end. /* valid-object */

        /* Discover any file-based DOH services if ROOT.map exists. */
        define variable cServiceMapPath as character no-undo.

        file-info:file-name = "ROOT.map". /* Look initially for a ROOT.map file on disk. */

        if file-info:full-pathname eq ? then /* File is not present, so try a different common file. */
            file-info:file-name = "catalog.map". /* Try looking for a catalog.map file on disk. */

        if file-info:full-pathname ne ? then /* When file is present, obtain the base path of the file. */
            assign cServiceMapPath = replace(substring(file-info:full-pathname, 1, length(file-info:full-pathname) - length(file-info:file-name)), "~\", "/").

        if (cServiceMapPath gt "") eq true then do:
            /* Use the base path of the ROOT.map file to know where to look for other available .MAP files. */
            oLoggingManager:logMessage(substitute("Loading Service Registry data from &1", cServiceMapPath), "SPARK-STRT", 3).
            OpenEdge.Web.DataObject.ServiceRegistry:RegisterAllFromFolder(cServiceMapPath).
        end. /* cServiceMapPath */

        /* Log the end of the initialization process with an elapsed time. */
        oLoggingManager:logMessage(substitute("Finished Loading Resource Metadata in &1ms",
                                              interval(now, dStart, string(DateTimeAddIntervalEnum:Milliseconds))), "SPARK-STRT", 2).

        finally:
            if valid-object(oBusinessEntity) then
                delete object oBusinessEntity no-error.
        end finally.
    end method. /* InitializeRegistries */


    method private void UpdateLogging ( ):
        /**
         * Force the reset of the logging config object,
         * and update to the latest logging level/types.
         */
        if valid-object(oLoggingManager) then do:
            oLoggingManager:updateLoggingLevel().
            oLoggingManager:updateLogEntryTypes().
        end. /* Valid Object */
    end method. /* UpdateLogging */


    /***** Event Methods *****/


    /* Event published to perform a security check before running an entity.
     * @param Progress.Lang.Object The handler publishing the event
     * @param ServiceDiscoveryEventArgs Event args for this event
     */
    method private void AuthorizeOperationHandler ( input poSender    as Progress.Lang.Object,
                                                    input poEventArgs as AuthorizeOperationEventArgs):
        /* Operation is an object of type "MappedOperation" representing the current operation. */
        if extent(poEventArgs:Operation:AccessControl) ne ? then do:
            oLogger:Debug(substitute("Operation target '&1:&2' has ACL roles [&3]",
                                     poEventArgs:Operation:TargetName,
                                     poEventArgs:Operation:TargetFunction,
                                     String:Join(poEventArgs:Operation:AccessControl, ",":u))).

            /* User should be an object of type "Principal" obtained via the session:current-request-info. */
            if valid-object(poEventArgs:User) and valid-handle(poEventArgs:User:Token) then
                oLogger:Debug(substitute("Found user information for '&1@&2' with roles '&3'",
                                         poEventArgs:User:Token:user-id,
                                         poEventArgs:User:Token:domain-name,
                                         poEventArgs:User:Token:roles)).
        end. /* Has AccessControl */
    end method. /* AuthorizeOperationHandler */


    /* Event published to discover information about an available service.
     * eg. Determine the API version based on URL or header information.
     * @param Progress.Lang.Object The handler publishing the event
     * @param ServiceDiscoveryEventArgs Event args for this event
     */
    method private void DiscoverServiceHandler ( input poSender    as Progress.Lang.Object,
                                                 input poEventArgs as ServiceDiscoveryEventArgs):
        /* Existing pattern uses the URL path to determine the name and URI of the current service being requested,
         * essentially the part after the /web/<prefix>/ segment of our request. Once the name and URI of the service
         * has been isolated, use either poEventArgs:Registry or ServiceRegistry object instance is consulted via
         * HasService() and GetService() by poEventArgs:Name and poEventArgs:Version and assigned to poEventArgs:Service.
         * The default pattern is /pdo[[/{version}]/{service}] but could be adjusted to meet your needs.
         *
         * Note that the ServiceRegistry will attempt to load an implementation of the class from the CCS ServiceManager,
         * or otherwise fall back to implementing the default class. When a .map file is present, it is the job of the
         * ServiceRegistryLoader to configure each available service in the registry by use of the PutOperation and
         * related methods in the ServiceRegistry implementation.
         */
        define variable dStart  as datetime no-undo.
        define variable lExists as logical  no-undo initial false.

        assign dStart = now. /* Record start of discovery process. */

        /* If we have a service, or something already went wrong, return. */
        if valid-object(poEventArgs:Service) or poEventArgs:Cancel or valid-object(poEventArgs:Error) then return.

        /* Output the parsed service-related values as seen by the registry. */
        oLogger:Debug(substitute("DISCOVER - WebApp: &1 | Service: &2 v&3 | URI: &4 [&5 &6]",
                                 poEventArgs:Request:WebAppPath,
                                 poEventArgs:Name, SemanticVersion:Parse(poEventArgs:version):ToString(),
                                 poEventArgs:ServiceURI, poEventArgs:Request:Method, poEventArgs:Request:URI:ToString())).

        if valid-object(oCatalogManager) then do on error undo, leave:
            /* Consult the built-in registry which implements IServiceRegistry. */
            if valid-object(poEventArgs:Registry) then
                if poEventArgs:Registry:HasService(poEventArgs:Name, poEventArgs:Version) then
                    assign poEventArgs:Service = poEventArgs:Registry:GetService(poEventArgs:Name, poEventArgs:Version).

            /**
             * Attempt to locate and register an available service from the Spark Toolkit metadata. In this use-case the available
             * entities are dynamically discovered through class reflection and configured with specific URI patterns and verbs for
             * access. This data can be converted into a compatible format as used by the OE.W.DO.ServiceRegistry and DOH classes.
             */
            assign lExists = valid-object(poEventArgs:Service).
            if not lExists then do:
                /* Utilize the catalog manager to obtain service information. */
                assign poEventArgs:Service = oCatalogManager:registerService(poEventArgs:Registry,
                                                                             poEventArgs:Name,
                                                                             SemanticVersion:Parse(poEventArgs:Version)).

                /* If service is still not available, log a message and allow event to run the default handler. */
                if not valid-object(poEventArgs:Service) then
                    oLogger:Debug(substitute("DISCOVER - Service registration failed for '&1' v&2",
                                             poEventArgs:Name, SemanticVersion:Parse(poEventArgs:Version):ToString())).
            end. /* No Service Available */

            catch err as Progress.Lang.Error:
                /* Important: Don't throw an error, just assign to the event args, create a message, and continue. */
                assign poEventArgs:Error = err.
                oLogger:Error(substitute("DISCOVER - &1: &2", poEventArgs:ServiceURI, err:GetMessage(1))).
            end catch.
            finally:
                /* Note whether we found or created the service being returned. */
                oLogger:Debug(substitute("DISCOVER - Service '&1' &2 in &3ms",
                                         poEventArgs:Name, string(lExists, "located/created"),
                                         interval(now, dStart, string(DateTimeAddIntervalEnum:Milliseconds)))).
            end finally.
        end. /* Catalog Manager Not Enabled */
        else
            oLogger:Debug("DISCOVER - Catalog Manager not in use for service discovery.").

        /**
         * If we do not have a registered service by now, the default event logic will look on disk for a .GEN and/or .MAP file.
         */
    end method. /* DiscoverServiceHandler */


    /* Event published to invoke/load a piece of business logic (aka Business Entity).
     * If none exists, we try a simple DYNAMIC-NEW.
     * @param Progress.Lang.Object The handler publishing the event
     * @param HandlerLoadEntityEventArgs Event args for this event
     */
    method private void LoadEntityHandler ( input poSender    as Progress.Lang.Object,
                                            input poEventArgs as HandlerLoadEntityEventArgs ):
        /* Leave a log message that the DOH event handler is being loaded. */
        oLogger:Debug(substitute("DOH-LOAD - Requested Entity '&1' as &2", poEventArgs:Operation:TargetName, poEventArgs:Operation:TargetType)).

        this-object:UpdateLogging(). /* Refresh logging options for Spark. */

        /* Determine the target type of the entity, which for this implementation should be Class or Procedure. */
        define variable oTargetType as TargetTypeEnum no-undo.
        assign oTargetType = TargetTypeEnum:GetEnum(poEventArgs:Operation:TargetType).

        /* Attempt to load the requested service for this business entity. */
        case oTargetType:
            when TargetTypeEnum:Class then do:
                define variable oServiceClass as Progress.Lang.Class no-undo.
                assign oServiceClass = Progress.Lang.Class:GetClass(poEventArgs:Operation:TargetName) no-error.
                if valid-object(oServiceClass) then do:
                    /* Start and obtain a service class instance from the local CCS ServiceManager implementation. */
                    /* DO NOT use an "assign" here as that causes a syntax error with the dynamic-new declaration. */
                    poEventArgs:BusinessEntity = Ccs.Common.Application:ServiceManager:getService(oServiceClass).

                    /* Leave a log message that the DOH event handler has been loaded. */
                    oLogger:Debug(substitute("DOH-LOAD - Located Class Entity '&1'", oServiceClass:TypeName)).
                end. /* valid-object */
            end. /* class */

            when TargetTypeEnum:Procedure then do:
                define variable hProcedure as handle no-undo.

                /* Start the procedure as a persistent handle and store in an OE.Core.WidgetHandle class. */
                run value(poEventArgs:Operation:TargetName) persistent set hProcedure.
                assign poEventArgs:BusinessEntity = new WidgetHandle(hProcedure, true). /* true = auto-destroy */

                /* Leave a log message that the DOH event handler has been loaded. */
                oLogger:Debug(substitute("DOH-LOAD - Located Procedure Entity '&1'", poEventArgs:Operation:TargetName)).
            end. /* procedure */

            otherwise
                assign poEventArgs:BusinessEntity = ?.
        end case. /* oTargetType */

        /**
         * If we do not have an available entity by now, the default event logic will be run within the DOH class.
         */
    end method. /* LoadEntityHandler */


    /* Event published before the business logic function is called by the handler.
     * @param Progress.Lang.Object The handler publishing the event
     * @param OperationInvocationEventArgs Event args for this event
     */
    method private void InvokingHandler ( input poSender    as Progress.Lang.Object,
                                          input poEventArgs as OperationInvocationEventArgs ):
        assign dInvokeTime = now. /* Remember when we start execution. */

        /* Determine the target type of the entity. */
        define variable oTargetType as TargetTypeEnum no-undo.
        assign oTargetType = TargetTypeEnum:GetEnum(poEventArgs:Operation:TargetType).

        if poEventArgs:Operation:ServiceURI eq "/" then
            oLogger:Debug(substitute("INVOKING - &1 '&2' [&3]",
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:TargetName)).
        if oTargetType eq TargetTypeEnum:Procedure then
            oLogger:Debug(substitute("INVOKING - &1 /&2 &3 -> '&4' in &5",
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:ServiceURI,
                                     poEventArgs:Operation:TargetFunction,
                                     poEventArgs:Operation:TargetName)).
        else
            oLogger:Debug(substitute("INVOKING - &1 /&2/&3 -> &4:&5",
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:ServiceURI,
                                     poEventArgs:Operation:TargetName,
                                     poEventArgs:Operation:TargetFunction)).

        /**
         * Assert the current user's identity for this session request.
         *
         * Note: For working with anonymous security, ensure the following are set:
         *  OEClientPrincipalFilter.anonymous=true
         *  OEClientPrincipalFilter.sealAnonymous=true
         *  OEClientPrincipalFilter.passthru=true
         *
         * No principal token will be available without the above settings present.
         */
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).
        if valid-object(oPrincipal) then
            Ccs.Common.Application:SessionManager:establishRequestEnvironment(oPrincipal:Token).

        catch err as Progress.Lang.Error:
            assign poEventArgs:Error = err.
            oLogger:Error(substitute("INVOKING - &1: &2", poEventArgs:Operation:TargetName, err:GetMessage(1))).
        end catch.
    end method. /* InvokingHandler */


    /* Event published after the business logic function was called by the handler.
     * @param Progress.Lang.Object The handler publishing the event
     * @param OperationInvocationEventArgs Event args for this event
     */
    method private void InvokedHandler ( input poSender    as Progress.Lang.Object,
                                         input poEventArgs as OperationInvocationEventArgs ):
        define variable oData    as JsonObject no-undo.
        define variable lChanged as logical    no-undo initial false.

        case true:
            when type-of(poEventArgs:BusinessEntity, ISparkEntity) then do:
                /* If dealing with a Spark Entity class performing a READ operation, attempt to get
                 * the last-known number of records read and return as part of the response object.
                 * Also output any messages queued for output as part of any executed class method.
                 */
                define variable oEntity as ISparkEntity no-undo.

                /* Cast to JSON object if found to be of valid type. */
                if valid-object(poEventArgs:Response:Entity) and
                   type-of(poEventArgs:Response:Entity, JsonObject) then do:
                    assign oData = cast(cast(poEventArgs:Response:Entity, JsonObject):Clone(), JsonObject).
                    assign oEntity = cast(poEventArgs:BusinessEntity, ISparkEntity).

                    if poEventArgs:Operation:Method eq OpenEdge.Net.HTTP.MethodEnum:get and
                       poEventArgs:Operation:TargetFunction matches "Read*" then do on error undo, leave:
                         /* Append a record count property to the outbound object. */
                         if valid-object(oEntity) and valid-object(oData) and not oData:Has("numRecs") then do:
                             oData:Add("numRecs", oEntity:LastCount).
                             assign lChanged = true.
                         end. /* Needs numRecs */
                     end. /* GET/READ */

                     /* Append any context messages to the output. */
                     if valid-object(oEntity) and valid-object(oData) and oEntity:oContextMessage:hasAnyMessages() then do:
                         oData:Add(oEntity:oContextMessage:ContextPropName, oEntity:oContextMessage:getMessageArray()).
                         oData:Add(oEntity:oContextMessage:ReturnValueName, oEntity:oContextMessage:ReturnValue).
                         assign lChanged = true.
                     end. /* Has Messages */

                     if valid-object(oData) and lChanged then
                         poEventArgs:Response:Entity = cast(oData:Clone(), JsonObject).
                end. /* Valid JSON Entity */
            end. /* ISparkEntity */

            when type-of(poEventArgs:BusinessEntity, IDynamicResource) then do:
                /* If dealing with any Dynamic Resource, check for context messages to add to the response. */
                define variable oResource as IDynamicResource no-undo.

                /* Cast to JSON object if found to be of valid type. */
                if valid-object(poEventArgs:Response:Entity) and
                   type-of(poEventArgs:Response:Entity, JsonObject) then do:
                    assign oData = cast(cast(poEventArgs:Response:Entity, JsonObject):Clone(), JsonObject).
                    assign oResource = cast(poEventArgs:BusinessEntity, IDynamicResource).

                    /* Append any context messages to the output. */
                    if valid-object(oResource) and valid-object(oData) and oResource:oContextMessage:hasAnyMessages() then do:
                        oData:Add(oResource:oContextMessage:ContextPropName, oResource:oContextMessage:getMessageArray()).
                        if oResource:oContextMessage:ReturnValue ne ? then
                            oData:Add(oResource:oContextMessage:ReturnValueName, oResource:oContextMessage:ReturnValue).
                        assign lChanged = true.
                    end. /* Has Messages */

                    if valid-object(oData) and lChanged then
                        poEventArgs:Response:Entity = cast(oData:Clone(), JsonObject).
                end. /* Valid JSON Entity */
            end. /* IDynamicResource */
        end case.

        define variable iElapsed as int64 no-undo initial 0.
        if dInvokeTime ne ? then do on error undo, leave:
            define variable oHeader as HttpHeader no-undo.

            /* Add the elapsed time for this request as a custom header value. */
            assign iElapsed = interval(now, dInvokeTime, string(OpenEdge.Core.DateTimeAddIntervalEnum:Milliseconds)).
            assign oHeader = new HttpHeader("X-Elapsed", trim(string(iElapsed, ">>>,>>>,>>9")) + "ms").
            poEventArgs:Response:SetHeader(oHeader).
        end. /* iStart gt 0 */

        /* Determine the target type of the entity. */
        define variable oTargetType as TargetTypeEnum no-undo.
        assign oTargetType = TargetTypeEnum:GetEnum(poEventArgs:Operation:TargetType).

        if poEventArgs:Operation:ServiceURI eq "/" then
            oLogger:Debug(substitute("INVOKED_ - &1 '&2' [&3] (&4ms)",
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:TargetName,
                                     iElapsed)).
        if oTargetType eq TargetTypeEnum:Procedure then
            oLogger:Debug(substitute("INVOKED_ - &1 /&2 &3 -> '&4' in &5",
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:ServiceURI,
                                     poEventArgs:Operation:TargetFunction,
                                     poEventArgs:Operation:TargetName)).
        else
            oLogger:Debug(substitute("INVOKED_ - &1 /&2/&3 -> &4:&5 (&6ms)",
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:ServiceURI,
                                     poEventArgs:Operation:TargetName,
                                     poEventArgs:Operation:TargetFunction,
                                     iElapsed)).

        catch err as Progress.Lang.Error:
            assign poEventArgs:Error = err.
            oLogger:Error(substitute("INVOKED_ - &1: &2", poEventArgs:Operation:TargetName, err:GetMessage(1))).
        end catch.
        finally:
            delete object oData no-error. /* Delete the temporary data object. */
            this-object:SessionCleanup(). /* Perform any necessary cleanup. */
        end finally.
    end method. /* InvokedHandler */


    /* Event published when an error is encountered.
     * @param Progress.Lang.Object The handler publishing the event
     * @param HandlerErrorEventArgs Event args for this event
     */
    method private void OperationErrorHandler ( input poSender    as Progress.Lang.Object,
                                                input poEventArgs as HandlerErrorEventArgs ):
        oLogger:Error(substitute("OP-ERROR - &1: &2", poEventArgs:Operation:TargetName,
                      if valid-object(poEventArgs:OperationError) then poEventArgs:OperationError:GetMessage(1)
                      else "-no valid error object-")).

        catch err as Progress.Lang.Error:
            /* Just provide a message, but don't throw this as an error (we want to focus on what the entity threw). */
            oLogger:Error(substitute("An error occurred while handling an Operation Error: &1", err:GetMessage(1))).
        end catch.
        finally:
            this-object:SessionCleanup(). /* Perform any necessary cleanup. */
        end finally.
    end method. /* OperationErrorHandler */


    /* Event published to unload a piece of business logic (aka Business Entity).
     * @param Progress.Lang.Object The handler publishing the event
     * @param HandlerLoadEntityEventArgs Event args for this event
     */
    method private void UnloadEntityHandler ( input poSender    as Progress.Lang.Object,
                                              input poEventArgs as HandlerLoadEntityEventArgs ):
        /* Determine the target type of the entity. */
        define variable oTargetType as TargetTypeEnum no-undo.
        assign oTargetType = TargetTypeEnum:GetEnum(poEventArgs:Operation:TargetType).

        if oTargetType eq TargetTypeEnum:Procedure then do:
            /* Directly destroy the WidgetHandle class around any procedures (auto-destroys procedure handle). */
            delete object poEventArgs:BusinessEntity no-error.
            assign poEventArgs:BusinessEntity = ?.
        end. /* procedure */

        /* Stop all services with a "request" lifetime. */
        Ccs.Common.Application:ServiceManager:stopServices(ServiceLifeCycleEnum:request).

        /* Leave a log message that the DOH event handler has been loaded. */
        oLogger:Debug(substitute("DOH-UNLD - Unloading Entity '&1'", poEventArgs:Operation:TargetName)).
    end method. /* UnloadEntityHandler */

end class.