Ext.data.JsonP.Spark_Core_Manager_IServiceManager({"files":[],"uses":["Spark.Core.Message.IAbstractMessage"],"id":"class-Spark.Core.Manager.IServiceManager","tagname":"class","name":"Spark.Core.Manager.IServiceManager","extends":"Ccs.Common.IServiceManager","author":"progress","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eIServiceManager\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eImplement a customized CCS Startup Manager\u003c/p\u003e\n\u003ch3\u003eDescription:\u003c/h3\u003e\n\u003cp\u003eStartup Manager (Interface)\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eTue Mar 03 13:55:33 EST 2015\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cp\u003eAn instance is to be created and set in the ServiceManager\nproperty of Ccs.Common.Application and accessed from there.\u003c/p\u003e\n","icon":"interface","superclasses":["Ccs.Common.IServiceManager","Spark.Core.Manager.IServiceManager"],"subclasses":[],"implementers":["Spark.Core.Manager.ServiceManager"],"members":[{"id":"method-callServiceFunction","name":"callServiceFunction","owner":"Spark.Core.Manager.IServiceManager","tagname":"method","comment":"","parameters":[{"name":"poServiceClass","datatype":"Progress.Lang.Class","mode":""},{"name":"pcFunction","datatype":"CHARACTER","mode":""},{"name":"poRequest","datatype":"Spark.Core.Message.IAbstractMessage","mode":""},{"name":"poResponse","datatype":"Spark.Core.Message.IAbstractMessage","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-callServiceFunction-1","name":"callServiceFunction","owner":"Spark.Core.Manager.IServiceManager","tagname":"method","comment":"","parameters":[{"name":"poServiceClass","datatype":"Progress.Lang.Class","mode":""},{"name":"pcFunction","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-getServiceImplementation","name":"getServiceImplementation","owner":"Spark.Core.Manager.IServiceManager","tagname":"method","comment":"","parameters":[{"name":"poService","datatype":"Progress.Lang.Class","mode":""}],"returns":{"datatype":"Progress.Lang.Class","comment":""},"meta":{}}],"meta":{}});