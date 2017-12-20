var OrderOrderGridInGridSPACtrl = (function(){
    "use strict";

    var masterResourceName = "order";
    var detailResourceName = "order";
    var searchField1 = "CustNum";
    var searchOper1 = "equals";
    var datasetName = "dsOrder";
    var masterTableName = "ttOrder";
    var detailTableName = "ttOrderLine";
    var masterKeyName = "OrderNum";
    var detailKeyName = "OrderNum";
    var viewName = "#OrderOrderGridInGridSPAView";
    var searchOnLoad = false;

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
                        value: parseInt(params.searchValue, 10) // Parameter should be an integer.
                    });
                }
                getDataSource().filter(filter);
            }
        }
    });

    var _primaryDS = null;
    function getDataSource(){
        if (!_primaryDS) {
            _primaryDS = spark.createJSDODataSource(masterResourceName, {
                pageSize: 20,
                sort: {field: searchField1, dir: "asc"},
                tableRef: masterTableName,
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

    function getDetailDS(ev){
        var detailDS = null;
        if (ev) {
            // NOTE: This is a custom implementation, as data is returned for this page
            // as a nested DataSet, meaning the child records are included within the
            // parent record data. We need only to extract it for this DataSource.

            // Create the primary datasource.
            detailDS = new kendo.data.DataSource({
                data: ev.data[detailTableName],
                pageSize: 10,
                serverFiltering: false,
                serverPaging: false,
                serverSorting: false
            });
        } else {
            detailDS = new kendo.data.DataSource();
        }
        return detailDS;
    }

    function showGrid(){
        var gridColumns = [{            field: "OrderNum",            attributes: {class: "numbers"},            template: "#=kendo.toString(OrderNum, 'n0')#",            title: "Order Num",            width: 120        }, {            field: "CustName",            attributes: {class: "numbers"},            template: "#=kendo.toString(CustNum, 'n0')# - #=CustName#",            title: "Customer",            width: 180        }, {            field: "OrderDate",            template: "#=kendo.toString(kendo.parseDate(OrderDate, 'yyyy-MM-dd'), 'MM/dd/yyyy')#",            title: "Ordered",            width: 150        }, {            field: "ShipDate",            template: "#=(ShipDate ? kendo.toString(kendo.parseDate(ShipDate, 'yyyy-MM-dd'), 'MM/dd/yyyy') : '')#",            title: "Shipped",            width: 150        }, {            field: "PromiseDate",            template: "#=kendo.toString(kendo.parseDate(PromiseDate, 'yyyy-MM-dd'), 'MM/dd/yyyy')#",            title: "Promised",            width: 150        }, {            field: "Carrier",            title: "Carrier",            width: 150        }, {            field: "Instructions",
            hidden: true,            title: "Instructions",            width: 150        }, {            field: "PO",
            hidden: true,            title: "PO",            width: 150        }, {            field: "Terms",            title: "Terms",            width: 150        }, {            field: "SalesRep",
            template: "#=SalesRepName#",            title: "Sales Rep",            width: 150        }, {            field: "BillToID",            attributes: {class: "numbers"},
            hidden: true,            template: "#=kendo.toString(BillToID, 'n0')#",            title: "Bill To ID",            width: 120        }, {            field: "ShipToID",
            hidden: true,            attributes: {class: "numbers"},            template: "#=kendo.toString(ShipToID, 'n0')#",            title: "Ship To ID",            width: 120        }, {            field: "OrderStatus",            title: "Order Status",            width: 150        }, {            field: "WarehouseNum",            attributes: {class: "numbers"},            template: "#=kendo.toString(WarehouseNum, 'n0')#",            title: "Warehouse Num",            width: 120        }, {            field: "Creditcard",
            hidden: true,            title: "Credit Card",            width: 150        }];

        // Create the primary grid component.
        var masterGrid = $(viewName + " div[name=MasterGrid]").kendoGrid({
            autoBind: false,
            autoSync: true,
            columns: gridColumns,
            columnMenu: true,
            dataBound: function() {
                // Un-comment this line to expand the first row by default.
                //this.expandRow(this.tbody.find("tr.k-master-row").first());
            },
            dataSource: getDataSource(),
            detailInit: detailInit,
            editable: "popup",
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
            toolbar: ["excel"],
            change: function(ev) {
                var record = spark.grid.getSelectedRecord(ev);
                primaryVM.set("selectedRow", record);
                var detailGrid = $(viewName + " div[name=DetailGrid]").data("kendoGrid");
                var paramObj = {
                    field: detailKeyName,
                    operator: "eq",
                    value: record[masterKeyName]
                };
                if (detailGrid && detailGrid.dataSource) {
                    detailGrid.dataSource.filter(paramObj);
                }
            }
        });

        function detailInit(ev) {
            var detailColumns = [{                field: "LineNum",                attributes: {class: "numbers"},                template: "#=kendo.toString(LineNum, 'n0')#",                title: "Line Num",                width: 120            }, {                field: "ItemNum",                template: "#=kendo.toString(ItemNum, 'n0')# - #=ItemName#",                title: "Item Num",                width: 120            }, {
                field: "OrderLineStatus",
                title: "Order Line Status",
                width: 150
            }, {                field: "Price",                attributes: {class: "numbers"},                template: "#=kendo.toString(Price, 'n2')#",                title: "Price",                width: 120            }, {                field: "Qty",                attributes: {class: "numbers"},                template: "#=kendo.toString(Qty, 'n0')#",                title: "Quantity",                width: 120            }, {                field: "Discount",                attributes: {class: "numbers"},                template: "#=kendo.toString(Discount, 'n0')#",                title: "Discount",                width: 120            }, {                field: "ExtendedPrice",                attributes: {class: "numbers"},                template: "#=kendo.toString(ExtendedPrice, 'n2')#",                title: "Extended Price",                width: 120            }];

            $("<div/>").appendTo(ev.detailCell).kendoGrid({
                autoBind: true,
                columns: detailColumns,
                dataSource: getDetailDS(ev),
                scrollable: true,
                selectable: false,
                height: 300,
                pageable: {
                    pageSize: 10,
                    pageSizes: [10, 20, 30]
                }
            });
        }

        masterGrid.getKendoGrid().one("dataBound", function(e) {
            this.element.find("tbody tr:first").addClass("k-state-selected");
            var row = this.element.find("tr:first");
            var rowData = masterGrid.getKendoGrid().dataSource.data()[0];
            masterGrid.select(row);
            primaryVM.set("selectedRow", rowData);
        });

        // Moves grid pager to the footer.
        var pager = masterGrid.find(".k-grid-pager");
        if (pager) {
            pager.appendTo($(viewName + " div[name=MasterGridPager]"));
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
        // Bind the observable to the view.
        kendo.bind($(viewName), primaryVM);
        showGrid(); // Initialize grids.

        // Customize the Name field to utilize a remote entity.
        var custName = spark.field.createResourceAutoComplete(viewName + " form[name=searchForm] input[name=CustName]", {
            dataTextField: "CustNum", // Value to use after selection.
            filterField: "CustName", // Field to search on (custom property).
            pageSize: 20, // Return result sets of 20 records at a time.
            placeholder: "Search by Customer", // Hint displayed when empty.
            resourceName: "customer", // Remote resource (custom property).
            resourceTable: "ttCustomer", // Temp-table name (custom property).
            template: "#=CustNum# - #=CustName#" // Template for dropdown options.
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
