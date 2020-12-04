/*------------------------------------------------------------------------
    File        : ServiceManager
    Purpose     : Primary manager for framework startup
    Description : Service Startup Manager
    Author(s)   : rosmith
    Created     : Nov 02 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Ccs.Common.IService from propath.
using Ccs.ServiceManager.ILifecycleScope from propath.
using Ccs.ServiceManager.ITransientScope from propath.
using Spark.Core.Message.IAbstractMessage from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.ServiceLifeCycleEnum from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Util.OSTools from propath.

block-level on error undo, throw.

class Spark.Core.Manager.ServiceManager inherits Spark.Core.Manager.Manager implements Spark.Core.Manager.IServiceManager:

    define protected property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.

    define private temp-table ttImplMapping no-undo serialize-name "ServiceMapping"
        field Service        as character
        field Implementation as character
        index ix1 as primary unique Service.

    define private temp-table ttLifeCycle no-undo serialize-name "ServiceLifeCycle"
        field ServiceMatch as character
        field LifeCycle    as character.
    /* No index - Want them in the order they are listed! */

    define private dataset dsConfig serialize-name "Config"
        for ttImplMapping, ttLifeCycle.

    define private temp-table ttLifeCycleMapping no-undo
        field ServiceMatch as character
        field LifeCycle    as character
        field SearchOrder  as integer
        index ix1 as primary SearchOrder.

    define private temp-table ttServices no-undo
        field ServiceInstance as Progress.Lang.Object
        field ServiceTypeName as character
        field AliasName       as character
        field LifeCycle       as character
        index ix1            ServiceInstance
        index ix2 as primary ServiceTypeName AliasName
        index ix3            LifeCycle ServiceTypeName AliasName.

    constructor public ServiceManager ( ):
        super().
    end constructor.

    method override public void initialize ( ):
        loadConfig().
    end method.

    method override public void dispose ( ):
    end method.

    method protected void loadConfig ( ):

        define variable cCfgFileName     as character no-undo.
        define variable cFullCfgFileName as character no-undo.
        define variable iCnt             as integer   no-undo.

        cCfgFileName = "service.json".
        file-info:file-name = OSTools:sparkConf + cCfgFileName.
        cFullCfgFileName = file-info:full-pathname.

        if cFullCfgFileName ne ? then
        do:
            dataset dsConfig:read-json("FILE", cFullCfgFileName, "EMPTY").

            for each ttLifeCycle:
                iCnt = iCnt + 1.
                create ttLifeCycleMapping.
                buffer-copy ttLifeCycle to ttLifeCycleMapping
                assign ttLifeCycleMapping.SearchOrder = iCnt.
                delete ttLifeCycle.
            end.
        end.
        else do:
            undo, throw new AppError(substitute("Services config file [&1] not found in [&2]", cCfgFileName, OSTools:sparkConf), 0).
        end.

        /* Create a known lifecycle mapping (session) for the OE.W.DO.ServiceRegistryImpl class,
         * as we do not want this to be stopped at the end of each request (as is the default).
         * Without this setting, the DataObjectHandler may not work as expected!
         */
        if not can-find(first ttLifeCycleMapping no-lock
                        where ttLifeCycleMapping.ServiceMatch eq "OpenEdge.Web.DataObject.ServiceRegistryImpl") then do:
            create ttLifeCycleMapping.
            assign
                ttLifeCycleMapping.ServiceMatch = "OpenEdge.Web.DataObject.ServiceRegistryImpl"
                ttLifeCycleMapping.LifeCycle    = ServiceLifeCycleEnum:session:ToString()
                .
        end. /* not can-find */

        /* Create a known lifecycle mapping (session) for the OE.W.DO.ServiceRegistryLoader class,
         * as we do not want this to be stopped at the end of each request (as is the default).
         * Without this setting, the DataObjectHandler may not work as expected!
         */
        if not can-find(first ttLifeCycleMapping no-lock
                        where ttLifeCycleMapping.ServiceMatch eq "OpenEdge.Web.DataObject.ServiceRegistryLoader") then do:
            create ttLifeCycleMapping.
            assign
                ttLifeCycleMapping.ServiceMatch = "OpenEdge.Web.DataObject.ServiceRegistryLoader"
                ttLifeCycleMapping.LifeCycle    = ServiceLifeCycleEnum:session:ToString()
                .
        end. /* not can-find */

    end method.

    /**
     * Returns the Service Implementation for the given service interface.
     *
     * @param poService The class of the service to start
     * @return The service implementation of the requested service
     */
    method public Progress.Lang.Class getServiceImplementation ( input poService as Progress.Lang.Class ):

        define variable cImp as character           no-undo.
        define variable oImp as Progress.Lang.Class no-undo.

        find first ttImplMapping no-lock
             where ttImplMapping.Service eq poService:TypeName no-error.

        if available(ttImplMapping) then do:
            oImp = Progress.Lang.Class:GetClass(ttImplMapping.Implementation) no-error.
            if valid-object (oImp) then
                assign poService = oImp.
        end.

        if poService:isInterface() then do:
            /* Assuming the naming convention of interfaces beginning with "I",
               so ITestService ==> TestService as implementation. */
            assign cImp = replace(poService:TypeName, poService:Package + ".", "").
            if cImp begins "I" then
                assign cImp = substring(cImp, 2).

            assign cImp = poService:Package + "." + cImp.
            assign oImp = Progress.Lang.Class:GetClass(cImp) no-error.
        end.
        else
            assign oImp = poService.

        if not valid-object(oImp) then do:
            oLoggingManager:logMessage(substitute("Implementation Class for &1 can not be found", poService:TypeName), "GET-SVC", 3).
            return ?. /* Return unknown instead of throwing error. */
        end.

        return oImp.

    end method.

    /**
     * Returns the life cycle that a service will be scoped to.
     * For example a common user library service would be scoped to the ABL session
     * whilst a validation service for a business task may be scoped to the current request.
     * Some services will not be managed and only be started by the service manager.
     *
     * When a request is made via a service interface the interface will execute the request
     * and once it completes, the interface will notify the service manager that the request
     * is complete so that the service manager can close down any services scoped to the request.
     *
     * @param poService The implementation class of the service that will be started
     * @return The life cycle scope for the service
     */
    method protected ILifecycleScope getLifeCycleScope ( input poService as Progress.Lang.Class ):

        return this-object:getLifeCycleScope(poService:TypeName).

    end method.

    /**
     * Returns the life cycle that a service will be scoped to.
     * For example a common user library service would be scoped to the ABL session
     * whilst a validation service for a business task may be scoped to the current request.
     * Some services will not be managed and only be started by the service manager.
     *
     * When a request is made via a service interface the interface will execute the request
     * and once it completes, the interface will notify the service manager that the request
     * is complete so that the service manager can close down any services scoped to the request.
     *
     * @param pcService The implementation class TypeName of the service that will be started
     * @return The life cycle scope for the service
     */
    method protected ILifecycleScope getLifeCycleScope ( input pcService as character ):
        define variable cScope as character no-undo.

        assign cScope = ServiceLifeCycleEnum:session:ToString().
        for first ttLifeCycleMapping no-lock
            where ttLifeCycleMapping.LifeCycle eq cScope
            and pcService matches ttLifeCycleMapping.ServiceMatch:
            return ServiceLifeCycleEnum:session.
        end.

        assign cScope = ServiceLifeCycleEnum:request:ToString().
        for first ttLifeCycleMapping no-lock
            where ttLifeCycleMapping.LifeCycle eq cScope
            and pcService matches ttLifeCycleMapping.ServiceMatch:
            return ServiceLifeCycleEnum:request.
        end.

        assign cScope = ServiceLifeCycleEnum:none:ToString().
        for first ttLifeCycleMapping no-lock
            where ttLifeCycleMapping.LifeCycle eq cScope
            and pcService matches ttLifeCycleMapping.ServiceMatch:
            return ServiceLifeCycleEnum:none.
        end.

        return ServiceLifeCycleEnum:default.

    end method.

    /**
     * Gets the requested service and then invokes the service function/method
     *
     * @param poServiceClass The Progress.Lang.Class of the interface or implemented class of the service containing the function
     * @param pcMethodName The method name of the function to invoke
     * @param poRequest The Service Message object containing the method's request parameters
     * @param poResponse The Response object that will be populated with the functions response. Can be any Service that inherits a Response message
     */
    method public void callServiceFunction ( input poService as Progress.Lang.Class, input pcMethodName as character, input poRequest as IAbstractMessage, input poResponse as IAbstractMessage ):

        dynamic-invoke(getService(poService), pcMethodName, input poRequest, input poResponse).

        /*Let any thrown errors propagate up the stack - all will be caught in the interface layer*/

    end method.

    /**
     * Gets the requested service and then invokes the service function/method
     *
     * @param poServiceClass The Progress.Lang.Class of the interface or implemented class of the service containing the function
     * @param pcMethodName The function name (method name) of the function to invoke
     */
    method public void callServiceFunction ( input poService as Progress.Lang.Class, input pcMethodName as character ):

        dynamic-invoke(getService(poService), pcMethodName).

        /*Let any thrown errors propagate up the stack - all will be caught in the interface layer*/

    end method.

    /* Returns a usable instance of the requested service.

       @param P.L.Class The service name requested
       @return P.L.Object A usable instance
       @throws P.L.AppError Thrown when no implementation can be found */
    method public Progress.Lang.Object getService ( input poService as class Progress.Lang.Class ):
        return getService(poService, "").
    end method.

    /* Returns a usable instance of the requested service.

       @param P.L.Class The service name requested
       @param ILifecycleScope A requested scope. THIS will be ingnored as the ServiceManager is in control of the scope
       @return P.L.Object A usable instance
       @throws P.L.AppError Thrown when no implementation can be found */
    method public Progress.Lang.Object getService ( input poService as class Progress.Lang.Class,
                                                    input poScope as Ccs.ServiceManager.ILifecycleScope ):
        return getService(poService, "").
    end method.

    /**
     * Returns a usable instance of the requested service.
     *
     * @param poService The service name requested
     * @param pcAlias An alias for the service.
     * @return P.L.Object A usable instance
     * @throws P.L.AppError Thrown when no implementation can be found
     */
    method public Progress.Lang.Object getService ( input poService as class Progress.Lang.Class, input pcAlias as character ):

        define variable oServiceImpl   as Progress.Lang.Class  no-undo.
        define variable oServiceReturn as Progress.Lang.Object no-undo.

        define buffer lbServices for ttServices.

        if poService:IsInterface() then do:
            case true:
                when poService:TypeName eq "OpenEdge.Web.DataObject.IServiceRegistry" then do:
                    /* Assume use of standard implementation if none specified. */
                    assign pcAlias = "OpenEdge.Web.DataObject.ServiceRegistryImpl" when pcAlias eq "".
                end. /* IServiceRegistry */

                when poService:TypeName eq "Progress.Web.IWebHandler" then do:
                    /* Assume use of the local handler if none is specified by alias. */
                    if pcAlias eq "" then /* If blank, assume the OE standard class. */
                        assign pcAlias = "OpenEdge.Web.DataObject.DataObjectHandler".
                    else do:
                        /* Use a more specific service class for the given WebHandler. */
                        assign poService = Progress.Lang.Class:GetClass(pcAlias).
                        if not poService:IsA(get-class(Progress.Web.IWebHandler)) then
                            return ?. /* Cannot start class, type is not IWebHandler. */
                    end. /* Non-blank Alias */
                end. /* IWebHandler */

                otherwise
                    /* Use the service class name, if given alias is blank. */
                    assign pcAlias = poService:TypeName when pcAlias eq "".
            end case. /* TypeName */

            if not can-find(first ttImplMapping where ttImplMapping.Service eq poService:TypeName) then do:
                /* Provide a standard implementation for this service service when not present. */
                create ttImplMapping.
                assign
                    ttImplMapping.Service        = poService:TypeName
                    ttImplMapping.Implementation = pcAlias
                    .
            end. /* not can-find */
        end. /* IsInterface */

        /* Obtain configured implementation for the given service. */
        oServiceImpl = this-object:getServiceImplementation(poService).

        oLoggingManager:logMessage(substitute("Getting &1 service implemention: &2",
                                              poService:TypeName, oServiceImpl:TypeName), "GET-SVC", 5).

        /* Attempt to use an available service instance. */
        find first lbServices no-lock
             where lbServices.ServiceTypeName eq oServiceImpl:TypeName
               and lbServices.AliasName eq pcAlias no-error.

        if available(lbServices) and valid-object(lbServices.ServiceInstance) then
            oServiceReturn = lbServices.ServiceInstance.
        else
            oServiceReturn = this-object:startService(oServiceImpl, pcAlias).

        return oServiceReturn.
    end method.

    /**
     * Starts and returns a service as specified by a class
     *
     * @param poService The class of the service to start
     * @param pcAlias An alias name for the service. This allows us to have mulitple bindings for a single class, specialised by alias name.
     * @return P.L.Object The running instance of the requested service
     */
    method private Progress.Lang.Object startService ( input poService as Progress.Lang.Class, input pcAlias as character ):

        define variable oService   as Progress.Lang.Object no-undo.
        define variable oLifeCycle as ILifecycleScope      no-undo.

        define buffer lbServices for ttServices.

        if not valid-object(poService) then return ?. /* Cannot start what we do not have. */
        if poService:IsAbstract() then return ?. /* Cannot start an abstract class. */
        if poService:IsInterface() then return ?. /* Cannot start an interface class. */

        oLoggingManager:logMessage(substitute("Starting service of type &1 (&2)",
                                              poService:TypeName, pcAlias), "START-SVC", 4).

        /* Cannot start a service of such a simple type; likely indicates misconfiguration. */
        if poService:TypeName eq "Progress.Lang.Object" then return ?.

        oService = poService:New().

        if poService:IsA(get-class(IService)) then
            cast(oService, IService):initialize().

        oLifeCycle = this-object:getLifeCycleScope(poService).

        if not oLifeCycle:GetClass():IsA(get-class(ITransientScope)) then
        do transaction:
            find first lbServices exclusive-lock
                 where lbServices.ServiceInstance eq oService no-error.
            if not available lbServices then create lbServices.
            assign
                lbServices.ServiceInstance = oService
                lbServices.ServiceTypeName = poService:TypeName
                lbServices.AliasName       = pcAlias
                lbServices.LifeCycle       = ServiceLifeCycleEnum:stringFromEnum(oLifeCycle)
                .

            oLoggingManager:logMessage(substitute("Started service &1 with '&2' lifecycle",
                                                  poService:TypeName, lbServices.LifeCycle), "START-SVC", 4).
        end.

        return oService.

    end method.

    /* Destroys and flushes from any cache(s) objects scoped to the argument scope.

       @param ILifecycleScope A requested scope for which to stop services. */
    method public void stopServices ( input poScope as ILifecycleScope ):

        define variable cScope as character no-undo.

        define buffer lbServices for ttServices.

        assign cScope = ServiceLifeCycleEnum:stringFromEnum(poScope).
        for each lbServices no-lock
           where lbServices.LifeCycle eq cScope:
            this-object:stopService(lbServices.ServiceTypeName, lbServices.AliasName).
        end.

    end method.

    /**
     * Stops a running service.
     *
     * @param pcServiceTypeName The TypeName of the service to stop
     * @param pcAlias The Alias of the service to stop
     */
    method private void stopService ( input pcServiceTypeName as character, input pcAlias as character ):

        define buffer lbServices for ttServices.

        do transaction:
            find first lbServices exclusive-lock
                 where lbServices.ServiceTypeName eq pcServiceTypeName
                   and lbServices.AliasName       eq pcAlias no-error.

            if available(lbServices) then do:
                oLoggingManager:logMessage(substitute("Stopping Service: &1", lbServices.ServiceTypeName), "STOP-SVC", 4).
                if valid-object(lbServices.ServiceInstance) and lbServices.ServiceInstance:GetClass():IsA(get-class(IService)) then
                    cast(lbServices.ServiceInstance, IService):dispose().

                /* Delete the reference to the Object and the garbage collection will remove the object. */
                delete lbServices.
            end.
        end.

    end method.

end class.
