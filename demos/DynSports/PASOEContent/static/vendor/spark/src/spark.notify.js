/**
 * @file Singleton object for displaying on-screen messages.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($, kendo){
    "use strict";

    if ($ && kendo && window.spark) {

        /**
         * Notification operations for PMFO.
         * @namespace spark.notify
         * @memberof spark
         */
        window.spark.notify = {

            /**
             * Sets a specific DOM element for handling notification events.
             * @method spark.notify.setNotificationArea
             * @memberof spark.notify
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} options Properties for widget
             * @returns {Object} [kendo.ui.Notification]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/notification}
             */
            setNotificationArea: function(selector, options){
                var notificationObj = null; // Notification object instance.
                var el = $(selector);
                if (el.length) {
                    // Create a new notification widget.
                    notificationObj = el.kendoNotification($.extend({
                        appendTo: selector, // Element that anchors all messages.
                        autoHideAfter: 30000, // Hide the message after 30 seconds.
                        button: true // Display dismissal button in message area.
                    }, options)).getKendoNotification();

                    // Add a method to display a message and scroll into view.
                    notificationObj.showNotification = function(message, type){
                        var self = this;
                        if (self) {
                            try {
                                // Type is "info" (default), "success", "warning", or "error".
                                if (typeof(message) === "string" && message !== "") {
                                    // Single message as string.
                                    self.show(message, type || "info");
                                } else if (Array.isArray(message)) {
                                    $.each(message, function(i, msg){
                                        // Message is an array of strings.
                                        if (msg !== "") {
                                            self.show(msg, type || "info");
                                        }
                                    });
                                }
                                if (self.options && self.options.appendTo) {
                                    var container = $(self.options.appendTo);
                                    if (container.length) {
                                        container.scrollTop(container[0].scrollHeight);
                                    }
                                }
                            } catch(e){
                                console.log(e);
                            }
                        }
                    };
                }
                return notificationObj;
            },

            /**
             * Checks a response object for a potential "_errors" property, and messages with an info type.
             * @method spark.notify.responseHasInfo
             * @memberof spark.notify
             * @param {Object} responseObject Response object from AJAX call
             * @returns {boolean}
             */
            responseHasInfo: function(responseObject){
                // If present, _errors should be an array.
                var errorArray = (responseObject || {})._errors || [];
                var hasInfo = false;
                var errorType = null;

                // Cycle through array, if not a null set.
                $.each(errorArray, function(i, error){
                    // Each error object should have an _errorType.
                    errorType = error._errorType || "";
                    if (errorType === "INFORMATION" || errorType === "SUCCESS") {
                        hasInfo = true; // Only set if locating an info type.
                    }
                });
                return hasInfo;
            },

            /**
             * Checks a response object for a potential "_errors" property, and messages with an error type.
             * @method spark.notify.responseHasErrors
             * @memberof spark.notify
             * @param {Object} responseObject Response object from AJAX call
             * @returns {boolean}
             */
            responseHasErrors: function(responseObject){
                // If present, _errors should be an array.
                var errorArray = (responseObject || {})._errors || [];
                var hasErrors = false;
                var errorType = null;

                // Cycle through array, if not a null set.
                $.each(errorArray, function(i, error){
                    // Each error object should have an _errorType.
                    errorType = error._errorType || "";
                    if (errorType === "ERROR" || errorType === "FATAL" || errorType === "TRACE") {
                        hasErrors = true; // Only set if locating an error/fatal type.
                    }
                });
                return hasErrors;
            }

        }; // window.spark.notify

    } // if
})(window.jQuery, window.kendo);
