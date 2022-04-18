Ext.data.JsonP.Spark_Core_Manager_CatalogManager({"files":[],"uses":["Progress.Lang.*","Progress.Json.ObjectModel.*","Progress.Json.ObjectModel.ObjectModelParser","OpenEdge.Core.*","OpenEdge.Core.Collections.*","OpenEdge.Net.HTTP.MethodEnum","OpenEdge.Net.HTTP.StatusCodeEnum","OpenEdge.Web.DataObject.*","OpenEdge.Web.DataObject.Writer.*","Spark.Core.Manager.ILoggingManager","Spark.Core.Manager.ISchemaManager","Spark.Core.Service.Service","Spark.Core.Service.ISparkEntity","Spark.Core.Service.IDynamicEntity","Spark.Core.Service.IDynamicResource","Spark.Core.Util.GenTools","Spark.Core.Util.OperationEnum","Spark.Core.Util.OSTools","Spark.Core.Util.Reflection"],"id":"class-Spark.Core.Manager.CatalogManager","tagname":"class","name":"Spark.Core.Manager.CatalogManager","extends":"Spark.Core.Manager.Manager","author":"Dustin Grau (dugrau@progress.com)","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eCatalogManager\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eFri Dec 19 14:30:46 EST 2014\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cp\u003eSetting the logging-level for your ABL Application to at\nleast 3 (verbose) will trigger additional messages in\nthe logs as well as output multiple files in the session\ntemp directory (eg. the service mapping files).\u003c/p\u003e\n\u003cp\u003eThis class provides 3 distinct functions at present:\u003c/p\u003e\n\u003col\u003e\n\u003cli\u003eDiscover any classes/procedures to be exposed as RESTful endpoints\nPerformed by loadResources()\u003c/li\u003e\n\u003cli\u003eCreate a JSDO-compatible DataObject Catalog for public consumption\nPerformed by getCatalog()\u003c/li\u003e\n\u003cli\u003eRegister all ABL resources as DataObjectServices for internal use\nPerformed by registerService() via registerAllServices()\u003c/li\u003e\n\u003c/ol\u003e\n\u003cp\u003eIn respect to the DataObject Catalog and the DataObjectServices these\nprovide similar but limited sets of data about the exposed resources.\nWhile they draw upon the same sources of information, the artifacts\ndescribe this data differently for each of their intended purposes.\nTherefore, a \u0026quot;source of truth\u0026quot; is provided in the form of ProDatasets\nwithin this class which contains all necessary information gathered\nduring the resource discovery process (stored in dsResource).\u003c/p\u003e\n","icon":"class","superclasses":["Spark.Core.Service.Service","Spark.Core.Manager.Manager","Spark.Core.Manager.CatalogManager"],"subclasses":[],"implements":["Spark.Core.Manager.ICatalogManager"],"members":[{"id":"property-ApiVersion","name":"ApiVersion","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"DECIMAL","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-IdProperty","name":"IdProperty","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"CHARACTER","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-SeqProperty","name":"SeqProperty","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"CHARACTER","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-ReadFilter","name":"ReadFilter","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"CHARACTER","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-ServicePrefix","name":"ServicePrefix","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"CHARACTER","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-CatalogService","name":"CatalogService","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"CHARACTER","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-UseRequestObj","name":"UseRequestObj","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"LOGICAL","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-oLoggingManager","name":"oLoggingManager","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"Spark.Core.Manager.ILoggingManager","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-oSchemaManager","name":"oSchemaManager","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"Spark.Core.Manager.ISchemaManager","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-TemporaryDir","name":"TemporaryDir","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"CHARACTER","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-Annotations","name":"Annotations","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"JsonObject","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-ParamUUID","name":"ParamUUID","owner":"Spark.Core.Manager.CatalogManager","tagname":"property","datatype":"INT64","comment":"\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-clearResourceMethods","name":"clearResourceMethods","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-getJsonType","name":"getJsonType","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003eclearResourceMethods\u003c/p\u003e\n","parameters":[{"name":"pcABLType","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-getList","name":"getList","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003egetJsonType\u003c/p\u003e\n","parameters":[{"name":"poJsonArray","datatype":"JsonArray","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-processAnnotations","name":"processAnnotations","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003egetList\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""},{"name":"pcClassPath","datatype":"CHARACTER","mode":""},{"name":"pcSourcePath","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-loadDynamicResource","name":"loadDynamicResource","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003eprocessAnnotations\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-registerMethods","name":"registerMethods","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003eloadDynamicResource\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-registerMethods-1","name":"registerMethods","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003eregisterMethods\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""},{"name":"pcOperations","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-registerProcedures","name":"registerProcedures","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003eregisterMethods\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""},{"name":"pcResourceName","datatype":"CHARACTER","mode":""},{"name":"phProcHandle","datatype":"HANDLE","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-runPreloader","name":"runPreloader","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003eregisterProcedures\u003c/p\u003e\n","returns":{"comment":""},"meta":{}},{"id":"method-setResourceMethod","name":"setResourceMethod","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003erunPreloader\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""},{"name":"pcMethodName","datatype":"CHARACTER","mode":""},{"name":"pcEntityName","datatype":"CHARACTER","mode":""},{"name":"poMethodParams","datatype":"JsonArray","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-setResourceProcedure","name":"setResourceProcedure","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003esetResourceMethod\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""},{"name":"pcMethodName","datatype":"CHARACTER","mode":""},{"name":"pcMethodSignature","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-getBeforeImageFlag","name":"getBeforeImageFlag","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""},{"name":"pcOperationType","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-getServices","name":"getServices","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003egetBeforeImageFlag\u003c/p\u003e\n","parameters":[{"name":"pcServiceUUID","datatype":"CHARACTER","mode":""},{"name":"pcResourceName","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"JsonArray","comment":""},"meta":{}},{"id":"method-getResources","name":"getResources","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003egetServices\u003c/p\u003e\n","parameters":[{"name":"pcServiceUUID","datatype":"CHARACTER","mode":""},{"name":"pcResourceName","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"JsonArray","comment":""},"meta":{}},{"id":"method-getSchema","name":"getSchema","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003egetResources\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""},{"name":"plPrimaryEntity","datatype":"LOGICAL","mode":""}],"returns":{"datatype":"JsonObject","comment":""},"meta":{}},{"id":"method-getRelations","name":"getRelations","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003egetSchema\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"JsonArray","comment":""},"meta":{}},{"id":"method-getTable","name":"getTable","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003egetRelations\u003c/p\u003e\n","parameters":[{"name":"pcDatasetName","datatype":"CHARACTER","mode":""},{"name":"pcTableName","datatype":"CHARACTER","mode":""},{"name":"pcPrimaryKey","datatype":"CHARACTER","mode":""},{"name":"pcForeignKey","datatype":"CHARACTER","mode":""},{"name":"pcSerialized","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"JsonObject","comment":""},"meta":{}},{"id":"method-getOperations","name":"getOperations","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003egetTable\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"JsonArray","comment":""},"meta":{}},{"id":"method-getDataDefs","name":"getDataDefs","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003egetOperations\u003c/p\u003e\n","parameters":[{"name":"pcResourceUUID","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"JsonObject","comment":""},"meta":{}},{"id":"method-initialize","name":"initialize","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"","returns":{"comment":""},"meta":{"override":true}},{"id":"method-dispose","name":"dispose","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003einitialize\u003c/p\u003e\n","returns":{"comment":""},"meta":{"override":true}},{"id":"method-stripFileExtensions","name":"stripFileExtensions","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003edispose\u003c/p\u003e\n","parameters":[{"name":"pcFileName","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-checkForResources","name":"checkForResources","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003estripFileExtension\u003c/p\u003e\n","returns":{"comment":""},"meta":{}},{"id":"method-loadResources","name":"loadResources","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003echeckForResources\u003c/p\u003e\n","returns":{"comment":""},"meta":{}},{"id":"method-addProperty","name":"addProperty","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003eloadResources\u003c/p\u003e\n","parameters":[{"name":"pcServiceURI","datatype":"CHARACTER","mode":""},{"name":"pcClassPath","datatype":"CHARACTER","mode":""},{"name":"pcOperationType","datatype":"CHARACTER","mode":""},{"name":"pcPropertyName","datatype":"CHARACTER","mode":""},{"name":"pcPropertyType","datatype":"CHARACTER","mode":""},{"name":"pcPropertyValue","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-describeEntity","name":"describeEntity","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003eaddProperty\u003c/p\u003e\n","parameters":[{"name":"pcServiceUUID","datatype":"CHARACTER","mode":""},{"name":"pcResClassPath","datatype":"CHARACTER","mode":""},{"name":"pcEntityName","datatype":"CHARACTER","mode":""},{"name":"pcPrimaryKeys","datatype":"CHARACTER","mode":""},{"name":"pcForeignKeys","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-describeFields","name":"describeFields","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003edescribeEntity\u003c/p\u003e\n","parameters":[{"name":"pcEntityName","datatype":"CHARACTER","mode":""},{"name":"pcTableName","datatype":"CHARACTER","mode":""},{"name":"poFieldData","datatype":"JsonObject","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-describeResource","name":"describeResource","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003edescribeFields\u003c/p\u003e\n","parameters":[{"name":"pcServiceURI","datatype":"CHARACTER","mode":""},{"name":"pcClassPath","datatype":"CHARACTER","mode":""},{"name":"pcMethodName","datatype":"CHARACTER","mode":""},{"name":"pcPublicName","datatype":"CHARACTER","mode":""},{"name":"pcOperationType","datatype":"CHARACTER","mode":""},{"name":"pcOperationVerb","datatype":"CHARACTER","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-getCatalog","name":"getCatalog","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003edescribeResource\u003c/p\u003e\n","parameters":[{"name":"pcServiceURI","datatype":"CHARACTER","mode":""},{"name":"pcResourceName","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"JsonObject","comment":""},"meta":{}},{"id":"method-stopProcedures","name":"stopProcedures","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003egetCatalog\u003c/p\u003e\n","returns":{"comment":""},"meta":{}},{"id":"method-registerAllServices","name":"registerAllServices","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003estopProcedures\u003c/p\u003e\n","parameters":[{"name":"poRegistry","datatype":"IServiceRegistry","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-registerService","name":"registerService","owner":"Spark.Core.Manager.CatalogManager","tagname":"method","comment":"\u003cp\u003eregisterAllServices\u003c/p\u003e\n","parameters":[{"name":"poRegistry","datatype":"IServiceRegistry","mode":""},{"name":"pcServiceName","datatype":"CHARACTER","mode":""},{"name":"poServiceVersion","datatype":"SemanticVersion","mode":""}],"returns":{"datatype":"DataObjectService","comment":""},"meta":{}},{"id":"temptable-GeneralParam","name":"GeneralParam","owner":"Spark.Core.Manager.CatalogManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE GeneralParam SERIALIZE-NAME \u0027General\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ApiVersion AS DECIMAL\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD CatalogService AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD BusinessRoot AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD IdProperty AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD SeqProperty AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD PreLoader AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ReadFilter AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServicePrefix AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxEntity PRIMARY UNIQUE BusinessRoot\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"\u003cp\u003eGeneral settings for the catalog manager.\u003c/p\u003e\n","meta":{}},{"id":"temptable-ServiceList","name":"ServiceList","owner":"Spark.Core.Manager.CatalogManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ServiceList SERIALIZE-NAME \u0027ServiceSource\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceUUID AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceURI AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ClassPath AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD SendOnlyChanges AS LOGICAL INITIAL false\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD UseRequest AS LOGICAL INITIAL false\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxPrimary PRIMARY UNIQUE ServiceName ServiceURI\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxClassPath UNIQUE ClassPath\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"\u003cp\u003ePre-defined services to be exposed via the catalog manager.\u003c/p\u003e\n","meta":{}},{"id":"temptable-ResourceList","name":"ResourceList","owner":"Spark.Core.Manager.CatalogManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ResourceList SERIALIZE-NAME \u0027ServiceResource\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceUUID AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ClassPath AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxPrimary PRIMARY UNIQUE ClassPath\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"\u003cp\u003eInitial definitions or discovered resources to expose on a per-service basis.\u003c/p\u003e\n","meta":{}},{"id":"temptable-ServiceInfo","name":"ServiceInfo","owner":"Spark.Core.Manager.CatalogManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ServiceInfo SERIALIZE-NAME \u0027Service\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceUUID AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceURI AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ClassPath AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD SendOnlyChanges AS LOGICAL INITIAL false\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD UseRequest AS LOGICAL INITIAL false\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxPrimary PRIMARY UNIQUE ServiceName ServiceURI\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxName UNIQUE ClassPath\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"\u003cp\u003eServiceList is our initial \u0026quot;service listing\u0026quot;, but because tables cannot exist in more than\n1 dataset we use this as a clone for associating the ResourceInfo table and its children.\u003c/p\u003e\n","meta":{}},{"id":"temptable-ResourceInfo","name":"ResourceInfo","owner":"Spark.Core.Manager.CatalogManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ResourceInfo SERIALIZE-NAME \u0027Resource\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ServiceUUID AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ResourceUUID AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ClassPath AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD PublicName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD SourcePath AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ResourceURI AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ApiVersion AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ProcHandle AS HANDLE\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD IsClass AS LOGICAL\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ValidClass AS LOGICAL\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD EntityName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD EntityKeys AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ForeignKeys AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ClassSig AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD Security AS Progress.Lang.Object\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxPrimary PRIMARY UNIQUE ResourceUUID\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxPublic UNIQUE ServiceUUID ClassPath\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxResource UNIQUE ServiceUUID PublicName\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{}},{"id":"temptable-MethodInfo","name":"MethodInfo","owner":"Spark.Core.Manager.CatalogManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE MethodInfo SERIALIZE-NAME \u0027Operation\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ResourceUUID AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD MethodName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD PublicName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD MethodURI AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD MethodSignature AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD OperationType AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD OperationVerb AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ContentType AS CHARACTER INITIAL application/json\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD Security AS Progress.Lang.Object\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxPrimary PRIMARY UNIQUE ResourceUUID MethodName\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxPublic UNIQUE ResourceUUID PublicName\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{}},{"id":"temptable-ParameterInfo","name":"ParameterInfo","owner":"Spark.Core.Manager.CatalogManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ParameterInfo SERIALIZE-NAME \u0027Parameter\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ResourceUUID AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ParamUUID AS INT64\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD MethodName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ParamName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD PublicName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD IOMode AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD DataType AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD DataTypeExtent AS INTEGER INITIAL 0\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ElementType AS CHARACTER INITIAL field\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX pukOrder PRIMARY UNIQUE ParamUUID\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{}},{"id":"temptable-ResourceProperty","name":"ResourceProperty","owner":"Spark.Core.Manager.CatalogManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE ResourceProperty SERIALIZE-NAME \u0027Property\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD ResourceUUID AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD OperationType AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD PropertyName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD PropertyType AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD PropertyValue AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxPrimary PRIMARY UNIQUE ResourceUUID OperationType PropertyName\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{}},{"id":"temptable-EntityProperty","name":"EntityProperty","owner":"Spark.Core.Manager.CatalogManager","tagname":"temptable","definition":"DEFINE TEMP-TABLE EntityProperty SERIALIZE-NAME \u0027Entity\u0027 \u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD EntityName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD TableName AS CHARACTER\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  FIELD FieldData AS Progress.Lang.Object\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;  INDEX idxPrimary PRIMARY UNIQUE EntityName TableName\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{}},{"id":"dataset-dsConfig","name":"dsConfig","owner":"Spark.Core.Manager.CatalogManager","tagname":"dataset","definition":"DEFINE DATASET dsConfig FOR GeneralParam, ServiceList, ResourceList\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"\u003cp\u003eThe configuration dataset as used by the catalog.json manager configuration file.\u003c/p\u003e\n","meta":{}},{"id":"dataset-dsResource","name":"dsResource","owner":"Spark.Core.Manager.CatalogManager","tagname":"dataset","definition":"DEFINE DATASET dsResource FOR ServiceInfo, ResourceInfo, MethodInfo, ParameterInfo, ResourceProperty\u003cbr\u003e\u0026nbsp;\u0026nbsp;\u0026nbsp;\u0026nbsp;","comment":"","meta":{}},{"id":"constructor-Spark_Core_Manager_Manager_Manager1","name":"Manager","owner":"Spark.Core.Manager.Manager","tagname":"constructor","comment":"","meta":{}},{"id":"constructor-Spark_Core_Service_Service_Service1","name":"Service","owner":"Spark.Core.Service.Service","tagname":"constructor","comment":"","meta":{}},{"id":"method-Spark_Core_Service_Service_initialize","name":"initialize","owner":"Spark.Core.Service.Service","tagname":"method","comment":"\u003cp\u003eInitializer/Startup\u003c/p\u003e\n","returns":{"comment":""},"meta":{"abstract":true}},{"id":"method-Spark_Core_Service_Service_dispose","name":"dispose","owner":"Spark.Core.Service.Service","tagname":"method","comment":"\u003cp\u003eDestroy/Shutdown/Anti-Initializer\u003c/p\u003e\n","returns":{"comment":""},"meta":{"abstract":true}}],"meta":{}});