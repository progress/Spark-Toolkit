Please follow the provided upgrade process from version 2.x to 3.x (first introduction of the CCS-based classes):

startup.p:
    ConfigManager:Instance:sessionStart -> Ccs.Common.Application:StartupManager = Spark.Core.Manager.StartupManager:Instance

Obsoleted:
    Spark/Core/Manager/ConfigManager.cls (became StartupManager)
    Spark/Core/Manager/IConfigManager.cls (replaced by IStartupManager)
    Spark/Core/Manager/IManager.cls (replaced by CCS version)
    Spark/Core/Manager/IUserContext.cls (became IClientContext)
    Spark/Core/Manager/UserContext.cls (became ClientContext)
    Spark/Core/Service/IService.cls (replaced by CCS version)

Replacements:
    currentUserContext -> CurrentClientContext
    Spark.Core.Manager.IManager -> Ccs.Common.IManager
    ConfigManager:Instance -> Ccs.Common.Application:StartupManager
    ConfigManager:Instance:ServiceManager -> cast(Ccs.Common.Application:ServiceManager, IServiceManager)
    ConfigManager:Instance:SessionManager -> cast(Ccs.Common.Application:SessionManager, ISessionManager)
    ConfigManager:Instance:SessionManager:CurrentClientContext -> cast(Ccs.Common.Application:SessionManager:CurrentClientContext, IClientContext)
    ConfigManager:Instance:CatalogManager -> cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager)
    ConfigManager:Instance:LoggingManager -> cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager)
    ConfigManager:Instance:MessageManager -> cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager)
    ConfigManager:Instance:SchemaManager -> cast(Ccs.Common.Application:StartupManager:getManager(get-class(ISchemaManager)), ISchemaManager)
    ConfigManager:Instance:StateManager -> cast(Ccs.Common.Application:StartupManager:getManager(get-class(IStateManager)), IStateManager)
    ConfigManager:Instance:TranslationManager -> cast(Ccs.Common.Application:StartupManager:getManager(get-class(ITranslationManager)), ITranslationManager)

    Use the full class path for all "inherits" and "implements" keywords in class definitions.
        inherits Manager -> inherits Spark.Core.Manager.Manager
        inherits Service -> inherits Spark.Core.Manager.Service

    For all classes that inherit Manager and implement an initializeManager() method, replace with initialize()
    For all classes that inherit Service and implement an initializeService() method, replace with initialize()
    Remove any remaining references to Spark.Core.Manager.ConfigManager and replace with the appropriate item above.

    Within classes that inherit from DynamicEntity or DynamicResource, you can replace the following:
        ConfigManager:Instance:SessionManager:CurrentUserContext -> oClientContext
        initializeService -> initialize

Configuration Changes:
    Move the "SessionParam" property/object from config.json to session.json config file.
    Rename the config.json file to startup.json (to match the StartupManager as its consumer).
    In the startup.json file, make sure your "ManagerMapping" array contains the appropriate values for the Service and Session managers:
    {
        "Manager": "Spark.Core.Manager.IServiceManager",
        "Implementation": "Spark.Core.Manager.ServiceManager"
    }, {
        "Manager": "Spark.Core.Manager.ISessionManager",
        "Implementation": "Spark.Core.Manager.SessionManager"
    }
