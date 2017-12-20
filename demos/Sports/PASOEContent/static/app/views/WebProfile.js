var WebProfileCtrl = (function(){
    "use strict";

    var resourceName = "webprofile";
    var searchField1 = "Username";
    var searchTitle = "Username";
    var searchOper1 = "startswith";
    var datasetName = "dsWebProfile";
    var tableName = "ttWebProfile";
    var viewName = "#WebProfileView";

    var primaryVM = kendo.observable({
        mode: null,
        params: {
            Username: ""
        },
        selectedRow: {
            UserNum: null,
            Username: "",
            DomainName: "",
            Password: "",
            ResetCode: "",
            FirstName: "",
            LastName: "",
            IsActive: false,
            IsLocked: false,
            UseTFA: false,
            TFAMethod: "",
            TFAToken: "",
            TFASecret: "",
            Email: "",
            CompanyName: "",
            JobTitle: "",
            HomePhone: "",
            WorkPhone: "",
            MobilePhone: "",
            MobileCarrier: "",
            SecurityQuestion: "",
            SecurityAnswer: "",
            PasswordExpires: null,
            OldPassword: "",
            ForcePWChange: false,
            LockOutDate: null,
            LockOutTime: null,
            SecurityRole: "",
            TaskAdjust: "",
            Comments: "",
            FirstLogin: null,
            LastLogin: null,
            LoginCount: null
        },
        doSearch: function(ev){
            if (spark.form.validate(viewName + " form[name=searchForm]")) {
                var params = this.toJSON().params || {};
                var filter = []; // Add default options here.
                if ((params.Username || "") !== "") {
                    filter.push({
                        field: searchField1,
                        operator: searchOper1,
                        value: params.Username
                    });
                }
                getDataSource().filter(filter);
            }
        },
        cancelEdit: function(ev){
            ev.preventDefault();
            this.set("mode", null);
            spark.form.reset(viewName + " form[name=editForm]");
        },
        createNew: function(ev){
            ev.preventDefault();
            this.set("mode", "new");
            this.set("selectedRow", {
                UserNum: null,
                Username: "",
                DomainName: "",
                Password: "",
                ResetCode: "",
                FirstName: "",
                LastName: "",
                IsActive: false,
                IsLocked: false,
                UseTFA: false,
                TFAMethod: "",
                TFAToken: "",
                TFASecret: "",
                Email: "",
                CompanyName: "",
                JobTitle: "",
                HomePhone: "",
                WorkPhone: "",
                MobilePhone: "",
                MobileCarrier: "",
                SecurityQuestion: "",
                SecurityAnswer: "",
                PasswordExpires: null,
                OldPassword: "",
                ForcePWChange: false,
                LockOutDate: null,
                LockOutTime: null,
                SecurityRole: "",
                TaskAdjust: "",
                Comments: "",
                FirstLogin: null,
                LastLogin: null,
                LoginCount: null
            });
            spark.form.reset(viewName + " form[name=editForm]");
        },
        saveRecord: function(ev){
            ev.preventDefault();
            if (spark.form.validate(viewName + " form[name=editForm]")) {
                var self = this;
                var data = this.toJSON();
                var options = $.extend({}, spark.optionDefaults);
                var jsdo = getDataSource().options.transport.jsdo;
                if (data.mode === "new") {
                    options.data = data.selectedRow;
                    options.useSubmit = true;
                    spark.jsdo_create(jsdo, options)
                        .done(function(jsdo, success, request){
                            alert("Record successfully created.");
                        });
                } else {
                    options.id = data.selectedRow._id || "";
                    options.data = data.selectedRow || {};
                    options.tableRef = tableName;
                    options.useSubmit = true;
                    spark.jsdo_update(jsdo, options)
                        .done(function(jsdo, success, request){
                            alert("Record successfully updated.");
                            self.doSearch(); // Refresh data.
                        });
                }
                this.set("mode", null);
            }
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
                spark.form.reset(viewName + " form[name=editForm]");
                var record = spark.grid.getSelectedRecord(ev);
                primaryVM.set("mode", null);
                primaryVM.set("selectedRow", {
                    UserNum: record.UserNum || null,
                    Username: record.Username || "",
                    DomainName: record.DomainName || "",
                    Password: record.Password || "",
                    ResetCode: record.ResetCode || "",
                    FirstName: record.FirstName || "",
                    LastName: record.LastName || "",
                    IsActive: record.IsActive || false,
                    IsLocked: record.IsLocked || false,
                    UseTFA: record.UseTFA || false,
                    TFAMethod: record.TFAMethod || "",
                    TFAToken: record.TFAToken || "",
                    TFASecret: record.TFASecret || "",
                    Email: record.Email || "",
                    CompanyName: record.CompanyName || "",
                    JobTitle: record.JobTitle || "",
                    HomePhone: record.HomePhone || "",
                    WorkPhone: record.WorkPhone || "",
                    MobilePhone: record.MobilePhone || "",
                    MobileCarrier: record.MobileCarrier || "",
                    SecurityQuestion: record.SecurityQuestion || "",
                    SecurityAnswer: record.SecurityAnswer || "",
                    PasswordExpires: record.PasswordExpires || null,
                    OldPassword: record.OldPassword || "",
                    ForcePWChange: record.ForcePWChange || false,
                    LockOutDate: record.LockOutDate || null,
                    LockOutTime: record.LockOutTime || null,
                    SecurityRole: record.SecurityRole || "",
                    TaskAdjust: record.TaskAdjust || "",
                    Comments: record.Comments || "",
                    FirstLogin: record.FirstLogin || null,
                    LastLogin: record.LastLogin || null,
                    LoginCount: record.LoginCount || null
                });
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
            primaryVM.set("params.Username", spark.getQueryStringValue(searchField1));
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

        var tfaMethod = spark.field.createSimpleLookup(viewName + " form[name=editForm] input[name=TFAMethod]", {
            dataSource: ["Email", "SMS", "Device"],
            optionLabel: "Select Method"
        });

        var mobileCarrier = spark.field.createSingleLookup(viewName + " form[name=editForm] input[name=MobileCarrier]", {
            dataSource: [{
                name: "AT&T",
                value: "txt.att.net"
            }, {
                name: "MetroPCS",
                value: "mymetropcs.com"
            }, {
                name: "Sprint",
                value: "messaging.sprintpcs.com"
            }, {
                name: "T-Mobile",
                value: "tmomail.net"
            }, {
                name: "Verizon",
                value: "vtext.com"
            }, {
                name: "Virgin",
                value: "vmobl.com"
            }],
            dataTextField: "name",
            dataValueField: "value",
            optionLabel: "Select Carrier"
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
