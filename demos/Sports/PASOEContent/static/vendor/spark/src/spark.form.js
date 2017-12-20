/**
 * @file Singleton object for common form operations.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($, kendo){
    "use strict";

    if ($ && kendo && window.spark) {

        /**
         * Form operations for PMFO.
         * @namespace spark.form
         * @memberof spark
         */
        window.spark.form = {

            /**
             * Perform an action on Enter keypress.
             * @method doOnEnter
             * @memberof spark.form
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Function} callback Properties for widget
             * @param {Object} target Target for keypress event
             * @returns void
             */
            doOnEnter: function(selector, callback, target){
                var el = $(selector);
                if (el.length) {
                    el.on("keypress", function(ev){
                            var keyCode = (ev.keyCode ? ev.keyCode : ev.which);
                            if (keyCode === 13) {
                                if (callback && typeof callback === "function") {
                                    setTimeout(function(){
                                        callback.apply(target || this, [ev]);
                                    }, 20);
                                }
                            }
                        });
                }
            },

            /**
             * Perform an action on form Submit.
             * @method doOnSubmit
             * @memberof spark.form
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Function} callback Properties for widget
             * @param {Object} target Target for keypress event
             * @returns void
             */
            doOnSubmit: function(selector, callback, target){
                var el = $(selector);
                if (el.length) {
                    el.on("submit", function(ev){
                            ev.preventDefault();
                            if (callback && typeof callback === "function") {
                                callback.apply(target || this, [ev]);
                            }
                        });
                }
            },

            /**
             * Returns (after createion, as necessary) a Kendo Validator object.
             * @method getValidator
             * @memberof spark.form
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} options Properties for widget
             * @returns {Object} [kendo.ui.Validator]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/validator}
             */
            getValidator: function(selector, options){
                // Create a validator object for the given selector.
                var el = $(selector);
                if (el.length) {
                    if (el.getKendoValidator() && !options) {
                        // Return the selector's validator if it exists and no options present.
                        return el.getKendoValidator();
                    }
                    // Otherwise create a new validator (with options) on the given selector.
                    return el.kendoValidator($.extend({}, options)).getKendoValidator();
                }
                return null;
            },

            /**
             * Performs a form reset while clearing any existing validator messages.
             * @method reset
             * @memberof spark.form
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} options Properties for widget
             * @returns void
             */
            reset: function(selector, options){
                // Reset form and hide messages.
                var el = $(selector);
                if (el.length) {
                    var validator = window.spark.form.getValidator(selector, options);
                    if (validator) {
                        // Reset form fields.
                        if (el[0] && el[0].reset) {
                            el[0].reset();
                        }
                        // Hide/clear messages.
                        validator.hideMessages();
                    }
                }
            },

            /**
             * Execute the [validate method]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/validator#methods-validate} on an existing Kendo Validator.
             * @method validate
             * @memberof spark.form
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} options Properties for widget
             * @returns {boolean} Result of validation
             */
            validate: function(selector, options){
                // Validate the given selector via validator instance.
                var validator = window.spark.form.getValidator(selector, options);
                if (validator && validator.validate) {
                    // Return the result of the validate method.
                    return validator.validate();
                }
                return false;
            },

            /**
             * Execute the [errors method]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/validator#methods-errors} on an existing Kendo Validator.
             * @method getErrors
             * @memberof spark.form
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @returns {Array(Object)} Array of validation errors
             */
            getErrors: function(selector){
                // Obtain the validator on the given selector.
                var validator = window.spark.form.getValidator(selector, {});
                if (validator && validator.errors) {
                    // Return the result of the errors method.
                    return validator.errors();
                }
                return [];
            },

            /**
             * Perform standardized validation on a grouping of fields, based on element type.
             * @method translateForm
             * @memberof spark.form
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Function} translator Translation function to use for modifying strings
             * @returns void
             */
            translateForm: function(selector, translator, options){
                /**
                 * Translate a form's input fields, looking for placeholder
                 * properties and required validation messages in particular.
                 */
                var inputs = $(selector + " input");
                $.each(inputs, function(i, el){
                    var req = $(el).attr("required");
                    var drm = $(el).attr("data-required-msg");
                    if (drm && drm !== "") {
                        // Translate specific message if available.
                        $(el).attr("data-required-msg", translator(drm));
                    }

                    var ph = $(el).attr("placeholder");
                    if (ph && ph !== "") {
                        // Translate any placeholder text.
                        $(el).attr("placeholder", translator(ph));
                        if (req && !drm) {
                            // Add a proper message for required fields.
                            // Initialize as <placeholder> + "is required".
                            drm = (ph + " is required");
                            $(el).attr("data-required-msg", translator(drm));
                        }
                    }

                    var name = $(el).attr("name");
                    if (name && name !== "") {
                        // Translate based on field name.
                        name = name.replace(/([A-Z])/g, " $1").trim();
                        name = name.replace(/^./, function(str){return str.toUpperCase();});
                        if (!ph) {
                            $(el).attr("placeholder", translator(name));
                        }
                        var drm = $(el).attr("data-required-msg");
                        if (req && !drm) {
                            // Add a proper message for required fields.
                            // Initialize as <name> + "is required".
                            drm = (name + " is required");
                            $(el).attr("data-required-msg", translator(drm));
                        }
                    }
                });

                /**
                 * Translate a form's textarea fields, looking for placeholder
                 * properties and required validation messages in particular.
                 */
                var textarea = $(selector + " textarea");
                $.each(textarea, function(i, el){
                    var req = $(el).attr("required");
                    var drm = $(el).attr("data-required-msg");
                    if (drm && drm !== "") {
                        // Translate specific message if available.
                        $(el).attr("data-required-msg", translator(drm));
                    }

                    var ph = $(el).attr("placeholder");
                    if (ph && ph !== "") {
                        // Translate any placeholder text.
                        $(el).attr("placeholder", translator(ph));
                        if (req && !drm) {
                            // Add a proper message for required fields.
                            // Initialize as <placeholder> + "is required".
                            drm = (ph + " is required");
                            $(el).attr("data-required-msg", translator(drm));
                        }
                    }

                    var name = $(el).attr("name");
                    if (name && name !== "") {
                        // Translate based on field name.
                        name = name.replace(/([A-Z])/g, " $1").trim();
                        name = name.replace(/^./, function(str){return str.toUpperCase();});
                        if (!ph) {
                            $(el).attr("placeholder", translator(name));
                        }
                        var drm = $(el).attr("data-required-msg");
                        if (req && !drm) {
                            // Add a proper message for required fields.
                            // Initialize as <name> + "is required".
                            drm = (name + " is required");
                            $(el).attr("data-required-msg", translator(drm));
                        }
                    }
                });

                /**
                 * Translate a form's label fields, using related fields when linked.
                 */
                var labels = $(selector + " label");
                $.each(labels, function(i, el){
                    var isFor = $(el).attr("for");
                    if (isFor) {
                        // Translate based on label text.
                        $(el).html(translator($(el).html()));

                        if (options && options.showRequiredIndicator) {
                            // Attempt to find an input field for this label.
                            var input = $(selector + " input[name=" + isFor + "]");
                            if (!input.length) {
                                // If not found, try to locate a textarea field.
                                input = $(selector + " textarea[name=" + isFor + "]");
                            }
                            if (input.length && $(input).attr("required")) {
                                // If input is found, add an indicator to the label.
                                $(el).prepend('<span class="text-danger m-r-xxs">' + (options.requiredIndicator || "*") + '</span>');
                            }
                        }
                    }

                    var helpTopic = $(el).attr("help");
                    if (helpTopic) {
                        // Append a help icon to the label, with translated text.
                        var help = $('<i class="fa fa-question-circle m-l-xs" data-container="body" data-placement="top"'
                                   + 'data-toggle="popover" data-trigger="hover" data-content="' + translator(helpTopic) + '"></i>');
                        $(el).append(help);
                    }
                });

                // Convert any new popover widgets.
                $("[data-toggle=popover]").popover();
            }

        }; // window.spark.form

    } // if
})(window.jQuery, window.kendo);
