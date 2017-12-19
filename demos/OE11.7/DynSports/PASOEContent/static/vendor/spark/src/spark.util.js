/**
 * @file Singleton object for common utilities.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($, kendo){
    "use strict";

    if ($ && kendo && typeof window.spark !== "undefined") {

        // This should directly extend the existing "spark" object.
        window.spark = $.extend(window.spark, {

            /**
             * Obtain any URL parameters as a JSON object.
             * @method getUrlParams
             * @memberof spark
             * @returns {Object} URL params as JSON object
             */
            getUrlParams: function(){
                /**
                 * A common problem with a common solution:
                 * "Allows for more characters in the search string. It uses a reviver function for URI decoding:"
                 * http://stackoverflow.com/questions/8648892/convert-url-parameters-to-a-javascript-object
                 */
                var /** Object */ retVal = {};
                var params = location.search.substring(1) || "";
                if (params == "") {
                    params = location.hash || "";
                    if (params.indexOf("?") > -1) {
                        params = params.split("?")[1];
                    }
                }
                if (params && params.indexOf("=") > -1) {
                    var paramString = params.replace(/&/g, '","').replace(/=/g,'":"');
                    retVal = JSON.parse('{"' + paramString + '"}', function(key, value){ return key === "" ? value : decodeURIComponent(value) });
                }
                return retVal;
            },

            /**
             * Clear data in the browser's local storage (if available).
             * @method clearPersistentObject
             * @memberof spark
             * @param {string} key - Name of the property to clear.
             * @returns {boolean} Success of operation
             */
            clearPersistentObject: function(key){
                var /** boolean */ retVal = false;
                var storage = window.localStorage || null;
                if (storage && storage.clearObject) {
                    storage.clearObject(key);
                    retVal = true;
                } else if (storage) {
                    delete storage[key];
                    retVal = true;
                } else {
                    // Fall back to using cookies.
                    window.spark.setCookie(key, "");
                    retVal = true;
                }
                return retVal;
            },

            /**
             * Set data in the browser's local storage (if available).
             * @method setPersistentObject
             * @memberof spark
             * @param {string} key - Name of the property to set.
             * @param {string} value - String value to be stored.
             * @returns {boolean} Success of operation
             */
            setPersistentObject: function(key, value){
                var /** boolean */ retVal = false;
                var storage = window.localStorage || null;
                if (storage && storage.getObject) {
                    storage.setObject(key, value);
                    retVal = true;
                } else if (storage) {
                    storage[key] = JSON.stringify(value);
                    retVal = true;
                } else {
                    // Fall back to using cookies.
                    window.spark.setCookie(key, JSON.stringify(value));
                    retVal = true;
                }
                return retVal;
            },

            /**
             * Get data in the browser's local storage (if available).
             * @method getPersistentObject
             * @memberof spark
             * @param {string} key - Name of the property to get.
             * @returns {string} Value of persistent object (stringified)
             */
            getPersistentObject: function(key){
                var /** string */ retVal = "";
                var storage = window.localStorage || null;
                if (storage && storage.getObject) {
                    return storage.getObject(key);
                } else if (storage) {
                    var /** string */ storageValue = storage[key];
                    if (typeof(storageValue) === "string") {
                        // Only strings should be stored.
                        try {
                            retVal = JSON.parse(storageValue);
                        } catch(e){}
                    }
                } else {
                    // Fall back to using cookies.
                    var /** string */ cookieValue = window.spark.getCookie(key);
                    if (typeof(cookieValue) === "string") {
                        // Only strings should be stored.
                        try {
                            retVal = JSON.parse(cookieValue);
                        } catch(e){}
                    }
                }
                return retVal;
            },

            /**
             * Clear data in the browser's session storage (if available).
             * @method clearSessionObject
             * @memberof spark
             * @param {string} key - Name of the property to clear.
             * @returns {boolean} Success of operation
             */
            clearSessionObject: function(key){
                var /** boolean */ retVal = false;
                var storage = window.sessionStorage || null;
                if (storage && storage.clearObject) {
                    storage.clearObject(key);
                    retVal = true;
                } else if (storage) {
                    delete storage[key];
                    retVal = true;
                }
                return false;
            },

            /**
             * Set data in the browser's session storage (if available).
             * @method setSessionObject
             * @memberof spark
             * @param {string} key - Name of the property to set.
             * @param {string} value - String value to be stored.
             * @returns {boolean} Success of operation
             */
            setSessionObject: function(key, value){
                var /** boolean */ retVal = false;
                var storage = window.sessionStorage || null;
                if (storage && storage.getObject) {
                    storage.setObject(key, value);
                    retVal = true;
                } else if (storage) {
                    storage[key] = JSON.stringify(value);
                    retVal = true;
                }
                return retVal;
            },

            /**
             * Get data in the browser's session storage (if available).
             * @method getSessionObject
             * @memberof spark
             * @param {string} key - Name of the property to get.
             * @returns {string} Value of session object (stringified)
             */
            getSessionObject: function(key){
                var /** string */ retVal = "";
                var storage = window.sessionStorage || null;
                if (storage && storage.getObject) {
                    // Only strings should be stored.
                    retVal = storage.getObject(key);
                } else if (storage) {
                    var value = storage[key];
                    if (typeof(storage[key]) === "string") {
                        // Only strings should be stored.
                        retVal = JSON.parse(value);
                    }
                }
                return retVal;
            },

            /**
             * Get data via a standard browser cookie.
             * @method getCookie
             * @memberof spark
             * @param {string} key - Name of the cookie to get.
             * @returns {string} Value of cookie (stringified)
             */
            getCookie: function(key){
                var name = key + "=";
                var i = null;
                var ca = document.cookie.split(";");
                var c = "";
                for(i=0; i<ca.length; i+=1) {
                    c = ca[i];
                    while (c.charAt(0) == " ") {
                        c = c.substring(1);
                    }
                    if (c.indexOf(name) == 0) {
                        return c.substring(name.length, c.length);
                    }
                }
                return "";
            },

            /**
             * Set data via a standard browser cookie.
             * @method setCookie
             * @memberof spark
             * @param {string} key - Name of the cookie to set.
             * @param {string} value - Value of the set cookie.
             * @param {number} exdays - Days to live for cookie.
             */
            setCookie: function(key, value, exdays){
                var d = new Date();
                d.setTime(d.getTime() + ((exdays || 1) * 24 * 60 * 60 * 1000));
                var expires = "expires=" + d.toUTCString();
                document.cookie = key + "=" + value + "; " + expires + "; path=/";
            },

            /**
             * Returns today's date without a date component.
             * @method getToday
             * @memberof spark
             * @returns {Object} Today's date, as JavaScript Date object
             */
            getToday: function(){
                var today = new Date();
                return (new Date(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0, 0, 0));
            },

            /**
             * Get a date by adding/subtracting days from today.
             * @method getDateByDays
             * @memberof spark
             * @param {number} numDays - Number of days to subtract/add.
             * @returns {Object} New date before/after given days, as JavaScript Date object
             */
            getDateByDays: function(numDays){
                if (typeof(numDays) == "number" && numDays != 0) {
                    var today = new Date();
                    var timestamp = today.setDate(today.getDate() + numDays);
                    return (new Date(timestamp));
                }
                return (new Date());
            },

            /**
             * Get a date by adding/subtracting weeks from this week.
             * @method getDateByWeeks
             * @memberof spark
             * @param {number} numWeeks - Number of weeks to subtract/add.
             * @returns {Object} New date before/after given weeks, as JavaScript Date object
             */
            getDateByWeeks: function(numWeeks){
                if (typeof(numWeeks) == "number" && numWeeks != 0) {
                    var today = new Date();
                    var timestamp = this.getDateByDays(-1 * today.getDay());
                    timestamp = today.setDate(timestamp.getDate() + (7 * numWeeks));
                    return (new Date(timestamp));
                }
                return (new Date());
            },

            /**
             * Get a date by adding/subtracting weeks from this week.
             * @method getTemplate
             * @memberof spark
             * @param {string} selector - JQuery selector for locating template.
             * @param {Object} data - JSON object to be applied to template.
             * @returns {Object} Kendo template object instance
             */
            getTemplate: function(selector, data){
                if ($(selector).length) {
                    // Load a template (as selector) and apply data (if present).
                    var templateObject = kendo.template($(selector).html());
                    if (data) {
                        return templateObject(data);
                    }
                    return templateObject;
                }
                return null;
            }

        }); // $.extend window.spark
    } // if

    /**
     * Prepare custom methods to extend functionality of DOM storage.
     * These are designed to allow storing non-string objects, after
     * appropriate conversion through the browser's JSON object.
     */
    if (window.Storage) {
        /**
         * Add methods to the object prototype, for all storage types.
         * Only applies when Storage object is supported by browser.
         */

        /**
         * Enhance prototype for clearing object.
         */
        Storage.prototype.clearObject = function(key){
            if (this.removeItem) {
                this.removeItem(key);
            }
        };

        /**
         * Enhance prototype for retrieving object.
         */
        Storage.prototype.getObject = function(key){
            if (this.getItem) {
                // Automatically parse back to JSON format.
                return JSON.parse(this.getItem(key));
            }
            return ""; // Return empty when method unavailable.
        };

        /**
         * Enhance prototype for storing object.
         */
        Storage.prototype.setObject = function(key, value){
            if (this.setItem) {
                try{
                    // Automatically stringify complex JSON values.
                    var jsonValue = JSON.stringify(value);
                    this.setItem(key, jsonValue);
                }
                catch(err){
                    console.warn("Unable to store peristent object in DOM: " + err);
                    console.warn("An error was encountered while storing data to the browser. Please view the ISC logs for details.");
                }
            }
        };
    } // if window.storage

})(window.jQuery, window.kendo);
