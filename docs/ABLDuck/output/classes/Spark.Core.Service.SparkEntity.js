Ext.data.JsonP.Spark_Core_Service_SparkEntity({"files":[],"uses":["Progress.Json.ObjectModel.*","Ccs.BusinessLogic.*","OpenEdge.BusinessLogic.*","OpenEdge.BusinessLogic.Filter.*","OpenEdge.BusinessLogic.Query.*","Progress.Reflect.Method","Progress.Lang.ParameterList","Spark.Core.Manager.IClientContext","Spark.Core.Manager.ICatalogManager","Spark.Core.Manager.ILoggingManager","Spark.Core.Message.IContextMessage","Spark.Core.Util.*"],"id":"class-Spark.Core.Service.SparkEntity","tagname":"class","name":"Spark.Core.Service.SparkEntity","extends":"OpenEdge.BusinessLogic.BusinessEntity","author":"Dustin Grau (dugrau@progress.com)","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eSparkEntity\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eTue Mar 17 09:31:42 EDT 2015\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cp\u003eResources for Error-Handling:\u003c/p\u003e\n\u003ch3\u003ehttps:\u003c/h3\u003e\n\u003cp\u003e//wiki.progress.com/pages/viewpage.action?title\u003dError+handling+in+the+JSDO\u0026amp;spaceKey\u003doeagile#ErrorhandlingintheJSDO-HTTP200(JSONobjectwithprods:errors)\u003c/p\u003e\n\u003ch3\u003ehttps:\u003c/h3\u003e\n\u003cp\u003e//documentation.progress.com/output/ua/OpenEdge_latest/index.html#page/dvpds/setting-and-using-error,-error-string,-and-rejec.html\u003c/p\u003e\n\u003ch3\u003ehttps:\u003c/h3\u003e\n\u003cp\u003e//documentation.progress.com/output/pdo/#page/pdo%2Fgeterrors(-)-method.html\u003c/p\u003e\n","icon":"class","superclasses":["OpenEdge.BusinessLogic.BusinessEntity","Spark.Core.Service.SparkEntity"],"subclasses":["Spark.Core.Service.DynamicEntity"],"implements":["Spark.Core.Service.ISparkEntity"],"members":[{"id":"constructor-SparkEntity1","name":"SparkEntity","owner":"Spark.Core.Service.SparkEntity","tagname":"constructor","comment":"\u003cp\u003eImplement constructor in each class instance to provide a handle to ProDataSet!\u003c/p\u003e\n","meta":{}},{"id":"constructor-SparkEntity2","name":"SparkEntity","owner":"Spark.Core.Service.SparkEntity","tagname":"constructor","comment":"","parameters":[{"name":"phDataset","datatype":"DATASET-HANDLE","mode":"INPUT"}],"meta":{}},{"id":"property-oClientContext","name":"oClientContext","owner":"Spark.Core.Service.SparkEntity","tagname":"property","datatype":"Spark.Core.Manager.IClientContext","comment":"\u003cp\u003eDefined in OpenEdge.BusinessLogic.BusinessEntity as handle to DataSet in context:\ndefine protected property ProDataSet as handle no-undo get. set.\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{"protected":true}},{"id":"property-oLoggingManager","name":"oLoggingManager","owner":"Spark.Core.Service.SparkEntity","tagname":"property","datatype":"Spark.Core.Manager.ILoggingManager","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{"protected":true}},{"id":"property-oCatalogManager","name":"oCatalogManager","owner":"Spark.Core.Service.SparkEntity","tagname":"property","datatype":"Spark.Core.Manager.ICatalogManager","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{"protected":true}},{"id":"property-oContextMessage","name":"oContextMessage","owner":"Spark.Core.Service.SparkEntity","tagname":"property","datatype":"Spark.Core.Message.IContextMessage","comment":"\u003cp\u003eHold non-fatal messages for output (as determined by interface for class access).\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003eGET - PRIVATE SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-LastCount","name":"LastCount","owner":"Spark.Core.Service.SparkEntity","tagname":"property","datatype":"INT64","comment":"\u003cp\u003eTo be used by DOHEventHandler to supply record count on response object for READ.\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003eGET - PROTECTED SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-getClassName","name":"getClassName","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"","returns":{"datatype":"CHARACTER","comment":""},"meta":{"protected":true,"final":true}},{"id":"method-getFilterObject","name":"getFilterObject","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003egetClassName\u003c/p\u003e\n","parameters":[{"name":"pcRawFilter","datatype":"LONGCHAR","mode":"INPUT"}],"returns":{"datatype":"JsonObject","comment":""},"meta":{"protected":true}},{"id":"method-filterData","name":"filterData","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003egetFilter\u003c/p\u003e\n","parameters":[{"name":"pcFilter","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"INT64","comment":""},"meta":{"protected":true}},{"id":"method-getFilterOnly","name":"getFilterOnly","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003efilterData\u003c/p\u003e\n","parameters":[{"name":"poFilter","datatype":"JsonObject","mode":"INPUT"}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{"protected":true}},{"id":"method-getRecCount","name":"getRecCount","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003egetFilterOnly\u003c/p\u003e\n","parameters":[{"name":"pcRawFilter","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"INT64","comment":""},"meta":{"protected":true}},{"id":"method-getRecCount-1","name":"getRecCount","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003egetRecCount\u003c/p\u003e\n","parameters":[{"name":"pcFilter","datatype":"CHARACTER","mode":"INPUT"},{"name":"phTable","datatype":"HANDLE","mode":"INPUT"}],"returns":{"datatype":"INT64","comment":""},"meta":{"protected":true}},{"id":"method-preCommitLogic","name":"preCommitLogic","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003egetRecCount\u003c/p\u003e\n","parameters":[{"name":"pcAction","datatype":"CHARACTER","mode":"INPUT"},{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-postCommitLogic","name":"postCommitLogic","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003epreCommitLogic\u003c/p\u003e\n","parameters":[{"name":"pcAction","datatype":"CHARACTER","mode":"INPUT"},{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-postFetchRecord","name":"postFetchRecord","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003epostCommitLogic\u003c/p\u003e\n","returns":{"comment":""},"meta":{"protected":true}},{"id":"method-validateData","name":"validateData","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003epostFetchRecord\u003c/p\u003e\n","parameters":[{"name":"pcAction","datatype":"CHARACTER","mode":"INPUT"},{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{"protected":true}},{"id":"method-initialize","name":"initialize","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"","returns":{"comment":""},"meta":{}},{"id":"method-dispose","name":"dispose","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003einitialize\u003c/p\u003e\n","returns":{"comment":""},"meta":{}},{"id":"method-getDataset","name":"getDataset","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"","parameters":[{"name":"phDataset","datatype":"DATASET-HANDLE","mode":"OUTPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-postRowFill","name":"postRowFill","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003egetDataset\u003c/p\u003e\n","parameters":[{"name":"phDataset","datatype":"DATASET-HANDLE","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-readData","name":"readData","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"","parameters":[{"name":"filter","datatype":"CHARACTER","mode":"INPUT"},{"name":"numRecs","datatype":"INT64","mode":"OUTPUT"},{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":"OUTPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-createData","name":"createData","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003ereadData\u003c/p\u003e\n","parameters":[{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{"override":true}},{"id":"method-updateData","name":"updateData","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003ecreateData\u003c/p\u003e\n","parameters":[{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{"override":true}},{"id":"method-deleteData","name":"deleteData","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003eupdateData\u003c/p\u003e\n","parameters":[{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{"override":true}},{"id":"method-submitData","name":"submitData","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003edeleteData\u003c/p\u003e\n","parameters":[{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-getData","name":"getData","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003ePublic | CCS-compliant Read, Count, and Update (aka. Submit)\u003c/p\u003e\n","parameters":[{"name":"poRequest","datatype":"IGetDataRequest","mode":"INPUT"},{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":"OUTPUT"}],"returns":{"datatype":"IGetDataResponse","comment":""},"meta":{}},{"id":"method-getResultCount","name":"getResultCount","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003egetData\u003c/p\u003e\n","parameters":[{"name":"poRequest","datatype":"IGetDataRequest","mode":"INPUT"}],"returns":{"datatype":"IGetResultCountResponse","comment":""},"meta":{}},{"id":"method-updateData-1","name":"updateData","owner":"Spark.Core.Service.SparkEntity","tagname":"method","comment":"\u003cp\u003egetResultCount\u003c/p\u003e\n","parameters":[{"name":"phDataSet","datatype":"DATASET-HANDLE","mode":""},{"name":"poUpdateDataRequest","datatype":"IUpdateDataRequest","mode":"INPUT"}],"returns":{"datatype":"Progress.Lang.Object","comment":""},"meta":{}},{"id":"constructor-OpenEdge_BusinessLogic_BusinessEntity_BusinessEntity1","name":"BusinessEntity","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"hDS","datatype":"HANDLE","mode":"INPUT"}],"meta":{"protected":true}},{"id":"property-OpenEdge_BusinessLogic_BusinessEntity_ProDataSet","name":"ProDataSet","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"property","datatype":"HANDLE","comment":"\u003cp\u003eThe dataset currently in use\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{"protected":true}},{"id":"property-OpenEdge_BusinessLogic_BusinessEntity_ProDataSource","name":"ProDataSource","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"property","datatype":"HANDLE","comment":"\u003cp\u003eStores a data source for each table in dataset. Should be in table order as defined in DataSet.\u003c/p\u003e\n\u003cul\u003e\n\u003cli\u003eThere must be a data source entry for each table in dataset.\u003c/li\u003e\n\u003c/ul\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{"protected":true}},{"id":"property-OpenEdge_BusinessLogic_BusinessEntity_SkipList","name":"SkipList","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"property","datatype":"CHARACTER","comment":"\u003cp\u003eStores skip-list entry for each table in dataset. Should be in table order as defined in DataSet.\u003c/p\u003e\n\u003cul\u003e\n\u003cli\u003eEach skip-list entry is a comma-separated list of field names, to be ignored in create stmt.\u003c/li\u003e\n\u003c/ul\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_ReadData","name":"ReadData","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eGeneric routine to read data for the dataset.\u003c/p\u003e\n","parameters":[{"name":"cFilter","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_ReadData-1","name":"ReadData","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eGeneric routine to read data for the dataset with no filter specified.\u003c/p\u003e\n","returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_ReadData-2","name":"ReadData","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eGeneric routine to read data for the dataset.\u003c/p\u003e\n","parameters":[{"name":"cFilter","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_ReadData-3","name":"ReadData","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eGeneric routine to read data for a table within a dataset.\u003c/p\u003e\n","parameters":[{"name":"cFilter","datatype":"CHARACTER","mode":"INPUT"},{"name":"hBuffer","datatype":"HANDLE","mode":"INPUT"}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_ReadData-4","name":"ReadData","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eGeneric routine to read data for a table within a dataset with no filter specified.\u003c/p\u003e\n","parameters":[{"name":"hBuffer","datatype":"HANDLE","mode":"INPUT"}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_CreateData","name":"CreateData","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eCreate one or more new records\u003c/p\u003e\n","parameters":[{"name":"hDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_UpdateData","name":"UpdateData","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eUpdate one or more new records\u003c/p\u003e\n","parameters":[{"name":"hDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_DeleteData","name":"DeleteData","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eDelete one or more records\u003c/p\u003e\n","parameters":[{"name":"hDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_SaveRows","name":"SaveRows","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eSaves/Submits one or more changed rows (creates, updates, and/or deletes)\nwhere each changed row is processed as a separate transaction.\nSaveRows() is similar to Submit(), but acts as a bulk submit, with separate\nrow transactions.\u003c/p\u003e\n","parameters":[{"name":"hDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_Submit","name":"Submit","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eSubmits one or more changed records (creates, updates, and/or deletes)\nwhere the changed record set is processed as a single transaction.\u003c/p\u003e\n","parameters":[{"name":"hDataSet","datatype":"DATASET-HANDLE","mode":""}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_ProcessTransactionalError","name":"ProcessTransactionalError","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eProcessTransactionalError() is called when we are processing a single\ntransaction, and an error occurs for one of the row changes.\nWhen this occurs, all rows should have REJECTED set to TRUE,\nand the error message should be set on the offending row.\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cp\u003eIf there is no bi data being sent between client and server (CUD_NOBI),\nthen we throw the error (resulting in http 500 error),\nand we also must back out all changes.\u003c/p\u003e\n","parameters":[{"name":"err","datatype":"Progress.Lang.Error","mode":"INPUT"}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_CommitData","name":"CommitData","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eGeneric routine to save or commit data for a dataset.\u003c/p\u003e\n","parameters":[{"name":"iRowState","datatype":"INTEGER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_AttachDataSources","name":"AttachDataSources","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eAttach Data Sources to  DataSet\u0027s buffers\u003c/p\u003e\n","returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_AttachDataSources-1","name":"AttachDataSources","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eAttach Data Sources to  DataSet\u0027s buffers\u003c/p\u003e\n","parameters":[{"name":"cFieldList","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_ValidateDataSources","name":"ValidateDataSources","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eMust verify that ProDataSource contains a data source entry for each\ntable specified in dataset. Also verify that they are valid handles.\nA data source entry can be set to UNKNOWN as well, as allow for that.\u003c/p\u003e\n","returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_ValidateFieldLists","name":"ValidateFieldLists","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eMust verify that cFieldList\u0027s EXTENT value is same as number of buffers in dataset\u003c/p\u003e\n","parameters":[{"name":"cFieldList","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_SetFillWhereString","name":"SetFillWhereString","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003cp\u003eAdds a FILL-WHERE-STRING to a datasource\u003c/p\u003e\n","parameters":[{"name":"cWhere","datatype":"CHARACTER","mode":"INPUT"},{"name":"hBuffer","datatype":"HANDLE","mode":"INPUT"}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_ReadData-5","name":"ReadData","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003cp\u003eGeneric read data routine using a filter object (instead of strings).\nThis supports CCS-compliant BE\u0027s.\u003c/p\u003e\n","parameters":[{"name":"pGetRequest","datatype":"Ccs.BusinessLogic.IGetDataRequest","mode":"INPUT"}],"returns":{"datatype":"Ccs.BusinessLogic.IGetDataResponse","comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_DoFill","name":"DoFill","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003cp\u003ePerforms the dataset or buffer FILL() operation.\u003c/p\u003e\n","parameters":[{"name":"pDataset","datatype":"HANDLE","mode":"INPUT"}],"returns":{"comment":""},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_CountDatasetRecords","name":"CountDatasetRecords","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003cp\u003eReturns the count of the total number of result records currently in a dataset.\u003c/p\u003e\n","parameters":[{"name":"pData","datatype":"HANDLE","mode":"INPUT"}],"returns":{"datatype":"Ccs.BusinessLogic.IGetResultCountResponse","comment":"IGetResultCountResponse The IGetResultCountResponse instance for the request"},"meta":{"protected":true}},{"id":"method-OpenEdge_BusinessLogic_BusinessEntity_CountBufferRecords","name":"CountBufferRecords","owner":"OpenEdge.BusinessLogic.BusinessEntity","tagname":"method","comment":"\u003cp\u003eReturns the count of the total number of result records currently in a buffer\u003c/p\u003e\n","parameters":[{"name":"pData","datatype":"HANDLE","mode":"INPUT"}],"returns":{"datatype":"Ccs.BusinessLogic.IGetTableResultCountResponse","comment":"IGetTableResultCountResponse The IGetTableResultCountResponse instance for the request"},"meta":{"protected":true}}],"meta":{"abstract":true}});