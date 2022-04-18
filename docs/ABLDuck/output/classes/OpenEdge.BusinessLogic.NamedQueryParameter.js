Ext.data.JsonP.OpenEdge_BusinessLogic_NamedQueryParameter({"files":[],"uses":["Ccs.BusinessLogic.INamedQueryParameter","Ccs.Common.Support.IPrimitiveArrayHolder","Ccs.Common.Support.IPrimitiveHolder","OpenEdge.BusinessLogic.IO.JsonPropertyNameEnum","OpenEdge.Core.Assert","OpenEdge.Core.Json.IJsonSerializer","OpenEdge.Core.Json.JsonConverter","OpenEdge.Core.Json.JsonPropertyHelper","Progress.Json.ObjectModel.JsonConstruct","Progress.Json.ObjectModel.JsonDataType","Progress.Json.ObjectModel.JsonObject"],"id":"class-OpenEdge.BusinessLogic.NamedQueryParameter","tagname":"class","name":"OpenEdge.BusinessLogic.NamedQueryParameter","extends":"","author":"pjudge","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eNamedQueryParameter\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003e2018-06-15\u003c/p\u003e\n","icon":"class","superclasses":["OpenEdge.BusinessLogic.NamedQueryParameter"],"subclasses":[],"implements":["INamedQueryParameter","OpenEdge.Core.Json.IJsonSerializer"],"members":[{"id":"constructor-NamedQueryParameter1","name":"NamedQueryParameter","owner":"OpenEdge.BusinessLogic.NamedQueryParameter","tagname":"constructor","comment":"\u003cp\u003eDefault Constructor\u003c/p\u003e\n","meta":{}},{"id":"constructor-NamedQueryParameter2","name":"NamedQueryParameter","owner":"OpenEdge.BusinessLogic.NamedQueryParameter","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pName","datatype":"CHARACTER","mode":""}],"meta":{}},{"id":"constructor-NamedQueryParameter3","name":"NamedQueryParameter","owner":"OpenEdge.BusinessLogic.NamedQueryParameter","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pName","datatype":"CHARACTER","mode":""},{"name":"pValue","datatype":"Ccs.Common.Support.IPrimitiveHolder","mode":""}],"meta":{}},{"id":"constructor-NamedQueryParameter4","name":"NamedQueryParameter","owner":"OpenEdge.BusinessLogic.NamedQueryParameter","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pName","datatype":"CHARACTER","mode":""},{"name":"pValues","datatype":"Ccs.Common.Support.IPrimitiveArrayHolder","mode":""}],"meta":{}},{"id":"property-Name","name":"Name","owner":"OpenEdge.BusinessLogic.NamedQueryParameter","tagname":"property","datatype":"CHARACTER","comment":"\u003cp\u003eReturns the name of the named query parameter\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-Value","name":"Value","owner":"OpenEdge.BusinessLogic.NamedQueryParameter","tagname":"property","datatype":"Ccs.Common.Support.IPrimitiveHolder","comment":"\u003cp\u003eReturns a single value for this named query parameter\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-Values","name":"Values","owner":"OpenEdge.BusinessLogic.NamedQueryParameter","tagname":"property","datatype":"Ccs.Common.Support.IPrimitiveArrayHolder","comment":"\u003cp\u003eReturns a list of values for this named query parameter\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-ToJsonConstruct","name":"ToJsonConstruct","owner":"OpenEdge.BusinessLogic.NamedQueryParameter","tagname":"method","comment":"\u003cp\u003eSerializes this object\u003c/p\u003e\n","returns":{"datatype":"Progress.Json.ObjectModel.JsonConstruct","comment":"JsonConstruct The serialized object. Always JsonObject."},"meta":{}},{"id":"method-FromJson","name":"FromJson","owner":"OpenEdge.BusinessLogic.NamedQueryParameter","tagname":"method","comment":"\u003cp\u003eDeserializes this object\u003c/p\u003e\n","parameters":[{"name":"pJson","datatype":"Progress.Json.ObjectModel.JsonConstruct","mode":""}],"returns":{"comment":""},"meta":{}}],"meta":{}});