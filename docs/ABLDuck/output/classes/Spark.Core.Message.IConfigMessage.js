Ext.data.JsonP.Spark_Core_Message_IConfigMessage({"files":[],"uses":["Spark.Core.Message.*"],"id":"class-Spark.Core.Message.IConfigMessage","tagname":"class","name":"Spark.Core.Message.IConfigMessage","extends":"Spark.Core.Message.IAbstractMessage","author":"","comment":"\u003cp\u003eA Configuration Message (or a Service Message loaded from a JSON file or JSON text)\u003c/p\u003e\n","icon":"interface","superclasses":["Spark.Core.Message.IAbstractMessage","Spark.Core.Message.IConfigMessage"],"subclasses":[],"implementers":["Spark.Core.Message.ConfigMessage"],"members":[{"id":"method-deserializeMessageFromFile","name":"deserializeMessageFromFile","owner":"Spark.Core.Message.IConfigMessage","tagname":"method","comment":"","parameters":[{"name":"pcFile","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-deserializeMessage","name":"deserializeMessage","owner":"Spark.Core.Message.IConfigMessage","tagname":"method","comment":"","parameters":[{"name":"pcMessage","datatype":"LONGCHAR","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"property-Spark_Core_Message_IAbstractMessage_messageKeyPin","name":"messageKeyPin","owner":"Spark.Core.Message.IAbstractMessage","tagname":"property","datatype":"CHARACTER","comment":"","meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_promoteObject","name":"promoteObject","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_demoteObject","name":"demoteObject","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setNullParam","name":"setNullParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcValue","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-1","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcValue","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-2","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcValue","datatype":"LONGCHAR","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-3","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcValue","datatype":"LONGCHAR","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-4","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"piValue","datatype":"INTEGER","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-5","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"piValue","datatype":"INTEGER","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-6","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"piValue","datatype":"INT64","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-7","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"piValue","datatype":"INT64","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-8","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plValue","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-9","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plValue","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-10","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"pdValue","datatype":"DECIMAL","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-11","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"pdValue","datatype":"DECIMAL","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-12","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"ptValue","datatype":"DATE","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-13","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"ptValue","datatype":"DATE","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-14","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"ptValue","datatype":"DATETIME","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-15","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"ptValue","datatype":"DATETIME","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-16","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"ptValue","datatype":"DATETIME-TZ","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-17","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"ptValue","datatype":"DATETIME-TZ","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-18","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"prValue","datatype":"ROWID","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-19","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"prValue","datatype":"ROWID","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-20","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"prValue","datatype":"RECID","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-21","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"prValue","datatype":"RECID","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-22","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"pmValue","datatype":"MEMPTR","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-23","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"pmValue","datatype":"MEMPTR","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-24","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"poValue","datatype":"Progress.Json.ObjectModel.JsonObject","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-25","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"poValue","datatype":"Progress.Json.ObjectModel.JsonArray","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-26","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"phValue","datatype":"HANDLE","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_setParam-27","name":"setParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"phValue","datatype":"HANDLE","mode":"INPUT"},{"name":"plBefore","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParams","name":"getParams","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamCount","name":"getParamCount","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","returns":{"datatype":"INTEGER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_hasParam","name":"hasParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_removeParam","name":"removeParam","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamObject","name":"getParamObject","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","returns":{"datatype":"Progress.Json.ObjectModel.JsonObject","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamType","name":"getParamType","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"INTEGER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsJsonText","name":"getParamAsJsonText","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LONGCHAR","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsJsonText-1","name":"getParamAsJsonText","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"LONGCHAR","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsChar","name":"getParamAsChar","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsChar-1","name":"getParamAsChar","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsCharEx","name":"getParamAsCharEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsCharEx-1","name":"getParamAsCharEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsLongChar","name":"getParamAsLongChar","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LONGCHAR","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsLongChar-1","name":"getParamAsLongChar","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"LONGCHAR","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsLongCharEx","name":"getParamAsLongCharEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LONGCHAR","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsLongCharEx-1","name":"getParamAsLongCharEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"LONGCHAR","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsInt","name":"getParamAsInt","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"INTEGER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsInt-1","name":"getParamAsInt","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"INTEGER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsIntEx","name":"getParamAsIntEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"INTEGER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsIntEx-1","name":"getParamAsIntEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"INTEGER","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsInt64","name":"getParamAsInt64","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"INT64","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsInt64-1","name":"getParamAsInt64","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"INT64","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsInt64Ex","name":"getParamAsInt64Ex","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"INT64","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsInt64Ex-1","name":"getParamAsInt64Ex","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"INT64","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDec","name":"getParamAsDec","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"DECIMAL","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDec-1","name":"getParamAsDec","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"DECIMAL","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDecEx","name":"getParamAsDecEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"DECIMAL","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDecEx-1","name":"getParamAsDecEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"DECIMAL","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDate","name":"getParamAsDate","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"DATE","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDate-1","name":"getParamAsDate","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"DATE","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDateEx","name":"getParamAsDateEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"DATE","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDateEx-1","name":"getParamAsDateEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"DATE","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDatetime","name":"getParamAsDatetime","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"DATETIME","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDatetime-1","name":"getParamAsDatetime","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"DATETIME","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDatetimeEx","name":"getParamAsDatetimeEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"DATETIME","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDatetimeEx-1","name":"getParamAsDatetimeEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"DATETIME","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDatetimeTZ","name":"getParamAsDatetimeTZ","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"DATETIME-TZ","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDatetimeTZ-1","name":"getParamAsDatetimeTZ","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"DATETIME-TZ","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDatetimeTZEx","name":"getParamAsDatetimeTZEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"DATETIME-TZ","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsDatetimeTZEx-1","name":"getParamAsDatetimeTZEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"DATETIME-TZ","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsLog","name":"getParamAsLog","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsLog-1","name":"getParamAsLog","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsLogEx","name":"getParamAsLogEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsLogEx-1","name":"getParamAsLogEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsRowid","name":"getParamAsRowid","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"ROWID","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsRowid-1","name":"getParamAsRowid","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"ROWID","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsRowidEx","name":"getParamAsRowidEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"ROWID","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsRowidEx-1","name":"getParamAsRowidEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"ROWID","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsRecid","name":"getParamAsRecid","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"RECID","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsRecid-1","name":"getParamAsRecid","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"RECID","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsRecidEx","name":"getParamAsRecidEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"RECID","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsRecidEx-1","name":"getParamAsRecidEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"RECID","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsMemptr","name":"getParamAsMemptr","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"MEMPTR","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsMemptr-1","name":"getParamAsMemptr","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"MEMPTR","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsMemptrEx","name":"getParamAsMemptrEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"MEMPTR","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsMemptrEx-1","name":"getParamAsMemptrEx","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"MEMPTR","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsJsonObject","name":"getParamAsJsonObject","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"Progress.Json.ObjectModel.JsonObject","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsJsonObject-1","name":"getParamAsJsonObject","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"Progress.Json.ObjectModel.JsonObject","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsJsonArray","name":"getParamAsJsonArray","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"Progress.Json.ObjectModel.JsonArray","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsJsonArray-1","name":"getParamAsJsonArray","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"plOptionalParam","datatype":"LOGICAL","mode":"INPUT"}],"returns":{"datatype":"Progress.Json.ObjectModel.JsonArray","comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_getParamAsHandle","name":"getParamAsHandle","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","parameters":[{"name":"pcParam","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcMode","datatype":"CHARACTER","mode":"INPUT"},{"name":"phData","datatype":"HANDLE","mode":"INPUT"}],"returns":{"comment":""},"meta":{}},{"id":"method-Spark_Core_Message_IAbstractMessage_serializeMessage","name":"serializeMessage","owner":"Spark.Core.Message.IAbstractMessage","tagname":"method","comment":"","returns":{"datatype":"LONGCHAR","comment":""},"meta":{}}],"meta":{}});