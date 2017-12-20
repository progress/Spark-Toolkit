var WebDataGridCtrl = (function(){
    "use strict";

    var resourceName = "webdata";
    var datasetName = "dsWebDataStore";
    var tableName = "ttWebDataStore";
    var viewName = "#WebDataGridView";
    var searchOnLoad = false;

    var primaryVM = kendo.observable({
        context: {},
        params: {
            sessionID: "",
            objectName: ""
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
                if ((params.sessionID || "") !== "") {
                    filter.push({
                        field: "WebSessionID",
                        operator: "startswith",
                        value: params.sessionID
                    });
                }
                if ((params.objectName || "") !== "") {
                    filter.push({
                        field: "ObjectName",
                        operator: "equals",
                        value: params.objectName
                    });
                }
                getDataSource().filter(filter);
            }
        }
    });

    var _primaryDS = null;
    function getDataSource(){
        if (!_primaryDS) {
            _primaryDS = spark.createJSDODataSource(resourceName, {
                group: { field: "WebSessionID" },
                pageSize: 5,
                sort: {field: "WebSessionID", dir: "asc"},
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
        var gridColumns = [{            field: "WebSessionID",
            hidden: true,            title: "SessionID"        }, {            field: "ObjectName",            title: "Object",            width: 260        }, {            field: "ObjectData",            template: "<pre><code>#=ObjectData.replace(/\\s+/g,' ')#</code></pre>",
            title: "Data",            width: "100%"        }];

        // Create the primary grid component.
        var grid = $(viewName + " div[name=MasterGrid]").kendoGrid({
            autoBind: false,
            columns: gridColumns,
            columnMenu: true,
            dataSource: getDataSource(),
            excel: {
                allPages: true,
                fileName: "Kendo UI Grid Export.xlsx",
                proxyURL: "http://demos.telerik.com/kendo-ui/service/export",
                filterable: true
            },
            filterable: true,
            groupable: false,
            height: "90%",
            pageable: {
                refresh: true,
                pageSizes: [5, 10, 20],
                pageSize: 5,
                buttonCount: 5
            },
            reorderable: true,
            resizable: true,
            scrollable: true,
            selectable: false,
            sortable: true,
            toolbar: ["excel"]
        });

        primaryVM.set("params.sessionID", spark.getQueryStringValue("WebSessionID") || "");
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
        showGrid(); // Initialize grid.
    }

    function loadTemplates(){
        // Load additional templates for header/footer.
    }

    return {
        init: init,
        loadTemplates: loadTemplates
    };

})();
