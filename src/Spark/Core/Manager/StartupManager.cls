/*------------------------------------------------------------------------
    File        : StartupManager
    Purpose     : Primary manager for framework startup
    Description : System Startup Manager
    Author(s)   : rosmith
    Created     : Nov 02 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Util.OSTools from propath.
using Spark.Core.Util.GenTools from propath.

block-level on error undo, throw.

class Spark.Core.Manager.StartupManager inherits Spark.Core.Manager.Manager implements Spark.Core.Manager.IStartupManager use-widget-pool:

    define private temp-table ttGeneral no-undo serialize-name "General"
        field iStopAfter as integer serialize-name "Timeout".

    define private temp-table ttImplMapping no-undo serialize-name "ManagerMapping"
        field Manager        as character
        field Implementation as character.
        /* No index - want them in the order they are defined. */

    define private dataset dsConfig serialize-name "Config"
        for ttGeneral, ttImplMapping.

    define private temp-table ttManager no-undo
        field ManagerInstance as Progress.Lang.Object
        field ManagerTypeName as character
        index ix1            ManagerInstance
        index ix2 as primary ManagerTypeName.

    /* The Static instance object used to instantiate a singleton. */
    define public static property Instance as Spark.Core.Manager.IStartupManager no-undo
        get():
            if not valid-object(Instance) then
                Instance = new Spark.Core.Manager.StartupManager().
            return Instance.
        end get.
        private set.

    /* The STOP-AFTER value used to set a time-out value for each interface request. */
    define public property interfaceStopAfter as integer initial 20 no-undo
        get.
        private set.

    constructor private StartupManager ( ):
        initialize().
    end constructor.

    destructor public StartupManager ( ):
        dispose().
    end destructor.

    method override public void initialize ( ):
        loadConfig().
        startManagers().
    end method.

    method override public void dispose ( ):
        delete object Instance no-error. /* Destroy instance. */
    end method.

    /* Loads the Config JSON which defines which manager implementations to initialize. */
    method private void loadConfig ( ):
        define variable cFullCfgFileName as character no-undo.

        file-info:file-name = OSTools:sparkConf + "startup.json".
        cFullCfgFileName = file-info:full-pathname.
        if cFullCfgFileName ne ? then
            dataset dsConfig:read-json("FILE", cFullCfgFileName, "EMPTY").
        else
            undo, throw new AppError(substitute("Required config file [startup.json] not found in [&1]", OSTools:sparkConf), 0).

        find first ttGeneral no-lock no-error.
        if available(ttGeneral) and ttGeneral.iStopAfter ne 0 then
            interfaceStopAfter = ttGeneral.iStopAfter.

        if session:debug-alert or session:error-stack-trace then
            interfaceStopAfter = -1.
    end method.

    /* Instantiate and initialize all configured managers. */
    method private void startManagers ( ):
        checkAllManagersAreListed().

        for each ttImplMapping:
            startManager(ttImplMapping.Manager, ttImplMapping.Implementation).
        end.
    end method.

    method private void checkAllManagersAreListed ( ):
        /* CCS Managers (Required) */
        checkManagerIsListed(get-class(Spark.Core.Manager.IServiceManager):TypeName, get-class(Spark.Core.Manager.ServiceManager):TypeName).
        checkManagerIsListed(get-class(Spark.Core.Manager.ISessionManager):TypeName, get-class(Spark.Core.Manager.SessionManager):TypeName).

        /* Application Managers (Required by default, unless only dependent on another manager) */
        checkManagerIsListed(get-class(Spark.Core.Manager.ILoggingManager):TypeName, get-class(Spark.Core.Manager.LoggingManager):TypeName).
        checkManagerIsListed(get-class(Spark.Core.Manager.IStateManager):TypeName, get-class(Spark.Core.Manager.StateManager):TypeName).
        checkManagerIsListed(get-class(Spark.Core.Manager.ITranslationManager):TypeName, get-class(Spark.Core.Manager.TranslationManager):TypeName).
        if checkManagerIsListed(get-class(Spark.Core.Manager.ICatalogManager):TypeName, get-class(Spark.Core.Manager.CatalogManager):TypeName, false) then do:
            /* If the CatalogManager is present, then make sure the supporting SchemaManager is listed as well. */
            checkManagerIsListed(get-class(Spark.Core.Manager.ISchemaManager):TypeName, get-class(Spark.Core.Manager.SchemaManager):TypeName).
        end. /* CatalogManager Listed */

        /* Optional Managers (Must not be a dependency in any capacity by the managers above.) */
        checkManagerIsListed(get-class(Spark.Core.Manager.IConnectionManager):TypeName, get-class(Spark.Core.Manager.ConnectionManager):TypeName, false).
    end method.

    method private logical checkManagerIsListed ( input pcManager        as character,
                                                  input pcImplementation as character ):
        /* Check if manager is listed, otherwise create as required by default. */
        return this-object:checkManagerIsListed(pcManager, pcImplementation, true).
    end method.

    method private logical checkManagerIsListed ( input pcManager        as character,
                                                  input pcImplementation as character,
                                                  input plIsRequired     as logical ):
        find first ttImplMapping
             where ttImplMapping.Manager eq pcManager no-error.
        if not available(ttImplMapping) and plIsRequired then do:
            /* Create any missing, required manager implementations. */
            create ttImplMapping.
            assign
                ttImplMapping.Manager        = pcManager
                ttImplMapping.Implementation = pcImplementation
                .
        end.
        return available(ttImplMapping).
    end method.

    method private void startManager ( input pcManager        as character,
                                       input pcImplementation as character ):

        define variable oManager        as Progress.Lang.Class no-undo.
        define variable oImplementation as Progress.Lang.Class no-undo.

        define buffer lbManager for ttManager.

        oManager = Progress.Lang.Class:GetClass(pcManager) no-error.
        if not valid-object(oManager) then
            undo, throw new AppError(substitute("Invalid Manager [&1]", pcManager), 0).

        oImplementation = Progress.Lang.Class:GetClass(pcImplementation) no-error.
        if not valid-object(oImplementation) then
            undo, throw new AppError(substitute("Invalid Manager Implementation [&1]", pcImplementation), 0).

        create lbManager.
        assign
            lbManager.ManagerTypeName = pcManager
            lbManager.ManagerInstance = oImplementation:New().

        if oManager:IsA(get-class(Ccs.Common.IManager)) then
        do on error undo, throw:
            /* Run the standard class initialization method as dictated by the IManager interface. */
            cast(lbManager.ManagerInstance, Ccs.Common.IManager):initialize().

            catch err as Progress.Lang.Error:
                message substitute("Error while initializing manager '&1': &2", pcManager, err:GetMessage(1)).
                if session:error-stack-trace then
                    message err:CallStack.
            end catch.
        end. /* IsA Ccs.Common.IManager */

        /*Assign the Application:ServiceManager property here so that it is available for other managers as soon as it has been started*/
        if oManager:IsA(get-class(Ccs.Common.IServiceManager)) then
            Ccs.Common.Application:ServiceManager = cast(lbManager.ManagerInstance, Ccs.Common.IServiceManager).

        /*Assign the Application:SessionManager property here so that it is available for other managers as soon as it has been started*/
        if oManager:IsA(get-class(Ccs.Common.ISessionManager)) then
            Ccs.Common.Application:SessionManager = cast(lbManager.ManagerInstance, Ccs.Common.ISessionManager).

    end method.

    method private void stopManager ( input pcManager as character ):

        define buffer lbManager for ttManager.

        do transaction:
            find first lbManager exclusive-lock
                 where lbManager.ManagerTypeName eq pcManager no-error.

            if available(lbManager) then do:
                cast(this-object:getManager(get-class(Spark.Core.Manager.ILoggingManager)), Spark.Core.Manager.ILoggingManager)
                    :logMessage(substitute("Stopping Manager: &1", lbManager.ManagerTypeName), "STOP-MGR", 3).
                if valid-object(lbManager.ManagerInstance) and lbManager.ManagerInstance:GetClass():IsA(get-class(Ccs.Common.IManager)) then
                    cast(lbManager.ManagerInstance, Ccs.Common.IManager):dispose().

                /* Delete the reference to the Object and the garbage collection will remove the object. */
                delete lbManager.
            end.
        end.

    end method.

    /*------------------------------------------------------------------------------
        Purpose: Retrieve an instance of the specified IManager object.
        Notes:
        @param pServiceType The Progress.Lang.Class repersenting the required service.
        @return IManager implementation of the requested type, or ? if its not configured.
        ------------------------------------------------------------------------------*/
    method public Ccs.Common.IManager getManager ( input poServiceType as Progress.Lang.Class ):

        define buffer lbManager for ttManager.

        find first lbManager no-lock
             where lbManager.ManagerTypeName eq poServiceType:TypeName no-error.
        if not available(lbManager) then
            undo, throw new AppError(substitute("Invalid Manager Type [&1]", poServiceType:TypeName), 0).

        return cast(lbManager.ManagerInstance, Ccs.Common.IManager).

        catch err as Progress.Lang.Error:
            if log-manager:logging-level ge 3 then
                log-manager:write-message(err:GetMessage(1), "GET-MGR").
            return ?. /* Return unknown instead of throwing error higher. */
        end catch.
    end method.

    /* Purpose: Stop all non-essential application managers. */
    method public void stopManagers ( ):
        stopManager(get-class(Spark.Core.Manager.ICatalogManager):TypeName).
        stopManager(get-class(Spark.Core.Manager.ISchemaManager):TypeName).
        stopManager(get-class(Spark.Core.Manager.IConnectionManager):TypeName).
        stopManager(get-class(Spark.Core.Manager.IStateManager):TypeName).
        stopManager(get-class(Spark.Core.Manager.ITranslationManager):TypeName).
        /* Stop this last, as it may be used by other managers above. */
        stopManager(get-class(Spark.Core.Manager.ILoggingManager):TypeName).
    end method.

end class.
