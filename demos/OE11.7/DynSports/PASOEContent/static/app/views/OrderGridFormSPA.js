var OrderGridFormSPACtrl = (function(){
    "use strict";

    var resourceName = "order";
    var searchField1 = "OrderNum";
    var searchTitle = "Order\#";
    var searchOper1 = "equals";
    var datasetName = "dsOrder";
    var tableName = "ttOrder";
    var viewName = "#OrderGridFormSPAView";

    var primaryVM = kendo.observable({
        mode: null,
        params: {
            searchValue: ""
        },
        selectedRow: {},
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
        },
        cancelEdit: function(ev){
            ev.preventDefault();
            this.set("mode", null);
            $(viewName + " form[name=editForm]").get(0).reset();
        },
        createNew: function(ev){
            ev.preventDefault();
            this.set("mode", "new");
            this.set("selectedRow", {});
            $(viewName + " form[name=editForm]").get(0).reset();
        },
        deleteRecord: function(ev){
            ev.preventDefault();
            if (confirm("Confirm - You want to Delete This Record")) {
                var options = $.extend({}, spark.optionDefaults);
                var jsdo = getDataSource().options.transport.jsdo;
                var data = this.toJSON();
                options.id = data.selectedRow._id || jsdo.getId();
                options.useSubmit = true;
                spark.jsdo_delete(jsdo, options)
                    .done(function(jsdo, success, request){
                        $(viewName + " form[name=editForm]").get(0).reset();
                        alert("Record successfully deleted.");
                    });
            }
        },
        saveRecord: function(ev){
            ev.preventDefault();
            var self = this;
            var data = this.toJSON();
            var options = $.extend({}, spark.optionDefaults);
            var jsdo = getDataSource().options.transport.jsdo;
            options.useSubmit = true;
            if (data.mode === "new") {
                options.data = data.selectedRow;
                spark.jsdo_create(jsdo, options)
                    .done(function(jsdo, success, request){
                        alert("Record successfully created.");
                    });
            } else {
                options.id = data.selectedRow._id || "";
                options.data = data.selectedRow || {};
                options.tableRef = tableName;
                spark.jsdo_update(jsdo, options)
                    .done(function(jsdo, success, request){
                        alert("Record successfully updated.");
                        self.doSearch(); // Refresh data.
                    });
            }
            this.set("mode", null);
        }
    });

    var _primaryDS = null;
    function getDataSource(){
        if (!_primaryDS) {
            _primaryDS = spark.createJSDODataSource(resourceName, {
                pageSize: 100,
                sort: {field: searchField1, dir: "asc"},
                tableRef: tableName
            });
        }
        return _primaryDS;
    }

    function showGrid() {
        $(viewName + " div[name=SearchGrid]").kendoGrid({
            columns: [{
                field: searchField1,
                template: "#=OrderNum# - #=CustName#",
                title: searchTitle
            }],
            dataSource: getDataSource(),
            editable: false,
            filterable: false,
            height: "100%",
            reorderable: false,
            resizable: false,
            scrollable: { virtual: true },
            selectable: "row",
            sortable: true,
            change: function(ev) {
                var record = spark.grid.getSelectedRecord(ev);
                primaryVM.set("selectedRow", record);
                primaryVM.set("mode", null);
            }
        });

        $(viewName + " div[name=SearchGrid]").getKendoGrid().one("dataBound", function(e) {
            this.element.find("tbody tr:first").addClass("k-state-selected")
            var row = this.element.find("tr:first");
            var rowData = $(viewName + " div[name=SearchGrid]").getKendoGrid().dataSource.data()[0];
            $(viewName + " div[name=SearchGrid]").select(row);
            primaryVM.set("selectedRow", rowData);
        });

        // Initial search when value passed along with URL.
        if (spark.getQueryStringValue(searchField1) !== "") {
            primaryVM.set("params.searchValue", spark.getQueryStringValue(searchField1));
            primaryVM.doSearch();
        }

        $(viewName + " form[name=searchForm]")
            .on("submit", function(ev){
                primaryVM.doSearch(ev);
                ev.preventDefault();
            });

        $(viewName + " form[name=editForm]")
            .on("submit", function(ev){
                ev.preventDefault();
            });
    }

    function init(){
        // Bind the observable to the view.
        kendo.bind($(viewName), primaryVM);
        showGrid(); // Initialize grid.

        // Convert all elements with a "dateitem" class to a date picker.
        spark.field.createDatePicker(viewName + " .dateitem");

        // Customize the CustNum field to utilize a remote entity.
        var custNum = spark.field.createResourceLookup(viewName + " form[name=editForm] input[name=CustNum]", {
            dataTextField: "CustName", // Displayed text.
            dataValueField: "CustNum", // Actual value.
            resourceName: "customer", // Remote resource (custom property).
            resourceTable: "ttCustomer", // Temp-table name (custom property).
            optionLabel: "Search by Customer", // Blank selection text.
            template: "#=CustNum# - #=CustName#", // Template for dropdown options.
            valueTemplate: "#=CustNum# - #=CustName#" // Template for selected item.
        });

        // Customize the SalesRep field to utilize a remote entity.
        var salesRep = spark.field.createResourceLookup(viewName + " form[name=editForm] input[name=SalesRep]", {
            dataTextField: "RepName", // Displayed text.
            dataValueField: "SalesRep", // Actual value.
            resourceName: "salesrep", // Remote resource (custom property).
            resourceTable: "ttSalesrep", // Temp-table name (custom property).
            optionLabel: "Search by Sales Rep", // Blank selection text.
            template: "#=SalesRep# - #=RepName#", // Template for dropdown options.
            valueTemplate: "#=SalesRep# - #=RepName#" // Template for selected item.
        });
    }

    function loadTemplates(){
        // Load additional templates for header/footer.
    }

    return {
        init: init,
        loadTemplates: loadTemplates
    };

})();
