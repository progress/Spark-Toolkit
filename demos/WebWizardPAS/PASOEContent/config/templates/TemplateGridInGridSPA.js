var <Spark_TemplateName>Ctrl = (function(){
    "use strict";

    var masterResourceName = "<Spark_MasterResource>";
    var detailResourceName = "<Spark_DetailResource>";
    var searchField1 = "<Spark_SearchField1>";
    var searchOper1 = "<Spark_SearchField1Oper>";
    var datasetName = "ds<Spark_MasterTable>";
    var masterTableName = "tt<Spark_MasterTable>";
    var detailTableName = "tt<Spark_DetailTable>";
    var masterKeyName = "<Spark_MasterKey1>";
    var detailKeyName = "<Spark_DetailKey1>";
    var viewName = "#<Spark_TemplateName>View";
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
                        value: params.searchValue
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
            // Create the detail datasource.
            detailDS = spark.createJSDODataSource(detailResourceName, {
                filter: {
                    field: detailKeyName,
                    operator: "eq",
                    value: ev.data[masterKeyName]
                },
                pageSize: 10,
                serverFiltering: true,
                serverPaging: useServerOpts,
                serverSorting: useServerOpts,
                tableRef: detailTableName,
            });
        } else {
            detailDS = new kendo.data.DataSource();
        }
        return detailDS;
    }

    function showGrid(){
        var gridColumns = [<Spark_GridFields>];

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
            var detailColumns = [<Spark_GridFieldsDetail>];

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
    }

    function loadTemplates(){
        // Load additional templates for header/footer.
    }

    return {
        init: init,
        loadTemplates: loadTemplates
    };

})();
