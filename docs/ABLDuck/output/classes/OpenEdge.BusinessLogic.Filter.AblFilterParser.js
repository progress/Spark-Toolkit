Ext.data.JsonP.OpenEdge_BusinessLogic_Filter_AblFilterParser({"files":[],"uses":["Ccs.BusinessLogic.IGetDataRequest","Ccs.BusinessLogic.IGetDataTableRequest","Ccs.BusinessLogic.IQueryEntry","Ccs.BusinessLogic.IQueryGroup","Ccs.BusinessLogic.IQuerySortEntry","Ccs.BusinessLogic.JoinEnum","Ccs.BusinessLogic.QueryOperatorEnum","Ccs.BusinessLogic.SortOrderEnum","Ccs.Common.Support.ICharacterArrayHolder","Ccs.Common.Support.ICharacterHolder","Ccs.Common.Support.ILongcharArrayHolder","Ccs.Common.Support.ILongcharHolder","Ccs.Common.Support.IPrimitiveHolder","OpenEdge.BusinessLogic.Filter.FilterParser","OpenEdge.BusinessLogic.GetDataRequest","OpenEdge.BusinessLogic.GetDataTableRequest","OpenEdge.BusinessLogic.QueryDefinition","OpenEdge.BusinessLogic.QueryGroup","OpenEdge.BusinessLogic.QueryOperatorHelper","OpenEdge.BusinessLogic.QueryPredicate","OpenEdge.BusinessLogic.QuerySortEntry","OpenEdge.Core.Assert","OpenEdge.Core.Collections.ObjectStack","OpenEdge.Core.String","OpenEdge.Core.StringConstant","Progress.Json.ObjectModel.JsonArray","Progress.Json.ObjectModel.JsonDataType","Progress.Json.ObjectModel.JsonObject","Progress.Lang.AppError"],"id":"class-OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"class","name":"OpenEdge.BusinessLogic.Filter.AblFilterParser","extends":"OpenEdge.BusinessLogic.Filter.FilterParser","author":"pjudge","comment":"\u003ch3\u003eFile:\u003c/h3\u003e\n\u003cp\u003eAblFilterParser\u003c/p\u003e\n\u003ch3\u003eCreated:\u003c/h3\u003e\n\u003cp\u003eWed Dec 07 14:11:10 EST 2016\u003c/p\u003e\n\u003ch3\u003eNotes:\u003c/h3\u003e\n\u003cul\u003e\n\u003cli\u003eString with \u0026quot;WHERE\u0026quot;...\u003c/li\u003e\n\u003c/ul\u003e\n","icon":"class","superclasses":["OpenEdge.BusinessLogic.Filter.FilterParser","OpenEdge.BusinessLogic.Filter.AblFilterParser"],"subclasses":["OpenEdge.BusinessLogic.Filter.JfpFilterParser"],"implements":[],"members":[{"id":"constructor-AblFilterParser1","name":"AblFilterParser","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"constructor","comment":"\u003cp\u003eDefault constructor\u003c/p\u003e\n","meta":{}},{"id":"constructor-AblFilterParser2","name":"AblFilterParser","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"constructor","comment":"\u003cp\u003eConstructor.\u003c/p\u003e\n","parameters":[{"name":"pTable","datatype":"CHARACTER","mode":""}],"meta":{}},{"id":"constructor-AblFilterParser3","name":"AblFilterParser","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"constructor","comment":"\u003cp\u003eConstructor.\u003c/p\u003e\n","parameters":[{"name":"pTable","datatype":"CHARACTER","mode":""}],"meta":{}},{"id":"method-ParseSortString","name":"ParseSortString","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eParses an ABL BY expression into an array of IQuerySortEntry.\u003c/p\u003e\n\u003cp\u003eIf the string is malformed (ie can\u0027t be used as an ABL sort), then an indeterminate array\nis returned. mallformed might be something like \u0026quot;by eq 21\u0026quot; or \u0026quot;by\u0026quot;.\u003c/p\u003e\n","parameters":[{"name":"pSortBy","datatype":"LONGCHAR","mode":""}],"returns":{"datatype":"Ccs.BusinessLogic.IQuerySortEntry","comment":"IQuerySortEntry[] An array of sort entries. Will be indeterminate if the input value is empty or null,\n or if the string isn\u0027t of the format \"BY \u003cfield\u003e [BY \u003cfield-2\u003e]\""},"meta":{}},{"id":"method-ParseWhereString","name":"ParseWhereString","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eParses a where string into a query entry - either a group or a predicate.\u003c/p\u003e\n\u003cp\u003eIf the parsing runs into problems (eg a malformed string) a null IQueryEntry is returned.\nSplitting of a string into groups using \u0026quot;(\u003cgrp-1\u003e)\u0026quot; is not supported.\u003c/p\u003e\n","parameters":[{"name":"pWhere","datatype":"LONGCHAR","mode":""}],"returns":{"datatype":"Ccs.BusinessLogic.IQueryEntry","comment":"IQueryEntry A query group, query predicate or unknown (if the string cannot be parsed)"},"meta":{}},{"id":"method-IsMatchesExpression","name":"IsMatchesExpression","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eIndicates whether a string can be used with a MATCHES operator:\nit needs to have an unescaped * or . in the string.\u003c/p\u003e\n","parameters":[{"name":"pExpr","datatype":"CHARACTER","mode":""}],"returns":{"datatype":"LOGICAL","comment":"logical TRUE if the expression contains at least one * or .; FALSE otherwise"},"meta":{}},{"id":"method-GetGroupParent","name":"GetGroupParent","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eReads the whole tree of groups in a group to find a particular group\u0027s parent group.\u003c/p\u003e\n","parameters":[{"name":"pParent","datatype":"OpenEdge.BusinessLogic.QueryGroup","mode":""},{"name":"pGroup","datatype":"OpenEdge.BusinessLogic.QueryGroup","mode":""}],"returns":{"datatype":"OpenEdge.BusinessLogic.QueryGroup","comment":"QueryGroup The parent group, or NULL if none found."},"meta":{}},{"id":"method-AddToGroup","name":"AddToGroup","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eAdds a query entry to an existing group.\u003c/p\u003e\n","parameters":[{"name":"pParentGroup","datatype":"OpenEdge.BusinessLogic.QueryGroup","mode":""},{"name":"pEntry","datatype":"Ccs.BusinessLogic.IQueryEntry","mode":""},{"name":"pJoin","datatype":"Ccs.BusinessLogic.JoinEnum","mode":""}],"returns":{"datatype":"LOGICAL","comment":"logical TRUE if the query entry was added; FALSE otherwise"},"meta":{}},{"id":"method-ParseSortBy","name":"ParseSortBy","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eParses an SORT-BY phrase and returns an array of IQuerySortEntry objects.\u003c/p\u003e\n","parameters":[{"name":"pSortBy","datatype":"Progress.Lang.Object","mode":""}],"returns":{"datatype":"Ccs.BusinessLogic.IQuerySortEntry","comment":"IQuerySortEntry[] An array of sort phrases. An indeterminate array is returned if the input phrase is empty"},"meta":{"override":true}},{"id":"method-ParseWhere","name":"ParseWhere","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eParses where/filter phrase and returns an IQueryEntry object for a single table\u003c/p\u003e\n","parameters":[{"name":"pWhere","datatype":"Progress.Lang.Object","mode":""}],"returns":{"datatype":"Ccs.BusinessLogic.IQueryEntry","comment":"IQueryEntry The query entry.We return one of an IQueryPredicate (single clause)\n or an IQueryGroup (many clauses)"},"meta":{"override":true}},{"id":"method-Parse","name":"Parse","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eReads and processes (parses) the filter.\u003c/p\u003e\n","parameters":[{"name":"pData","datatype":"Progress.Lang.Object","mode":""}],"returns":{"datatype":"Ccs.BusinessLogic.IGetDataRequest","comment":""},"meta":{"override":true}},{"id":"method-ParseTableRequest","name":"ParseTableRequest","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eReads a single table\u0027s request\u003c/p\u003e\n\u003cp\u003eThis method knows which properties in the input JSON are for the where clause, for the sort-by etc\u003c/p\u003e\n","parameters":[{"name":"pTable","datatype":"CHARACTER","mode":""},{"name":"pData","datatype":"Progress.Json.ObjectModel.JsonObject","mode":""}],"returns":{"datatype":"Ccs.BusinessLogic.IGetDataTableRequest","comment":"IGetDataTableRequest A single table Get Request"},"meta":{}},{"id":"method-GetFieldValue","name":"GetFieldValue","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eReturns a field value from the current parsed string\u003c/p\u003e\n","parameters":[{"name":"pVal","datatype":"CHARACTER","mode":""},{"name":"pQuotedNull","datatype":"LOGICAL","mode":""},{"name":"pOperator","datatype":"Ccs.BusinessLogic.QueryOperatorEnum","mode":""}],"returns":{"datatype":"OpenEdge.Core.String","comment":"String The String containing the value"},"meta":{}},{"id":"method-GetJoin","name":"GetJoin","owner":"OpenEdge.BusinessLogic.Filter.AblFilterParser","tagname":"method","comment":"\u003cp\u003eDetermines the join value.\u003c/p\u003e\n\u003cp\u003eIf there is an existing join value passed in,\nand it\u0027s value is either \u0026quot;And\u0026quot; or \u0026quot;Or\u0026quot;, and the current string\nvalue is \u0026quot;not\u0026quot;, then return a new \u0026quot;AndNot\u0026quot; or \u0026quot;OrNot\u0026quot;.\u003c/p\u003e\n\u003cp\u003eIf there is an existing join value passed in, and it is not \u0026quot;And\u0026quot; or\n\u0026quot;Or\u0026quot;, then that value is returned.\u003c/p\u003e\n\u003cp\u003eIf no join value is passed in, then use the string value to determine the\nenum.\u003c/p\u003e\n","parameters":[{"name":"pVal","datatype":"CHARACTER","mode":""},{"name":"pJoin","datatype":"Ccs.BusinessLogic.JoinEnum","mode":""}],"returns":{"datatype":"Ccs.BusinessLogic.JoinEnum","comment":"JoinEnum The new join."},"meta":{}},{"id":"constructor-OpenEdge_BusinessLogic_Filter_FilterParser_FilterParser1","name":"FilterParser","owner":"OpenEdge.BusinessLogic.Filter.FilterParser","tagname":"constructor","comment":"\u003cp\u003eDefault constructor.\u003c/p\u003e\n","meta":{}},{"id":"constructor-OpenEdge_BusinessLogic_Filter_FilterParser_FilterParser2","name":"FilterParser","owner":"OpenEdge.BusinessLogic.Filter.FilterParser","tagname":"constructor","comment":"\u003cp\u003eConstructor.\u003c/p\u003e\n","parameters":[{"name":"pTable","datatype":"CHARACTER","mode":""}],"meta":{}},{"id":"constructor-OpenEdge_BusinessLogic_Filter_FilterParser_FilterParser3","name":"FilterParser","owner":"OpenEdge.BusinessLogic.Filter.FilterParser","tagname":"constructor","comment":"\u003cp\u003eConstructor.\u003c/p\u003e\n","parameters":[{"name":"pTable","datatype":"CHARACTER","mode":""}],"meta":{}},{"id":"property-OpenEdge_BusinessLogic_Filter_FilterParser_FilterTable","name":"FilterTable","owner":"OpenEdge.BusinessLogic.Filter.FilterParser","tagname":"property","datatype":"CHARACTER","comment":"\u003cp\u003eAn ordered set of table names used to create this filter.\nTypically just one, but potentially more\u003c/p\u003e\n\u003ch3\u003eModifier:\u003c/h3\u003e\n\u003cp\u003e\u003ccode\u003ePUBLIC GET\u003c/code\u003e\u003c/p\u003e\n","meta":{}},{"id":"method-OpenEdge_BusinessLogic_Filter_FilterParser_Parse","name":"Parse","owner":"OpenEdge.BusinessLogic.Filter.FilterParser","tagname":"method","comment":"\u003cp\u003eReads and processes (parses) a complete data filter.\u003c/p\u003e\n","parameters":[{"name":"pData","datatype":"Progress.Lang.Object","mode":""}],"returns":{"datatype":"Ccs.BusinessLogic.IGetDataRequest","comment":""},"meta":{"abstract":true}},{"id":"method-OpenEdge_BusinessLogic_Filter_FilterParser_ParseWhere","name":"ParseWhere","owner":"OpenEdge.BusinessLogic.Filter.FilterParser","tagname":"method","comment":"\u003cp\u003eParses where/filter phrase and returns an IQueryEntry object for a single table\u003c/p\u003e\n","parameters":[{"name":"pWhere","datatype":"Progress.Lang.Object","mode":""}],"returns":{"datatype":"Ccs.BusinessLogic.IQueryEntry","comment":"IQueryEntry The query entry.We return one of an IQueryPredicate (single clause) \n or an IQueryGroup (many clauses)"},"meta":{"abstract":true}},{"id":"method-OpenEdge_BusinessLogic_Filter_FilterParser_ParseSortBy","name":"ParseSortBy","owner":"OpenEdge.BusinessLogic.Filter.FilterParser","tagname":"method","comment":"\u003cp\u003eParses an SORT-BY phrase and returns an array of IQuerySortEntry objects.\u003c/p\u003e\n","parameters":[{"name":"pSortBy","datatype":"Progress.Lang.Object","mode":""}],"returns":{"datatype":"Ccs.BusinessLogic.IQuerySortEntry","comment":"IQuerySortEntry[] An array of sort phrases. An indeterminate array is returned if the input phrase is empty"},"meta":{"abstract":true}}],"meta":{}});