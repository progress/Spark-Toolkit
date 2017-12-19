$(document).ready(function(){
    // Keep hidden until ready.
    $("#errorContent").hide();
    $("#mainContent").hide();

    // Create session, perform login, and init screen.
    var serviceName = window.location.pathname ? window.location.pathname.split("/")[1] : "";
    var serviceURI = "/WebWizard/"; // Set based on the prepared WAR file.
    var catalogURI = "/WebWizard/web/pdo/wizard";
    var authModel = progress.data.Session.AUTH_TYPE_FORM;

    // Create authentication provider, obtains anonymous access to back-end.
    spark.setCredentials("wizard", "bravepoint");
    spark.checkAuthentication(serviceURI, authModel)
        .then(function(authProvider, result, info){
            // If able to get anonymous access, create JSDO session and obtain catalog.
            spark.createSession(serviceURI, catalogURI, authModel)
                .then(function(){
                    initScreen(); // Initialize screen when session is ready.
                    $("#mainContent").show();
                });
        }, function(error){
            console.warn(error);
            var h2 = $("<h2></h2>").text("System Error").addClass("m-t-lg");
            var p = $("<p></p>").text("Unable to authenticate.").addClass("text-lg text-muted");
            var output = $("<div></div>").addClass("text-center").append(h2, p);
            $("#errorContent").html(output);
            $("#errorContent").show();
        });
});

// Primary screen initialization.
function initScreen(){
    var component = {}; // List of components on the screen.
    var wizardJSDO = new progress.data.JSDO({name: "wizard"});
    var catalogPath = ""; // Placeholder for API-returned variable.

    var dsResource = new kendo.data.DataSource();
    var dsTemplates = new kendo.data.DataSource();
    var dsCSS = new kendo.data.DataSource();
    var dsIncludes = new kendo.data.DataSource();
    var dsParams = new kendo.data.DataSource();
    var dsSchemaDataset = new kendo.data.DataSource();
    var dsSchemaTables = new kendo.data.DataSource();
    var dsMetadata = new kendo.data.DataSource();
    var dsDatabase = new kendo.data.DataSource();
    var dsMasterTables = new kendo.data.DataSource();
    var dsDetailTables = new kendo.data.DataSource();
    var dsMasterFields = new kendo.data.DataSource();
    var dsDetailFields = new kendo.data.DataSource();
    var dsMasterKeys = new kendo.data.DataSource();
    var dsDetailKeys = new kendo.data.DataSource();

    var JSDOCatalog = {
        _service: null,
        _resource: null,
        _operation: null,
        data: "",
        setData: function(data){
            // Transform data as needed for viewer.
            $.each((data.services || []), function(i, service){
                $.each((service.resources), function(j, resource){
                    $.each((resource.operations || []), function(k, operation){
                        if (!operation.name) {
                            // Provide a name for the operation if not present.
                            operation.name = operation.type;
                        }
                    });
                });
            });
            this.data = data;
        },
        getService: function(index){
            if (!index) { index = 0; }
            return (this.data.services || [])[index] || {};
        },
        setContext: function(serviceIndex, resourceName, operationName){
        	if (serviceIndex === null) {
            	for (var i=0; i<this.data.services.length; i++) {
            		this._service = this.getService(i);
                    if (this._service.resources) {
                        $.each(this._service.resources, function(j, resource){
                            if (resource.name === resourceName) {
                            	serviceIndex = i;
                            }
                        });
                    }
    			}
            }

        	this._service = this.getService(serviceIndex);

            if (!$.isEmptyObject(this._service)) {
                this._resource = ($.grep(this._service.resources, function(e){ return e.name === resourceName; }))[0] || null;
            } else {
                this._resource = null;
            }

            if (this._resource) {
                this._operation = ($.grep(this._resource.operations, function(e){ return e.name === operationName; }))[0] || null;
                if (!this._operation) {
                    // Otherwise location operation by type (typical for CRUD).
                    this._operation = ($.grep(this._resource.operations, function(e){ return e.type === operationName; }))[0] || null;
                }
            } else {
                this._operation = null;
            }
        },
        getResource: function(){
            return this._resource || null;
        },
        getOperation: function(){
            return this._operation || null;
        },
        getSchema: function(){
            return ((this._resource || {}).schema || {}).properties || null;
        },
        getBaseURL: function(){
            return protocol + "//" + origin + "/" + this._service.name + this._service.address;
        },
        getOperationURL: function(){
            return this.getBaseURL() + (this._resource.path || "") + (this._operation.path || "");
        },
        getAllResourceNames: function(){
			var options = [];
			for (var i=0; i<this.data.services.length; i++) {
                var service = this.getService(i);
                if (service.resources) {
                    $.each(service.resources, function(j, resource){
                        if (resource.name !== "wizard") {
                            options.push(resource.name);
                        }
                    });
                }
			}
			return options.sort();
        }
    };

    var viewModel = kendo.observable({
        flags: {
            showInstructions: true, // Display basic instructions.
            canGenerate: false,     // Denotes user can generate code.
            useCatalog: false,      // Can use catalog data.
            useResourceName: false, // Can select a catalog resource.
            useTemplate: false,     // Can select a template.
            useDataChoice: false,   // Can choose data source for BE.
            useSchema: false,       // Can choose schema file for BE.
            useDatabase: false,     // Can select a database.
            useEntityName: false,   // Can specify an alternate entity name.
            useEntityTbl: false,    // Can select an entity table (BE-only).
            useServiceURI: false,   // Can supply a service URI (BE-only).
            useCustomCSS: false,    // Can select a custom CSS file.
            useMasterSel: false,    // Can select a master table (CRUD).
            useDetailSel: false,    // Can select a detail table (CRUD, HasRelation)
            useKeySelect: false,    // Can select a master/detail join.
            useSearchFld: false,    // Can select a primary search field.
            useInvokeOpt: false,    // Can select options for invoke.
            useMetadata: false      // Can select previous metadata options.
        },
        params: {
            ipGenBE: "UI from Catalog",
            ipTemplateName: "",
            ipMetadata: "",
            ipDataSource: "",
            ipCatalog: catalogPath,
            ipServiceURI: "/web/pdo/common",
            ipResourceMaster: "",
            ipResourceDetail: "",
            ipDatabase: "",
            ipCSSFile: "",
            ipEntityTable: [],
            ipMasterTable: "",
            ipMasterFields: [],
            ipMasterFieldsRaw: "",
            ipDetailTable: "",
            ipDetailFields: [],
            ipDetailFieldsRaw: "",
            ipSearchField: "",
            ipMasterKey: "",
            ipDetailKey: "",
            ipTTDefFileName: "",
            ipInvokeDSName: "",
            ipInvokeTTName: "",
            ipEntityName: "",
            ipSearchField1: "",
            ipSearchField2: "",
            ipSearchField3: ""
        },
        templateData: {},
        enableFields: function(){
            var data = this.toJSON();
            var params = data.params;
            var flags = data.flags;
            if (params.ipResourceMaster) {
                var template = data.templateData || {};
                flags.useCustomCSS = (template.EntityType === "CRUD");
                flags.useEntityName = (template.EntityType === "CRUD" && !template.HasRelation);
                flags.useMasterSel = (template.EntityType === "CRUD");
                flags.useDetailSel = (template.TemplateID === "Custom" || template.HasRelation);
                flags.useSearchFld = (template.EntityType === "CRUD");
                flags.useKeySelect = (template.HasRelation);
            }
            // Remember if resource name should be used.
            var service = JSDOCatalog.getService();
            flags.useResourceName = (!$.isEmptyObject(service));
            this.set("flags", flags);
        },
        generateCode: function(ev, useTheForce){
            // Isolate the params object, and send stringified to server.
            var self = this;
            var params = this.toJSON().params;
            if (params.ipResourceMaster !== "") {
                // Using catalog resource, but no fields selected for master table.
                if (params.ipMasterTable !== "" && params.ipMasterFields.length === 0) {
                    this.selectAllMaster(); // Select all available fields.
                }

                // Using catalog resource, but no fields selected for detail table.
                if (params.ipDetailTable !== "" && params.ipDetailFields.length === 0) {
                    this.selectAllDetail(); // Select all available fields.
                }

                // Set entity name as based on selected resources.
                if (params.ipEntityName === "") {
                    this.set("params.ipEntityName", spark.toProperCase(params.ipResourceMaster) + spark.toProperCase(params.ipResourceDetail));
                }

                // Set the catalog-provided URL of the service.
                if (JSDOCatalog._service.name !== "") {
                	this.set("params.ipServiceURI", "/" + JSDOCatalog._service.name);
                } else {
                	this.set("params.ipServiceURI", "/web/pdo/common");
                }

                // Obtain new params values after modifications above.
                params = this.toJSON().params;
            }
            var options = {paramObject: JSON.stringify(params), forceCreate: useTheForce || false};
            wizardJSDO.invoke("generate", options)
                .then(function(jsdo, result, request){
                    // Success, display any applicable notices to user.
                    var response = (request.response) ? request.response : request;
                    var message = (response.resultMessage || "Generation Success!");
                    if (message.startsWith("Error:")) {
                        if (response.resultCode === -205) {
                            if (confirm("One or more files already exist, and have been modified since they were originally created. "
                                      + "Are you sure you wish to overwrite these existing files?") === true) {
                                setTimeout(function(){
                                    self.generateCode(null, true);
                                });
                            }
                        } else {
                            showStaticNotification(kendo.toString(new Date(), 'HH:MM:ss: ') + message, "warning");
                        }
                    } else {
                        showStaticNotification(kendo.toString(new Date(), 'HH:MM:ss: ') + message, "success");
                    }
                }, function(){
                    // Failure
                    showStaticNotification(kendo.toString(new Date(), 'HH:MM:ss: ') + "Generation Failed!", "error");
                });
        },
        getCatalogData: function(){
            var self = this;
            var params = this.toJSON().params;
            if (params.ipCatalog !== "") {
                var success = function(data, textStatus, jqXHR){
                    if (textStatus !== "success") {
                        alert("Error retrieving catalog.");
                    } else {
                        // Add data to the local catalog object.
                        JSDOCatalog.setData(data);

                        // Set values as needed.
						dsResource.data(JSDOCatalog.getAllResourceNames());
                        self.set("flags.useResourceName", true);

                        // Update the screen with new resources.
                        checkValues();
                    }
                };
                $.get(params.ipCatalog, null, success, "json");
            }
        },
        resetAll: function(ev, ipGenBE){
            // Resets the entire screen back to a default state.
            $("#globalForm")[0].reset();
            $("#wizardForm")[0].reset();
            setTimeout(function(){
                viewModel.set("params", {
                    ipGenBE: ipGenBE || "UI from Catalog",
                    ipTemplateName: "",
                    ipMetadata: "",
                    ipDataSource: "",
                    ipCatalog: catalogPath,
                    ipServiceURI: "/web/pdo/common",
                    ipResourceMaster: "",
                    ipResourceDetail: "",
                    ipDatabase: "",
                    ipCSSFile: "",
                    ipEntityTable: [],
                    ipMasterTable: "",
                    ipMasterFields: [],
                    ipMasterFieldsRaw: "",
                    ipDetailTable: "",
                    ipDetailFields: [],
                    ipDetailFieldsRaw: "",
                    ipSearchField: "",
                    ipMasterKey: "",
                    ipDetailKey: "",
                    ipTTDefFileName: "",
                    ipInvokeDSName: "",
                    ipInvokeTTName: "",
                    ipEntityName: "",
                    ipSearchField1: "",
                    ipSearchField2: "",
                    ipSearchField3: ""
                });
                viewModel.set("flags.useTemplate", true);
                viewModel.resetViewFlags();
            }, 10);
        },
        resetWizard: function(){
            // Resets only the details portion of the screen.
            $("#wizardForm")[0].reset(); // Reset the form.

            // Reset observable properties.
            var oldParams = this.get("params");
            var newParams = {
                ipGenBE: oldParams.ipGenBE || "UI from Catalog",
                ipTemplateName: oldParams.ipTemplateName || "",
                ipTemplateName: "",
                ipMetadata: "",
                ipDataSource: "",
                ipCatalog: catalogPath,
                ipServiceURI: "/web/pdo/common",
                ipResourceMaster: "",
                ipResourceDetail: "",
                ipDatabase: "",
                ipCSSFile: "",
                ipEntityTable: [],
                ipMasterTable: "",
                ipMasterFields: [],
                ipMasterFieldsRaw: "",
                ipDetailTable: "",
                ipDetailFields: [],
                ipDetailFieldsRaw: "",
                ipSearchField: "",
                ipMasterKey: "",
                ipDetailKey: "",
                ipTTDefFileName: "",
                ipInvokeDSName: "",
                ipInvokeTTName: "",
                ipEntityName: "",
                ipSearchField1: "",
                ipSearchField2: "",
                ipSearchField3: ""
            };
            this.set("params", newParams);

            // Reset the data in certain dataSources.
            dsMasterTables.data([]);
            dsDetailTables.data([]);
            dsMasterFields.data([]);
            dsDetailFields.data([]);
            dsMasterKeys.data([]);
            dsDetailKeys.data([]);
        },
        resetTableOptions: function(){
            // Use flags to hide certain fields for now.
            var flags = this.toJSON().flags;
            this.set("flags", $.extend(flags, {
                useEntityName: false,
                useMasterSel: false,
                useDetailSel: false,
                useKeySelect: false,
                useSearchFld: false
            }));

            // Reset certain fields on change.
            var params = this.toJSON().params;
            this.set("params", $.extend(params, {
                ipEntityName: "",
                ipMasterTable: "",
                ipDetailTable: "",
                ipMasterFields: "",
                ipMasterFieldsRaw: "",
                ipDetailFields: "",
                ipDetailFieldsRaw: "",
                ipMasterKey: "",
                ipDetailKey: "",
                ipSearchField: ""
            }));
            this.resetAllMaster();
            this.resetAllDetail();
        },
        resetViewFlags: function(){
            // Resets flags that indicate which options are visible.
            var flags = this.toJSON().flags;
            this.set("flags", $.extend(flags, {
                useCatalog: false,
                useResourceName: false,
                useDataChoice: false,
                useSchema: false,
                useDatabase: false,
                useEntityName: false,
                useEntityTbl: false,
                useServiceURI: false,
                useCustomCSS: false,
                useMasterSel: false,
                useDetailSel: false,
                useKeySelect: false,
                useSearchFld: false,
                useInvokeOpt: false,
                useMetadata: false,
                showInstructions: true
            }));
            checkValues();
        },
        selectAllMaster: function(){
            // Selects all master field for multi-select.
            if (this.get("params.ipMasterTable") !== "") {
                var fld = component.ipMasterFields.getKendoMultiSelect();
                var data = fld.dataSource.data();
                var options = [];
                $.each(data, function(i, record){
                    options.push(record.fieldName);
                });
                fld.value(options);
                this.set("params.ipMasterFields", options);
            }
        },
        resetAllMaster: function(){
            // Resets all master field for multi-select.
            component.ipMasterFields.getKendoMultiSelect().value([]);
            this.set("params.ipMasterFields", "");
        },
        selectAllDetail: function(){
            // Selects all detail field for multi-select.
            if (this.get("params.ipDetailTable") !== "") {
                var fld = component.ipDetailFields.getKendoMultiSelect();
                var data = fld.dataSource.data();
                var options = [];
                $.each(data, function(i, record){
                    options.push(record.fieldName);
                });
                fld.value(options);
                this.set("params.ipDetailFields", options);
            }
        },
        resetAllDetail: function(){
            // Resets all detail field for multi-select.
            component.ipDetailFields.getKendoMultiSelect().value([]);
            this.set("params.ipDetailFields", "");
        }
    });
    kendo.bind($("#mainContent"), viewModel); // Bind model to screen content.

    function checkValues(){
        // Must use a timeout to allow observable object time to update.
        setTimeout(function(){
            // Sets and checks conditions to allow user to generate.
            var data = viewModel.toJSON();
            var flags = data.flags;
            var params = data.params;
            var database = params.ipDatabase || "";
            var template = params.ipTemplateName || "";

            // Has no template selection (when applicable).
            var noTemplate = (params.ipGenBE === "UI from Catalog" && template === "");

            // Generate when template is an invokable pattern.
            var isBlank = params.ipTemplateName.startsWith("TemplateBlank");

            // Generate when template is an invokable pattern.
            var invokeable = (params.ipTemplateName === "TemplateInvoke");

            // Generating BE
            var genBE = (params.ipGenBE === "BE Class File");

            // Generate when generating all BE's for a database.
            var allTables = (genBE && database !== "");

            // Has all fields for CRUD use.
            var crudReady = (params.ipMasterTable !== "" && params.ipSearchField !== "");

            // Has custom schema chosen.
            var hasSchema = (genBE && params.ipInvokeTTName);

            // Generate from previous metadata (no user selections necessary).
            var withMetadata = ((params.ipMetadata || "") !== "");

            // Generate if special SPA page types.
            var isLogin = (template === "TemplateLoginSPA");
            var isLanding = (template === "TemplateLandingSPA");

            // Update flags as necessary from derived data above.
            viewModel.set("flags.useEntityTbl", (database !== ""));
            viewModel.set("flags.useServiceURI", genBE);
            viewModel.set("flags.showInstructions", (noTemplate || (noTemplate && !genBE)));
            viewModel.set("flags.canGenerate", (invokeable || hasSchema || allTables || isBlank || crudReady || withMetadata || isLogin || isLanding));
        }, 10);
    }

    function setDefaults(defaults){
        // Must use a timeout to allow observable object time to udpate.
        setTimeout(function(){
            var params = viewModel.get("params");
            $.each(defaults, function(i, defaultParam){
                var valuePair = defaultParam.split("|");
                var defaultName = valuePair[0] || "";
                var defaultValue = valuePair[1] || "";
                if (defaultName !== "") {
                    // Update the model parameter value.
                    params[defaultName] = defaultValue;
                    var fld = $("#wizardForm input[name=" + defaultName + "]");
                    if (fld) {
                        // If field exists, update the screen value.
                        switch(defaultName){
                            case "ipCSSFile":
                                component.ipCSSFile.getKendoDropDownList().value(defaultValue);
                                break;
                            case "ipTTDefFileName":
                                component.ipTTDefFileName.getKendoDropDownList().value(defaultValue);
                                break;
                            default:
                                fld.val(defaultValue); // Update input field as-is.
                        }
                    }
                }
            });
            viewModel.set("params", params);
        }, 10);
    }

    function showStaticNotification(message, type){
        if (component.staticNotification) {
            component.staticNotification.show(message, type || "info");
            var container = $(component.staticNotification.options.appendTo);
            container.scrollTop(container[0].scrollHeight);
        }
    }

    /***** Screen Components *****/

    var _loadCount = 0; // Start at 1 for page loaded.
    var _loadTotal = 5; // Number of items to pre-load.
    function updateLoadPercent(){
        _loadCount++;
        if (_loadCount >= _loadTotal) {
            $("#loadingMsg").hide();
        } else {
            var pb = $("#progressBar").data("kendoProgressBar");
            if (!pb) {
                pb = $("#progressBar").kendoProgressBar({
                    min: 5,
                    max: 100,
                    type: "percent",
                    animation: {
                        duration: 400
                    }
                }).data("kendoProgressBar");
            } else {
                pb.value(Math.floor((_loadCount / _loadTotal) * 100));
            }
        }
    }

    function createComponents(){
        updateLoadPercent(); // Start the progress bar.

        component.ipGenBE = $("#globalForm select[name=ipGenBE]").kendoDropDownList({
            dataSource: ["UI from Catalog", "BE Class File"],
            select: function(e){
                var self = this;
                var item = e.item || {};
                var value = item.text();

                // Change of option requires reset of screen (complete).
                viewModel.resetAll(null, value);

                setTimeout(function(){
                    // Must use a timeout to allow observable object time to udpate.
                    self.value(value);
                    if (value === "BE Class File") {
                        // For BE-Only, allow selection of table(s) for generation.
                        viewModel.set("flags.useDataChoice", true); // Is required.
                        viewModel.set("flags.useTemplate", false); // Not required.
                    } else if (value === "UI from Catalog") {
                        // For the UI-Only mode, require selection of a template.
                        viewModel.set("flags.useDataChoice", false); // Not shown.
                        viewModel.set("flags.useTemplate", true); // Is required.
                    } else {
                        alert("Feature not yet implemented.");
                    }
                    checkValues();
                }, 20);
            }
        });

        component.staticNotification = $("#staticNotification").kendoNotification({
            appendTo: "#appendto", // Element that gets new messages.
            autoHideAfter: 0, // Do not dismiss messages automatically.
            button: true // Display hide button to let user dismiss.
        }).data("kendoNotification");

        component.ipTemplateName = $("#globalForm select[name=ipTemplateName]").kendoDropDownList({
            dataSource: dsTemplates,
            dataTextField: "TemplateLabel",
            dataValueField: "TemplateID",
            optionLabel: "- Select a Template -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                var item = e.item || {};
                var templateData = this.dataItem(item.index() + 1);
                if (item.text() !== "- Select a Template -") {
                    // Reset the details portion of the screen.
                    viewModel.resetWizard();
                    viewModel.resetViewFlags();
                    viewModel.set("templateData", templateData);

                    // Enable specific options based on template type.
                    if (templateData.EntityType === "CRUD") {
                        // CRUD relies on table selections.
                        viewModel.set("flags.useCustomCSS", true);
                        viewModel.set("flags.useCatalog", true);
                    } else if (templateData.EntityType === "Blank") {
                        // Display only CSS and EntityName field.
                        viewModel.set("flags.useCustomCSS", true);
                        viewModel.set("flags.useEntityName", true);
                    } else if (templateData.EntityType === "Invoke") {
                        // Display special panel for invoke parameters.
                        viewModel.set("flags.useInvokeOpt", true);
                        viewModel.set("flags.useSearchFld", true);
                        getIncludes(); // Get list of include files.
                    } else if (templateData.EntityType === "Metadata") {
                        getMetadata(); // Load current metadata files.
                        viewModel.set("flags.useMetadata", true);
                    } else {
                        // Placeholder for currently-unsupported types.
                    }

                    // Keep the resource field enabled if a service is available.
                    var service = JSDOCatalog.getService();
                    if (!$.isEmptyObject(service)) {
                        // Always use resource if catalog data present.
                        viewModel.set("flags.useResourceName", true);
                    }
                    if (templateData.EntityType === "Invoke" || (templateData.IsSPA && templateData.RoleSPA === "Landing")) {
                        // Always disable if Invoke entity or SPA landing template.
                        viewModel.set("flags.useResourceName", false);
                    }

                    // Add any default params to the model.
                    if ((templateData.Defaults || []).length > 0) {
                        setDefaults(templateData.Defaults);
                    }
                }
                checkValues();
            }
        });

        component.ipMetadata = $("#globalForm select[name=ipMetadata]").kendoDropDownList({
            dataSource: dsMetadata,
            dataTextField: "fileName",
            dataValueField: "filePath",
            optionLabel: "- Select File -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                checkValues();
            }
        });

        component.ipCSSFile = $("#wizardForm input[name=ipCSSFile]").kendoDropDownList({
            dataSource: dsCSS,
            optionLabel: "- Select CSS -",
            valuePrimitive: true // Allows initial value to be nullable
        });

        component.ipTTDefFileName = $("#wizardForm input[name=ipTTDefFileName]").kendoDropDownList({
            dataSource: dsIncludes,
            dataTextField: "fileName",
            dataValueField: "filePath",
            optionLabel: "- Select File -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                var item = e.item || {};
                var filePath = (this.dataItem(item.index() + 1) || {}).filePath || null;
                if (filePath) {
                    parseInclude(filePath);
                }
            }
        });

        component.ipInvokeDSName = $("#wizardForm input[name=ipInvokeDSName]").kendoDropDownList({
            dataSource: dsSchemaDataset,
            optionLabel: "- Select Dataset -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
            	checkValues();
            }
        });

        component.ipInvokeTTName = $("#wizardForm input[name=ipInvokeTTName]").kendoDropDownList({
            dataSource: dsSchemaTables,
            optionLabel: "- Select Table -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
            	checkValues();
            }
        });

        component.ipSearchField1 = $("#wizardForm input[name=ipSearchField1]").kendoDropDownList({
            dataSource: dsParams,
            optionLabel: "- Select Value -",
            valuePrimitive: true // Allows initial value to be nullable
        });

        component.ipSearchField2 = $("#wizardForm input[name=ipSearchField2]").kendoDropDownList({
            dataSource: dsParams,
            optionLabel: "- Select Value -",
            valuePrimitive: true // Allows initial value to be nullable
        });

        component.ipSearchField3 = $("#wizardForm input[name=ipSearchField3]").kendoDropDownList({
            dataSource: dsParams,
            optionLabel: "- Select Value -",
            valuePrimitive: true // Allows initial value to be nullable
        });

        component.ipDataSource = $("#wizardForm input[name=ipDataSource]").kendoDropDownList({
            dataSource: ["Database Table", "ProDataset"],
            optionLabel: "- Select Data Source -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                var item = e.item || {};
                var value = item.text();
                // Change of option requires reset of screen (broad).
                setTimeout(function(){
                    // Must use a timeout to allow observable object time to udpate.
                    if (value === "Database Table") {
                        // For database, allow selection of table(s) for generation.
                        viewModel.set("flags.useDatabase", true); // Is required.
                        viewModel.set("flags.useSchema", false); // Not required.
                    } else if (value === "ProDataset") {
                        // For all other modes, require selection of an include file.
                        viewModel.set("flags.useDatabase", true); // Is required.
                        viewModel.set("flags.useSchema", true); // Is required.
                        getIncludes(); // Get list of include files.
                    }

                    // Reset values related to catalog/resource data.
                    viewModel.set("params.ipDatabase", "");
                    viewModel.set("params.ipResourceMaster", "");
                    viewModel.set("params.ipResourceDetail", "");
                    JSDOCatalog.setData({});

                    // Reset and re-enable fields.
                    viewModel.resetTableOptions();
                    checkValues();
                }, 10);
            }
        });

        component.ipResourceMaster = $("#wizardForm input[name=ipResourceMaster]").kendoDropDownList({
            dataSource: dsResource,
            optionLabel: "- Select a Resource -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                // Get item value.
                var item = e.item || {};
                var value = item.text();
                // Change of option requires reset of screen (limited).
                setTimeout(function(){
                    // Get names of tables from resource schema for selection.
                    if (value) {
                        JSDOCatalog.setContext(null, value);
                        var schema = JSDOCatalog.getSchema() || {};
                        var datasetName = Object.getOwnPropertyNames(schema).sort()[0];
                        var tables = [];
                        if (datasetName) {
                            var dataset = schema[datasetName] || {};
                            tables = Object.getOwnPropertyNames(dataset.properties).sort();
                        }
                        var data = []; // Options for tables.
                        $.each(tables, function(i, table){
                            data.push({tableName: table});
                        });
                        dsMasterTables.data(data);
                    }

                    // Reset and re-enable fields.
                    viewModel.resetTableOptions();
                    viewModel.enableFields();
                    checkValues();
                }, 10);
            }
        });

        component.ipResourceDetail = $("#wizardForm input[name=ipResourceDetail]").kendoDropDownList({
            dataSource: dsResource,
            optionLabel: "- Select a Resource -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                // Get item value.
                var item = e.item || {};
                var value = item.text();
                // Change of option requires reset of screen (limited).
                setTimeout(function(){
                    // Get names of tables from resource schema for selection.
                    if (value) {
                        JSDOCatalog.setContext(null, value);
                        var schema = JSDOCatalog.getSchema() || {};
                        var datasetName = Object.getOwnPropertyNames(schema).sort()[0];
                        var tables = [];
                        if (datasetName) {
                            var dataset = schema[datasetName] || {};
                            tables = Object.getOwnPropertyNames(dataset.properties).sort();
                        }
                        var data = []; // Options for tables.
                        $.each(tables, function(i, table){
                            data.push({tableName: table});
                        });
                        dsDetailTables.data(data);
                    }
                    checkValues();
                }, 10);
            }
        });

        component.ipDatabase = $("#wizardForm input[name=ipDatabase]").kendoDropDownList({
            dataSource: dsDatabase,
            optionLabel: "- Select a Database -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                var item = e.item || {};
                getTables(item.text());
                checkValues();
            }
        });

        component.ipEntityTable = $("#wizardForm input[name=ipEntityTable]").kendoMultiSelect({
            autoClose: false,
            dataSource: dsMasterTables,
            dataTextField: "tableName",
            dataValueField: "tableName",
            placeholder: "Click here to select tables or leave blank to use all.",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                var item = e.item || {};
                checkValues();
            }
        });

        component.ipMasterTable = $("#wizardForm input[name=ipMasterTable]").kendoDropDownList({
            dataSource: dsMasterTables,
            dataTextField: "tableName",
            dataValueField: "tableName",
            optionLabel: "- Select a Table -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                var item = e.item || {};
                var value = item.text();
                var params = viewModel.toJSON().params;
                if (params.ipResourceMaster && params.ipResourceMaster !== "") {
                    JSDOCatalog.setContext(null, params.ipResourceMaster);
                    var schema = JSDOCatalog.getSchema() || {};
                    var datasetName = Object.getOwnPropertyNames(schema).sort()[0];
                    if (datasetName) {
                        var dataset = schema[datasetName] || {};
                        var table = dataset.properties[value] || {};
                        var fields = (table.items || {}).properties || {};
                        var data = [];
                        delete fields._id;
                        delete fields._errorString;
                        delete fields.id;
                        delete fields.rid;
                        delete fields.seq;
                        $.each(fields, function(field){
                            if (!field.startsWith("_")) {
                                data.push({fieldName: field});
                            }
                        });
                        setFieldData("master", data, data);
                        viewModel.set("params.ipMasterFieldsRaw", JSON.stringify(fields));
                    }
                }
                viewModel.set("params.ipMasterFields", "");
                viewModel.set("params.ipMasterKey", "");
                viewModel.set("params.ipSearchField", "");
                checkValues();
            }
        });

        component.ipDetailTable = $("#wizardForm input[name=ipDetailTable]").kendoDropDownList({
            dataSource: dsDetailTables,
            dataTextField: "tableName",
            dataValueField: "tableName",
            optionLabel: "- Select a Table -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                var item = e.item || {};
                var value = item.text();
                var params = viewModel.toJSON().params;
                if (params.ipResourceDetail && params.ipResourceDetail !== "") {
                    JSDOCatalog.setContext(null, params.ipResourceDetail);
                    var schema = JSDOCatalog.getSchema() || {};
                    var datasetName = Object.getOwnPropertyNames(schema).sort()[0];
                    if (datasetName) {
                        var dataset = schema[datasetName] || {};
                        var table = dataset.properties[value] || {};
                        var fields = (table.items || {}).properties || {};
                        var data = [];
                        delete fields._id;
                        delete fields._errorString;
                        delete fields.id;
                        delete fields.seq;
                        $.each(fields, function(field){
                            if (!field.startsWith("_")) {
                                data.push({fieldName: field});
                            }
                        });
                        setFieldData("detail", data, data);
                        viewModel.set("params.ipDetailFieldsRaw", JSON.stringify(fields));
                    }
                }
                viewModel.set("params.ipDetailFields", "");
                viewModel.set("params.ipDetailKey", "");
                checkValues();
            }
        });

        component.ipMasterFields = $("#wizardForm input[name=ipMasterFields]").kendoMultiSelect({
            autoClose: false,
            dataSource: dsMasterFields,
            dataTextField: "fieldName",
            dataValueField: "fieldName",
            placeholder: "Click here to select fields, use the Select All button, or leave blank to use all.",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                checkValues();
            }
        });

        component.ipDetailFields = $("#wizardForm input[name=ipDetailFields]").kendoMultiSelect({
            autoClose: false,
            dataSource: dsDetailFields,
            dataTextField: "fieldName",
            dataValueField: "fieldName",
            placeholder: "Click here to select fields, use the Select All button, or leave blank to use all.",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                checkValues();
            }
        });

        component.ipSearchField = $("#wizardForm input[name=ipSearchField]").kendoDropDownList({
            dataSource: dsMasterFields,
            dataTextField: "fieldName",
            dataValueField: "fieldName",
            optionLabel: "- Select a Field -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                checkValues();
            }
        });

        component.ipMasterKey = $("#wizardForm input[name=ipMasterKey]").kendoDropDownList({
            dataSource: dsMasterKeys,
            dataTextField: "fieldName",
            dataValueField: "fieldName",
            optionLabel: "- Select a Field -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                checkValues();
            }
        });

        component.ipDetailKey = $("#wizardForm input[name=ipDetailKey]").kendoDropDownList({
            dataSource: dsDetailKeys,
            dataTextField: "fieldName",
            dataValueField: "fieldName",
            optionLabel: "- Select a Field -",
            valuePrimitive: true, // Allows initial value to be nullable
            select: function(e){
                checkValues();
            }
        });
    }

    function setFieldData(tableType, fields, keys){
        if (tableType === "master") {
            // Update only the master datasources.
            dsMasterFields.data(fields);
            dsMasterKeys.data(keys);
        } else if (tableType === "detail") {
            // Update only the detail datasources.
            dsDetailFields.data(fields);
            dsDetailKeys.data(keys);
        } else {
            // Update all datasources with fields.
            dsMasterFields.data(fields);
            dsMasterKeys.data(keys);
            dsDetailFields.data(fields);
            dsDetailKeys.data(keys);
        }
    }

    /***** Data Operations *****/

    /* Fetch data immediately, no parameters needed. */
    wizardJSDO.invoke("templates", {})
        .then(function(jsdo, result, request){
            var data = request.response || {};
            var templates = data.Template || null;
            if (templates && templates.Template) {
                // Table may be nested, bring it to the surface.
                templates = templates.Template;
            }
            if (data && data.DefaultCatalog) {
                // Grab the default catalog and update the UI.
                catalogPath = data.DefaultCatalog;
                viewModel.set("params.ipCatalog", catalogPath);
            }
            dsTemplates.data(templates || []);

            // Default to single-table mode and display templates.
            viewModel.set("flags.useTemplate", true);
            updateLoadPercent(); // Increment loading progress bar.
            fetchDefaults(); // Load any remaining defaults.
        });

    function fetchDefaults(){
        /* Fetches data immediately, no parameters needed. */
        wizardJSDO.invoke("css", {})
            .then(function(jsdo, result, request){
                var data = (request.response || {}).cssList || null;
                if (data && typeof(data) === "string") {
                    try {
                        data = JSON.parse(data);
                    } catch(e){}
                }
                dsCSS.data(data || []);

                // Re-select last value after load of data.
                var cssFile = viewModel.get("params").ipCSSFile;
                component.ipCSSFile.getKendoDropDownList().value(cssFile);
                updateLoadPercent(); // Increment loading progress bar.
            });

        /* Fetches data immediately, no parameters needed. */
        wizardJSDO.invoke("databases", {})
            .then(function(jsdo, result, request){
                var data = (request.response || {}).databaseList || null;
                if (data && typeof(data) === "string") {
                    try {
                        data = JSON.parse(data);
                    } catch(e){}
                }
                dsDatabase.data(data || []);
                updateLoadPercent(); // Increment loading progress bar.
            });

        /* Fetches data immediately, no parameters needed. */
        wizardJSDO.invoke("tooltips", {})
            .then(function(jsdo, result, request){
                var data = (request.response || {}).tooltipData || null;
                if (data && typeof(data) === "string") {
                    try {
                        data = JSON.parse(data);
                    } catch(e){}
                }
                $.each(data, function(fieldName, toolText){
                    component.metadataTooltip = $("#" + fieldName + "Tooltip").kendoTooltip({
                        animation: false,
                        content: toolText,
                        position: "top",
                        width: 200
                    });
                });
                updateLoadPercent(); // Increment loading progress bar.
            });
    }

    function getMetadata(){
        /* Fetch data to get latest values. */
        wizardJSDO.invoke("metadata", {})
            .then(function(jsdo, result, request){
                var data = (request.response || {}).metadataList || null;
                if (data && typeof(data) === "string") {
                    try {
                        data = JSON.parse(data);
                    } catch(e){}
                }
                dsMetadata.data(data);
            });
    }

    function getIncludes(){
        /* Fetch data to get latest values. */
        wizardJSDO.invoke("includes", {})
            .then(function(jsdo, result, request){
                var data = (request.response || {}).includeList || null;
                if (data && typeof(data) === "string") {
                    try {
                        data = JSON.parse(data);
                    } catch(e){}
                }
                dsIncludes.data(data || []);
            });
    }

    function parseInclude(filePath){
    	// Display a progress bar while parsing include.
    	var overlayObj = $("#wizardForm");
        kendo.ui.progress(overlayObj, true);

        wizardJSDO.invoke("parse", {includePath: filePath})
        .then(function(jsdo, result, request){
            var data = (request.response || {}).includeData || null;
            if (data && typeof(data) === "string") {
                try {
                    data = JSON.parse(data);
                } catch(e){}
            }

            // Extract names of datasets from object.
            var datasets = [];
            $.each(data.datasets, function(name, tables){
            	datasets.push(name);
            });

            // Update datasources for dropdowns.
            dsSchemaDataset.data(datasets);
            dsSchemaTables.data(data.tables);
            dsParams.data(data.inputs);

            // Dismiss progress bar to continue.
            kendo.ui.progress(overlayObj, false);
        }, function(){
        	// Hide progress bar on failure.
        	kendo.ui.progress(overlayObj, false);
        });
    }

    function getTables(databaseName){
        /* Fetch data when parameter is available. */
        wizardJSDO.invoke("tables", {databaseName: databaseName})
            .then(function(jsdo, result, request){
                var data = (request.response || {}).ttSchema || null;
                if (data && data.ttSchema) {
                    data = data.ttSchema;
                }
                dsMasterTables.data(data);
                dsDetailTables.data(data);
            });
    }

    function getFields(databaseName, tableName, tableType){
        /* Fetch data when parameter is available. */
        wizardJSDO.invoke("fields", {databaseName: databaseName, tableName: tableName})
            .then(function(jsdo, result, request){
                var data = (request.response || {}).ttSchema || null;
                if (data && data.ttSchema) {
                    data = data.ttSchema;
                }
                var keys = [];
                $.each(data, function(i, field){
                    if (field.isIndexed) {
                        keys.push(field);
                    }
                });
                setFieldData(tableType, data, keys);
           });
    }

    /***** Initialization *****/

    createComponents();
}