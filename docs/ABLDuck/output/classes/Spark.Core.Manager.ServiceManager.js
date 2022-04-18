Ext.data.JsonP.Spark_Core_Manager_ServiceManager({"files":[],"uses":["Progress.Lang.*","Ccs.Common.IService","Ccs.ServiceManager.ILifecycleScope","Ccs.ServiceManager.ITransientScope","Spark.Core.Message.IAbstractMessage","Spark.Core.Manager.ILoggingManager","Spark.Core.Manager.ServiceLifeCycleEnum","Spark.Core.Util.GenTools","Spark.Core.Util.OSTools"],"id":"class-Spark.Core.Manager.ServiceManager","tagname":"class","name":"Spark.Core.Manager.ServiceManager","extends":"Spark.Core.Manager.Manager","author":"rosmith","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eServiceManager\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003ePrimary manager for framework startup\u003c/p\u003e\n\u003ch3\u003eDescription:\u003c/h3\u003e\n\u003cp\u003eService Startup Manager\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eNov 02 2016\u003c/p\u003e\n","icon":"class","superclasses":["Spark.Core.Service.Service","Spark.Core.Manager.Manager","Spark.Core.Manager.ServiceManager"],"subclasses":[],"implements":["Spark.Core.Manager.IServiceManager"],"members":[{"id":"constructor-ServiceManager1","name":"ServiceManager","owner":"Spark.Core.Manager.ServiceManager","tagname":"constructor","comment":"","meta":{}},{"id":"property-oLoggingManager","name":"oLoggingManager","owner":"Spark.Core.Manager.ServiceManager","tagname":"property","datatype":"Spark.Core.Manager.ILoggingManager","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-initialize","name":"initialize","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{"override":true}},{"id":"method-dispose","name":"dispose","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{"override":true}},{"id":"method-loadConfig","name":"loadConfig","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{}},{"id":"method-getServiceImplementation","name":"getServiceImplementation","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eReturns the Service Implementation for the given service interface.\u003c/p\u003e\n","parameters":[{"name":"poService","datatype":"Progress.Lang.Class","mode":"","comment":"The class of the service to start"}],"returns":{"datatype":"Progress.Lang.Class","comment":"The service implementation of the requested service"},"meta":{}},{"id":"method-getLifeCycleScope","name":"getLifeCycleScope","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eReturns the life cycle that a service will be scoped to.\nFor example a common user library service would be scoped to the ABL session\nwhilst a validation service for a business task may be scoped to the current request.\nSome services will not be managed and only be started by the service manager.\u003c/p\u003e\n\u003cp\u003eWhen a request is made via a service interface the interface will execute the request\nand once it completes, the interface will notify the service manager that the request\nis complete so that the service manager can close down any services scoped to the request.\u003c/p\u003e\n","parameters":[{"name":"poService","datatype":"Progress.Lang.Class","mode":"","comment":"The implementation class of the service that will be started"}],"returns":{"datatype":"Ccs.ServiceManager.ILifecycleScope","comment":"The life cycle scope for the service"},"meta":{}},{"id":"method-getLifeCycleScope-1","name":"getLifeCycleScope","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eReturns the life cycle that a service will be scoped to.\nFor example a common user library service would be scoped to the ABL session\nwhilst a validation service for a business task may be scoped to the current request.\nSome services will not be managed and only be started by the service manager.\u003c/p\u003e\n\u003cp\u003eWhen a request is made via a service interface the interface will execute the request\nand once it completes, the interface will notify the service manager that the request\nis complete so that the service manager can close down any services scoped to the request.\u003c/p\u003e\n","parameters":[{"name":"pcService","datatype":"CHARACTER","mode":"","comment":"The implementation class TypeName of the service that will be started"}],"returns":{"datatype":"Ccs.ServiceManager.ILifecycleScope","comment":"The life cycle scope for the service"},"meta":{}},{"id":"method-callServiceFunction","name":"callServiceFunction","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eGets the requested service and then invokes the service function/method\u003c/p\u003e\n","parameters":[{"name":"poService","datatype":"Progress.Lang.Class","mode":""},{"name":"pcMethodName","datatype":"CHARACTER","mode":"","comment":"The method name of the function to invoke"},{"name":"poRequest","datatype":"Spark.Core.Message.IAbstractMessage","mode":"","comment":"The Service Message object containing the method\u0027s request parameters"},{"name":"poResponse","datatype":"Spark.Core.Message.IAbstractMessage","mode":"","comment":"The Response object that will be populated with the functions response. Can be any Service that inherits a Response message"}],"returns":{"comment":""},"meta":{}},{"id":"method-callServiceFunction-1","name":"callServiceFunction","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eGets the requested service and then invokes the service function/method\u003c/p\u003e\n","parameters":[{"name":"poService","datatype":"Progress.Lang.Class","mode":""},{"name":"pcMethodName","datatype":"CHARACTER","mode":"","comment":"The function name (method name) of the function to invoke"}],"returns":{"comment":""},"meta":{}},{"id":"method-getService","name":"getService","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eReturns a usable instance of the requested service.\u003c/p\u003e\n\u003ch3\u003ethrows:\u003c/h3\u003e\n\u003cp\u003eP.L.AppError Thrown when no implementation can be found\u003c/p\u003e\n","parameters":[{"name":"poService","datatype":"Progress.Lang.Class","mode":""}],"returns":{"datatype":"Progress.Lang.Object","comment":"P.L.Object A usable instance"},"meta":{}},{"id":"method-getService-1","name":"getService","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eReturns a usable instance of the requested service.\u003c/p\u003e\n\u003ch3\u003ethrows:\u003c/h3\u003e\n\u003cp\u003eP.L.AppError Thrown when no implementation can be found\u003c/p\u003e\n","parameters":[{"name":"poService","datatype":"Progress.Lang.Class","mode":""},{"name":"poScope","datatype":"Ccs.ServiceManager.ILifecycleScope","mode":""}],"returns":{"datatype":"Progress.Lang.Object","comment":"P.L.Object A usable instance"},"meta":{}},{"id":"method-getService-2","name":"getService","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eReturns a usable instance of the requested service.\u003c/p\u003e\n","parameters":[{"name":"poService","datatype":"Progress.Lang.Class","mode":"","comment":"The service name requested"},{"name":"pcAlias","datatype":"CHARACTER","mode":"","comment":"An alias for the service."}],"returns":{"datatype":"Progress.Lang.Object","comment":"P.L.Object A usable instance"},"meta":{}},{"id":"method-startService","name":"startService","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eStarts and returns a service as specified by a class\u003c/p\u003e\n","parameters":[{"name":"poService","datatype":"Progress.Lang.Class","mode":"","comment":"The class of the service to start"},{"name":"pcAlias","datatype":"CHARACTER","mode":"","comment":"An alias name for the service. This allows us to have mulitple bindings for a single class, specialised by alias name."}],"returns":{"datatype":"Progress.Lang.Object","comment":"P.L.Object The running instance of the requested service"},"meta":{}},{"id":"method-stopServices","name":"stopServices","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eDestroys and flushes from any cache(s) objects scoped to the argument scope.\u003c/p\u003e\n","parameters":[{"name":"poScope","datatype":"Ccs.ServiceManager.ILifecycleScope","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-stopService","name":"stopService","owner":"Spark.Core.Manager.ServiceManager","tagname":"method","comment":"\u003cp\u003eStops a running service.\u003c/p\u003e\n","parameters":[{"name":"pcServiceTypeName","datatype":"CHARACTER","mode":"","comment":"The TypeName of the service to stop"},{"name":"pcAlias","datatype":"CHARACTER","mode":"","comment":"The Alias of the service to stop"}],"returns":{"comment":""},"meta":{}},{"id":"temptable-ttImplMapping","name":"ttImplMapping","owner":"Spark.Core.Manager.ServiceManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ttImplMapping SERIALIZE-NAME \u0027ServiceMapping\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD Service AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD Implementation AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX ix1 PRIMARY UNIQUE Service\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{}},{"id":"temptable-ttLifeCycle","name":"ttLifeCycle","owner":"Spark.Core.Manager.ServiceManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ttLifeCycle SERIALIZE-NAME \u0027ServiceLifeCycle\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceMatch AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD LifeCycle AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{}},{"id":"temptable-ttLifeCycleMapping","name":"ttLifeCycleMapping","owner":"Spark.Core.Manager.ServiceManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ttLifeCycleMapping \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceMatch AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD LifeCycle AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD SearchOrder AS INTEGER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX ix1 PRIMARY SearchOrder\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{}},{"id":"temptable-ttServices","name":"ttServices","owner":"Spark.Core.Manager.ServiceManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ttServices \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceInstance AS Progress.Lang.Object\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceTypeName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD AliasName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD LifeCycle AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX ix1 ServiceInstance\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX ix2 PRIMARY ServiceTypeName AliasName\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX ix3 LifeCycle ServiceTypeName AliasName\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{}},{"id":"dataset-dsConfig","name":"dsConfig","owner":"Spark.Core.Manager.ServiceManager","tagname":"dataset","definition":"DEFINE DATASET dsConfig FOR ttImplMapping, ttLifeCycle\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"\u003cp\u003eNo index - Want them in the order they are listed!\u003c/p\u003e\n","meta":{}},{"id":"constructor-Spark_Core_Manager_Manager_Manager1","name":"Manager","owner":"Spark.Core.Manager.Manager","tagname":"constructor","comment":"","meta":{}},{"id":"constructor-Spark_Core_Service_Service_Service1","name":"Service","owner":"Spark.Core.Service.Service","tagname":"constructor","comment":"","meta":{}},{"id":"method-Spark_Core_Service_Service_initialize","name":"initialize","owner":"Spark.Core.Service.Service","tagname":"method","comment":"\u003cp\u003eInitializer/Startup\u003c/p\u003e\n","returns":{"comment":""},"meta":{"abstract":true}},{"id":"method-Spark_Core_Service_Service_dispose","name":"dispose","owner":"Spark.Core.Service.Service","tagname":"method","comment":"\u003cp\u003eDestroy/Shutdown/Anti-Initializer\u003c/p\u003e\n","returns":{"comment":""},"meta":{"abstract":true}}],"meta":{}});