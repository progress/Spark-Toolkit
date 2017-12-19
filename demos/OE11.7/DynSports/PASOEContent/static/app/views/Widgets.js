var WidgetsCtrl = (function(){
    "use strict";

    var viewName = "#WidgetsView";

    var primaryVM = kendo.observable({
        context: {},
        params: {
            country: "USA",
            stateProvince: "",
            salesrep: "",
            digitInput: "",
            standardDate: ""
        },
        modalTarget: "",
        doSubmit: function(ev){
            /**
             * Perform a "submit" of a form by gathering the current values,
             * but will first attempt to validate the form using any custom
             * rules (if provided) or standard rules (such as required files).
             */
            var validationOptions = {
                rules: {
                    isValidDate: function(input){
                        var name = $(input).attr("name");
                        if (name !== "") {
                            // Use the field name to get the underlying value.
                            var data = primaryVM.toJSON().params;
                            var value = data[name] || input.val();
                            if (value !== "") {
                                // Check date validity on a per-field basis.
                                var isValid = true;
                                switch(name){
                                    case "standardDate":
                                        // Should only allow valid dates.
                                        isValid = kendo.parseDate(value);
                                        break;
                                }
                                return isValid;
                            }
                        }
                        return true;
                    }
                },
                messages: {
                    isValidDate: function(){
                        // Return a translated string on each failure.
                        return app.getText("Date is invalid");
                    }
                }
            };
            if (spark.form.validate(viewName + " form[name=widgetForm]", validationOptions)) {
                console.log(this.toJSON().params);
            }
        },
        doReset: function(ev){
            // Reset the form using a standard method call.
            spark.form.reset(viewName + " form[name=widgetForm]");
        },
        goHome: function(ev){
            // Perform a navigation back to the application start.
            app.navigateTo("#\/");
        },
        openSearchModal: function(ev){
            // Opens modal via JavaScript and resets the screen.
            $("#SalesRepModal").modal("show");

            // Trigger initialization of modal elements.
            modalSalesRepSearchCtrl.init();

            // Reset on-screen modal elements.
            modalSalesRepSearchCtrl.vm.doReset();
        },
        openUploadModal: function(ev){
            // Opens modal via JavaScript and resets the screen.
            $("#UploadModal").modal("show");

            // Trigger initialization of modal elements.
            modalUploadCtrl.init();

            // Reset on-screen modal elements.
            modalUploadCtrl.vm.doReset();
        }
    });

    function createWidgets(){
        /**
         * Convert all fields with "datePicker" class to standard date picker.
         * This should use the current culture to dictate what format the date
         * will be displayed as, along with what formats will be accepted by
         * the field for conversion (US, European, ISO, 2/4-digit year, etc).
         * The format "ddd, MMM dd, yyyy" shows as "Wed, Jan 18, 2017"
         */
        spark.field.createDatePicker(viewName + " .datePicker", {format: "ddd, MMM dd, yyyy"});

        /**
         * Convert an input to a selection field, which provides data to the
         * widget via simple array. This example illustrates the dynamic
         * loading of data in another field after a selection is made.
         */
        var countryList = spark.field.createSimpleLookup(viewName + " input[name=countryList]", {
            dataSource: ["USA", "Canada"],
            select: function(ev){
                if (ev && ev.item) {
                    var item = ev.item || {};
                    var value = item.text();
                    stateProvinceList.fetchData({country: value || ""});
                }
            }
        });

        /**
         * Convert an input to a selection field, which provides data to the
         * widget via an invoke operation. This should convert the returned
         * array of objects into a dataSource, using the given text/value
         * field names to drive the respective display or underlying value.
         */
        var stateProvinceList = spark.field.createInvokeLookup(viewName + " input[name=stateProvinceList]", {
            autoBind: true,
            dataTextField: "FullName",
            dataValueField: "Abbrev",
            invokeResource: "locality",
            invokeMethod: "stateProvince",
            invokeDataProperty: "states",
            optionLabel: " ",
            params: {country: "USA"},
            placeholder: "Select State/Province"
        });

        /**
         * Convert an input to a selection field, which uses the Read operation
         * of a resource to populate the list. This special use case includes
         * default criteria for limiting results.
         */
        var salesRep = spark.field.createResourceLookup(viewName + " input[name=salesrepList]", {
            dataTextField: "RepName",
            dataValueField: "SalesRep",
            filter: {
                field: "SalesRep",
                operator: "startsWith",
                value: "d"
            },
            resourceName: "salesrep",
            resourceTable: "ttSalesrep",
            optionLabel: "Search by Sales Rep",
            template: "#=SalesRep# - #=RepName#",
            valueTemplate: "#=SalesRep# - #=RepName#"
        });

        /**
         * @TODO: Need the following examples:
         * -Popup (modal) search launched from an icon beside a text field (populate with choice).
         */
    }

    function init(){
        // Bind the observable to the view.
        kendo.bind($(viewName), primaryVM);

        // Convert HTML to Kendo widgets.
        createWidgets();

        // Obtain session info locally, as opposed to a remote API call.
        app.getSessionInfo(true)
            .then(function(session, matches, loggedIn){
                // Export all page information for sample usage/display.
                $("#pageInfo").html("Page: " + app.currentPage.name + "<br/>Path: " + app.currentPage.path
                                             + "<br/>Params: " + JSON.stringify(app.currentPage.params)
                                             + "<br/>Logged In: " + loggedIn);
            });

        /**
         * Convert an input to a filtered field, which will only accept a subset
         * of possible values (in this case only digits). This can be adjusted
         * via the regex "filter" property. Events such as when the user presses
         * "Enter" or performs a keypress will also fire when necessary. Some
         * events will trigger automatically after the specified "delay" value,
         * which is time in miliseconds after no keypress events are detected.
         */
        var digitKeyOptions = {
            delay: 400,
            filter: /[0-9]/g,
            onEnter: function(){
                // Perform immediate search on Enter key.
                var value = $(viewName + " input[name=digitInput]").val() || "";
                console.info("Entered:", value);
            },
            onValidKey: function(){
                // Update the VM value after each keypress, as this is not
                // normally updated until focus is removed from the field.
                var value = $(viewName + " input[name=digitInput]").val() || "";
                console.info("Validated:", value);
            }
        }
        spark.field.addKeypressEvent(viewName + " input[name=digitInput]", digitKeyOptions);
    }

    function loadTemplates(){
        // Load additional templates for this view (including any modals).

        // Inject an external HTML page into the current view, in element with ID of "fileupload".
        spark.loader.loadExtInclude("app/common/SalesRepSearch.html", "salesrepSearch")
            .then(function(){
                // When loading of HTML is complete, prepare to receive events from modal.
                modalSalesRepSearchCtrl.vm.bind("modalDataReady", function(ev){
                    // When event "modalDataReady" is triggered by the modal,
                    // perform some action here (within the calling view).
                    primaryVM.set("params.salesrep", (ev.data || {}).SalesRep);
                });
            });

        // Inject an external HTML page into the current view, in element with ID of "fileupload".
        spark.loader.loadExtInclude("app/common/FileUpload.html", "fileupload")
            .then(function(){
                // When loading of HTML is complete, prepare to receive events from modal.
                modalUploadCtrl.vm.bind("modalDataReady", function(ev){
                    // When event "modalDataReady" is triggered by the modal,
                    // perform some action here (within the calling view).
                    app.showMessage(ev.data, "success");
                });
            });
    }

    return {
        init: init,
        loadTemplates: loadTemplates
    };

})();
