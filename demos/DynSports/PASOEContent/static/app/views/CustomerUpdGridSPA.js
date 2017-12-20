var CustomerUpdGridSPACtrl = (function(){
    "use strict";

    var resourceName = "customer";
    var searchField1 = "CustName";
    var searchOper1 = "startsWith";
    var datasetName = "dsCustomer";
    var tableName = "ttCustomer";
    var gridName = "MasterGrid";
    var viewName = "#CustomerUpdGridSPAView";
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
                        value: params.searchValue
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
                    if (success && request.operation === progress.data.JSDO._OP_SUBMIT) {
                        // Obtain information about submit operation that just occurred.
                        var data = (((request || {}).response[datasetName] || {})[tableName] || [])[0] || null;
                        if (data) {
                            // Perform a search (refresh) when search field is found in results.
                            primaryVM.set("params.searchValue", data[searchField1] || "");
                            primaryVM.doSearch();
                        }
                    }

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
            field: "CustNum",
            attributes: {class: "numbers"},
            template: "#=kendo.toString(CustNum, 'n0')#",
            title: "Cust\#",
            width: 120
        }, {
            field: "CustName",
            title: "Customer Name",
            width: 150
        }, {
            field: "Address",
            title: "Address",
            width: 150
        }, {
            field: "Address2",
            hidden: true,
            title: "Address2",
            width: 150
        }, {
            field: "City",
            title: "City",
            width: 150
        }, {
            field: "State",
            title: "State/Province",
            width: 150,
            editor: function(container, options){
                // Create the field params using some grid information (like the Country value).
                var fieldOptions = {
                    autoBind: true,
                    dataTextField: "FullName",
                    dataValueField: "Abbrev",
                    invokeResource: "locality",
                    invokeMethod: "stateProvince",
                    invokeDataProperty: "states",
                    params: {country: options.model.Country},
                    dataBound: function(ev){
                        var data = options.model[options.field] || options.model.defaults[options.field];
                        ev.sender.value(data);
                    }
                };
                // Create the function (with field params) to create the editor (with grid params).
                return (spark.grid.createInvokeLookupEditor(fieldOptions))(container, options);
            }
        }, {
            field: "PostalCode",
            title: "Postal Code",
            width: 150
        }, {
            field: "Country",
            title: "Country",
            width: 150,
            editor: spark.grid.createSimpleLookupEditor({dataSource: ["USA", "Canada"]})
        }, {
            field: "Contact",
            hidden: true,
            title: "Contact",
            width: 150
        }, {
            field: "Phone",
            title: "Phone",
            width: 150,
            editor: spark.grid.createFormattedFieldEditor({mask: getDataSource().getFieldSchema("Phone").mask || null})
        }, {
            field: "SalesRep",
            title: "Sales Rep",
            width: 150,
            editor: spark.grid.createSingleLookupEditor({
                dataTextField: "RepName",
                dataValueField: "SalesRep",
                dataSource: salesReps,
                filter: "startsWith"
            })
        }, {
            field: "CreditLimit",
            attributes: {class: "numbers"},
            hidden: true,
            template: "#=kendo.toString(CreditLimit, 'n2')#",
            title: "Credit Limit",
            width: 120
        }, {
            field: "Balance",
            attributes: {class: "numbers"},
            hidden: true,
            template: "#=kendo.toString(Balance, 'n2')#",
            title: "Balance",
            width: 120
        }, {
            field: "Terms",
            hidden: true,
            title: "Terms",
            width: 150
        }, {
            field: "Discount",
            attributes: {class: "numbers"},
            hidden: true,
            template: "#=kendo.toString(Discount, 'n0')#",
            title: "Discount",
            width: 120
        }, {
            field: "Comments",
            hidden: true,
            title: "Comments",
            width: 150
        }, {
            field: "Fax",
            hidden: true,
            title: "Fax",
            width: 150
        }, {
            field: "EmailAddress",
            title: "Email",
            width: 150
        }];

        gridColumns.push({
            command: ["edit", "destroy"],
            title: "&nbsp;",
            width: 220
        });

        var grid = $(viewName + " div[name=" + gridName + "]").kendoGrid({
            autoBind: false,
            columns: (viewState[gridName] && viewState[gridName].columns) ? viewState[gridName].columns : gridColumns,
            columnMenu: true,
            dataSource: getDataSource(),
            editable: "inline",
            excel: {
                allPages: true,
                fileName: "Kendo UI Grid Export.xlsx",
                proxyURL: "http://demos.telerik.com/kendo-ui/service/export",
                filterable: true
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
            toolbar: ["create", "excel"],
            columnMenuInit: function(ev){
                if (ev && ev.container) {
                    var grid = this;
                    var popup = ev.container.data("kendoPopup");
                    var menu = ev.container.find(".k-menu").data("kendoMenu");
                    menu.append({text: "Toggle Editor Style"});
                    menu.bind("select", function(ev2) {
                        if (ev2) {
                            var item = $(ev2.item);
                            if (item && item.text() === "Toggle Editor Style") {
                                var isPopupEditor = (grid.options.editable === "popup");
                                grid.options.editable = (isPopupEditor ? "inline" : "popup");
                                popup.close();
                                menu.close();
                            }
                        }
                    });
                }
            }
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
