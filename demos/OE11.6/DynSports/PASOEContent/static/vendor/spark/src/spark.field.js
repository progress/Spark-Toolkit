/**
 * @file Singleton object for common field operations.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($, kendo){
    "use strict";

    if ($ && kendo && window.spark) {

        /**
         * Field operations for PMFO.
         * @namespace spark.field
         * @memberof spark
         */
        window.spark.field = {

            /**
             * @description Default field name for lookup text
             * @property {string} lookupTextField
             * @memberof spark.field
             */
            lookupTextField: "name",
            /**
             * @description Default field name for lookup values
             * @property {string} lookupValueField
             * @memberof spark.field
             */
            lookupValueField: "value",
            /**
             * @description Static array of US state abbreviations
             * @property {string[]} USStateList
             * @memberof spark.field
             */
            USStateList: [
                "AL", "AK", "AS", "AZ", "AR",
                "CA", "CO", "CT",
                "DE", "DC",
                "FM", "FL",
                "GA", "GU",
                "HI",
                "ID", "IL",
                "IN", "IA",
                "KS", "KY",
                "LA",
                "ME", "MH", "MD", "MA", "MI", "MN", "MS", "MO", "MP", "MT",
                "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND",
                "OH", "OK", "OR",
                "PW", "PA", "PR",
                "RI",
                "SC", "SD",
                "TN", "TX",
                "UT",
                "VT", "VI", "VA",
                "WA", "WV", "WI", "WY"
            ],

            /**
             * Return the currently-selected record for a data-driven field.
             * @method getSelectedRecord
             * @memberof spark.field
             * @param {Object} field Widget instance
             * @returns {Object} Selected record
             */
            getSelectedRecord: function(field){
                try {
                    if (field.dataSource && field.select) {
                        // Proceed if field has dataSource and select method.
                        var data = field.dataSource.data();
                        if (field.select() > -1 && data.length > 0) {
                            // Return selected data, when present.
                            return data[field.select()];
                        }
                    }
                } catch(e) {}
                return {};
            },

            /**
             * Create a culture-based date picker that understands common input formats.
             * @method createDatePicker
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.DatePicker]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/datepicker}
             */
            createDatePicker: function(selector, fieldOptions){
                var el = $(selector);
                if (el.length) {
                    var patterns = ((kendo.cultures.current || {}).calendar || {}).patterns || {};
                    var primary = patterns.d || "MM/dd/yyyy";
                    return el.kendoDatePicker($.extend({
                        format: primary,
                        parseFormats: [primary, "MM/dd/yyyy", "MM/dd/yy", "yyyy-MM-dd"]
                    }, fieldOptions)).getKendoDatePicker();
                }
                return null;
            },

            /**
             * Create a standard MDY date picker that understands common input formats.
             * @method createDatePickerMDY
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.DatePicker]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/datepicker}
             */
            createDatePickerMDY: function(selector, fieldOptions){
                var el = $(selector);
                if (el.length) {
                    return el.kendoDatePicker($.extend({
                        format: "MM/dd/yyyy",
                        parseFormats: ["MM/dd/yyyy", "MM/dd/yy", "yyyy-MM-dd"]
                    }, fieldOptions)).getKendoDatePicker();
                }
                return null;
            },

            /**
             * Create a masked input field with a specific format.
             * @method createFormattedField
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.MaskedTextBox]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/maskedtextbox}
             */
            createFormattedField: function(selector, fieldOptions){
                var el = $(selector);
                if (el.length) {
                    return el.kendoMaskedTextBox($.extend({
                        mask: fieldOptions.mask || null
                    }, fieldOptions)).getKendoMaskedTextBox();
                }
                return null;
            },

            /**
             * Create a standard text input for phone format.
             * @method createFormattedPhone
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.MaskedTextBox]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/maskedtextbox}
             */
            createFormattedPhone: function(selector, fieldOptions){
                var el = $(selector);
                if (el.length) {
                    return el.kendoMaskedTextBox($.extend({
                        mask: "(000) 000-0000"
                    }, fieldOptions)).getKendoMaskedTextBox();
                }
                return null;
            },

            /**
             * Create a standard text input for SSN format.
             * @method createFormattedSSN
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.MaskedTextBox]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/maskedtextbox}
             */
            createFormattedSSN: function(selector, fieldOptions){
                var el = $(selector);
                if (el.length) {
                    return el.kendoMaskedTextBox($.extend({
                        mask: "000-00-0000"
                    }, fieldOptions)).getKendoMaskedTextBox();
                }
                return null;
            },

            /**
             * Create a standard dropdown for multiple lookup values.
             * @method createMultiLookup
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.MultiSelect]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/multiselect}
             */
            createMultiLookup: function(selector, fieldOptions){
                var el = $(selector);
                if (el.length) {
                    return el.kendoMultiSelect($.extend({
                        autoClose: false,
                        dataSource: new kendo.data.DataSource(), // Standard datasource.
                        dataTextField: window.spark.field.lookupTextField,
                        dataValueField: window.spark.field.lookupValueField,
                        suggest: true,
                        valuePrimitive: true // Allows initial value to be nullable.
                    }, fieldOptions)).getKendoMultiSelect();
                }
                return null;
            },

            /**
             * Create a culture-based date picker that understands common input formats.
             * @method createSimpleLookup
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.MultiSelect]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/multiselect} or [kendo.ui.DropDownList]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/dropdownlist}
             */
            createSimpleLookup: function(selector, fieldOptions){
                // Create a simple dropdown for a single lookup value.
                var el = $(selector);
                if (el.length) {
                    if (fieldOptions.multiple === true) {
                        return el.kendoMultiSelect($.extend({
                            autoClose: false,
                            dataSource: [],
                            suggest: true,
                            valuePrimitive: true // Allows initial value to be nullable.
                        }, fieldOptions)).getKendoMultiSelect();
                    } else {
                        return el.kendoDropDownList($.extend({
                            dataSource: [],
                            suggest: true,
                            valuePrimitive: true // Allows initial value to be nullable.
                        }, fieldOptions)).getKendoDropDownList();
                    }
                }
                return null;
            },

            /**
             * Create a culture-based date picker that understands common input formats.
             * @method createSingleLookup
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.DropDownList]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/dropdownlist}
             */
            createSingleLookup: function(selector, fieldOptions){
                // Create a name/value dropdown for a single lookup value.
                var el = $(selector);
                if (el.length) {
                    return el.kendoDropDownList($.extend({
                        dataSource: new kendo.data.DataSource(), // Standard datasource.
                        dataTextField: window.spark.field.lookupTextField,
                        dataValueField: window.spark.field.lookupValueField,
                        suggest: true,
                        valuePrimitive: true // Allows initial value to be nullable.
                    }, fieldOptions)).getKendoDropDownList();
                }
                return null;
            },

            /**
             * Create a culture-based date picker that understands common input formats.
             * @method createUSStateList
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.DropDownList]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/dropdownlist}
             */
            createUSStateList: function(selector, fieldOptions){
                // Create a common dropdown for US state/province selection.
                var el = $(selector);
                if (el.length) {
                    return el.kendoDropDownList($.extend({
                        dataSource: window.spark.field.USStateList,
                        optionLabel: "Select",
                        valuePrimitive: true // Allows initial value to be nullable.
                    }, fieldOptions)).getKendoDropDownList();
                }
                return null;
            },

            /**
             * Create a culture-based date picker that understands common input formats.
             * @method createInvokeLookup
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.MultiSelect]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/multiselect} or [kendo.ui.DropDownList]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/dropdownlist}
             */
            createInvokeLookup: function(selector, fieldOptions){
                var el = $(selector);
                if (el.length) {
                    // First create as a single-item-selection lookup.
                    var lookup = null;
                    if (fieldOptions.multiple === true) {
                        lookup = el.kendoMultiSelect($.extend({
                            autoClose: false,
                            dataSource: new kendo.data.DataSource(), // Standard datasource.
                            filter: "contains",
                            suggest: true,
                            valuePrimitive: true // Allows initial value to be nullable.
                        }, fieldOptions)).getKendoMultiSelect();
                    } else {
                        lookup = el.kendoDropDownList($.extend({
                            dataSource: new kendo.data.DataSource(), // Standard datasource.
                            filter: "contains",
                            valuePrimitive: true // Allows initial value to be nullable.
                        }, fieldOptions)).getKendoDropDownList();
                    }

                    if (!fieldOptions.invokeResource) {
                        console.log("Resource name was not specified for invoke lookup:", selector);
                        return lookup;
                    }

                    // Perform initial load of data from invoke method.
                    if (lookup && fieldOptions.invokeResource) {
                        lookup._jsdo = window.spark.createJSDO(fieldOptions.invokeResource);
                        if (fieldOptions.invokeMethod) {
                            // Create a method that can be called at-will to update data.
                            lookup.fetchData = function(params){
                                return lookup._jsdo.invoke(fieldOptions.invokeMethod, (params || {}))
                                    .done(function(jsdo, status, request){
                                        var response = request.response || {};
                                        if (fieldOptions.invokeDataProperty) {
                                            // Data should be found within a specific response property.
                                            var data = response[fieldOptions.invokeDataProperty] || [];
                                            lookup.dataSource.data(data);
                                        } else {
                                            // Otherwise use the entire response as-is.
                                            lookup.dataSource.data(response);
                                        }
                                    });
                            };
                            if (fieldOptions.autoBind == undefined || fieldOptions.autoBind === true) {
                                // Perform initial fetch only if autoBind is not present,
                                // or if option is present and explicitly set to true.
                                // Send default params as criteria, when provided.
                                lookup.fetchData(fieldOptions.params || null);
                            }
                        } else {
                            lookup.fetchData = function(params){
                                console.log("Method is not currently configured for use.");
                            };
                            console.log("No method name provided for invoke lookup:", selector);
                        }
                    }
                    return lookup;
                }
                return null;
            },

            /**
             * Create a resource-driven dropdown that will simply load a set of remote data values.
             * @method createResourceLookup
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.DropDownList]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/dropdownlist}
             */
            createResourceLookup: function(selector, fieldOptions){
                if (!fieldOptions.resourceName) {
                    console.log("Resource name was not specified for resource lookup:", selector);
                    return null;
                }

                var el = $(selector);
                if (el.length) {
                    var dsOptions = {
                        transport: {
                            jsdo: window.spark.createJSDO(fieldOptions.resourceName)
                        },
                        type: "jsdo"
                    };
                    delete fieldOptions.resourceName;

                    var jsdoProps = dsOptions.transport.jsdo.getMethodProperties("read");
                    if (jsdoProps && jsdoProps.capabilities) {
                        dsOptions.serverFiltering = (jsdoProps.capabilities || "").indexOf("filter") > -1;
                        dsOptions.serverPaging = (jsdoProps.capabilities || "").indexOf("top") > -1;
                        dsOptions.serverSorting = (jsdoProps.capabilities || "").indexOf("sort") > -1;
                    }
                    if (fieldOptions.resourceTable) {
                        dsOptions.transport.tableRef = fieldOptions.resourceTable;
                        delete fieldOptions.resourceTable;
                    }
                    if (fieldOptions.dataValueField) {
                        dsOptions.sort = {field: fieldOptions.dataValueField, dir: "asc"};
                    }
                    if (fieldOptions.filter) {
                        dsOptions.filter = fieldOptions.filter;
                        delete fieldOptions.filter;
                    }

                    return el.kendoDropDownList($.extend({
                        dataSource: new kendo.data.DataSource(dsOptions),
                        filter: "contains",
                        suggest: true,
                        valuePrimitive: true // Allows initial value to be nullable.
                    }, fieldOptions)).getKendoDropDownList();
                }
                return null;
            },

            /**
             * Create a resource-driven dropdown that will search remotely for matching values.
             * @method createResourceAutoComplete
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} [kendo.ui.AutoComplete]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/autocomplete}
             */
            createResourceAutoComplete: function(selector, fieldOptions){
                var el = $(selector);
                if (el.length) {
                    if (!fieldOptions.resourceName) {
                        console.log("Resource name was not specified for resource auto-complete:", selector);
                        return null;
                    }

                    var dsOptions = {
                        transport: {
                            jsdo: window.spark.createJSDO(fieldOptions.resourceName)
                        },
                        type: "jsdo",
                        requestStart: function(e){
                            var filters = (this.filter() || {}).filters || [];
                            if (filters.length === 0 || (filters[0] || {}).value == "") {
                                // Do not perform a search without a filter!
                                e.preventDefault();
                                return false;
                            } else if (filters.length > 1) {
                                // If more than 1 filter, send the first entry.
                                e.sender.filter(filters[0]);
                                e.preventDefault();
                                return false;
                            }
                        }
                    };
                    delete fieldOptions.resourceName;

                    var jsdoProps = dsOptions.transport.jsdo.getMethodProperties("read");
                    if (jsdoProps && jsdoProps.capabilities) {
                        dsOptions.serverFiltering = (jsdoProps.capabilities || "").indexOf("filter") > -1;
                        dsOptions.serverPaging = (jsdoProps.capabilities || "").indexOf("top") > -1;
                        dsOptions.serverSorting = (jsdoProps.capabilities || "").indexOf("sort") > -1;
                    }
                    if (fieldOptions.pageSize) {
                        dsOptions.pageSize = fieldOptions.pageSize;
                        delete fieldOptions.pageSize;
                    }
                    if (fieldOptions.resourceTable) {
                        dsOptions.transport.tableRef = fieldOptions.resourceTable;
                        delete fieldOptions.resourceTable;
                    }
                    if (fieldOptions.dataValueField) {
                        dsOptions.sort = {field: fieldOptions.dataValueField, dir: "asc"};
                    }
                    if (fieldOptions.dataSourceOptions) {
                        dsOptions = $.extend(dsOptions, fieldOptions.dataSourceOptions);
                        delete fieldOptions.dataSourceOptions;
                    }

                    return el.kendoAutoComplete($.extend({
                        dataSource: new kendo.data.DataSource(dsOptions),
                        delay: 400,
                        filter: "startsWith",
                        minLength: 2,
                        virtual: true,
                        change: function(e) {
                            /**
                             * Reset the filter after each change of data.
                             * Necessary due to filters apparently stacking
                             * up as you change the search value.
                             */
                            //e.sender.dataSource.filter({});
                        },
                        filtering: function(e){
                            /**
                             * Adjust the filter before sending, allowing for the
                             * ability to search on an alternate field--one that
                             * is not the same field to be used as the dataTextField.
                             */
                            var filter = e.filter;
                            if (fieldOptions.filterField) {
                                filter.field = fieldOptions.filterField;
                            }
                            return filter;
                        }
                    }, fieldOptions)).getKendoAutoComplete();
                }
                return null;
            },

            /**
             * Perform some kind of keypress filtering on an element.
             * @method addKeypressEvent
             * @memberof spark.field
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} fieldOptions Properties for widget
             * @returns {boolean} Result of keypress event
             */
            addKeypressEvent: function(selector, fieldOptions){
                var _timeout = null;
                var el = $(selector);
                if (el.length) {
                    if (!fieldOptions.onInvalidKey) {
                        fieldOptions.onInvalidKey = function(ev){
                            if (ev) {
                                ev.preventDefault();
                            }
                            return false; // Ignore any uncaught keys.
                        }
                    }
                    el.keypress(function(ev){
                        if (ev.which !== 0) {
                            var value = String.fromCharCode(ev.which);
                            if (ev.which === kendo.keys.BACKSPACE) {
                                // Allow Backspace as a valid key.
                                clearTimeout(_timeout);
                                _timeout = setTimeout(fieldOptions.onValidKey, fieldOptions.delay || 400);
                            } else if (ev.which === kendo.keys.ENTER) {
                                // Perform action on Enter keypress.
                                clearTimeout(_timeout);
                                _timeout = setTimeout(fieldOptions.onEnter, fieldOptions.delay || 400);
                            } else if (value.match(fieldOptions.filter || /.*/)) {
                                // Filter only certain keys, disallowing all other keys.
                                // Default pattern should match any key not already caught.
                                clearTimeout(_timeout);
                                _timeout = setTimeout(fieldOptions.onValidKey, fieldOptions.delay || 400);
                            } else {
                                return fieldOptions.onInvalidKey.apply(this, [ev]);
                            }
                        }
                    });
                    el.keyup(function(ev){
                        if (ev.which === kendo.keys.DELETE) {
                            // Can only capture the Delete key with "keyup" event.
                            clearTimeout(_timeout);
                            _timeout = setTimeout(fieldOptions.onValidKey, fieldOptions.delay || 400);
                        }
                    });
                    return true;
                }
                return false;
            }

        }; // window.spark.field

    } // if
})(window.jQuery, window.kendo);
