/**
 * @file Singleton object for accessing common features, specifically in the [JSDO client library]{@link https://documentation.progress.com/output/pdo/index.html#page/pdo%2Fjsdo-class-and-object-reference.html%23}.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($, kendo, progress, window){
    "use strict";

    if ($ && kendo && progress && typeof window.spark === "undefined") {

        var jsdoUsername = null; // Internal property for user AuthN.
        var jsdoPassword = null; // Internal property for user AuthN.
        var _jsdoSession = null; // Private handle to current JSDO session.
        var _authProvider = null; // Private handle to authentication provider.
        var optionDefaults = {id: "", filterQuery: "", data: {}, success: false, error: false};
        var _sessionName = null; // Unique name for storing JSDO session data locally.

        /**
         * Primary client-side object for PMFO.
         * @namespace spark
         * @type {Object}
         */
        window.spark = {

            /* Current version, tagged with a build date. */
            version: "v3.2.1 (2017.10.03.100340)",

            /** Reserved Properties **/

            field: {},   // For field transformations.
            form: {},    // For form/validation helpers.
            grid: {},    // For grid transformations.
            loader: {},  // External file loader methods.
            nav: {},     // App routing and navigation.
            notify: {},  // Notifications and messages.
            strings: {}, // String manipulation.

            /** Special Handler Functions **/

            /**
             * Standard callback method for handling JSDO errors.
             * @method jsdoError
             * @memberof spark
             * @param {Object} ev Event object
             * @returns {boolean}
             */
            jsdoError: function(ev){
                // Utilizes methods in JSDO release v4.2+
                var jsdo = ((ev.xhr || {}).jsdo || {getErrors: function(){return [];}});
                var errorArray = jsdo.getErrors();
                var errors = []; // List of errors to report.
                $.each(errorArray, function(i, error){
                    switch(error.type){
                        case -1: // Error
                            var errObj = null;
                            if (error.responseText) {
                                try {
                                    errObj = JSON.parse(error.responseText || "");
                                }
                                catch(e) {
                                    console.log("Error while parsing response: " + error.responseText || "N/A");
                                }
                            }
                            if (errObj && typeof(errObj) === "object") {
                                $.each(errObj, function(dsName, ds){
                                    if (ds["prods:errors"]) {
                                        $.each(ds["prods:errors"], function(ttName, tt){
                                            $.each(tt, function(j, ttErr){
                                                errors.push(ttErr["prods:error"]);
                                            });
                                        });
                                    }
                                });
                            } else {
                                errors.push(error.error);
                            }
                            break;
                        case -2: // App Error
                            errors.push(error.error + " (" + error.errorNum + ")");
                            break;
                        case -3: // Return Value
                            errors.push(error.error);
                            break;
                        case -4: // Data Error
                            errors.push(error.error);
                            break;
                        default:
                            console.log("Unknown error:", error);
                    }
                });

                // Make a final attempt to gather any errors thrown.
                if (errors.length === 0 && ev.errorThrown !== "") {
                    errors.push(ev.errorThrown);
                }

                // Output all bundled errors to user.
                if (errors.length > 0) {
                    console.warn("Errors: ", errors);
                    if (window.app && window.app.showMessage) {
                        window.app.showMessage(errors, "error");
                    } else {
                        alert(errors[0]);
                    }
                }
                ev.preventDefault();
                return false;
            },

            /**
             * Reserved callback method for handling JSDO errors.
             * @method jsdoFailure
             * @memberof spark
             * @param {Object} jsdo Instance of the JavaScript Data Object
             * @param {boolean} success State of the response (pass/fail)
             * @param {Object} request Original request object, which contains the response
             * @returns void
             */
            jsdoFailure: function(jsdo, success, request){
                // Custom handler for individual CRUD operation wrappers.
                if (request.xhr && request.xhr.status === 401 || request.xhr.status === 403) {
                    // Check if an authentication error occurred during request.
                    if (window.spark.jsdoAuthError) {
                        window.spark.jsdoAuthError(request);
                    } else {
                        alert("Session has expired. Please login again.");
                    }
                } else if (request.response && request.response._errors && request.response._errors.length > 0) {
                    // Interrogate the response and log any errors.
                    var errorMsg = "";
                    var idxError = null;
                    var lenErrors = request.response._errors.length;
                    var errorEntry = "";
                    for (idxError=0; idxError<lenErrors; idxError+=1) {
                        errorEntry = request.response._errors[idxError] || {};
                        errorMsg = errorMsg + " " + errorEntry._errorMsg || "UNKNOWN";
                    }
                    if ($.trim(errorMsg) !== "") {
                        console.warn(errorMsg);
                    }
                }
            },

            /** Initialization Functions **/

            /**
             * Critical startup method for establishing an Authentication Provider, which provides the mechanism for authenticating
             * a user for this application. This will immediately confirm if a session has already been authenticated.
             * @method checkAuthentication
             * @memberof spark
             * @param {string} serviceURI Root directory for all services
             * @param {string} authModel Authentication model (default: anonymous)
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            checkAuthentication: function(serviceURI, authModel){
                if (!_authProvider) {
                    _authProvider = new progress.data.AuthenticationProvider({
                        uri: serviceURI,
                        authenticationModel: authModel || progress.data.Session.AUTH_TYPE_ANON,
                    });
                }
                var username = jsdoUsername || "anonymous";
                var password = jsdoPassword || "anonymous";
                if (_authProvider.hasClientCredentials()) {
                    return _authProvider.logout()
                            .then(function(){
                                return _authProvider.login(username, password);
                            });
                } else {
                    return _authProvider.login(username, password);
                }                
            },
            
            /**
             * Critical startup method for establishing a [JSDO session]{@link https://documentation.progress.com/output/pdo/index.html#page/pdo%2Fprogress.data.jsdosession-class.html%23}
             * which also authenticates the user and obtains any necessary Data Object Service Catalog(s). Note that there can be only one...JSDOSession.
             * @method spark.createSession
             * @memberof spark
             * @param {string} serviceURI Root directory for all services
             * @param {Array(string)} catalogURI Catalog URI as an array of strings (legacy: single string)
             * @param {string} authModel Authentication model (default: anonymous)
             * @param {string} sessionName Unique session name (default: JSDOSession + serviceURI)
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            createSession: function(serviceURI, catalogURI, authModel, sessionName){
                if (!_jsdoSession) {
                    if (!_sessionName) {
                        // A session name must be determined before proceeding.
                        if (sessionName) {
                            // Assign the given session name, if provided.
                            _sessionName = sessionName;
                        } else {
                            // If no session name set already, use the serviceURI as base.
                            this.setSessionName(serviceURI);
                        }
                    }

                    if (!_authProvider) {
                        _authProvider = new progress.data.AuthenticationProvider({
                            uri: serviceURI,
                            authenticationModel: authModel || progress.data.Session.AUTH_TYPE_ANON,
                        });
                    }

                    // Create the primary JSDO Session to be used for this page.
                    _jsdoSession = new progress.data.JSDOSession({
                        // anonymous = progress.data.Session.AUTH_TYPE_ANON
                        // basic-* = progress.data.Session.AUTH_TYPE_BASIC
                        // form-* = progress.data.Session.AUTH_TYPE_FORM
                        authenticationModel: authModel || progress.data.Session.AUTH_TYPE_ANON,
                        authProvider: _authProvider,
                        serviceURI: serviceURI || null,
                        name: _sessionName || "JSDOSession_Default"
                    });
                }

                if (catalogURI) {
                    // If a catalog URI has been provided, then it is intended that this session
                    // will provide for JSDO access to RESTful end-points. Therefore, we must do
                    // a check of the user's session, or otherwise attempt to login using stored
                    // or default [anonymous] credentials (to allow access to public resources).
                    if (_jsdoSession.loginResult === progress.data.Session.LOGIN_SUCCESS) {
                        // Perform a check to see if the user's session is still available.
                        return _jsdoSession.isAuthorized()
                            .then(function(session, result, info){
                                // Obtain catalogs whenever authorized.
                                return window.spark.loadCatalogs(catalogURI);
                            }, function(session, result, info){
                                // Attempt to obtain catalogs anyway.
                                // Likely case when user is anonymous.
                                return window.spark.loadCatalogs(catalogURI);
                            });
                    } else {
                        // Obtain cached credentials or provide defaults for anonymous use.
                        // This should be called as a last resort if no valid login result.
                        var username = jsdoUsername || "anonymous";
                        var password = jsdoPassword || "anonymous";
                        return _authProvider.login(username, password)
                            .then(function(authProvider, result, info){
                                // Load the catalogs as part of the session creation process.
                                return window.spark.loadCatalogs(catalogURI);
                            }, function(){
                                return "Unable to reach the REST adapter to establish a session.";
                            });
                    }
                } else {
                    // If no catalog has been provided, then return a fulfilled promise.
                    // No data will be transmitted via the JSDO under this scenario.
                    var promise = $.Deferred();
                    promise.resolve("No catalog(s) requested.");
                    return promise;
                }
            },

            /**
             * Internal method to obtain Data Object Service Catalog(s).
             * Traditionally called by createSession() automatically.
             * @method loadCatalogs
             * @memberof spark
             * @private
             * @param {Array(string)} catalogURI Catalog URI as an array of strings (legacy: single string)
             * @returns {string|Array(string)} Array of statuses or reason for failure
             */
            loadCatalogs: function(catalogURI){
                // Add a property to track the catalogs to be loaded.
                _jsdoSession.catalogLoaded = {};
                if (typeof catalogURI == "string") {
                    _jsdoSession.catalogLoaded[catalogURI] = false;
                } else if (catalogURI instanceof Array) {
                    $.each(catalogURI, function(i, catalog){
                        _jsdoSession.catalogLoaded[catalog] = false;
                    });
                }

                // Load one (string) or more (array) catalogs to this session.
                return _jsdoSession.addCatalog(catalogURI)
                    .then(function(session, result, responses){
                        // Denote when a catalog has been loaded.
                        $.each(responses, function(i, response){
                            _jsdoSession.catalogLoaded[response.catalogURI] = (response.result ? true : false);
                        });
                        return responses;
                    }, function(session, result, responses){
                        console.log("Response:", responses);
                        return "Failed to load catalog(s).";
                    });
            },

            /**
             * Create a JSDO instance, or attempt to utilize an existing instance from session memory.
             * @method createJSDO
             * @memberof spark
             * @param {string} resourceName Name of unique resource to create as JSDO instance
             * @returns {Object} [JSDO instance object]{@link https://documentation.progress.com/output/pdo/index.html#page/pdo/progress.data.jsdo-class.html}
             */
            createJSDO: function(resourceName){
                // First check if a JSDO exists in the session, otherwise create.
                var jsdo = null;
                $.each(_jsdoSession.JSDOs, function(i, j){
                    if (j.name === resourceName) {
                        jsdo = j;
                        return;
                    }
                });
                return (jsdo || (new progress.data.JSDO({name: resourceName})));
            },

            /**
             * Return an array of runtime errors if present.
             * @method getMessages
             * @memberof spark
             * @param {Object} response AJAX response object
             * @returns {Array(Object)|boolean} Array of errors if present, otherwise false
             */
            getMessages: function(response){
                if (response.response) {
                    response = response.response;
                }
                if (response && response._errors && response._errors.length > 0) {
                    return response._errors || false;
                }
                return false;
            },

            /**
             * Display a message using an appropriate Kendo display function.
             * @method showMessage
             * @memberof spark
             * @param {Object} message Message object
             * @param {Function} showMethod Message display method
             * @returns {void}
             */
            showMessage: function(message, showMethod){
                var errorMsg = message._errorMsg || "";
                var errorType = null;
                switch(message._errorType.toLowerCase()){
                    case "error":
                    case "fatal":
                    case "trace":
                        errorType = "error";
                        break;
                    case "validation":
                    case "warning":
                        errorType = "warning";
                        break;
                    default:
                        // Information or other.
                        errorType = "info";
                }
                if (errorMsg !== "" && errorType && showMethod) {
                    showMethod(errorMsg, errorType);
                }
            },

            /**
             * Store user credentials in local variables for session use.
             * @method setCredentials
             * @memberof spark
             * @param {string} username Username
             * @param {string} password Password
             * @returns void
             */
            setCredentials: function(username, password){
                jsdoUsername = username || null;
                jsdoPassword = password || null;
            },

            /**
             * Set a custom name for this session for this website.
             * @method setSessionName
             * @memberof spark
             * @param {string} sessionName Name of JSDO session
             * @returns {string} Corrected name of JSDO session
             */
            setSessionName: function(sessionName){
                // Remove any slashes from the given name.
                _sessionName = sessionName.replace(/\//g, "");
                if (_sessionName === "") {
                    // Default value if name is blank.
                    _sessionName = "Root";
                }
                // Prefix the name to define intent.
                _sessionName = "JSDOSession_" + _sessionName;
                return _sessionName;
            },

            /** Utility Functions **/

            /**
             * Helper method to clone an object.
             * @method clone
             * @memberof spark
             * @param {Object} originalProps Original object with properties
             * @param {Object} newProps New object with mergeable properties
             * @returns {Object} Cloned object
             */
            clone: function(originalProps, newProps){
                return $.extend(true, {}, originalProps, newProps);
            },

            /**
             * Convert a string to proper case.
             * @method toProperCase
             * @memberof spark
             * @param {string} string Original string to be converted
             * @returns {string}
             */
            toProperCase: function(string){
                return string.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
            },

            /**
             * Obtain the JSDO Session object.
             * @method getJsdoSession
             * @memberof spark
             * @returns {Object} JSDO Session object
             */
            getJsdoSession: function(){
                return _jsdoSession;
            },

            /**
             * Obtain default options for custom CRUD operations.
             * @method getMergedOptions
             * @memberof spark
             * @param {Object} options Additional object to merge to options
             * @returns {Object} Merged options
             */
            getMergedOptions: function(options){
                return this.clone(optionDefaults, options);
            },

            /**
             * Obtain value from query string by named parameter.
             * @method getQueryStringValue
             * @memberof spark
             * @param {string} key Specific query property to be returned
             * @returns {string} Found property
             */
            getQueryStringValue: function(key){
                // Extract a specific value from the URL parameters.
                var urlParams = window.location.search;
                if (urlParams === "") {
                    urlParams = window.location.href;
                }
                return unescape(urlParams.replace(new RegExp("^(?:.*[&\\?]" + escape(key).replace(/[\.\+\*]/g, "\\$&") + "(?:\\=([^&]*))?)?.*$", "i"), "$1"));
            },

            /**  JSDO methods for CRUD operation **/

            /**
             * Create a new Kendo DataSource driven by a JSDO instance.
             * @method createJSDODataSource
             * @memberof spark
             * @param {string} resourceName Name of unique resource to create as JSDO instance
             * @param {Object} options Properties for this DataSource
             * @returns {Object} Kendo DataSource instance
             */
            createJSDODataSource: function(resourceName, options){
                // Create or retrieve a resource JSDO by name.
                var jsdo = window.spark.createJSDO(resourceName);

                if (options.onBeforeFill) {
                    // Set up a callback to run before each fill command.
                    jsdo.subscribe("beforeFill", options.onBeforeFill);
                }

                if (options.onAfterSaveChanges) {
                    // Set up a callback to run after each saveChanges command.
                    jsdo.subscribe("afterSaveChanges", options.onAfterSaveChanges);
                }

                // Determine capabilities for READ operation.
                var jsdoProps = jsdo.getMethodProperties("read");
                var capabilities = [];
                if (jsdoProps && jsdoProps.capabilities) {
                    capabilities = jsdoProps.capabilities.split(",");
                }

                // Setup the default options for the DataSource.
                var defaults = {
                    serverFiltering: capabilities.indexOf("filter") > -1,
                    serverPaging: (capabilities.indexOf("skip") > -1 && capabilities.indexOf("top") > -1),
                    serverSorting: (capabilities.indexOf("orderBy") > -1 || capabilities.indexOf("sort") > -1),
                    transport: {
                        jsdo: jsdo
                    },
                    type: "jsdo",
                    error: window.spark.jsdoError
                };

                // Provide special overrides for inner objects.
                if (options.tableRef) {
                    defaults.transport.tableRef = options.tableRef;
                    delete options.tableRef;
                }

                // Create the new Kendo DataSource instance.
                var _dataSource = new kendo.data.DataSource($.extend(defaults, options));

                // Add a method to return schema information.
                var _schema = [];
                _dataSource.getFieldSchema = function(fieldName){
                    if (_schema.length === 0) {
                        var jsdo = (_dataSource.transport || {}).jsdo || null;
                        _schema = (jsdo) ? jsdo.getSchema() : [];
                    }

                    return $.grep(_schema, function(field){
                        return field.title == fieldName;
                    })[0] || {};
                }

                return _dataSource;
            },

            /**
             * Wrapper method to fetch a dataset.
             * @method jsdo_read
             * @memberof spark
             * @param {Object} jsdoObj Instance of the JavaScript Data Object
             * @param {Object} options Standard options to send through this JSDO
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            jsdo_read: function(jsdoObj, options){
                var promise = null;
                var filterQuery = options.filterQuery || "";
                if (filterQuery === "") {
                    promise = jsdoObj.fill();
                } else {
                    promise = jsdoObj.fill(filterQuery);
                }
                promise
                    .done(function(jsdo, success, request){
                        // Provide overrides or logic when request is successful.
                    })
                    .fail(window.spark.jsdoFailure);
                return promise;
            },

            /**
             * Wrapper method to create a record.
             * @method jsdo_create
             * @memberof spark
             * @param {Object} jsdoObj Instance of the JavaScript Data Object
             * @param {Object} options Standard options to send through this JSDO
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            jsdo_create: function(jsdoObj, options){
                var currentRecord = options.data;
                var jsrecord = jsdoObj.add(currentRecord);
                var promise = jsdoObj.saveChanges(options.useSubmit);
                promise
                    .done(function(jsdo, success, request){
                        // Provide overrides or logic when request is successful.
                    })
                    .fail(window.spark.jsdoFailure);
                return promise;
            },

            /**
             * Wrapper method to update a record.
             * @method jsdo_update
             * @memberof spark
             * @param {Object} jsdoObj Instance of the JavaScript Data Object
             * @param {Object} options Standard options to send through this JSDO
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            jsdo_update: function(jsdoObj, options){
                var jsrecord = {};
                if (options.tableRef && jsdoObj[options.tableRef]) {
                    // If a specific table is given, look for record there.
                    jsrecord = jsdoObj[options.tableRef].findById(options.id);
                } else {
                    // Otherwise use the "global" method for this JSDO.
                    jsrecord = jsdoObj.findById(options.id);
                }
                try {
                    jsrecord.assign(options.data);
                } catch(e){
                    options.error(null, null, e);
                }
                var promise = jsdoObj.saveChanges(options.useSubmit);
                promise
                    .done(function(jsdo, success, request){
                        // Provide overrides or logic when request is successful.
                    })
                    .fail(window.spark.jsdoFailure);
                return promise;
            },

            /**
             * Wrapper method to delete a record.
             * @method jsdo_delete
             * @memberof spark
             * @param {Object} jsdoObj Instance of the JavaScript Data Object
             * @param {Object} options Standard options to send through this JSDO
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            jsdo_delete: function(jsdoObj, options){
                var jsrecord = jsdoObj.findById(options.id);
                try {
                    jsrecord.remove();
                } catch(e){
                    options.error(null, null, e);
                }
                var promise = jsdoObj.saveChanges(options.useSubmit);
                promise
                    .done(function(jsdo, success, request){
                        // Provide overrides or logic when request is successful.
                    })
                    .fail(window.spark.jsdoFailure);
                return promise;
            }

        }; // window.spark

    } // if
})(window.jQuery, window.kendo, window.progress, window);
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
                var search = location.search.substring(1);
                if (search) {
                    var searchVal = search.replace(/&/g, '","').replace(/=/g,'":"');
                    retVal = JSON.parse('{"' + searchVal + '"}', function(key, value){ return key === "" ? value : decodeURIComponent(value) });
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
/**
 * @file Singleton object for external file loading.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($, kendo){
    "use strict";

    if ($ && kendo && window.spark) {

        /**
         * File loading operations for PMFO.
         * @namespace spark.loader
         * @memberof spark
         */
        window.spark.loader = {

            /**
             * Loads an external screen (JS + HTML) from path into the DOM.
             * @method loadExtScreen
             * @memberof spark.loader
             * @param {string} rootPath Base name of file to be loaded
             * @param {string} contentID Unique DOM ID for anchoring loaded content
             * @param {string} pageName User-friendly name of page to load
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            loadExtScreen: function(rootPath, contentID, pageName){
                // Use jQuery Ajax to fetch the JS model file.
                return $.ajax({
                    dataType: "script",
                    url: rootPath + ".js",
                    success: function(jsResult){
                        // Use jQuery Ajax to fetch the HTML view file.
                        return $.ajax({
                            dataType: "html",
                            url: rootPath + ".html",
                            success: function(htmlResult){
                                // On success, add contents to DOM where specified.
                                kendo.destroy($("#" + contentID).children());
                                $("#" + contentID).empty();
                                $("#" + contentID).html(htmlResult);
                            },
                            error: function(result){
                                alert("Error loading HTML file " + rootPath + ".html");
                            }
                        });
                    },
                    error: function(result){
                        alert("Error loading JavaScript file " + rootPath + ".js");
                    }
                });
            },

            /**
             * Loads an external HTML modal from a specific location into the DOM.
             * @method loadExtInclude
             * @memberof spark.loader
             * @param {string} filePath Base path of file to be loaded
             * @param {string} contentID Unique DOM ID for anchoring loaded content
             * @param {string} templateID DOM ID of template in loaded file
             * @param {Object} options Data to be applied to the template
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            loadExtInclude: function(filePath, contentID, modalName, options){
                // Use jQuery Ajax to fetch the modal content.
                return $.ajax({
                    dataType: "html",
                    url: filePath,
                    success: function(htmlResult){
                        // On success, add contents to DOM where specified.
                        kendo.destroy($("#" + contentID).children());
                        $("#" + contentID).empty();
                        $("#" + contentID).html(htmlResult);
                        $("[data-toggle=tooltip]").tooltip();
                    },
                    error: function(result){
                        alert("Error loading template file " + filePath);
                    }
                });
            },

            /**
             * Loads an external [Kendo Template]{@link http://docs.telerik.com/kendo-ui/framework/templates/overview} from a specific location into the DOM.
             * @method loadExtTemplate
             * @memberof spark.loader
             * @param {string} filePath Base path of file to be loaded
             * @param {string} contentID Unique DOM ID for anchoring loaded content
             * @param {string} templateID DOM ID of template in loaded file
             * @param {Object} options Data to be applied to the template
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            loadExtTemplate: function(filePath, contentID, templateID, options){
                // Use jQuery Ajax to fetch the template script.
                return $.ajax({
                    dataType: "html",
                    url: filePath,
                    success: function(tmplResult){
                        // On success, add contents to DOM where specified.
                        $("#" + contentID).append(tmplResult);
                        var template = kendo.template($("#" + templateID).html());
                        var htmlBody = template(options || {});
                        kendo.destroy($("#" + contentID).children());
                        $("#" + contentID).empty();
                        $("#" + contentID).html(htmlBody);
                    },
                    error: function(result){
                        alert("Error loading template file " + filePath);
                    }
                });
            }

        }; // window.spark.loader

    } // if
})(window.jQuery, window.kendo);
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
/**
 * @file Singleton object for common file IO transformations.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($){
    "use strict";

    if ($ && window.spark) {

        /**
         * File IO operations for PMFO.
         * @namespace spark.io
         * @memberof spark
         */
        window.spark.io = {

            /**
             * Obtain a Font-Awesome icon class based on file extension.
             * @method addExtensionClass
             * @memberof spark.io
             * @param {string} extension File extension startubg with "."
             * @returns {string} Set of FA icon classes
             */
            addExtensionClass: function(extension){
                switch(extension){
                    case ".jpg":
                    case ".img":
                    case ".png":
                    case ".gif":
                        return "fa fa-file-image-o fa-3x";
                    case ".doc":
                    case ".docx":
                        return "fa fa-file-word-o fa-3x";
                    case ".xls":
                    case ".xlsx":
                        return "fa fa-file-excel-o fa-3x";
                    case ".pdf":
                        return "fa fa-file-pdf-o fa-3x";
                    case ".zip":
                    case ".rar":
                        return "fa fa-file-zip-o fa-3x";
                    default:
                        return "fa fa-file-o fa-3x";
                }
            },

            /**
             * Create a standard Kendo file upload widget.
             * @method createUpload
             * @memberof spark.io
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} uploadOptions Options for upload behavior
             * @param {Object} overrides Overrides for the upload widget
             * @returns {Object} [kendo.ui.Upload]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/upload}
             */
            createUpload: function(selector, uploadOptions, overrides){
                var el = $(selector);
                if (el) {
                    return el.kendoUpload($.extend({
                        async: {
                            // autoUpload: when true, uploads begin as soon as files are dropped/chosen.
                            autoUpload: uploadOptions.autoUpload || false,

                            // batch: when multiple files are selected or dropped TOGETHER, sent as single POST.
                            batch: uploadOptions.batchUpload || false,

                            // relative path to this page: http://[server]:[port]/upload.
                            saveUrl: uploadOptions.saveUrl || "upload",

                            // saveField: sets the Content-Disposition "name" attribute to "group" the upload.
                            saveField: uploadOptions.saveField || "files"
                        },

                        // Basic operations (enable selection button, multi-file upload).
                        enabled: uploadOptions.enableUpload || false,
                        multiple: uploadOptions.multiUpload || false,

                        // Enables the display of the listing of [to-be] uploaded files.
                        showFileList: uploadOptions.showFileList || false,

                        // Template used to render the file list
                        template: uploadOptions.template || null,

                        // These events are fired only in async mode.
                        cancel: uploadOptions.onCancel || null,     // Fires when the upload has been cancelled while in progress.
                        complete: uploadOptions.onComplete || null, // Fires when all active uploads completed either successfully or with errors.
                        error: uploadOptions.onError || null,       // Fires when an upload/remove operation has failed.
                        progress: uploadOptions.onProgress || null, // Fires when upload progress data is available [not fired in IE <10].
                        success: uploadOptions.onSuccess || null,   // Fires when an upload/remove operation has been completed successfully.
                        upload: uploadOptions.onUpload || null,     // Fires when files are about to be uploaded; canceling will prevent the upload.

                        // Sync and async events.
                        select: uploadOptions.onSelect || null, // Triggered when a file is selected; canceling will prevent selection from occurring.
                        remove: uploadOptions.onRemove || null  // Fires when uploaded file is about to be removed; canceling will prevent the remove.
                    }, overrides)).getKendoUpload();
                }
                return null;
            }

        }; // window.spark.io

    } // if
})(window.jQuery);
/**
 * @file Singleton object for application navigation.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($, kendo){
    "use strict";

    if ($ && kendo && window.spark) {

        /**
         * Navigation operations for PMFO.
         * @namespace spark.nav
         * @memberof spark
         */
        window.spark.nav = {

            /**
             * Create a simplistic path-based router for site navigation.
             * @method createSimpleRouter
             * @memberof spark.nav
             * @param {Object} options Properties object for widget
             * @param {string} options.filePathPrefix Relative location of physical files
             * @param {string} options.mainContentID ID for loading content dynamically
             * @param {method} options.getLandingPage Obtain name of landing page file
             * @param {method} options.onChange Event callback on each change of route
             * @param {method} options.onLoad Event callback after loading extra files
             * @returns {Object} [kendo.Router]{@link http://docs.telerik.com/kendo-ui/api/javascript/router}
             */
            createSimpleRouter: function(options){
                // Options property must be an object.
                if (!options) { options = {}; }

                // Make sure property is set with a default ID.
                if (!options.mainContentID || options.mainContentID === "") {
                    options.mainContentID = "mainContent";
                }

                // Define a new router with specific paths.
                var router = new kendo.Router({
                    change: options.onChange || function(ev){}
                });

                function loadPage(page, path, sec, sub){
                    // Loads the model/view files and initializes the new page.
                    window.spark.loader.loadExtScreen(path, options.mainContentID, page)
                        .complete(function(){
                            if (options.onLoad && typeof(options.onLoad) === "function") {
                                options.onLoad(page, path, sec, sub);
                            }
                        });
                }

                // Add custom properties and methods.
                router.loggedIn = false; // Denotes AuthN state.
                router.menuData = []; // Placeholder for menu data.
                router.isSecurePage = function(url){
                    var isSecure = false;
                    $.each(this.menuData || [], function(i, topItem){
                        if (topItem.items) {
                            $.each(topItem.items, function(i, menuItem){
                                if (menuItem.url == url) {
                                    // When found, mark as secure if property is explicitly set.
                                    isSecure = (menuItem.secure === true);
                                }
                            });
                        }
                    });
                    return isSecure;
                };

                // Define a simple routing patterns for this application.
                router.route("/", function(){
                    /**
                     * Returning to the index page may require the loading of a specific
                     * landing page. Therefore we must assume a callback will be required
                     * and so a promise will be used to track the result. This allows
                     * the getLandingPage method to be asynchronous as well. Possible
                     * values are either a physical page (View+Controller) or a URI.
                     * For a URI the router will navigate to the target location.
                     */
                    var promise = $.Deferred();
                    if (options.getLandingPage) {
                        // Replace local promise with returned promise.
                        promise = options.getLandingPage();
                    } else {
                        // Immediately resolve the local promise.
                        promise.resolve("");
                    }

                    // Setup for successful response from promise.
                    promise.done(function(page){
                        if ((page || "").startsWith("#/")) {
                            // Navigate to the relative route and load from there.
                            router.navigate(page);
                        } else if ((page || "") !== "") {
                            var path = options.filePathPrefix + page;

                            // Perform some action prior to loading the new screen.
                            if (options.onBeforeLoad && typeof(options.onBeforeLoad) === "function") {
                                options.onBeforeLoad(loadPage, page, path);
                            } else {
                                loadPage(page, path);
                            }
                        } else {
                            // Just initialize the landing page as-is.
                            if (options.onLoad && typeof(options.onLoad) === "function") {
                                options.onLoad("");
                            }
                        }
                    });
                });
                router.route("/logout", function(){
                    // Perform a logout and redirect to login page.
                    window.spark.getJsdoSession().logout()
                        .then(function(){
                            if (options.onLogout) {
                                options.onLogout(); // Perform post-logout action.
                            }
                        });
                });
                router.route("/:page", function(page){
                    var path = options.filePathPrefix + page;

                    // Perform some action prior to loading the new screen.
                    if (options.onBeforeLoad && typeof(options.onBeforeLoad) === "function") {
                        options.onBeforeLoad(loadPage, page, path);
                    } else {
                        loadPage(page, path);
                    }
                });
                router.route("/:sec/:page", function(sec, page){
                    var path = options.filePathPrefix + sec + "/" + page;

                    // Perform some action prior to loading the new screen.
                    if (options.onBeforeLoad && typeof(options.onBeforeLoad) === "function") {
                        options.onBeforeLoad(loadPage, page, path, sec);
                    } else {
                        loadPage(page, path, sec);
                    }
                });
                router.route("/:sec/:sub/:page", function(sec, sub, page){
                    var path = options.filePathPrefix + sec + "/" + sub + "/" + page;

                    // Perform some action prior to loading the new screen.
                    if (options.onBeforeLoad && typeof(options.onBeforeLoad) === "function") {
                        options.onBeforeLoad(loadPage, page, path, sec, sub);
                    } else {
                        loadPage(page, path, sec, sub);
                    }
                });

                return router;
            },

            /**
             * Create a collapsible, vertically-stacked menu.
             * @method createVerticalStackMenu
             * @memberof spark.nav
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Array(Object)} menuData Array of menu objects (parents + children)
             * @param {string} menuData.text Parent item title
             * @param {string} menuData.icon Font-Awesome icon class
             * @param {Array(Object)} menuData.items Array of child items
             * @param {string} menuData.items.text Child item title
             * @param {string} menuData.items.url Child item URL
             * @returns void
             */
            createVerticalStackMenu: function(selector, menuData){
                var el = $(selector);
                if (el) {
                    // Destroy any previous contents.
                    el.empty();

                    // Cycle through menu data, building structure.
                    var navItem = $('<nav class="nav-primary hidden-xs" data-ride="collapse" role="navigation"></nav>');
                    var navList = $('<ul class="nav" data-ride="collapse"></ul>');
                    if (typeof(menuData) === "object") {
                        $.each(menuData, function(i, parent){
                            var currentPath = ""; // Identifies the current link in use.
                            if (window.app && window.app.currentPage.path && window.app.currentPage.path != "") {
                                currentPath = "#" + window.app.currentPage.path.replace("app/views", "");
                            }

                            // Construct the parent menu item.
                            var navParentLink = $('<a href="javascript:void(0)" class="auto nav-link"></a>');
                            if (parent.icon) {
                                navParentLink.append($('<i class="fa ' + parent.icon + ' m-r-xs"></i>'));
                            } else if (parent.spriteCssClass) {
                            	navParentLink.append($('<i class="' + parent.spriteCssClass + ' m-r-xs"></i>'));
                            }

                            // Add parent link to new parent menu item.
                            var navParent = $('<li class="nav-item"></li>');
                            navParentLink.append($('<span>' + parent.text + '</span>'));
                            navParent.append(navParentLink);

                            // Build all child menu items.
                            var navChildList = $('<ul class="nav dker"></ul>');
                            if (typeof(parent.items) === "object") {
                                $.each(parent.items, function(j, child){
                                    // Create the menu link for this child.
                                    var navChildLink = $('<a class="nav-link"></a>');
                                    navChildLink.attr("href", child.url);
                                    if (child.url.indexOf("http") === 0) {
                                        navChildLink.attr("target", "_blank");
                                    }

                                    // Create new child menu item and append link.
                                    var navChild = $('<li class="nav-item"></li>');
                                    navChild.append(navChildLink.text(child.text));
                                    navChildList.append(navChild);

                                    // Mark parent and child as active when needed.
                                    if (currentPath != "" && currentPath == child.url) {
                                        navParent.addClass("active");
                                        navChildLink.addClass("active");
                                    }
                                });
                            }

                            // Add children to parent menu, add to navigation.
                            navParent.append(navChildList);
                            navList.append(navParent);
                        });
                    }
                    navItem.append(navList);
                    el.append(navItem);
                } else {
                    console.info("No menu element has been defined.");
                }

        		// Collapse navigation on click (via jQuery).
        		$(document).on("click", ".nav-primary a", function (e) {
        			var $this = $(e.target), $active;      
        			$this.is("a") || ($this = $this.closest("a"));
        			if ($(".nav-vertical").length){
        				return;
        			}

        			$active = $this.parent().siblings(".active");
        			$active && $active.find("> a").toggleClass("active") && $active.toggleClass("active").find("> ul:visible").slideUp(200);

        			($this.hasClass("active") && $this.next().slideUp(200)) || $this.next().slideDown(200);
        			$this.toggleClass("active").parent().toggleClass("active");
        			$this.next().is("ul") && e.preventDefault();

        			setTimeout(function(){ $(document).trigger("updateNav"); }, 300);
        		});
            }

        }; // window.spark.nav

    } // if
})(window.jQuery, window.kendo);
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
