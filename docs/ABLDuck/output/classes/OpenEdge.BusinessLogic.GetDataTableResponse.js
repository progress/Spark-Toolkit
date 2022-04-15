Ext.data.JsonP.OpenEdge_BusinessLogic_GetDataTableResponse({"files":[],"uses":["Ccs.BusinessLogic.IGetDataTableResponse","OpenEdge.BusinessLogic.IO.JsonPropertyNameEnum","OpenEdge.Core.Assert","OpenEdge.Core.Json.IJsonSerializer","OpenEdge.Core.Json.JsonPropertyHelper","Progress.Json.ObjectModel.JsonConstruct","Progress.Json.ObjectModel.JsonDataType","Progress.Json.ObjectModel.JsonObject"],"id":"class-OpenEdge.BusinessLogic.GetDataTableResponse","tagname":"class","name":"OpenEdge.BusinessLogic.GetDataTableResponse","extends":"","author":"pjudge","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eGetDataTableResponse\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003e2018-06-15\u003c/p\u003e\n","icon":"class","superclasses":["OpenEdge.BusinessLogic.GetDataTableResponse"],"subclasses":[],"implements":["IGetDataTableResponse","OpenEdge.Core.Json.IJsonSerializer"],"members":[{"id":"constructor-GetDataTableResponse1","name":"GetDataTableResponse","owner":"OpenEdge.BusinessLogic.GetDataTableResponse","tagname":"constructor","comment":"\u003cp\u003eDefault constructor\u003c/p\u003e\n","meta":{}},{"id":"constructor-GetDataTableResponse2","name":"GetDataTableResponse","owner":"OpenEdge.BusinessLogic.GetDataTableResponse","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pTableName","datatype":"CHARACTER","mode":"INPUT"}],"meta":{}},{"id":"property-NextPagingContext","name":"NextPagingContext","owner":"OpenEdge.BusinessLogic.GetDataTableResponse","tagname":"property","datatype":"CHARACTER","comment":"\u003cp\u003eReturns the paging context to be passed back to the business entity when requesting the next set\u003c/p\u003e\n","meta":{}},{"id":"property-PreviousPagingContext","name":"PreviousPagingContext","owner":"OpenEdge.BusinessLogic.GetDataTableResponse","tagname":"property","datatype":"CHARACTER","comment":"\u003cp\u003eReturns the paging context to be passed back to the business entity when requesting the previous set\u003c/p\u003e\n","meta":{}},{"id":"property-TableName","name":"TableName","owner":"OpenEdge.BusinessLogic.GetDataTableResponse","tagname":"property","datatype":"CHARACTER","comment":"\u003cp\u003eReturns the name of the ProDataset Table\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003eGET - PRIVATE SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-ToJsonConstruct","name":"ToJsonConstruct","owner":"OpenEdge.BusinessLogic.GetDataTableResponse","tagname":"method","comment":"\u003cp\u003eSerializes this object\u003c/p\u003e\n","returns":{"datatype":"Progress.Json.ObjectModel.JsonConstruct","comment":"JsonConstruct The serialized object. Always JsonObject."},"meta":{}},{"id":"method-FromJson","name":"FromJson","owner":"OpenEdge.BusinessLogic.GetDataTableResponse","tagname":"method","comment":"\u003cp\u003eDesrializes this object\u003c/p\u003e\n","parameters":[{"name":"pData","datatype":"Progress.Json.ObjectModel.JsonConstruct","mode":"INPUT"}],"returns":{"comment":""},"meta":{}}],"meta":{}});