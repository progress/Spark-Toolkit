Ext.data.JsonP.Spark_Core_Manager_StartupManager({"files":[],"uses":["Progress.Lang.*","Spark.Core.Util.OSTools","Spark.Core.Util.GenTools"],"id":"class-Spark.Core.Manager.StartupManager","tagname":"class","name":"Spark.Core.Manager.StartupManager","extends":"Spark.Core.Manager.Manager","author":"rosmith","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eStartupManager\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003ePrimary manager for framework startup\u003c/p\u003e\n\u003ch3\u003eDescription:\u003c/h3\u003e\n\u003cp\u003eSystem Startup Manager\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eNov 02 2016\u003c/p\u003e\n","icon":"class","superclasses":["Spark.Core.Service.Service","Spark.Core.Manager.Manager","Spark.Core.Manager.StartupManager"],"subclasses":[],"implements":["Spark.Core.Manager.IStartupManager"],"members":[{"id":"constructor-StartupManager1","name":"StartupManager","owner":"Spark.Core.Manager.StartupManager","tagname":"constructor","comment":"","meta":{"private":true}},{"id":"destructor-StartupManager","name":"StartupManager","owner":"Spark.Core.Manager.StartupManager","tagname":"destructor","comment":"","meta":{}},{"id":"property-Instance","name":"Instance","owner":"Spark.Core.Manager.StartupManager","tagname":"property","datatype":"Spark.Core.Manager.IStartupManager","comment":"\u003cp\u003eThe Static instance object used to instantiate a singleton.\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003eGET - PRIVATE SET\u003c/code\u003e\u003c/p\u003e\n","meta":{"static":true}},{"id":"property-interfaceStopAfter","name":"interfaceStopAfter","owner":"Spark.Core.Manager.StartupManager","tagname":"property","datatype":"INTEGER","comment":"\u003cp\u003eThe STOP-AFTER value used to set a time-out value for each interface request.\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003eGET - PRIVATE SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-initialize","name":"initialize","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{"override":true}},{"id":"method-dispose","name":"dispose","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{"override":true}},{"id":"method-loadConfig","name":"loadConfig","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"\u003cp\u003eLoads the Config JSON which defines which manager implementations to initialize.\u003c/p\u003e\n","returns":{"comment":""},"meta":{"private":true}},{"id":"method-startManagers","name":"startManagers","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"\u003cp\u003eInstantiate and initialize all configured managers.\u003c/p\u003e\n","returns":{"comment":""},"meta":{"private":true}},{"id":"method-checkAllManagersAreListed","name":"checkAllManagersAreListed","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"\u003cp\u003eCCS Managers (Required)\u003c/p\u003e\n","returns":{"comment":""},"meta":{"private":true}},{"id":"method-checkManagerIsListed","name":"checkManagerIsListed","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"\u003cp\u003eCheck if manager is listed, otherwise create as required by default.\u003c/p\u003e\n","parameters":[{"name":"pcManager","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcImplementation","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{"private":true}},{"id":"method-checkManagerIsListed-1","name":"checkManagerIsListed","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"","parameters":[{"name":"pcManager","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcImplementation","datatype":"CHARACTER","mode":"INPUT"},{"name":"plIsRequired","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{"private":true}},{"id":"method-startManager","name":"startManager","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"","parameters":[{"name":"pcManager","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcImplementation","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"private":true}},{"id":"method-stopManager","name":"stopManager","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"","parameters":[{"name":"pcManager","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"private":true}},{"id":"method-getManager","name":"getManager","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eRetrieve an instance of the specified IManager object.\u003c/p\u003e\n","parameters":[{"name":"poServiceType","datatype":"Progress.Lang.Class","mode":"INPUT"}],"returns":{"datatype":"Ccs.Common.IManager","comment":"IManager implementation of the requested type, or ? if its not configured."},"meta":{}},{"id":"method-stopManagers","name":"stopManagers","owner":"Spark.Core.Manager.StartupManager","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eStop all non-essential application managers.\u003c/p\u003e\n","returns":{"comment":""},"meta":{}},{"id":"temptable-ttGeneral","name":"ttGeneral","owner":"Spark.Core.Manager.StartupManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ttGeneral NO-UNDO SERIALIZE-NAME \u0027General\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD iStopAfter AS INTEGER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{"private":true,"global":true,"noundo":true}},{"id":"temptable-ttImplMapping","name":"ttImplMapping","owner":"Spark.Core.Manager.StartupManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ttImplMapping NO-UNDO SERIALIZE-NAME \u0027ManagerMapping\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD Manager AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD Implementation AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{"private":true,"global":true,"noundo":true}},{"id":"temptable-ttManager","name":"ttManager","owner":"Spark.Core.Manager.StartupManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ttManager NO-UNDO \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ManagerInstance AS Progress.Lang.Object\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ManagerTypeName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX ix1 ManagerInstance\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX ix2 PRIMARY ManagerTypeName\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{"private":true,"global":true,"noundo":true}},{"id":"dataset-dsConfig","name":"dsConfig","owner":"Spark.Core.Manager.StartupManager","tagname":"dataset","definition":"DEFINE DATASET dsConfig FOR ttGeneral, ttImplMapping\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"\u003cp\u003eNo index - want them in the order they are defined.\u003c/p\u003e\n","meta":{"private":true}},{"id":"constructor-Spark_Core_Manager_Manager_Manager1","name":"Manager","owner":"Spark.Core.Manager.Manager","tagname":"constructor","comment":"","meta":{}},{"id":"constructor-Spark_Core_Service_Service_Service1","name":"Service","owner":"Spark.Core.Service.Service","tagname":"constructor","comment":"","meta":{}},{"id":"method-Spark_Core_Service_Service_initialize","name":"initialize","owner":"Spark.Core.Service.Service","tagname":"method","comment":"\u003cp\u003eInitializer/Startup\u003c/p\u003e\n","returns":{"comment":""},"meta":{"abstract":true}},{"id":"method-Spark_Core_Service_Service_dispose","name":"dispose","owner":"Spark.Core.Service.Service","tagname":"method","comment":"\u003cp\u003eDestroy/Shutdown/Anti-Initializer\u003c/p\u003e\n","returns":{"comment":""},"meta":{"abstract":true}}],"meta":{}});