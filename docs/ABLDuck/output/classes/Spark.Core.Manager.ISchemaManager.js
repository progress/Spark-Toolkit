Ext.data.JsonP.Spark_Core_Manager_ISchemaManager({"files":[],"uses":[],"id":"class-Spark.Core.Manager.ISchemaManager","tagname":"class","name":"Spark.Core.Manager.ISchemaManager","extends":"Ccs.Common.IManager","author":"Dustin Grau (dugrau@progress.com)","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eISchemaManager\u003c/p\u003e\n\u003ch3\u003eDescription:\u003c/h3\u003e\n\u003cp\u003eSchema Manager (Interface)\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eTue Mar 03 13:55:33 EST 2015\u003c/p\u003e\n","icon":"interface","superclasses":["Ccs.Common.IManager","Spark.Core.Manager.ISchemaManager"],"subclasses":[],"implementers":["Spark.Core.Manager.SchemaManager"],"members":[{"id":"method-initSchema","name":"initSchema","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{}},{"id":"method-initMethodSignature","name":"initMethodSignature","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","parameters":[{"name":"poMethodSignature","datatype":"Spark.Core.Util.MethodSignature","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-deleteObjects","name":"deleteObjects","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{}},{"id":"method-dumpObjects","name":"dumpObjects","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{}},{"id":"method-getObject","name":"getObject","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","parameters":[{"name":"pcParentName","datatype":"CHARACTER","mode":""},{"name":"pcObjectName","datatype":"CHARACTER","mode":""},{"name":"pcObjectAltName","datatype":"CHARACTER","mode":""},{"name":"pcObjectType","datatype":"CHARACTER","mode":""},{"name":"pcObjectSchema","datatype":"LONGCHAR","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-getObjectChildren","name":"getObjectChildren","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","parameters":[{"name":"pcParentName","datatype":"CHARACTER","mode":""},{"name":"pcObjectList","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-getObjectList","name":"getObjectList","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","parameters":[{"name":"pcSchemaType","datatype":"CHARACTER","mode":""},{"name":"pcSchemaList","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-getDataset","name":"getDataset","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","parameters":[{"name":"pcDatasetName","datatype":"CHARACTER","mode":""},{"name":"phDatasetHandle","datatype":"DATASET-HANDLE","mode":""}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-getDataset-1","name":"getDataset","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","parameters":[{"name":"plcDatasetSchema","datatype":"LONGCHAR","mode":""},{"name":"phDatasetHandle","datatype":"DATASET-HANDLE","mode":""}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-getTempTable","name":"getTempTable","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","parameters":[{"name":"pcTableName","datatype":"CHARACTER","mode":""},{"name":"phTableHandle","datatype":"TABLE-HANDLE","mode":""}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-registerDataset","name":"registerDataset","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","parameters":[{"name":"phDatasetHandle","datatype":"HANDLE","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-registerTempTable","name":"registerTempTable","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","parameters":[{"name":"phTableHandle","datatype":"HANDLE","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-registerTempTable-1","name":"registerTempTable","owner":"Spark.Core.Manager.ISchemaManager","tagname":"method","comment":"","parameters":[{"name":"pcParentObject","datatype":"CHARACTER","mode":""},{"name":"phTableHandle","datatype":"HANDLE","mode":""}],"returns":{"comment":""},"meta":{}}],"meta":{}});