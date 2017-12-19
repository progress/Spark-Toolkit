/**
 * @file Singleton object for common form operations.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($){
    "use strict";

    if ($ && window.spark) {

        // Protected variable to track translated strings.
        var _translatedStrings = {};

        // Protected variable to track translations requests.
        var _translationRequests = [];

        // Implement polyfill for browsers that don't support "startsWith" (looking at you, IE).
        if (!String.prototype.startsWith) {
            String.prototype.startsWith = function(searchString, position) {
                position = position || 0;
                return this.indexOf(searchString, position) === position;
            };
        }

        /**
         * String operations for PMFO.
         * @namespace spark.strings
         * @memberof spark
         */
        window.spark.strings = {

            // Track all translations requests.
            trackTranslations: false,

            /**
             * Add additional strings to the internal list of translated strings.
             * @method addTranslatedStrings
             * @memberof spark.strings
             * @param {Object} newStrings New collection of translated strings to add to internal library
             * @returns void
             */
            addTranslatedStrings: function(newStrings){
                if (typeof newStrings === "object") {
                    _translatedStrings = $.extend(_translatedStrings, newStrings);
                }
            },

            /**
             * Obtain a translated string from the internal library.
             * @method getTranslatedString
             * @memberof spark.strings
             * @param {Object} newStrings New collection of translated strings to add to internal library
             * @returns {string} Translated string, if original text exists; otherwise returns original
             */
            getTranslatedString: function(originalText){
                // Potentially remember this translation.
                window.spark.strings.trackTranslation(originalText);

                if (_translatedStrings && _translatedStrings[originalText]) {
                    // Return a string from internal library.
                    return _translatedStrings[originalText];
                }

                // Otherwise returns original text, as-is.
                return originalText;
            },

            /**
             * Track or return requests for translated strings.
             * @method trackTranslation
             * @memberof spark.strings
             * @param {string} translationRequest String requested for translation use
             * @returns {Array(string)} List of translated string requests
             */
            trackTranslation: function(translationRequest){
                if (window.spark.strings.trackTranslations) {
                    // Proceed with tracking if variable has been set.
                    if (translationRequest && translationRequest !== "" &&
                            _translationRequests.indexOf(translationRequest) === -1) {
                        // Remember this unique string if not already tracked.
                        _translationRequests.push(translationRequest);
                    }
                }
                return _translationRequests;
            }

        }; // window.spark.strings

    } // if
})(window.jQuery);
