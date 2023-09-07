Ext.data.JsonP.OpenEdge_BusinessLogic_QuerySortEntry({"files":[],"uses":["Ccs.BusinessLogic.IQuerySortEntry","Ccs.BusinessLogic.SortOrderEnum","OpenEdge.BusinessLogic.IO.JsonPropertyNameEnum","OpenEdge.Core.Assert","OpenEdge.Core.Json.IJsonSerializer","Progress.Json.ObjectModel.JsonConstruct","Progress.Json.ObjectModel.JsonObject","OpenEdge.Core.Json.JsonPropertyHelper","Progress.Json.ObjectModel.JsonDataType"],"id":"class-OpenEdge.BusinessLogic.QuerySortEntry","tagname":"class","name":"OpenEdge.BusinessLogic.QuerySortEntry","extends":"","author":"pjudge","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eQuerySortEntry\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003e2018-06-15\u003c/p\u003e\n","icon":"class","superclasses":["OpenEdge.BusinessLogic.QuerySortEntry"],"subclasses":[],"implements":["IQuerySortEntry","OpenEdge.Core.Json.IJsonSerializer"],"members":[{"id":"constructor-QuerySortEntry1","name":"QuerySortEntry","owner":"OpenEdge.BusinessLogic.QuerySortEntry","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pFieldName","datatype":"CHARACTER","mode":""},{"name":"pSortDirection","datatype":"Ccs.BusinessLogic.SortOrderEnum","mode":""}],"meta":{}},{"id":"constructor-QuerySortEntry2","name":"QuerySortEntry","owner":"OpenEdge.BusinessLogic.QuerySortEntry","tagname":"constructor","comment":"\u003cp\u003eDefault constructor\u003c/p\u003e\n","meta":{}},{"id":"constructor-QuerySortEntry3","name":"QuerySortEntry","owner":"OpenEdge.BusinessLogic.QuerySortEntry","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pFieldName","datatype":"CHARACTER","mode":""}],"meta":{}},{"id":"property-FieldName","name":"FieldName","owner":"OpenEdge.BusinessLogic.QuerySortEntry","tagname":"property","datatype":"CHARACTER","comment":"\u003cp\u003eReturns the name of the field for this query sort entry\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-SortOrder","name":"SortOrder","owner":"OpenEdge.BusinessLogic.QuerySortEntry","tagname":"property","datatype":"Ccs.BusinessLogic.SortOrderEnum","comment":"\u003cp\u003eReturns the sort order for this query sort entry\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-ToString","name":"ToString","owner":"OpenEdge.BusinessLogic.QuerySortEntry","tagname":"method","comment":"","returns":{"datatype":"CHARACTER","comment":""},"meta":{"override":true}},{"id":"method-ToJsonConstruct","name":"ToJsonConstruct","owner":"OpenEdge.BusinessLogic.QuerySortEntry","tagname":"method","comment":"\u003cp\u003eSERIALIZATION METHOD:returns a JsonConstruct (JsonDataType:OBJECT or JsonDataType:ARRAY) representation\nof this object.\u003c/p\u003e\n","returns":{"datatype":"Progress.Json.ObjectModel.JsonConstruct","comment":"JsonConstruct A JSON representation of this object. May be unknown (JsonDataType:NULL)."},"meta":{}},{"id":"method-FromJson","name":"FromJson","owner":"OpenEdge.BusinessLogic.QuerySortEntry","tagname":"method","comment":"\u003cp\u003eDESERIALIZATION METHOD: populates this object with data from the JSON representation.\u003c/p\u003e\n","parameters":[{"name":"pJson","datatype":"Progress.Json.ObjectModel.JsonConstruct","mode":""}],"returns":{"comment":""},"meta":{}}],"meta":{}});