var SecurityRulesCtrl = (function(){
    "use strict";

    var viewName = "#SecurityRulesView";
    var _accessJSDO = null;

    var primaryVM = kendo.observable({
        rule: {
            index: null,
            transportName: "",
            interceptURI: "",
            httpMethod: "",
            accessRule: ""
        },
        addRule: function(){
            // Create a new rule and show editor.
            this.set("rule.index", -1);
            this.set("rule.transportName", "");
            this.set("rule.interceptURI", "");
            this.set("rule.httpMethod", "*");
            this.set("rule.accessRule", "");
            $(viewName + " form[name=editForm]").removeClass("none");
        },
        editRule: function(){
            // Set current rule and show editor.
            var index = _rules.select().index() || -1;
            if (index >= 0) {
                var dataItem = _rules.dataSource.view()[index] || {};
                this.set("rule.index", index);
                this.set("rule.transportName", dataItem.transportName || "");
                this.set("rule.interceptURI", dataItem.interceptURI || "");
                this.set("rule.httpMethod", dataItem.httpMethod || "");
                this.set("rule.accessRule", dataItem.accessRule || "");
                $(viewName + " form[name=editForm]").removeClass("none");
            }
        },
        saveRule: function(){
            if (spark.form.validate(viewName + " form[name=editForm]")) {
                var rule = primaryVM.toJSON().rule || {index: null};
                var data = _rules.dataSource.data();
                var index = rule.index || -1;
                delete rule.index;
                if (index >= 0) {
                    // Replace existing rule with new data.
                    data[index] = $.extend({ruleOrder: 0}, rule);
                } else {
                    // Add new rule just before the last element of the data array.
                    _rules.dataSource.insert(data.length-1, $.extend({ruleOrder: 0}, rule));
                }
                _rules.dataSource.data(data);
                $(viewName + " form[name=editForm]").addClass("none");
            }
        },
        cancelEdit: function(){
            $(viewName + " form[name=editForm]").addClass("none");
        },
        getRules: function(){
            if (_accessJSDO && _rules) {
                _accessJSDO.invoke("rules", {})
                    .then(function(jsdo, result, request){
                        var rules = (request.response || {}).rules || [];
                        _rules.dataSource.data(rules);
                    });
            }
        },
        setRules: function(){
            if (_accessJSDO && _rules) {
                var data = _rules.dataSource.data();
                _accessJSDO.invoke("apply", {rules: data})
                    .then(function(jsdo, result, request){
                        var success = (request.response || {}).success || false;
                        if (success) {
                            app.showMessage("Rules updated successfully.", "success");
                            primaryVM.getRules(); // Re-fetch rules from server.
                        } else {
                            app.showMessage("Rules could not be updated.", "warning");
                        }
                    });
            }
        }
    });

    var _rules = null;
    function createWidgets(){
        _rules = $(viewName + " select[name=rules]").kendoListBox({
            dataSource: new kendo.data.DataSource(),
            draggable: true,
            template: function(row){
                return (row.transportName + ": " + row.interceptURI + ", " + row.httpMethod + ", " + row.accessRule);
            },
            toolbar: {
                tools: ["moveUp", "moveDown", "remove"]
            },
            width: 300,
            reorder: function(ev) {
                ev.preventDefault();
                var dataSource = ev.sender.dataSource;
                var dataItem = ev.dataItems[0];
                var index = dataSource.indexOf(dataItem) + ev.offset;
                dataSource.remove(dataItem);
                dataSource.insert(index, dataItem);
            }
        }).getKendoListBox();

        // Fetch rules from server.
        primaryVM.getRules();
    }

    function init(){
        // Bind the observable to the view.
        kendo.bind($(viewName), primaryVM);

        // Create a JSDO instance.
        _accessJSDO = spark.createJSDO("access");

        // Convert HTML to Kendo widgets.
        createWidgets();

        var transportName = spark.field.createSimpleLookup(viewName + " input[name=transportName]", {
            dataSource: ["APSV", "REST", "SOAP", "WEB", "STATIC", "DEFAULT"],
            select: function(ev){
                if (ev && ev.item) {
                    if (primaryVM.get("rule.index") === -1) {
                        // Provide default starting point when adding new rule.
                        switch(ev.item.text()){
                            case "APSV":
                                primaryVM.set("rule.interceptURI", "/apsv/");
                                break;
                            case "REST":
                                primaryVM.set("rule.interceptURI", "/rest/");
                                break;
                            case "SOAP":
                                primaryVM.set("rule.interceptURI", "/soap/");
                                break;
                            case "WEB":
                                primaryVM.set("rule.interceptURI", "/web/");
                                break;
                            case "STATIC":
                                primaryVM.set("rule.interceptURI", "/static/");
                                break;
                            default:
                                primaryVM.set("rule.interceptURI", "/");
                                break;
                        }
                    }
                }
            }
        });

        var httpMethod = spark.field.createSimpleLookup(viewName + " input[name=httpMethod]", {
            dataSource: ["*", "GET", "POST", "PUT", "DELETE"]
        });
    }

    return {
        init: init
    };

})();
