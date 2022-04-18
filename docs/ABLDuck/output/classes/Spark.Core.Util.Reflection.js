Ext.data.JsonP.Spark_Core_Util_Reflection({"files":[],"uses":["Progress.Lang.*","Progress.Json.ObjectModel.*"],"id":"class-Spark.Core.Util.Reflection","tagname":"class","name":"Spark.Core.Util.Reflection","extends":"","author":"Dustin Grau (dugrau@progress.com)","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eReflection\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eProduct a common JSON format for class reflection in ABL\u003c/p\u003e\n\u003ch3\u003eSyntax:\u003c/h3\u003e\n\u003cp\u003eReflection.getClassSignature(\u0026lt;class.package\u0026gt;[, true|false])\u003c/p\u003e\n\u003ch3\u003eDescription:\u003c/h3\u003e\n\u003cp\u003eGenerates a JSON object with a single property containing\nclass attributes, properties, variables, and methods. Can\noptionally omit the outer object and class name property.\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eTue Jun 16 15:54:44 EDT 2015\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cp\u003eReflection will only be performed on OE 11.6 and later.\u003c/p\u003e\n","icon":"class","superclasses":["Spark.Core.Util.Reflection"],"subclasses":[],"implements":[],"members":[{"id":"method-getConstructors","name":"getConstructors","owner":"Spark.Core.Util.Reflection","tagname":"method","comment":"","parameters":[{"name":"poClassRef","datatype":"Progress.Lang.Class","mode":""}],"returns":{"datatype":"JsonObject","comment":""},"meta":{"static":true}},{"id":"method-getProperties","name":"getProperties","owner":"Spark.Core.Util.Reflection","tagname":"method","comment":"\u003cp\u003egetConstructors\u003c/p\u003e\n","parameters":[{"name":"poClassRef","datatype":"Progress.Lang.Class","mode":""}],"returns":{"datatype":"JsonObject","comment":""},"meta":{"static":true}},{"id":"method-getVariables","name":"getVariables","owner":"Spark.Core.Util.Reflection","tagname":"method","comment":"\u003cp\u003egetProperties\u003c/p\u003e\n","parameters":[{"name":"poClassRef","datatype":"Progress.Lang.Class","mode":""}],"returns":{"datatype":"JsonObject","comment":""},"meta":{"static":true}},{"id":"method-getMethods","name":"getMethods","owner":"Spark.Core.Util.Reflection","tagname":"method","comment":"\u003cp\u003egetVariables\u003c/p\u003e\n","parameters":[{"name":"poClassRef","datatype":"Progress.Lang.Class","mode":""}],"returns":{"datatype":"JsonObject","comment":""},"meta":{"static":true}},{"id":"method-getClassSignature","name":"getClassSignature","owner":"Spark.Core.Util.Reflection","tagname":"method","comment":"\u003cp\u003egetMethods\u003c/p\u003e\n","parameters":[{"name":"pcClassName","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"JsonObject","comment":""},"meta":{"static":true}},{"id":"method-getClassSignature-1","name":"getClassSignature","owner":"Spark.Core.Util.Reflection","tagname":"method","comment":"\u003cp\u003egetClassSignature\u003c/p\u003e\n","parameters":[{"name":"pcClassName","datatype":"CHARACTER","mode":""},{"name":"plOmitName","datatype":"LOGICAL","mode":""}],"returns":{"datatype":"JsonObject","comment":""},"meta":{"static":true}}],"meta":{"final":true}});