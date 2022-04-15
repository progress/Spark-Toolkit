Ext.data.JsonP.OpenEdge_Core_Assertion_AssertObject({"files":[],"uses":["OpenEdge.Core.AssertionFailedError","Progress.Lang.Object","OpenEdge.Core.Collections.ICollection","OpenEdge.Core.Assert","OpenEdge.Core.Collections.IMap","OpenEdge.Core.DataTypeEnum","OpenEdge.Core.DataTypeHelper","OpenEdge.Core.Assertion.AssertObject"],"id":"class-OpenEdge.Core.Assertion.AssertObject","tagname":"class","name":"OpenEdge.Core.Assertion.AssertObject","extends":"","author":"psajja","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eAssertObject\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eAssertions specific to Object(s)\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eTue Dec 16 12:28:50 IST 2014\u003c/p\u003e\n","icon":"class","superclasses":["OpenEdge.Core.Assertion.AssertObject"],"subclasses":[],"implements":[],"members":[{"id":"method-Equals","name":"Equals","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param a expected value Object\n   @param b the value of Object being expected\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"a","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"b","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotEqual","name":"NotEqual","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param a expected value Object\n   @param b the value of Object being expected\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"a","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"b","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotNull","name":"NotNull","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object to check\n   @param pcName the identifying name for the AssertionFailedError\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotNull-1","name":"NotNull","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsNull","name":"IsNull","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object to check\n   @param pcName the identifying name for the AssertionFailedError\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsNull-1","name":"IsNull","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotNull-2","name":"NotNull","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object array to check\n   @param pcName the identifying name for the AssertionFailedError\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotNull-3","name":"NotNull","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object array to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsNull-2","name":"IsNull","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object array to check\n   @param pcName the identifying name for the AssertionFailedError\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsNull-3","name":"IsNull","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object array to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotNullOrEmpty","name":"NotNullOrEmpty","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the ICollection object to check\n   @param pcName the identifying name for the AssertionFailedError\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"OpenEdge.Core.Collections.ICollection","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotNullOrEmpty-1","name":"NotNullOrEmpty","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the ICollection object to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"OpenEdge.Core.Collections.ICollection","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotNullOrEmpty-2","name":"NotNullOrEmpty","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the IMap object to check\n   @param pcName the identifying name for the AssertionFailedError\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"OpenEdge.Core.Collections.IMap","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotNullOrEmpty-3","name":"NotNullOrEmpty","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the IMap object to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"OpenEdge.Core.Collections.IMap","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotNullOrEmpty-4","name":"NotNullOrEmpty","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object array to check\n   @param pcName the identifying name for the AssertionFailedError\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotNullOrEmpty-5","name":"NotNullOrEmpty","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object array to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsInterface","name":"IsInterface","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the type to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Class","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotInterface","name":"NotInterface","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the type to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Class","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsAbstract","name":"IsAbstract","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the type to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Class","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotAbstract","name":"NotAbstract","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the type to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Class","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsFinal","name":"IsFinal","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the type to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Class","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotFinal","name":"NotFinal","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the type to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Class","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsType","name":"IsType","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument The Object being checked.\n   @param poType The type the being checked.\n   @throws AssertionFailedError Error thrown if the object array is not valid any of the array \n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"poType","datatype":"Progress.Lang.Class","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsType-1","name":"IsType","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument The Object being checked.\n   @param poType The type the being checked.\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"poType","datatype":"Progress.Lang.Class","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotType","name":"NotType","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument The Object being checked.\n   @param poType The type the being checked.\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"poType","datatype":"Progress.Lang.Class","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsType-2","name":"IsType","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param phArgument The handle being checked.\n   @param poCheckType The type the handle/variable being checked should be.\n   @param pcName The name of the variable/handle.   \n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"phArgument","datatype":"HANDLE","mode":"INPUT"},{"name":"poCheckType","datatype":"OpenEdge.Core.DataTypeEnum","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsType-3","name":"IsType","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param phArgument The handle being checked.\n   @param poCheckType The type the handle/variable being checked should be.\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"phArgument","datatype":"HANDLE","mode":"INPUT"},{"name":"poCheckType","datatype":"OpenEdge.Core.DataTypeEnum","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotType-1","name":"NotType","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param phArgument The handle being checked.\n   @param poCheckType The type the handle/variable being checked should be.\n   @param pcName the identifying name for the AssertionFailedError.\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"phArgument","datatype":"HANDLE","mode":"INPUT"},{"name":"poCheckType","datatype":"OpenEdge.Core.DataTypeEnum","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotType-2","name":"NotType","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param phArgument The handle being checked.\n   @param poCheckType The type the handle/variable being checked should be.\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"phArgument","datatype":"HANDLE","mode":"INPUT"},{"name":"poCheckType","datatype":"OpenEdge.Core.DataTypeEnum","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsIndeterminateArray","name":"IsIndeterminateArray","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object array to check\n   @param pcName the identifying name for the AssertionFailedError\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsIndeterminateArray-1","name":"IsIndeterminateArray","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object array to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-HasDeterminateExtent","name":"HasDeterminateExtent","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object array to check\n   @param pcName the identifying name for the AssertionFailedError\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"},{"name":"pcName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-HasDeterminateExtent-1","name":"HasDeterminateExtent","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cpre\u003e\u003ccode\u003e   @param poArgument the Object array to check\n\u003c/code\u003e\u003c/pre\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-IsSerializable","name":"IsSerializable","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cp\u003eAsserts that the given object can be serialized.\u003c/p\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}},{"id":"method-NotSerializable","name":"NotSerializable","owner":"OpenEdge.Core.Assertion.AssertObject","tagname":"method","comment":"\u003cp\u003eAsserts that the given object cannot be serialized.\u003c/p\u003e\n","parameters":[{"name":"poArgument","datatype":"Progress.Lang.Object","mode":"INPUT"}],"returns":{"comment":""},"meta":{"static":true}}],"meta":{}});