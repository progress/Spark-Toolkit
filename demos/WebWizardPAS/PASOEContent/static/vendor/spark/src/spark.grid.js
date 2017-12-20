/**
 * @file Singleton object for common grid operations.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($, kendo){
    "use strict";

    if ($ && kendo && window.spark) {

        /**
         * Grid operations for PMFO.
         * @namespace spark.grid
         * @memberof spark
         */
        window.spark.grid = {

            /**
             * Helper method to obtain a selected grid record.
             * @method getSelectedRecord
             * @memberof spark.grid
             * @param {Object} event Event object
             * @returns {Object} Selected record
             */
            getSelectedRecord: function(event, grid){
                if (grid) {
                    // Using grid and row, obtain the current record.
                    var tr = $(event.target).closest("tr");
                    return grid.dataItem(tr);
                } else {
                    // Using the given event, obtain the current record.
                    grid = event.sender;
                    if (grid) {
                        return grid.dataItem(grid.select());
                    }
                }
                return {};
            },

            /**
             * Returns a custom object with common grid state information.
             * @method getViewState
             * @memberof spark.grid
             * @param {Object} grid Grid instance of [kendo.ui.Grid]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/grid}
             * @returns {Object} Object with columns, sort, filter, and group properties
             */
            getViewState: function(grid) {
                if (grid) {
                    return {
                        columns: grid.columns || [],
                        filter: grid.dataSource.filter(),
                        group: grid.dataSource.group(),
                        sort: grid.dataSource.sort()
                    };
                }

                return {
                    columns: null,
                    filter: null,
                    group: null,
                    sort: null
                };
            },

            /**
             * Returns a custom function for managing the change (selection) on a grid.
             * @method getViewState
             * @memberof spark.grid
             * @param {Object} options Specific options for behavior of this method
             * @returns {Object} Function to be performed on grid during change event
             */
            onChange: function(options){
            	return function(ev){
            		var cell = this.select();
            		var selected = $.map(cell, function(item){
            			return $(item).text();
            		});
	                var column = this.columns[cell[0].cellIndex];
	                if (options.callback && typeof(options.callback) === "function") {
	                	options.callback(selected, column);
	                }
	                return (options.returnVal || false);
            	}
            },

            /**
             * Lazy-initializer for creating an "editor" that merely displays the value, and makes the column non-editable by not providing a input field.
             * @method createReadOnlyEditor
             * @memberof spark.grid
             * @returns {Object} Simple text container with column value
             */
            createReadOnlyEditor: function(){
                return function(container, options){
                    container.text(options.model[options.field]);
                }
            },

            /**
             * Lazy-initializer for creating a date editor field.
             * @method createDatePickerEditor
             * @memberof spark.grid
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} Instance of a {@link spark.field.createDatePicker}
             */
            createDatePickerEditor: function(fieldOptions){
                return function(container, options){
                    options.sparkEditor = window.spark.field.createDatePicker($('<input data-bind="value:' + options.field + '"/>').appendTo(container), fieldOptions);
                    setTimeout(function(){
                        var data = options.model[options.field] || options.model.defaults[options.field];
                        options.sparkEditor.value(data);
                    }, 20);
                }
            },

            /**
             * Lazy-initializer for creating an masked text editor field.
             * @method createFormattedFieldEditor
             * @memberof spark.grid
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} Instance of a {@link spark.field.createFormattedField}
             */
            createFormattedFieldEditor: function(fieldOptions){
                return function(container, options){
                    options.sparkEditor = window.spark.field.createFormattedField($('<input data-bind="value:' + options.field + '"/>').appendTo(container), fieldOptions);
                    setTimeout(function(){
                        var data = options.model[options.field] || options.model.defaults[options.field];
                        options.sparkEditor.value(data);
                    }, 20);
                }
            },

            /**
             * Lazy-initializer for creating an editor that utilizes a multi-select dropdown list.
             * @method createMultiLookup
             * @memberof spark.grid
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} Instance of a {@link spark.field.createMultiLookup}
             */
            createMultiLookup: function(fieldOptions){
                return function(container, options){
                    options.sparkEditor = window.spark.field.createMultiLookup($('<input data-bind="value:' + options.field + '"/>').appendTo(container), fieldOptions);
                    setTimeout(function(){
                        /**
                         * Convert comma-delimited data into an array, and assign as
                         * values of the new multi-select field. For some reason we
                         * need to do this with a small delay after widget creation.
                         */
                        var data = options.model[options.field] || options.model.defaults[options.field];
                        if (typeof(data) === "string" && data.indexOf(",") > -1) {
                            data = data.split(",");
                        }
                        options.sparkEditor.value(data);
                    }, 20);
                }
            },

            /**
             * Lazy-initializer for creating an editor that utilizes a simple array or object as options.
             * @method createSimpleLookupEditor
             * @memberof spark.grid
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} Instance of a {@link spark.field.createSimpleLookup}
             */
            createSimpleLookupEditor: function(fieldOptions){
                return function(container, options){
                    options.sparkEditor = window.spark.field.createSimpleLookup($('<input data-bind="value:' + options.field + '"/>').appendTo(container), fieldOptions);
                    setTimeout(function(){
                        var data = options.model[options.field] || options.model.defaults[options.field];
                        options.sparkEditor.value(data);
                    }, 20);
                }
            },

            /**
             * Lazy-initializer for creating an editor that utilizes a name/value pairing as options.
             * @method createSingleLookupEditor
             * @memberof spark.grid
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} Instance of a {@link spark.field.createSingleLookup}
             */
            createSingleLookupEditor: function(fieldOptions){
                return function(container, options){
                    options.sparkEditor = window.spark.field.createSingleLookup($('<input data-bind="value:' + options.field + '"/>').appendTo(container), fieldOptions);
                    setTimeout(function(){
                        var data = options.model[options.field] || options.model.defaults[options.field];
                        options.sparkEditor.value(data);
                    }, 20);
                }
            },

            /**
             * Lazy-initializer for creating an editor that utilizes an invoke method to populate options.
             * @method createInvokeLookupEditor
             * @memberof spark.grid
             * @param {Object} fieldOptions Properties for widget
             * @returns {Object} Instance of a {@link spark.field.createInvokeLookup}
             */
            createInvokeLookupEditor: function(fieldOptions){
                return function(container, options){
                    options.sparkEditor = window.spark.field.createInvokeLookup($('<input data-bind="value:' + options.field + '"/>').appendTo(container), fieldOptions);
                }
            }

        }; // window.spark.grid

    } // if
})(window.jQuery, window.kendo);
