Ext.data.JsonP.Ccs_BusinessLogic_IGetDataTableRequest({"mixedInto":[],"parentMixins":[],"files":[],"alternateClassNames":[],"mixins":[],"requires":[],"uses":[],"aliases":{},"id":"class-Ccs.BusinessLogic.IGetDataTableRequest","tagname":"class","name":"Ccs.BusinessLogic.IGetDataTableRequest","extends":"","author":"Mike Fechner / Consultingwerk Ltd.","shortDoc":"","html":"\u003cdiv\u003e\u003cpre class\u003d\"hierarchy\"\u003e\u003ch4\u003eImplementers\u003c/h4\u003e\u003cdiv class\u003d\"dependency\"\u003e\u003ca href\u003d\"#!/api/OpenEdge.BusinessLogic.GetDataTableRequest\" rel\u003d\"OpenEdge.BusinessLogic.GetDataTableRequest\" class\u003d\"docClass\"\u003eOpenEdge.BusinessLogic.GetDataTableRequest\u003c/a\u003e\u003c/div\u003e\u003ch4\u003eAuthor\u003c/h4\u003e\u003cdiv class\u003d\"dependency\"\u003eMike Fechner / Consultingwerk Ltd.\u003c/div\u003e\u003c/pre\u003e\u003cdiv class\u003d\"doc-contents\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eContains table specific request arguments of the\nIGetDataRequest interface, part of the request object send\nto the getData method of the IBusinessEntity\u003c/p\u003e\n\u003c/div\u003e\u003cdiv class\u003d\"members\"\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-constructor\"\u003eConstructors\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-event\"\u003eEvents\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-property\"\u003eProperties\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003cdiv id\u003d\"property-PagingContext\" class\u003d\"member first-child not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Ccs.BusinessLogic.IGetDataTableRequest\"\u003eCcs.BusinessLogic.IGetDataTableRequest\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Ccs.BusinessLogic.IGetDataTableRequest-property-PagingContext\" class\u003d\"name expandable\"\u003ePagingContext\u003c/a\u003e : CHARACTER\u003cspan class\u003d\"signature\"\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003ePurpose\nReturns the paging context\nNotes\nUsed for Paging. This value typically consists of record id ...\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eReturns the paging context\u003c/p\u003e\n\u003ch2\u003eNotes\u003c/h2\u003e\n\u003cp\u003eUsed for Paging. This value typically consists of record identifiers\n(e.g. DATA-SOURCE ROWID retrieved by the RESTART-ROWID function of\nthe previous call into IBusinessEntity:GetData or other data required\nby the Business Entity to build the next set of data).\nThe value passed in is the value of the NextPagingContext property\nof the IGetDataTableResponse for the table\u003c/p\u003e\n\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv id\u003d\"property-NumRecords\" class\u003d\"member  not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Ccs.BusinessLogic.IGetDataTableRequest\"\u003eCcs.BusinessLogic.IGetDataTableRequest\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Ccs.BusinessLogic.IGetDataTableRequest-property-NumRecords\" class\u003d\"name expandable\"\u003eNumRecords\u003c/a\u003e : INT64\u003cspan class\u003d\"signature\"\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003ePurpose\nReturns the number of records requested by the caller of the\nBusiness Entity getData method\n ...\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eReturns the number of records requested by the caller of the\nBusiness Entity getData method\u003c/p\u003e\n\u003ch2\u003eNotes\u003c/h2\u003e\n\u003cp\u003eUsed for Paging. When the value is 0, the business entity is expected\nto return all (remaining) records. When the value is ? the business\nentity is expected to return a reasonable default number of records\nto the caller. Negative values indicate paging in backwards direction\nis requested.\u003c/p\u003e\n\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv id\u003d\"property-QueryDefinition\" class\u003d\"member  not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Ccs.BusinessLogic.IGetDataTableRequest\"\u003eCcs.BusinessLogic.IGetDataTableRequest\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Ccs.BusinessLogic.IGetDataTableRequest-property-QueryDefinition\" class\u003d\"name expandable\"\u003eQueryDefinition\u003c/a\u003e : \u003ca href\u003d\"#!/api/Ccs.BusinessLogic.IQueryDefinition\" rel\u003d\"Ccs.BusinessLogic.IQueryDefinition\" class\u003d\"docClass\"\u003eIQueryDefinition\u003c/a\u003e\u003cspan class\u003d\"signature\"\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003ePurpose\nReturns the abstract query defintion for this request\nNotes\nTypically used as an alternative ...\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eReturns the abstract query defintion for this request\u003c/p\u003e\n\u003ch2\u003eNotes\u003c/h2\u003e\n\u003cp\u003eTypically used as an alternative to the QueryString\u003c/p\u003e\n\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv id\u003d\"property-QueryString\" class\u003d\"member  not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Ccs.BusinessLogic.IGetDataTableRequest\"\u003eCcs.BusinessLogic.IGetDataTableRequest\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Ccs.BusinessLogic.IGetDataTableRequest-property-QueryString\" class\u003d\"name expandable\"\u003eQueryString\u003c/a\u003e : CHARACTER\u003cspan class\u003d\"signature\"\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003ePurpose\nReturns the Query String for this table\nNotes\nQuery Strings must be expressed using the fiel ...\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eReturns the Query String for this table\u003c/p\u003e\n\u003ch2\u003eNotes\u003c/h2\u003e\n\u003cp\u003eQuery Strings must be expressed using the fields of the temp-table.\nIt\u0027s the task of the Business Entity or Data Access class to translate\nthe Query String into the form understood by the actual DBMS in case\nfield names require mapping etc.\nQuery Strings must be provided in the following format\nCustNum \u003d 42\nCustNum \u003d 42 AND OrderStatus \u003d “Ordered”\u003c/p\u003e\n\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv id\u003d\"property-Skip\" class\u003d\"member  not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Ccs.BusinessLogic.IGetDataTableRequest\"\u003eCcs.BusinessLogic.IGetDataTableRequest\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Ccs.BusinessLogic.IGetDataTableRequest-property-Skip\" class\u003d\"name expandable\"\u003eSkip\u003c/a\u003e : INT64\u003cspan class\u003d\"signature\"\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003ePurpose\nReturns the number of records to skip\nNotes\nUsed for Paging. Typically the value of (page# - ...\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eReturns the number of records to skip\u003c/p\u003e\n\u003ch2\u003eNotes\u003c/h2\u003e\n\u003cp\u003eUsed for Paging. Typically the value of (page# - 1) * NumRecords is\npassed in when requesting a certain page of result records\u003c/p\u003e\n\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv id\u003d\"property-TableName\" class\u003d\"member  not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Ccs.BusinessLogic.IGetDataTableRequest\"\u003eCcs.BusinessLogic.IGetDataTableRequest\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Ccs.BusinessLogic.IGetDataTableRequest-property-TableName\" class\u003d\"name expandable\"\u003eTableName\u003c/a\u003e : CHARACTER\u003cspan class\u003d\"signature\"\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003ePurpose\nReturns the name of the ProDataset Table\nNotes\nIdentifies the table this IGetDataTableReques ...\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eReturns the name of the ProDataset Table\u003c/p\u003e\n\u003ch2\u003eNotes\u003c/h2\u003e\n\u003cp\u003eIdentifies the table this IGetDataTableRequest belongs to\u003c/p\u003e\n\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-method\"\u003eMethods\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e","classIcon":"interface","members":[{"id":"property-PagingContext","name":"PagingContext","owner":"Ccs.BusinessLogic.IGetDataTableRequest","tagname":"property","datatype":"CHARACTER","meta":{}},{"id":"property-NumRecords","name":"NumRecords","owner":"Ccs.BusinessLogic.IGetDataTableRequest","tagname":"property","datatype":"INT64","meta":{}},{"id":"property-QueryDefinition","name":"QueryDefinition","owner":"Ccs.BusinessLogic.IGetDataTableRequest","tagname":"property","datatype":"IQueryDefinition","meta":{}},{"id":"property-QueryString","name":"QueryString","owner":"Ccs.BusinessLogic.IGetDataTableRequest","tagname":"property","datatype":"CHARACTER","meta":{}},{"id":"property-Skip","name":"Skip","owner":"Ccs.BusinessLogic.IGetDataTableRequest","tagname":"property","datatype":"INT64","meta":{}},{"id":"property-TableName","name":"TableName","owner":"Ccs.BusinessLogic.IGetDataTableRequest","tagname":"property","datatype":"CHARACTER","meta":{}}],"superclasses":[],"subclasses":[],"meta":{}});