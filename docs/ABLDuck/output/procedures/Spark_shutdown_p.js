Ext.data.JsonP.Spark_shutdown_p({"files":[],"uses":["Progress.Json.*","Spark.Core.Manager.ICatalogManager","Spark.Core.Manager.ISchemaManager","Spark.Core.Manager.IStartupManager","Spark.Core.Manager.ServiceLifeCycleEnum"],"id":"procedure-Spark\\shutdown","tagname":"procedure","name":"Spark/shutdown.p","author":"Dustin Grau (dugrau@progress.com)","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eSpark/shutdown\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eRecommended to check for any dynamic objects left behind\u003c/p\u003e\n\u003ch3\u003eDescription:\u003c/h3\u003e\n\u003cp\u003eAssigned as sessionShutdownProc in openedge.properties\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eTue Apr 28 15:03:17 EDT 2016\u003c/p\u003e\n","icon":"procedure","members":[{"id":"procedure-logObjects","name":"logObjects","tagname":"procedure","comment":"","meta":{}},{"id":"function-logMessage","name":"logMessage","tagname":"function","comment":"\u003cp\u003eObtain the current request object, which we will use to determine the logging solution.\u003c/p\u003e\n","parameters":[{"name":"pcMessage","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcSubSystem","datatype":"CHARACTER","mode":"INPUT"},{"name":"piLogLevel","datatype":"INTEGER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"function-logError","name":"logError","tagname":"function","comment":"","parameters":[{"name":"pcContextMessage","datatype":"CHARACTER","mode":"INPUT"},{"name":"poErr","datatype":"Progress.Lang.Error","mode":"INPUT"},{"name":"pcSubSystem","datatype":"CHARACTER","mode":"INPUT"},{"name":"piLogLevel","datatype":"INTEGER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"temptable-ttServerObjects","name":"ttServerObjects","tagname":"temptable","definition":"DEFINE TEMP-TABLE ttServerObjects NO-UNDO \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD objectType AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD objectFileName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD objectHandle AS INTEGER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{"global":true,"noundo":true}}],"meta":{}});