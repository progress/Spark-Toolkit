var <Spark_TemplateName>Ctrl = (function(){
    "use strict";

    var resourceName = "<Spark_ResourceName>";
    var searchField1 = "<Spark_SearchField1>";
    var searchTitle = "<Spark_SearchField1Title>";
    var datasetName = "ds<Spark_MasterTable>";
    var tableName = "tt<Spark_MasterTable>";
    var viewName = "#<Spark_TemplateName>View";
    var searchOnLoad = false;

    var primaryVM = kendo.observable({
        mode: null,
        params: {
            searchValue: ""
        },
        selectedRow: {},
        doSearch: function(ev){
            if (spark.form.validate(viewName + " form[name=searchForm]")) {
                var self = this;
                var params = this.toJSON().params || {};
                if ((params.searchValue || "") !== "") {
                    var options = $.extend({}, spark.optionDefaults);
                    var jsdo = getDataSource().options.transport.jsdo;
                    options.filterQuery = "where " + searchField1 + " eq '" + params.searchValue + "'";
                    spark.jsdo_read(jsdo, options)
                        .done(function(jsdo, success, request){
                            var record = (jsdo.getData() || [])[0] || null;
                            if (record) {
                                self.set("mode", null);
                                self.set("selectedRow", record);
                            } else {
                                self.set("mode", null);
                                self.set("selectedRow", {});
                            }
                        });
                }
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
            if (data.mode === "new") {
                options.data = data.selectedRow;
                spark.jsdo_create(jsdo, options)
                    .done(function(jsdo, success, request){
                        alert("Record successfully created.");
                    });
            } else {
                options.id = data.selectedRow._id || "";
                options.data = data.selectedRow || {};
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
            // Create the primary datasource.
            _primaryDS = spark.createJSDODataSource(resourceName, {
                pageSize: 100,
                sort: {field: searchField1, dir: "asc"},
                tableRef: tableName
            });
        }
        return _primaryDS;
    }

    function init(){
        // Bind the observable to the view.
        kendo.bind($(viewName), primaryVM);
        getDataSource(); // Initialize datasource.

        primaryVM.set("params.searchValue", spark.getQueryStringValue(searchField1) || "");
        if (searchOnLoad) {
            primaryVM.doSearch(); // Perform an initial search to populate the form.
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

    function loadTemplates(){
        // Load additional templates for header/footer.
    }

    return {
        init: init,
        loadTemplates: loadTemplates
    };

})();
