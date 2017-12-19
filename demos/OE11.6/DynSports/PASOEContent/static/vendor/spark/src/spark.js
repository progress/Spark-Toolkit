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
            version: "v@VERSION@ (@TIMESTAMP@)",

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
                try {
                    // Create or retrieve a resource JSDO by name.
                    var jsdo = window.spark.createJSDO(resourceName);

                    if (options.onBeforeFill) {
                        // Set up a callback to run before each fill command.
                        jsdo.subscribe("beforeFill", options.onBeforeFill);
                        delete options.onBeforeFill;
                    }

                    if (options.onAfterSaveChanges) {
                        // Set up a callback to run after each saveChanges command.
                        jsdo.subscribe("afterSaveChanges", options.onAfterSaveChanges);
                        delete options.onAfterSaveChanges;
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
                        if (jsdo._buffers && jsdo._buffers[options.tableRef]) {
                            defaults.transport.tableRef = options.tableRef;
                        } else {
                            console.log("Warning: Requested table '" + options.tableRef + "' does not exist in JSDO buffers.");
                        }
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
                } catch(e){
                    console.log("Unable to create JSDO DataSource for " + resourceName + ":", options);
                    console.log(e.stack);
                    return new kendo.data.DataSource(); // Return basic DataSource.
                }
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
