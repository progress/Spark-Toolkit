Ext.data.JsonP.Spark_Core_Security_HOTP({"mixedInto":[],"parentMixins":[],"files":[],"alternateClassNames":[],"mixins":[],"requires":[],"uses":[],"aliases":{},"id":"class-Spark.Core.Security.HOTP","tagname":"class","name":"Spark.Core.Security.HOTP","extends":"","author":"Dustin Grau (dugrau@progress.com)","shortDoc":"","html":"\u003cdiv\u003e\u003cpre class\u003d\"hierarchy\"\u003e\u003ch4\u003eAuthor\u003c/h4\u003e\u003cdiv class\u003d\"dependency\"\u003eDustin Grau (dugrau@progress.com)\u003c/div\u003e\u003c/pre\u003e\u003cdiv class\u003d\"doc-contents\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eGenerate a HOTP code for two-factor authentication\u003c/p\u003e\n\u003ch2\u003eNotes\u003c/h2\u003e\n\u003cp\u003eHMAC-based One-Time-Password (HOTP): https://www.ietf.org/rfc/rfc4226.txt\nShared Secret + Moving Factor (Counter)\nhttps://en.wikipedia.org/wiki/HMAC-based_One-time_Password_Algorithm\u003c/p\u003e\n\u003c/div\u003e\u003cdiv class\u003d\"members\"\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-constructor\"\u003eConstructors\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003cdiv id\u003d\"constructor-HOTP1\" class\u003d\"member first-child not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Spark.Core.Security.HOTP\"\u003eSpark.Core.Security.HOTP\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Spark.Core.Security.HOTP-constructor-HOTP1\" class\u003d\"name expandable\"\u003eHOTP\u003c/a\u003e( CHARACTER,  INTEGER,  INTEGER)\u003cspan class\u003d\"signature\"\u003e\u003cspan class\u003d\"private\"\u003ePRIVATE\u003c/span\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003e\u0026nbsp;\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u0026nbsp;\u003c/br\u003e\u003ch3 class\u003d\"pa\"\u003eParameters\u003c/h3\u003e\u003cul\u003e\u003cli\u003e\u003cspan class\u003d\"pre\"\u003epcClientSecret\u003c/span\u003e : CHARACTER\u003cdiv class\u003d\"sub-desc\"\u003e\u003c/div\u003e\u003c/li\u003e\u003cli\u003e\u003cspan class\u003d\"pre\"\u003epiTokenStep\u003c/span\u003e : INTEGER\u003cdiv class\u003d\"sub-desc\"\u003e\u003c/div\u003e\u003c/li\u003e\u003cli\u003e\u003cspan class\u003d\"pre\"\u003epiTokenLength\u003c/span\u003e : INTEGER\u003cdiv class\u003d\"sub-desc\"\u003e\u003c/div\u003e\u003c/li\u003e\u003c/ul\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv id\u003d\"constructor-HOTP2\" class\u003d\"member  not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Spark.Core.Security.HOTP\"\u003eSpark.Core.Security.HOTP\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Spark.Core.Security.HOTP-constructor-HOTP2\" class\u003d\"name expandable\"\u003eHOTP\u003c/a\u003e( CHARACTER)\u003cspan class\u003d\"signature\"\u003e\u003cspan class\u003d\"private\"\u003ePRIVATE\u003c/span\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003e\u0026nbsp;\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u0026nbsp;\u003c/br\u003e\u003ch3 class\u003d\"pa\"\u003eParameters\u003c/h3\u003e\u003cul\u003e\u003cli\u003e\u003cspan class\u003d\"pre\"\u003epcToken\u003c/span\u003e : CHARACTER\u003cdiv class\u003d\"sub-desc\"\u003e\u003c/div\u003e\u003c/li\u003e\u003c/ul\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-event\"\u003eEvents\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-property\"\u003eProperties\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003cdiv id\u003d\"property-Token\" class\u003d\"member first-child not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Spark.Core.Security.HOTP\"\u003eSpark.Core.Security.HOTP\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Spark.Core.Security.HOTP-property-Token\" class\u003d\"name expandable\"\u003eToken\u003c/a\u003e : CHARACTER\u003cspan class\u003d\"signature\"\u003e\u003cspan class\u003d\"private\"\u003ePRIVATE\u003c/span\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003e\u0026nbsp;\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u0026nbsp;\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv id\u003d\"property-EpochCounter\" class\u003d\"member  not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Spark.Core.Security.HOTP\"\u003eSpark.Core.Security.HOTP\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Spark.Core.Security.HOTP-property-EpochCounter\" class\u003d\"name expandable\"\u003eEpochCounter\u003c/a\u003e : INT64\u003cspan class\u003d\"signature\"\u003e\u003cspan class\u003d\"private\"\u003ePRIVATE\u003c/span\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003e\u0026nbsp;\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u0026nbsp;\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-method\"\u003eMethods\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003cdiv id\u003d\"method-newToken\" class\u003d\"member first-child not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Spark.Core.Security.HOTP\"\u003eSpark.Core.Security.HOTP\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Spark.Core.Security.HOTP-method-newToken\" class\u003d\"name expandable\"\u003enewToken\u003c/a\u003e( CHARACTER,  INTEGER,  INTEGER)\u003cspan class\u003d\"signature\"\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003e\u0026nbsp;\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u0026nbsp;\u003c/br\u003e\u003ch3 class\u003d\"pa\"\u003eParameters\u003c/h3\u003e\u003cul\u003e\u003cli\u003e\u003cspan class\u003d\"pre\"\u003epcClientSecret\u003c/span\u003e : CHARACTER\u003cdiv class\u003d\"sub-desc\"\u003e\u003c/div\u003e\u003c/li\u003e\u003cli\u003e\u003cspan class\u003d\"pre\"\u003epiTokenStep\u003c/span\u003e : INTEGER\u003cdiv class\u003d\"sub-desc\"\u003e\u003c/div\u003e\u003c/li\u003e\u003cli\u003e\u003cspan class\u003d\"pre\"\u003epiTokenLength\u003c/span\u003e : INTEGER\u003cdiv class\u003d\"sub-desc\"\u003e\u003c/div\u003e\u003c/li\u003e\u003c/ul\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e","classIcon":"class","members":[{"id":"constructor-HOTP1","name":"HOTP","owner":"Spark.Core.Security.HOTP","tagname":"constructor","signature":"HOTP(INPUT:character,INPUT:integer,INPUT:integer)","returnComment":"","meta":{"private":true}},{"id":"constructor-HOTP2","name":"HOTP","owner":"Spark.Core.Security.HOTP","tagname":"constructor","signature":"HOTP(INPUT:character)","returnComment":"","meta":{"private":true}},{"id":"method-newToken","name":"newToken","owner":"Spark.Core.Security.HOTP","tagname":"method","signature":"newToken(INPUT:character,INPUT:integer,INPUT:integer)","returnComment":"","meta":{}},{"id":"property-Token","name":"Token","owner":"Spark.Core.Security.HOTP","tagname":"property","datatype":"CHARACTER","meta":{"private":true}},{"id":"property-EpochCounter","name":"EpochCounter","owner":"Spark.Core.Security.HOTP","tagname":"property","datatype":"INT64","meta":{"private":true}}],"superclasses":[],"subclasses":[],"meta":{}});