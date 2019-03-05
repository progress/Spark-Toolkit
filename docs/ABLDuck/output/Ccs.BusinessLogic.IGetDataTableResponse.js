Ext.data.JsonP.Ccs_BusinessLogic_IGetDataTableResponse({"mixedInto":[],"parentMixins":[],"files":[],"alternateClassNames":[],"mixins":[],"requires":[],"uses":[],"aliases":{},"id":"class-Ccs.BusinessLogic.IGetDataTableResponse","tagname":"class","name":"Ccs.BusinessLogic.IGetDataTableResponse","extends":"","author":"Mike Fechner / Consultingwerk Ltd.","shortDoc":"","html":"\u003cdiv\u003e\u003cpre class\u003d\"hierarchy\"\u003e\u003ch4\u003eImplementers\u003c/h4\u003e\u003cdiv class\u003d\"dependency\"\u003e\u003ca href\u003d\"#!/api/OpenEdge.BusinessLogic.GetDataTableResponse\" rel\u003d\"OpenEdge.BusinessLogic.GetDataTableResponse\" class\u003d\"docClass\"\u003eOpenEdge.BusinessLogic.GetDataTableResponse\u003c/a\u003e\u003c/div\u003e\u003ch4\u003eAuthor\u003c/h4\u003e\u003cdiv class\u003d\"dependency\"\u003eMike Fechner / Consultingwerk Ltd.\u003c/div\u003e\u003c/pre\u003e\u003cdiv class\u003d\"doc-contents\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eContains table specific response of the IGetDataResponse\ninterface, part of the response object received by the\ngetData method of the IBusinessEntity\u003c/p\u003e\n\u003c/div\u003e\u003cdiv class\u003d\"members\"\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-constructor\"\u003eConstructors\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-event\"\u003eEvents\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-property\"\u003eProperties\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003cdiv id\u003d\"property-NextPagingContext\" class\u003d\"member first-child not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Ccs.BusinessLogic.IGetDataTableResponse\"\u003eCcs.BusinessLogic.IGetDataTableResponse\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Ccs.BusinessLogic.IGetDataTableResponse-property-NextPagingContext\" class\u003d\"name expandable\"\u003eNextPagingContext\u003c/a\u003e : CHARACTER\u003cspan class\u003d\"signature\"\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003ePurpose\nReturns the paging context to be passed back to the business\nentity when requesting the next ...\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eReturns the paging context to be passed back to the business\nentity when requesting the next set\u003c/p\u003e\n\u003ch2\u003eNotes\u003c/h2\u003e\n\u003cp\u003eUsed for Paging. This value typically consists of record identifiers\n(e.g. DATA-SOURCE ROWID retrieved by the RESTART-ROWID function\nor other data required by the Business Entity to build the next\nset of data in a follow up call).\u003c/p\u003e\n\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv id\u003d\"property-PreviousPagingContext\" class\u003d\"member  not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Ccs.BusinessLogic.IGetDataTableResponse\"\u003eCcs.BusinessLogic.IGetDataTableResponse\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Ccs.BusinessLogic.IGetDataTableResponse-property-PreviousPagingContext\" class\u003d\"name expandable\"\u003ePreviousPagingContext\u003c/a\u003e : CHARACTER\u003cspan class\u003d\"signature\"\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003ePurpose\nReturns the paging context to be passed back to the business\nentity when requesting the prev ...\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eReturns the paging context to be passed back to the business\nentity when requesting the previous set\u003c/p\u003e\n\u003ch2\u003eNotes\u003c/h2\u003e\n\u003cp\u003eUsed for Paging. This value typically consists of record identifiers\n(e.g. DATA-SOURCE ROWID retrieved by the RESTART-ROWID function\nor other data required by the Business Entity to build the previous\nset of data in a follow up call).\u003c/p\u003e\n\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv id\u003d\"property-TableName\" class\u003d\"member  not-inherited\"\u003e\u003ca href\u003d\"#\" class\u003d\"side expandable\"\u003e\u003cspan\u003e\u0026nbsp;\u003c/span\u003e\u003c/a\u003e\u003cdiv class\u003d\"title\"\u003e\u003cdiv class\u003d\"meta\"\u003e\u003cspan class\u003d\"defined-in\" rel\u003d\"Ccs.BusinessLogic.IGetDataTableResponse\"\u003eCcs.BusinessLogic.IGetDataTableResponse\u003c/span\u003e\u003cbr/\u003e\u003c/div\u003e\u003ca href\u003d\"#!/api/Ccs.BusinessLogic.IGetDataTableResponse-property-TableName\" class\u003d\"name expandable\"\u003eTableName\u003c/a\u003e : CHARACTER\u003cspan class\u003d\"signature\"\u003e\u003c/span\u003e\u003c/div\u003e\u003cdiv class\u003d\"description\"\u003e\u003cdiv class\u003d\"short\"\u003ePurpose\nReturns the name of the ProDataset Table\nNotes\nIdentifies the table this IGetDataTableRespon ...\u003c/div\u003e\u003cdiv class\u003d\"long\"\u003e\u003ch2\u003ePurpose\u003c/h2\u003e\n\u003cp\u003eReturns the name of the ProDataset Table\u003c/p\u003e\n\u003ch2\u003eNotes\u003c/h2\u003e\n\u003cp\u003eIdentifies the table this IGetDataTableResponse belongs to\u003c/p\u003e\n\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003cdiv class\u003d\"members-section\"\u003e\u003cdiv class\u003d\"definedBy\"\u003eDefined By\u003c/div\u003e\u003ch3 class\u003d\"members-title icon-method\"\u003eMethods\u003c/h3\u003e\u003cdiv class\u003d\"subsection\"\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e\u003c/div\u003e","classIcon":"interface","members":[{"id":"property-NextPagingContext","name":"NextPagingContext","owner":"Ccs.BusinessLogic.IGetDataTableResponse","tagname":"property","datatype":"CHARACTER","meta":{}},{"id":"property-PreviousPagingContext","name":"PreviousPagingContext","owner":"Ccs.BusinessLogic.IGetDataTableResponse","tagname":"property","datatype":"CHARACTER","meta":{}},{"id":"property-TableName","name":"TableName","owner":"Ccs.BusinessLogic.IGetDataTableResponse","tagname":"property","datatype":"CHARACTER","meta":{}}],"superclasses":[],"subclasses":[],"meta":{}});