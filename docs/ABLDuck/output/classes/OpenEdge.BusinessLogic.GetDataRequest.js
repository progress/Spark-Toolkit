Ext.data.JsonP.OpenEdge_BusinessLogic_GetDataRequest({"files":[],"uses":["Ccs.BusinessLogic.IGetDataRequest","Ccs.BusinessLogic.IGetDataTableRequest","Ccs.BusinessLogic.INamedQuery","OpenEdge.BusinessLogic.GetDataTableRequest","OpenEdge.BusinessLogic.IO.JsonPropertyNameEnum","OpenEdge.BusinessLogic.NamedQuery","OpenEdge.Core.Assert","OpenEdge.Core.Json.IJsonSerializer","OpenEdge.Core.Json.JsonConverter","OpenEdge.Core.Json.JsonPropertyHelper","OpenEdge.Core.Json.JsonSerializer","Progress.Json.ObjectModel.JsonArray","Progress.Json.ObjectModel.JsonConstruct","Progress.Json.ObjectModel.JsonDataType","Progress.Json.ObjectModel.JsonObject"],"id":"class-OpenEdge.BusinessLogic.GetDataRequest","tagname":"class","name":"OpenEdge.BusinessLogic.GetDataRequest","extends":"","author":"pjudge","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eGetDataRequest\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003e2018-06-15\u003c/p\u003e\n","icon":"class","superclasses":["OpenEdge.BusinessLogic.GetDataRequest"],"subclasses":[],"implements":["IGetDataRequest","OpenEdge.Core.Json.IJsonSerializer"],"members":[{"id":"constructor-GetDataRequest1","name":"GetDataRequest","owner":"OpenEdge.BusinessLogic.GetDataRequest","tagname":"constructor","comment":"\u003cp\u003eDefault constructor\u003c/p\u003e\n","meta":{}},{"id":"constructor-GetDataRequest2","name":"GetDataRequest","owner":"OpenEdge.BusinessLogic.GetDataRequest","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pQuery","datatype":"Ccs.BusinessLogic.INamedQuery","mode":""}],"meta":{}},{"id":"constructor-GetDataRequest3","name":"GetDataRequest","owner":"OpenEdge.BusinessLogic.GetDataRequest","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pNumTables","datatype":"INTEGER","mode":""}],"meta":{}},{"id":"constructor-GetDataRequest4","name":"GetDataRequest","owner":"OpenEdge.BusinessLogic.GetDataRequest","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pRequests","datatype":"Ccs.BusinessLogic.IGetDataTableRequest","mode":""}],"meta":{}},{"id":"property-CustomParameter","name":"CustomParameter","owner":"OpenEdge.BusinessLogic.GetDataRequest","tagname":"property","datatype":"Progress.Lang.Object","comment":"\u003cp\u003eReturns the custom parameter object\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-NamedQuery","name":"NamedQuery","owner":"OpenEdge.BusinessLogic.GetDataRequest","tagname":"property","datatype":"Ccs.BusinessLogic.INamedQuery","comment":"\u003cp\u003eReturns the named query instance\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-TableRequests","name":"TableRequests","owner":"OpenEdge.BusinessLogic.GetDataRequest","tagname":"property","datatype":"Ccs.BusinessLogic.IGetDataTableRequest","comment":"\u003cp\u003eReturns the Table requests\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-FromJson","name":"FromJson","owner":"OpenEdge.BusinessLogic.GetDataRequest","tagname":"method","comment":"\u003cp\u003eDeserializes this object from JSON.\u003c/p\u003e\n","parameters":[{"name":"pJson","datatype":"Progress.Json.ObjectModel.JsonConstruct","mode":""}],"returns":{"comment":""},"meta":{}},{"id":"method-ToJsonConstruct","name":"ToJsonConstruct","owner":"OpenEdge.BusinessLogic.GetDataRequest","tagname":"method","comment":"\u003cp\u003eSerializes this object to JSON\u003c/p\u003e\n","returns":{"datatype":"Progress.Json.ObjectModel.JsonConstruct","comment":"JsonConstruct a JSON Object representation of this object"},"meta":{}}],"meta":{}});