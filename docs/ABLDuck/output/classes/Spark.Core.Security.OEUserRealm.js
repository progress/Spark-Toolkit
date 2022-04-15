Ext.data.JsonP.Spark_Core_Security_OEUserRealm({"files":[],"uses":["Progress.Lang.*","Progress.Json.ObjectModel.*","Spark.Core.Constant.OERealmDefs","Spark.Core.Message.ConfigMessage"],"id":"class-Spark.Core.Security.OEUserRealm","tagname":"class","name":"Spark.Core.Security.OEUserRealm","extends":"","author":"Dustin Grau (dugrau@progress.com)","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eSpark.Core.Security.OEUserRealm\u003c/p\u003e\n\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eImplement methods for OERealm service.\u003c/p\u003e\n\u003ch3\u003eDescription:\u003c/h3\u003e\n\u003cp\u003eApplies back-end logic to OEReam authorization requests.\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eWed Dec 10 09:13:43 EST 2014\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cpre\u003e\n In the appSecurity-xxxx-oerealm.xml security model, this class\n is the target of the realmClass in the OERealmUserDetails bean.\n The security model is selected by filename in web.xml under the\n context-param section for \"contextConfigLocation\".\n The default operation/response of all methods contained in this class\n will return a passing value for all operations of the OERealm process!\n To avoid opening up your application to attack, you must provide an\n override to the getPassword() and checkPasswordHash() methods!\n \u003c/pre\u003e\n","icon":"class","superclasses":["Spark.Core.Security.OEUserRealm"],"subclasses":[],"implements":["Progress.Security.Realm.IHybridRealm","Spark.Core.Security.IAuthHandler"],"members":[{"id":"constructor-OEUserRealm1","name":"OEUserRealm","owner":"Spark.Core.Security.OEUserRealm","tagname":"constructor","comment":"","meta":{}},{"id":"method-loadConfig","name":"loadConfig","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"","returns":{"comment":""},"meta":{"protected":true}},{"id":"method-validateRequest","name":"validateRequest","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"","returns":{"datatype":"LOGICAL","comment":""},"meta":{"protected":true}},{"id":"method-validateRequest-1","name":"validateRequest","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"","parameters":[{"name":"pcSourceName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{"protected":true}},{"id":"method-checkPasswordHash","name":"checkPasswordHash","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eCompare the user-supplied password to a hashed password.\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cp\u003eImplement as a protected method in your own class.\u003c/p\u003e\n","parameters":[{"name":"pcPassword","datatype":"CHARACTER","mode":"INPUT","comment":"Externally supplied password by user"},{"name":"pcHashPass","datatype":"CHARACTER","mode":"INPUT","comment":"Internally stored password for user"}],"returns":{"datatype":"LOGICAL","comment":"Logical pass/fail for operation"},"meta":{"protected":true}},{"id":"method-checkPasswordHash-1","name":"checkPasswordHash","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eCompare the user-supplied password to a hashed password, with UserID.\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cp\u003eImplement as a protected method in your own class.\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT","comment":"UserID value, as integer"},{"name":"pcPassword","datatype":"CHARACTER","mode":"INPUT","comment":"Externally supplied password by user"},{"name":"pcHashPass","datatype":"CHARACTER","mode":"INPUT","comment":"Internally stored password for user"}],"returns":{"datatype":"LOGICAL","comment":"Logical pass/fail for operation"},"meta":{"protected":true}},{"id":"method-getPassword","name":"getPassword","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eObtain the password for a given UserID.\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cp\u003eImplement as a protected method in your own class.\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT","comment":"UserID value, as integer"}],"returns":{"datatype":"CHARACTER","comment":"Internally stored password value"},"meta":{"protected":true}},{"id":"method-postAuthenticate","name":"postAuthenticate","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003ePerform an action after authentication (validatePassword).\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cp\u003eImplement as a protected method in your own class, if needed.\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT","comment":"UserID value, as integer"},{"name":"lRetVal","datatype":"LOGICAL","mode":"INPUT","comment":"Result of authentication action, as logical"}],"returns":{"comment":"Void"},"meta":{"protected":true}},{"id":"method-getUserID","name":"getUserID","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eObtain the UserID for a given username (and domain, optional).\u003c/p\u003e\n","parameters":[{"name":"pcUsername","datatype":"CHARACTER","mode":"INPUT","comment":"Username portion of credentials"},{"name":"pcDomainName","datatype":"CHARACTER","mode":"INPUT","comment":"Domain portion of credentials"}],"returns":{"datatype":"INTEGER","comment":"Unique identifier for user, as integer"},"meta":{}},{"id":"method-isActive","name":"isActive","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eReturn active status for a given UserID.\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT","comment":"UserID value, as integer"}],"returns":{"datatype":"LOGICAL","comment":"Logical pass/fail for operation"},"meta":{}},{"id":"method-isExpired","name":"isExpired","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eReturn expiration status for a given UserID.\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT","comment":"UserID value, as integer"}],"returns":{"datatype":"LOGICAL","comment":"Logical pass/fail for operation"},"meta":{}},{"id":"method-isLocked","name":"isLocked","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eReturn locked status for a given UserID.\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT","comment":"UserID value, as integer"}],"returns":{"datatype":"LOGICAL","comment":"Logical pass/fail for operation"},"meta":{}},{"id":"method-getUserRoles","name":"getUserRoles","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003ch3\u003ePurpose:\u003c/h3\u003e\n\u003cp\u003eReturn available roles for a given UserID.\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT","comment":"UserID value, as integer"}],"returns":{"datatype":"CHARACTER","comment":"Comma-separated list of roles (without ROLE_ prefix)"},"meta":{}},{"id":"method-GetAttribute","name":"GetAttribute","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003cp\u003eThese methods come from the original IHybridRealm class within OpenEdge,\nand are broken down to call more atomic methods to obtain data. The goal\nis to not have to know how these are implemented directly, but to only\nrequire the individual components be overridden when necessary.\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT"},{"name":"pcAttrName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-GetAttributeNames","name":"GetAttributeNames","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003cp\u003eGetAttribute\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT"}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-GetUsernames","name":"GetUsernames","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003cp\u003eGetAttributeNames\u003c/p\u003e\n","returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-GetUsernamesByQuery","name":"GetUsernamesByQuery","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003cp\u003eGetUsernames\u003c/p\u003e\n","parameters":[{"name":"pcQueryString","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-GetUsernamesByQuery-1","name":"GetUsernamesByQuery","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003cp\u003eGetUsernamesByQuery\u003c/p\u003e\n","parameters":[{"name":"pcAttrName","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcAttrValue","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"CHARACTER","comment":""},"meta":{}},{"id":"method-RemoveAttribute","name":"RemoveAttribute","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003cp\u003eGetUsernamesByQuery\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT"},{"name":"pcAttrName","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-SetAttribute","name":"SetAttribute","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003cp\u003eRemoveAttribute\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT"},{"name":"pcAttrName","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcAttrValue","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-ValidatePassword","name":"ValidatePassword","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003cp\u003eSetAttribute\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT"},{"name":"pcPassword","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-ValidatePassword-1","name":"ValidatePassword","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003cp\u003eValidatePassword\u003c/p\u003e\n","parameters":[{"name":"piUserID","datatype":"INTEGER","mode":"INPUT"},{"name":"pcDigest","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcNonce","datatype":"CHARACTER","mode":"INPUT"},{"name":"pcTimestamp","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"LOGICAL","comment":""},"meta":{}},{"id":"method-ValidateUser","name":"ValidateUser","owner":"Spark.Core.Security.OEUserRealm","tagname":"method","comment":"\u003cp\u003eValidatePassword\u003c/p\u003e\n","parameters":[{"name":"pcUsername","datatype":"CHARACTER","mode":"INPUT"}],"returns":{"datatype":"INTEGER","comment":""},"meta":{}}],"meta":{"abstract":true}});