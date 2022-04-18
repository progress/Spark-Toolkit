Ext.data.JsonP.OpenEdge_BusinessLogic_UpdateDataRequest({"files":[],"uses":["Ccs.BusinessLogic.CommitScopeEnum","Ccs.BusinessLogic.IUpdateDataRequest","OpenEdge.BusinessLogic.IO.JsonPropertyNameEnum","OpenEdge.Core.Json.IJsonSerializer","OpenEdge.Core.Json.JsonPropertyHelper","OpenEdge.Core.Json.JsonSerializer","Progress.Json.ObjectModel.JsonArray","Progress.Json.ObjectModel.JsonConstruct","Progress.Json.ObjectModel.JsonDataType","Progress.Json.ObjectModel.JsonObject"],"id":"class-OpenEdge.BusinessLogic.UpdateDataRequest","tagname":"class","name":"OpenEdge.BusinessLogic.UpdateDataRequest","extends":"","author":"pjudge","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eUpdateDataRequest\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003e2018-06-20\u003c/p\u003e\n","icon":"class","superclasses":["OpenEdge.BusinessLogic.UpdateDataRequest"],"subclasses":[],"implements":["IUpdateDataRequest","OpenEdge.Core.Json.IJsonSerializer"],"members":[{"id":"property-CommitScope","name":"CommitScope","owner":"OpenEdge.BusinessLogic.UpdateDataRequest","tagname":"property","datatype":"Ccs.BusinessLogic.CommitScopeEnum","comment":"\u003cp\u003eReturns the CommitScope to be used by the updateData method. The value is considered as a recommendation as\nthe Business Entity may ignore this setting and use a different commit scope based on the business logic\nrequirements\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-CustomRequest","name":"CustomRequest","owner":"OpenEdge.BusinessLogic.UpdateDataRequest","tagname":"property","datatype":"Progress.Lang.Object","comment":"\u003cp\u003eReturns a custom request object\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-ToJsonConstruct","name":"ToJsonConstruct","owner":"OpenEdge.BusinessLogic.UpdateDataRequest","tagname":"method","comment":"\u003cp\u003eSerializes this object to JSON\u003c/p\u003e\n","returns":{"datatype":"Progress.Json.ObjectModel.JsonConstruct","comment":"JsonConstruct a JSON Object representation of this object"},"meta":{}},{"id":"method-FromJson","name":"FromJson","owner":"OpenEdge.BusinessLogic.UpdateDataRequest","tagname":"method","comment":"\u003cp\u003eDeserializes this object from JSON.\u003c/p\u003e\n","parameters":[{"name":"pJson","datatype":"Progress.Json.ObjectModel.JsonConstruct","mode":""}],"returns":{"comment":""},"meta":{}}],"meta":{}});