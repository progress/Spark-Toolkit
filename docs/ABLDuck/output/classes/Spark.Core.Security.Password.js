Ext.data.JsonP.Spark_Core_Security_Password({"files":[],"uses":["Progress.Lang.*"],"id":"class-Spark.Core.Security.Password","tagname":"class","name":"Spark.Core.Security.Password","extends":"","author":"Dustin Grau (dugrau@progress.com)","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003ePassword\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eProvide common methods for comparing/encoding passwords\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eWed Aug 16 16:19:44 EDT 2017\u003c/p\u003e\n","icon":"class","superclasses":["Spark.Core.Security.Password"],"subclasses":[],"implements":[],"members":[{"id":"method-createCode","name":"createCode","owner":"Spark.Core.Security.Password","tagname":"method","comment":"","parameters":[{"name":"piLength","datatype":"INTEGER","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{"static":true}},{"id":"method-checkPassword","name":"checkPassword","owner":"Spark.Core.Security.Password","tagname":"method","comment":"\u003cp\u003ecreateCode\u003c/p\u003e\n","parameters":[{"name":"pcRawPassword","datatype":"CHARACTER","mode":""},{"name":"pcOrigPassword","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{"static":true}},{"id":"method-encodePassword","name":"encodePassword","owner":"Spark.Core.Security.Password","tagname":"method","comment":"\u003cp\u003echeckPassword\u003c/p\u003e\n","parameters":[{"name":"pcPassword","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{"static":true}}],"meta":{"final":true}});