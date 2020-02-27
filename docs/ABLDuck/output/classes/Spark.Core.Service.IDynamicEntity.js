Ext.data.JsonP.Spark_Core_Service_IDynamicEntity({"files":[],"uses":[],"id":"class-Spark.Core.Service.IDynamicEntity","tagname":"class","name":"Spark.Core.Service.IDynamicEntity","extends":"Ccs.Common.IService","author":"Dustin Grau (dugrau@progress.com)\n","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eIDynamicEntity\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eTue Mar 17 09:29:59 EDT 2015\u003c/p\u003e\n","icon":"interface","superclasses":["Ccs.Common.IService","Spark.Core.Service.IDynamicEntity"],"subclasses":[],"implementers":["Spark.Core.Service.DynamicEntity"],"members":[{"id":"property-serviceURI","name":"serviceURI","owner":"Spark.Core.Service.IDynamicEntity","tagname":"property","datatype":"CHARACTER","comment":"","meta":{}},{"id":"property-resourceName","name":"resourceName","owner":"Spark.Core.Service.IDynamicEntity","tagname":"property","datatype":"CHARACTER","comment":"","meta":{}},{"id":"property-entityName","name":"entityName","owner":"Spark.Core.Service.IDynamicEntity","tagname":"property","datatype":"CHARACTER","comment":"","meta":{}},{"id":"property-primaryKeys","name":"primaryKeys","owner":"Spark.Core.Service.IDynamicEntity","tagname":"property","datatype":"CHARACTER","comment":"","meta":{}},{"id":"property-foreignKeys","name":"foreignKeys","owner":"Spark.Core.Service.IDynamicEntity","tagname":"property","datatype":"CHARACTER","comment":"","meta":{}},{"id":"property-mappingType","name":"mappingType","owner":"Spark.Core.Service.IDynamicEntity","tagname":"property","datatype":"CHARACTER","comment":"","meta":{}},{"id":"property-capabilities","name":"capabilities","owner":"Spark.Core.Service.IDynamicEntity","tagname":"property","datatype":"CHARACTER","comment":"","meta":{}},{"id":"property-operations","name":"operations","owner":"Spark.Core.Service.IDynamicEntity","tagname":"property","datatype":"CHARACTER","comment":"","meta":{}},{"id":"method-getDataset","name":"getDataset","owner":"Spark.Core.Service.IDynamicEntity","tagname":"method","comment":"","parameters":[{"name":"phDataset","datatype":"DATASET-HANDLE","mode":"OUTPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-postRowFill","name":"postRowFill","owner":"Spark.Core.Service.IDynamicEntity","tagname":"method","comment":"","parameters":[{"name":"phDataset","datatype":"DATASET-HANDLE","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-readData","name":"readData","owner":"Spark.Core.Service.IDynamicEntity","tagname":"method","comment":"","parameters":[{"name":"filter","datatype":"CHARACTER","mode":"INPUT"},{"name":"numRecs","datatype":"INT64","mode":"OUTPUT"},{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":"OUTPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-createData","name":"createData","owner":"Spark.Core.Service.IDynamicEntity","tagname":"method","comment":"","parameters":[{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":"INOUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-updateData","name":"updateData","owner":"Spark.Core.Service.IDynamicEntity","tagname":"method","comment":"","parameters":[{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":"INOUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-deleteData","name":"deleteData","owner":"Spark.Core.Service.IDynamicEntity","tagname":"method","comment":"","parameters":[{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":"INOUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-submitData","name":"submitData","owner":"Spark.Core.Service.IDynamicEntity","tagname":"method","comment":"","parameters":[{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":"INOUT"}],"returns":{"comment":""},"meta":{}}],"meta":{}});