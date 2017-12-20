var EmployeeGridSPACtrl = (function(){
    "use strict";

    var resourceName = "employee";
    var searchField1 = "LastName";
    var searchOper1 = "startswith";
    var searchField2 = "State";
    var searchOper2 = "eq";
    var datasetName = "dsEmployee";
    var tableName = "associate";
    var gridName = "MasterGrid";
    var viewName = "#EmployeeGridSPAView";
    var searchOnLoad = true;
    var viewState = null;

    var primaryVM = kendo.observable({
        context: {},
        params: {
            searchValue: "",
            searchValue2: ""
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
                    filter = [{
                        field: searchField1,
                        operator: searchOper1,
                        value: params.searchValue
                    }];
                }
                if ((params.searchValue2 || "") !== "") {
                    filter.push({
                        field: searchField2,
                        operator: searchOper2,
                        value: params.searchValue2
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
                }
            });
        }
        return _primaryDS;
    }

    function showGrid(){
        var gridColumns = [{            field: "EmpNum",            attributes: {class: "numbers"},            template: "#=kendo.toString(EmpNum, 'n0')#",            title: "Emp. \#",            width: 100        }, {            field: "LastName",            title: "Last Name",            width: 150        }, {            field: "FirstName",            title: "First Name",            width: 150        }, {            field: "Address",            title: "Address1",            width: 150        }, {            field: "Address2",
            hidden: true,            title: "Address2",            width: 150        }, {            field: "City",            title: "City",            width: 150        }, {            field: "State",            title: "State",            width: 150        }, {            field: "PostalCode",            title: "Postal Code",            width: 150        }, {            field: "HomePhone",
            hidden: true,            title: "Home Phone",            width: 150        }, {            field: "WorkPhone",
            hidden: true,            title: "Work Phone",            width: 150        }, {            field: "DeptCode",            title: "Dept."        }, {            field: "Position",            title: "Position",            width: 150        }, {            field: "Birthdate",
            hidden: true,            template: "#=kendo.toString(kendo.parseDate(Birthdate, 'yyyy-MM-dd'), 'MM/dd/yyyy')#",            title: "Birthdate",            width: 150        }, {            field: "StartDate",
            hidden: true,            template: "#=kendo.toString(kendo.parseDate(StartDate, 'yyyy-MM-dd'), 'MM/dd/yyyy')#",            title: "Start Date",            width: 150        }, {            field: "RemainingPTO",            attributes: {class: "numbers"},            template: "#=kendo.toString(RemainingPTO, 'n0')#",            title: "PTO Balance",            width: 120        }, {            field: "SickDaysLeft",            attributes: {class: "numbers"},            template: "#=kendo.toString(SickDaysLeft, 'n0')#",            title: "Sick Balance",            width: 140        }];

        // Create the primary grid component.
        var grid = $(viewName + " div[name=" + gridName + "]").kendoGrid({
            autoBind: false,
            columns: (viewState[gridName] && viewState[gridName].columns) ? viewState[gridName].columns : gridColumns,
            columnMenu: true,
            dataSource: getDataSource(),
            excel: {
                allPages: true,
                fileName: "Kendo UI Grid Export.xlsx",
                proxyURL: window.location.protocol + "//demos.telerik.com/kendo-ui/service/export",
                filterable: true
            },
            filterable: true,
            groupable: true,
            height: "90%",
            pageable: false,
            reorderable: true,
            resizable: true,
            scrollable: {
                endless: true,
                virtual: true
            },
            selectable: false,
            sortable: true,
            toolbar: ["excel"]
        });

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

                // Check for passed parameters.
                var urlParams = spark.getUrlParams();
                if (urlParams.EmpNum) {
                    getDataSource().filter([{
                        field: "EmpNum",
                        operator: "equals",
                        value: parseInt(urlParams.EmpNum, 10)
                    }]);
                }
            });

        // Customize the State field to utilize a remote data source.
        var stateList = spark.field.createInvokeLookup(viewName + " form[name=searchForm] select[name=State]", {
            dataTextField: "FullName", // Displayed text.
            dataValueField: "Abbrev", // Actual value.
            invokeResource: "locality", // Remote resource (custom property).
            invokeMethod: "states", // Resource method (custom property).
            invokeDataProperty: "states", // Data object/array (custom property).
            optionLabel: "Search by State", // Blank selection text.
            template: "#=Abbrev# - #=FullName#", // Template for dropdown options.
            valueTemplate: "#=Abbrev# - #=FullName#" // Template for selected item.
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
