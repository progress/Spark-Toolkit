Ext.data.JsonP.OpenEdge_BusinessLogic_NamedQuery({"files":[],"uses":["Ccs.BusinessLogic.INamedQuery","Ccs.BusinessLogic.INamedQueryParameter","OpenEdge.BusinessLogic.IO.JsonPropertyNameEnum","OpenEdge.BusinessLogic.NamedQueryParameter","OpenEdge.Core.Assert","OpenEdge.Core.Json.IJsonSerializer","OpenEdge.Core.Json.JsonConverter","OpenEdge.Core.Json.JsonPropertyHelper","OpenEdge.Core.Json.JsonSerializer","Progress.Json.ObjectModel.JsonArray","Progress.Json.ObjectModel.JsonConstruct","Progress.Json.ObjectModel.JsonDataType","Progress.Json.ObjectModel.JsonObject"],"id":"class-OpenEdge.BusinessLogic.NamedQuery","tagname":"class","name":"OpenEdge.BusinessLogic.NamedQuery","extends":"","author":"pjudge","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eNamedQuery\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003e2018-06-15\u003c/p\u003e\n","icon":"class","superclasses":["OpenEdge.BusinessLogic.NamedQuery"],"subclasses":[],"implements":["INamedQuery","OpenEdge.Core.Json.IJsonSerializer"],"members":[{"id":"constructor-NamedQuery1","name":"NamedQuery","owner":"OpenEdge.BusinessLogic.NamedQuery","tagname":"constructor","comment":"\u003cp\u003eDefault constructor. Needed for IJsonSerializer\u003c/p\u003e\n","meta":{}},{"id":"constructor-NamedQuery2","name":"NamedQuery","owner":"OpenEdge.BusinessLogic.NamedQuery","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pQryName","datatype":"CHARACTER","mode":""}],"meta":{}},{"id":"constructor-NamedQuery3","name":"NamedQuery","owner":"OpenEdge.BusinessLogic.NamedQuery","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pQryName","datatype":"CHARACTER","mode":""},{"name":"pNumParams","datatype":"INTEGER","mode":""}],"meta":{}},{"id":"constructor-NamedQuery4","name":"NamedQuery","owner":"OpenEdge.BusinessLogic.NamedQuery","tagname":"constructor","comment":"\u003cp\u003eConstructor\u003c/p\u003e\n","parameters":[{"name":"pQryName","datatype":"CHARACTER","mode":""},{"name":"pParams","datatype":"Ccs.BusinessLogic.INamedQueryParameter","mode":""}],"meta":{}},{"id":"property-Name","name":"Name","owner":"OpenEdge.BusinessLogic.NamedQuery","tagname":"property","datatype":"CHARACTER","comment":"\u003cp\u003eReturns the name of the named query\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"property-Parameters","name":"Parameters","owner":"OpenEdge.BusinessLogic.NamedQuery","tagname":"property","datatype":"Ccs.BusinessLogic.INamedQueryParameter","comment":"\u003cp\u003eReturns the array of (optional) parameters of the named query. Each Named Query Parameter consists of an\nidentifier (name) and a value (primitive holder) or values (primitive array holder)\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET - PUBLIC SET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-ToJsonConstruct","name":"ToJsonConstruct","owner":"OpenEdge.BusinessLogic.NamedQuery","tagname":"method","comment":"\u003cp\u003eSerializes this object\u003c/p\u003e\n","returns":{"datatype":"Progress.Json.ObjectModel.JsonConstruct","comment":"JsonConstruct The serialized object. Always JsonObject."},"meta":{}},{"id":"method-FromJson","name":"FromJson","owner":"OpenEdge.BusinessLogic.NamedQuery","tagname":"method","comment":"\u003cp\u003eDeserializes this object\u003c/p\u003e\n","parameters":[{"name":"pJson","datatype":"Progress.Json.ObjectModel.JsonConstruct","mode":""}],"returns":{"comment":""},"meta":{}}],"meta":{}});