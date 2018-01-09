var OrderUpdGridSPACtrl = (function(){
    "use strict";

    var resourceName = "order";
    var searchField1 = "OrderDate";
    var searchOper1 = "gte";
    var searchField2 = "SalesRep";
    var searchOper2 = "eq";
    var datasetName = "dsOrder";
    var tableName = "ttOrder";
    var gridName = "MasterGrid";
    var viewName = "#OrderUpdGridSPAView";
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
                    filter.push({
                        field: searchField1,
                        operator: searchOper1,
                        value: params.searchValue
                    });
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
                },
                onAfterSaveChanges: function(jsdo, success, request){
                    // Parse the result for any possible messages.
                    var response = request.response;
                    if (spark.notify.responseHasInfo(response) || spark.notify.responseHasErrors(response)) {
                        app.showMessages(response);
                    }
                }
            });
        }
        return _primaryDS;
    }

    function showGrid(){
        var gridColumns = [{
            editor: spark.grid.createDatePickerEditor()
            editor: spark.grid.createDatePickerEditor()
                if (row.ShipDate) {
                    return kendo.toString(kendo.parseDate(row.ShipDate, "yyyy-MM-dd"), "MM/dd/yyyy");
                }
                return "N/A";
            },
            editor: spark.grid.createDatePickerEditor()
            editor: spark.grid.createSimpleLookupEditor({dataSource: ["Ordered", "Shipped", "Pending"]})
            template: "#=SalesRepName#",
            editor: spark.grid.createSingleLookupEditor({
                dataTextField: "RepName",
                dataValueField: "SalesRep",
                dataSource: salesReps,
                filter: "startsWith"
            })
            hidden: true,
            hidden: true,
            hidden: true,
            hidden: true,
            hidden: true,
            hidden: true,
            hidden: true,
            hidden: true,

        gridColumns.push({
            command: ["edit", "destroy"],
            title: "&nbsp;",
            width: 220
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

    var salesReps = [];
    function init(){
        fetchViewState()
            .then(function(myViewState){
                viewState = myViewState;

                // Bind the observable to the view.
                kendo.bind($(viewName), primaryVM);

                // Obtain consistent data for dropdowns first.
                var salesRepJSDO = spark.createJSDO("salesrep");
                salesRepJSDO.fill()
                    .done(function(jsdo, status, request){
                        var response = (request || {}).response || {};
                        salesReps = (response.dsSalesrep || {}).ttSalesrep || [];
                        showGrid(); // Initialize grid.
                    });

                // Customize search field to utilize a standard date picker.
                var orderDate = spark.field.createDatePicker(viewName + " form[name=searchForm] input[name=Ordered]");

                // Customize the SalesRep field to utilize a remote entity.
                var salesRep = spark.field.createResourceLookup(viewName + " form[name=searchForm] select[name=SalesRep]", {
                    dataTextField: "RepName", // Displayed text.
                    dataValueField: "SalesRep", // Actual value.
                    resourceName: "salesrep", // Remote resource (custom property).
                    resourceTable: "ttSalesrep", // Temp-table name (custom property).
                    optionLabel: "Search by Sales Rep", // Blank selection text.
                    template: "#=SalesRep# - #=RepName#", // Template for dropdown options.
                    valueTemplate: "#=SalesRep# - #=RepName#" // Template for selected item.
                });
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