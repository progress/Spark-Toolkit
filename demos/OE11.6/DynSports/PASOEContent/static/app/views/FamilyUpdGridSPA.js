var FamilyUpdGridSPACtrl = (function(){
    "use strict";
 
    var resourceName = "family";
    var searchField1 = "EmpNum";
    var searchOper1 = "equals";
    var datasetName = "dsFamily";
    var tableName = "ttFamily";
    var gridName = "MasterGrid";
    var viewName = "#FamilyUpdGridSPAView";
    var searchOnLoad = true;
    var viewState = null;
 
    var primaryVM = kendo.observable({
        context: {},
        params: {
            searchValue: ""
        },
        clearErrors: function(){
            var validator = spark.form.getValidator(viewName + " form[name=searchForm]");
            if (validator) {
                validator.hideMessages();
            }
        },
        doSearch: function(ev){
            if (spark.form.validate(viewName + " form[name=searchForm]")) {
                var params = this.toJSON().params || {};
                var filter = []; // Add default options here.
                if ((params.searchValue || "") !== "") {
                    filter.push({
                        field: searchField1,
                        operator: searchOper1,
                        value: parseInt(params.searchValue, 10)
                    });
                }
                getDataSource().filter(filter);
            }
        }
    });
 
    function fetchViewState(){
        var promise = $.Deferred();
        var fetchViewStateJSDO = spark.createJSDO("user");
 
        fetchViewStateJSDO.invoke("contextFetch", {contextName: "grid:" + viewName})
            .then(function(jsdo, result, request){
                var myViewState = (request.response || {}).contextValue || null;
                myViewState = myViewState ? JSON.parse(myViewState.replace(/\\\"/g, "\"")) : {};
                promise.resolve(myViewState);
            }, function() {
                promise.resolve({});
            });
 
        return promise;
    }
 
    function saveViewState(){
        var promise = $.Deferred();
        var storeViewStateJSDO = spark.createJSDO("user");
 
        var grid = $(viewName + " div[name=" + gridName + "]").data("kendoGrid");
        viewState[gridName] = spark.grid.getViewState(grid);
 
        var params = {contextName: "grid:" + viewName, contextValue: JSON.stringify(viewState)};
        storeViewStateJSDO.invoke("contextStore", params)
            .always(function(){
                promise.resolve();
            });
 
        return promise;
    }
 
    var _primaryDS = null;
    function getDataSource(){
        if (!_primaryDS) {
            _primaryDS = spark.createJSDODataSource(resourceName, {
                pageSize: 20,
                filter: (viewState[gridName] && viewState[gridName].filter) ? viewState[gridName].filter : null,
                group: (viewState[gridName] && viewState[gridName].group) ? viewState[gridName].group : [],
                sort: (viewState[gridName] && viewState[gridName].sort) ? viewState[gridName].sort : {field: searchField1, dir: "asc"},
                tableRef: tableName,
                onBeforeFill: function(jsdo, request){
                    // Add context to the filter parameter in the request.
                    if (request.objParam) {
                        var data = JSON.parse(request.objParam.filter || "{}");
                        var context = primaryVM.toJSON().context;
                        data.context = context || {};
                        request.objParam.filter = JSON.stringify(data);
                    }
                },
                onAfterSaveChanges: function(jsdo, success, request){
                }
            });
        }
        return _primaryDS;
    }
 
    function showGrid(){
        var gridColumns = [{            field: "EmpNum",             attributes: {class: "numbers"},            template: function(row){
                return ('<a href="#/EmployeeGridSPA?EmpNum=' + row.EmpNum + '">' + kendo.toString(row.EmpNum, "n0") + '</a>');
            },            title: "Emp No",            width: 120        }, {            field: "RelativeName",             title: "Relative Name",            width: 150        }, {            field: "Relation",             title: "Relation",            width: 150        }, {            field: "Birthdate",            template: "#=kendo.toString(kendo.parseDate(Birthdate, 'yyyy-MM-dd'), 'MM/dd/yyyy')#",            title: "Birthdate",            width: 150,
            editor: spark.grid.createDatePickerEditor({footer: false})        }, {            field: "CoveredOnBenefits",             title: "Covered On Benefits",            width: 150        }, {            field: "BenefitDate",            template: "#=kendo.toString(kendo.parseDate(BenefitDate, 'yyyy-MM-dd'), 'MM/dd/yyyy')#",            title: "Benefit Date",            width: 150,
            editor: spark.grid.createDatePickerEditor({footer: false})        }];
 
        gridColumns.push({
            command: ["edit", "destroy"],
            title: "&nbsp;",
            width: 200
        });
 
        var grid = $(viewName + " div[name=" + gridName + "]").kendoGrid({
            autoBind: false,
            columns: gridColumns,
            columnMenu: true,
            dataSource: getDataSource(),
            editable: "inline",
            excel: {
                allPages: true,
                fileName: "Kendo UI Grid Export.xlsx",
                filterable: true,
                proxyURL: "http://demos.telerik.com/kendo-ui/service/export"
            },
            filterable: true,
            groupable: true,
            height: "90%",
            pageable: {
                refresh: true,
                pageSizes: [10, 20, 40],
                pageSize: 20,
                buttonCount: 5
            },
            reorderable: true,
            resizable: true,
            scrollable: true,
            selectable: false,
            sortable: true,
            toolbar: ["create", "excel"]
        });
 
        // Moves grid pager to the footer.
        var pager = grid.find(".k-grid-pager");
        if (pager) {
            pager.appendTo($(viewName + " div[name=" + gridName + "Pager]"));
        }
 
        primaryVM.set("params.searchValue", spark.getQueryStringValue(searchField1) || "");
        if (searchOnLoad) {
            primaryVM.doSearch(); // Perform an initial search to populate the grid.
        }
 
        $(viewName + " form[name=searchForm]")
            .on("submit", function(ev){
                primaryVM.doSearch(ev);
                ev.preventDefault();
            });
    }
 
    function init(){
        fetchViewState()
            .then(function(myViewState){
                viewState = myViewState;
 
                // Bind the observable to the view.
                kendo.bind($(viewName), primaryVM);
 
                showGrid(); // Initialize grid.
            });
    }
 
    function loadTemplates(){
        // Load additional templates for header/footer.
    }
 
    function destroy(){
        return saveViewState();
    }
 
    return {
        init: init,
        loadTemplates: loadTemplates,
        destroy: destroy
    };
 
})();
