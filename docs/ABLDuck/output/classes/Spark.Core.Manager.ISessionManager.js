Ext.data.JsonP.Spark_Core_Manager_ISessionManager({"files":[],"uses":[],"id":"class-Spark.Core.Manager.ISessionManager","tagname":"class","name":"Spark.Core.Manager.ISessionManager","extends":"Ccs.Common.ISessionManager","author":"progress","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eISessionManager\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eImplement a customized CCS Session Manager\u003c/p\u003e\n\u003ch3\u003eDescription:\u003c/h3\u003e\n\u003cp\u003eStartup Manager (Interface)\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eTue Mar 03 13:55:33 EST 2015\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cp\u003eAn instance is to be created and set in the SessionManager\nproperty of Ccs.Common.Application and accessed from there.\u003c/p\u003e\n","icon":"interface","superclasses":["Ccs.Common.ISessionManager","Spark.Core.Manager.ISessionManager"],"subclasses":[],"implementers":["Spark.Core.Manager.SessionManager"],"members":[{"id":"method-databasesConnected","name":"databasesConnected","owner":"Spark.Core.Manager.ISessionManager","tagname":"method","comment":"","returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-establishRequestEnvironment","name":"establishRequestEnvironment","owner":"Spark.Core.Manager.ISessionManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{}},{"id":"method-userLogin","name":"userLogin","owner":"Spark.Core.Manager.ISessionManager","tagname":"method","comment":"","parameters":[{"name":"pcUserID","datatype":"CHARACTER","mode":""},{"name":"pcDomain","datatype":"CHARACTER","mode":""},{"name":"pcPassword","datatype":"CHARACTER","mode":""},{"name":"pcExtra","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"RAW","comment":""},"meta":{}},{"id":"method-invalidateContext","name":"invalidateContext","owner":"Spark.Core.Manager.ISessionManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{}},{"id":"method-invalidateContext-1","name":"invalidateContext","owner":"Spark.Core.Manager.ISessionManager","tagname":"method","comment":"","parameters":[{"name":"pcContextId","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-invalidateContext-2","name":"invalidateContext","owner":"Spark.Core.Manager.ISessionManager","tagname":"method","comment":"","parameters":[{"name":"phClientPrincipal","datatype":"HANDLE","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-setSessionAttribute","name":"setSessionAttribute","owner":"Spark.Core.Manager.ISessionManager","tagname":"method","comment":"","parameters":[{"name":"oAttribute","datatype":"Spark.Core.Manager.SessionAttributeEnum","mode":""},{"name":"pcValue","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-getUserSSOToken","name":"getUserSSOToken","owner":"Spark.Core.Manager.ISessionManager","tagname":"method","comment":"","parameters":[{"name":"ptExpiration","datatype":"DATETIME-TZ","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-getUserSSOToken-1","name":"getUserSSOToken","owner":"Spark.Core.Manager.ISessionManager","tagname":"method","comment":"","parameters":[{"name":"pcRawToken","datatype":"CHARACTER","mode":""},{"name":"ptExpiration","datatype":"DATETIME-TZ","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}}],"meta":{}});