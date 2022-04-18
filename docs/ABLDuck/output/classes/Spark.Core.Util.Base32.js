Ext.data.JsonP.Spark_Core_Util_Base32({"files":[],"uses":["Progress.Lang.*","OpenEdge.Core.Collections.StringKeyedMap","OpenEdge.Core.Collections.StringStringMap"],"id":"class-Spark.Core.Util.Base32","tagname":"class","name":"Spark.Core.Util.Base32","extends":"","author":"Dustin Grau","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eBase32\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eImplement encode/decode for Base32 standard (RFC 4648)\u003c/p\u003e\n\u003ch3\u003eDescription:\u003c/h3\u003e\n\u003cp\u003ehttps://en.wikipedia.org/wiki/Base32\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eMon Oct 16 10:02:54 EDT 2017\u003c/p\u003e\n","icon":"class","superclasses":["Spark.Core.Util.Base32"],"subclasses":[],"implements":[],"members":[{"id":"constructor-Base321","name":"Base32","owner":"Spark.Core.Util.Base32","tagname":"constructor","comment":"","meta":{"static":true}},{"id":"method-DecodeToBinary","name":"DecodeToBinary","owner":"Spark.Core.Util.Base32","tagname":"method","comment":"","parameters":[{"name":"pcString","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{"static":true}},{"id":"method-ConvertToHex","name":"ConvertToHex","owner":"Spark.Core.Util.Base32","tagname":"method","comment":"\u003cp\u003eDecodeToBinary\u003c/p\u003e\n","parameters":[{"name":"pcString","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{"static":true}},{"id":"method-EncodeData","name":"EncodeData","owner":"Spark.Core.Util.Base32","tagname":"method","comment":"\u003cp\u003eConvertToHex\u003c/p\u003e\n","parameters":[{"name":"pcString","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{"static":true}},{"id":"method-DecodeData","name":"DecodeData","owner":"Spark.Core.Util.Base32","tagname":"method","comment":"\u003cp\u003eEncodeData\u003c/p\u003e\n","parameters":[{"name":"pcString","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{"static":true}}],"meta":{}});