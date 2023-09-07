Ext.data.JsonP.OpenEdge_Core_Json_IJsonSerializer({"files":[],"uses":["Progress.Json.ObjectModel.JsonConstruct"],"id":"class-OpenEdge.Core.Json.IJsonSerializer","tagname":"class","name":"OpenEdge.Core.Json.IJsonSerializer","extends":"","author":"pjudge","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eIJsonSerializer\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eIndicates that an object supports serialization to JSON\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003e2019-03-21\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cul\u003e\n\u003cli\u003eClasses implementing this interface MUST have a default\npublic constructor for deserialisation purposes, since the\nexpectation is that the entire object\u0027s state is taken from\nthe input argument to the deserialization method\u003c/li\u003e\n\u003c/ul\u003e\n","icon":"interface","superclasses":["OpenEdge.Core.Json.IJsonSerializer"],"subclasses":[],"implementers":["OpenEdge.BusinessLogic.QueryGroup","OpenEdge.BusinessLogic.GetDataRequest","OpenEdge.BusinessLogic.GetDataTableResponse","OpenEdge.BusinessLogic.QueryDefinition","OpenEdge.BusinessLogic.GetResultCountResponse","OpenEdge.BusinessLogic.UpdateDataRequest","OpenEdge.BusinessLogic.NamedQuery","OpenEdge.BusinessLogic.GetDataTableRequest","OpenEdge.BusinessLogic.GetTableResultCountResponse","OpenEdge.BusinessLogic.NamedQueryParameter","OpenEdge.BusinessLogic.QuerySortEntry","OpenEdge.BusinessLogic.GetDataResponse","OpenEdge.BusinessLogic.QueryPredicate"],"members":[{"id":"method-ToJsonConstruct","name":"ToJsonConstruct","owner":"OpenEdge.Core.Json.IJsonSerializer","tagname":"method","comment":"\u003cp\u003eSERIALIZATION METHOD:returns a JsonConstruct (JsonDataType:OBJECT or JsonDataType:ARRAY) representation\nof this object.\u003c/p\u003e\n","returns":{"datatype":"Progress.Json.ObjectModel.JsonConstruct","comment":"JsonConstruct A JSON representation of this object. May be unknown (JsonDataType:NULL)."},"meta":{}},{"id":"method-FromJson","name":"FromJson","owner":"OpenEdge.Core.Json.IJsonSerializer","tagname":"method","comment":"\u003cp\u003eDESERIALIZATION METHOD: populates this object with data from the JSON representation.\u003c/p\u003e\n","parameters":[{"name":"pJson","datatype":"Progress.Json.ObjectModel.JsonConstruct","mode":""}],"returns":{"comment":""},"meta":{}}],"meta":{}});