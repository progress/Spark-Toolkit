/**
 * Create an immediately-invoked function expression that returns a static object.
 * This is to be available globally via the variable "app" (aka "window.app").
 *
 * Assumes presence of the following global variables:
 *  var serviceURI = "/<webapp_name>/"; // Prefix to utilize for all REST requests.
 *  var catalogURI = "/[web/pdo|<catalog>.json]"; // Location of the JSDO catalog file.
 *  var authModel = progress.data.Session.AUTH_TYPE_FORM; // Authentication model for JSDO.
 *  var redirectOnLogout = true; // Should application perform a redirect when logout is triggered.
 *  var loginScreenURI = "/login.html"; // URI location to utilize for login purposes (can be standalone).
 */
var app = (function(){
    "use strict";

    /***** Variables / Objects / Overrides *****/

    // Set private flag for application to output messages.
    var useDebugs = false;

    // Set name for any application context.
    var contextName = "DynSportsContext";

    // Set the language code according to browser preference.
    // Only English (default), Spanish, and French are currently supported.
    var langCode = spark.getCookie("language");
    if (langCode === "") {
        langCode = window.navigator.language;
    }

    // Normalize the given language code.
    switch(langCode){
        case "es":
        case "es-ES":
            // Spanish
            langCode = "es-ES";
            break;
        case "fr":
        case "fr-FR":
            // French
            langCode = "fr-FR";
            break;
        default:
            // English
            langCode = "en-US";
            break;
    };
    spark.setCookie("language", langCode);

    // Append appropriate culture as based on the browser.
    $.getScript("vendor/kendo/js/cultures/kendo.culture." + langCode + ".min.js")
        .done(function(){
            kendo.culture(langCode);
        });

    // Append appropriate messages as based on the browser.
    $.getScript("vendor/kendo/js/messages/kendo.messages." + langCode + ".min.js")
        .done(function(){
            kendo.culture(langCode);
        });

    // Set defaults for Bootstrap modals.
    $.fn.modal.Constructor.DEFAULTS.backdrop = "static";
    $.fn.modal.Constructor.DEFAULTS.keyboard = false;

    // Set defaults for AuthN errors on Kendo DataSource.
    kendo.data.DataSource.prototype.options.error = function(ev){
        if (ev.xhr.status === 401 || ev.xhr.status === 403) {
             console.warn("Your session has expired.");
             app.doLogoutAction();
        }
    };

    // Set handler for authentication errors during JSDO operations.
    spark.jsdoAuthError = function(request){
        console.warn("Your session has expired.");
        app.doLogoutAction();
    };

    // Set defaults for common lookup fields (using "lookup" JSDO service).
    spark.field.lookupTextField = "lookupText";   // Based on common ttLookup schema.
    spark.field.lookupValueField = "lookupValue"; // Based on common ttLookup schema.

    // Setting default values to null will force an anonymous login.
    var sessionReady = spark.createSession(serviceURI, catalogURI, authModel);

    /***** Routing Setup *****/

    var routerOptions = {
        filePathPrefix: "app/views/", // Relative path to files.
        mainContentID: "mainContent", // ID to receive page content.
        getLandingPage: function(){
            /**
             * Determine the correct landing page as based on user context info.
             * Call with flag to check locally, though this could result in an
             * external server call. Therefore a promise is needed for response.
             */
            var promise = $.Deferred();
            setTimeout(function(){
                // Always resolve as "Home" for this application.
                promise.resolve("Home");
            }, 2);
            return promise;
        },
        onChange: function(ev){
            // Assign a convenient property with the current screen params.
            app.currentPage.params = ev.params || {};
        },
        onBeforeLoad: function(callback, page, path, sec, sub){
            if (app.currentPage && app.currentPage.name && app.currentPage.name !== "") {
                // Destroy current page when name is known and not the same as the current page.
                var result = destroyController(app.currentPage.name + "Ctrl");
                if (callback && typeof(callback) === "function") {
                    // Should always have a callback for this method, but check just in case.
                    if (result && typeof(result) === "object" && result.then) {
                        // Result is likely a promise, execute as "then" condition.
                        app.logMessage("Controller destroy() result returned a promise.");
                        result.then(function(){
                            // Promise success.
                            callback(page, path, sec, sub);
                        }, function(){
                            // Promise failure.
                            callback(page, path, sec, sub);
                        });
                    } else {
                        // Otherwise, just call method with expected params.
                        app.logMessage("Controller destroy() result returned '" + result + "'.");
                        callback(page, path, sec, sub);
                    }
                }
            } else {
                // Run standard callback, always.
                callback(page, path, sec, sub);
            }
        },
        onLoad: function(page, path, sec, sub){
            // Update properties for new page, just loaded.
            app.currentPage.secure = false;
            app.currentPage.url = "";
            if (page !== "") {
                // Store values and create the controller for the loaded page.
                app.currentPage.name = page || "";
                app.currentPage.path = path || "";
                app.currentPage.url = "#/"
                                    + ((sec && sec !== "") ? sec + "/" : "")
                                    + ((sub && sub !== "") ? sub + "/" : "")
                                    + page;
                app.currentPage.secure = router.isSecurePage(app.currentPage.url);

                // Run standard load routine after a brief delay.
                setTimeout(loadController, 100);
            }
        },
        onLogout: doLogoutAction
    };
    var router = spark.nav.createSimpleRouter(routerOptions);

    /***** Helper Functions *****/

    function logMessage(message, always){
        if ((useDebugs || always) && console && console.log) {
            console.log(message);
        }
    }

    function destroyController(ctrlName){
        // Delete screen controller.
        if (ctrlName) {
            var result = null;
            if (window[ctrlName] && window[ctrlName].destroy && typeof(window[ctrlName].destroy) === "function") {
                // Perform destroy on the controller, if the method exists.
                app.logMessage("Calling destroy() on Controller " + ctrlName);
                result = window[ctrlName].destroy();
            }
            app.logMessage("Destroying Controller " + ctrlName);
            try {
                window[ctrlName] = null;
                delete window[ctrlName];
                app.currentPage.ctrl = null;
            } catch(e) {
                console.warn(e);
            }
            return result || false;
        }
        return true;
    }

    function doLogoutAction(){
        // Clear session data for this user.
        spark.clearSessionObject(contextName);

        // Perform standard logout actions.
        $("#mainContent").hide();
        spark.clearSessionObject("username");
        spark.clearSessionObject("sessionInfo");
        if (window.redirectOnLogout && window.loginScreenURI) {
            window.location.href = window.loginScreenURI;
        } else {
            console.warn("User has been marked as logged out.");
        }
    }

    var lookupJSDO = null;
    function getLookupData(lookupType, params, callback){
        if (!lookupJSDO) { lookupJSDO = spark.createJSDO("lookup"); }

        // Retrieve data from the JSDO and return with parsed data.
        lookupJSDO.invoke(lookupType, params || {})
            .then(function(jsdo, result, request){
                var data = (request.response || {}).ttLookup || null;
                if (data && data.ttLookup) {
                    data = data.ttLookup;
                }
                if (callback && typeof callback === "function") {
                    callback.apply(this, [data]);
                }
            });
    }

    function getSessionInfo(useLocalData){
        var loggedIn = false; // Assume false until known otherwise.
        var existingSession = spark.getSessionObject("sessionInfo") || {};
        var promise = $.Deferred();

        if ($.isEmptyObject(existingSession)) {
            // Can't use local data, doesn't exist (yet).
            useLocalData = false; // Fetch from server.
        }

        if (useLocalData) {
            // Just return the locally-stored session object when available.
            if (existingSession.anonymous !== undefined && (existingSession.anonymous === false || existingSession.anonymous === "false")) {
                loggedIn = true;
            }
            promise.resolve(existingSession, true, loggedIn);
        } else if (sessionReady) {
            // Tap into the promise for the JSDO session.
            sessionReady.then(function(){
                // Create a JSDO for user context and fetch session info.
                var userJSDO = spark.createJSDO("user");
                userJSDO.invoke("session", {})
                    .done(function(jsdo, success, request){
                        // Compare the existing (stored) session to the latest session object.
                        var latestSession = request.response;
                        var matches = true; // Assume true initially.
                        if (!$.isEmptyObject(existingSession) && existingSession.sessionID) {
                            matches = (existingSession.sessionID === request.response.sessionID);
                            if (!matches) {
                                console.warn("SessionID values to not match, possible session expiration!");
                            }
                            var wasAnon = (existingSession.anonymous === true ||
                                           existingSession.anonymous === "true" ||
                                           existingSession.username === "anonymous");
                            loggedIn = !wasAnon; // Is (still) logged in if not previously an anonymous user.
                        } else {
                            // If no previous session, consider logged in if not explicitly anonymous.
                            loggedIn = (latestSession.anonymous === false ||
                                        latestSession.anonymous === "false");
                        }
                        // Save the user's current session info when returned.
                        spark.setSessionObject("sessionInfo", (latestSession || null));
                        promise.resolve(latestSession, matches, loggedIn);
                    })
                    .fail(function(){
                        promise.reject("Failed to get session info from server.");
                    });
            });
        } else {
            promise.reject("Unable to find session promise object.");
        }
        return promise;
    }

    function loadController(pageName){
        updateStyles(); // Update any special screen styles.

        // Obtain the name of the page currently loaded.
        if (app.currentPage.name && app.currentPage.name !== "") {
            // Check if screen controller exists.
            var ctrlName = app.currentPage.name + "Ctrl";
            if (window[ctrlName]) {
                // Set a convenient handle to the controller.
                app.currentPage.ctrl = window[ctrlName];

                // Load any additional templates on the page.
                if (app.currentPage.ctrl.loadTemplates) {
                    /**
                     * This should run prior to init to avoid delays
                     * in returning the session info from the server.
                     */
                    app.currentPage.ctrl.loadTemplates();
                }

                // Support legacy screens that use a "bindAll" method, replaced with
                // a more distinct "init" method for initialization of a controller.
                if (app.currentPage.ctrl.bindAll && !app.currentPage.ctrl.init){
                    // Assign a "bindAll" as the init() method for this screen.
                    app.currentPage.ctrl.init = app.currentPage.ctrl.bindAll;
                }

                // Run controller init method if available.
                if (app.currentPage.ctrl && app.currentPage.ctrl.init) {
                    /**
                     * Obtain session info on each change of page.
                     * This is done for two reasons:
                     *  1) Making a REST request keeps the session active.
                     *  2) To know when the sessionID may have changed.
                     */
                    app.getSessionInfo() // Call without parameter to perform server check.
                        .then(function(session, matches, loggedIn){
                            // Load screen when session info returned.
                            if (!loggedIn && app.currentPage.secure) {
                                // Redirect un-authenticated user to index when page is secure.
                                spark.setSessionObject("loginTarget", window.location.href);
                                app.doLogoutAction();
                            } else if (loggedIn && !matches) {
                                // Redirect authenticated user to index when sessionID changes.
                                spark.clearSessionObject("loginTarget");
                                app.doLogoutAction();
                            } else {
                                // Continue loading the current page controller.
                                if (app.currentPage.ctrl && app.currentPage.ctrl.init) {
                                    app.currentPage.ctrl.init();
                                }

                                // Translate items on the recently-loaded view.
                                app.translateView("#" + app.currentPage.name + "View");
                            }
                        }, function(errorMsg){
                            // Continue to load screen even on error.
                            if (app.currentPage.ctrl && app.currentPage.ctrl.init) {
                                app.currentPage.ctrl.init();
                            }

                            // Translate items on the recently-loaded view.
                            app.translateView("#" + app.currentPage.name + "View");
                            showMessage(errorMsg, "warning"); // Display error message to user.
                        });
                } else {
                    console.warn("Screen controller lacks an init method:", ctrlName);
                }
            } else {
                console.warn("Unable to find screen controller object:", ctrlName);
            }
        }
    }

    var _menuLoading = false;
    function refreshMenu(loggedIn){
        var promise = $.Deferred();
        if (!_menuLoading) {
            _menuLoading = true; // Limit to 1 call at a time.

            var updateMenu = function(response){
                // Convert response to JSON array.
                var menuData = response.menuData || null;
                if (menuData && typeof(menuData) === "string") {
                    try {
                        // Must parse stringified data.
                        menuData = JSON.parse(menuData);
                    } catch(e){}
                }

                if ($("#mainMenu")) {
                    // Destroy any previous contents.
                    kendo.destroy($("#mainMenu").children());
                    $("#mainMenu").empty();

                    if (menuStyle && menuStyle === "vertical") {
                        // Create a custom vertical menu and set the data.
                        spark.nav.createVerticalStackMenu("#mainMenu", menuData || []);
                    } else {
                        // Create a standard KendoUI horizontal menu and set the data.
                        $("#mainMenu").kendoMenu({
                            dataSource: menuData || []
                        });
                    }
                } else {
                    console.info("No menu element has been defined.");
                }

                // Reset loading flag when done.
                _menuLoading = false;

                // Return the parsed menu data.
                return menuData;
            };

            // Create JSDO to access user's menu data.
            var userJSDO = spark.createJSDO("user");
            userJSDO.invoke("menu", {})
                .then(function(jsdo, status, request){
                    promise.resolve(updateMenu(request.response || {}));
                }, function(jsdo, status, request){
                    promise.resolve(updateMenu(request.response || {}));
                });
        }
        return promise;
    }

    function updateStyles(){
        setTimeout(function(){
            // Convert bootstrap tooltip objects.
            $("[data-toggle=tooltip]").tooltip();
            // Convert bootstrap popover objects.
            $("[data-toggle=popover]").popover();
        }, 100);
    }

    function messageHandler(data){
        if (notify && data && data.messages) {
            $.each(data.messages, function(i, message){
                notify.showMessage(message.messageText, message.messageType);
            });
        }
    }

    function startMessaging(){
        try{
            // Implementation of Node.js and Socket.io for instant WebSocket messaging.
            var protocol = (window.location.protocol == "https:") ? "https://" : "http://";
            var hostname = document.location.hostname || "";
            var server = protocol + hostname + ":1337";
            var promise = $.ajax({
                dataType: "script",
                url: server + "/socket.io/socket.io.js",
                success: function(result){
                    app.getSessionInfo()
                        .then(function(session, matches, loggedIn){
                            // Perform connection to server if able to load Socket.io library.
                            var sio = io.connect(server);
                            sio.on("connect", function(){
                                var callback = function(successful){
                                    if (successful) {
                                        // Handle incoming broadcasts (sends "data" as a parameter).
                                        sio.on("broadcast-data", messageHandler);
                                    } else {
                                        // If the request to subscribe was rejected, show an error message.
                                        console.warn("Unable to listen to Node.js server: " + server);
                                    }
                                };
                                sio.emit("listen", session.sessionID, callback);
                        });
                    });
                }
            });
        } catch(e){}
    }

    /***** Application Customizations *****/

    function openQuickMenu(options){
        var window = $("#QuickMenuModal");
        if (window) {
            if (!window.getKendoWindow()) {
                // Create a new window.
                window.kendoWindow({
                    actions: ["Close"],
                    draggable: false,
                    modal: true,
                    resizable: false,
                    scrollable: false,
                    title: "Quick Menu",
                    width: 600
                });

                var menu = $("#mainMenu").getKendoMenu();
                var menuData = menu.options.dataSource || [];
                var findItem = function(data, itemName){
                    var foundItem = null;
                    $(data).each(function(i){
                        var match = this.text.search(new RegExp(itemName, "i"));
                        if (this.text && this.url && match > -1) {
                            foundItem = this;
                            return false;
                        } else if (this.items) {
                            var item = findItem(this.items, itemName);
                            if (item) {
                                foundItem = item;
                                return false;
                            }
                        }
                    });
                    return foundItem;
                }

                // Bind to a local observable.
                var qmenuVM = kendo.observable({
                    menuItem: {},
                    menuSearch: ""
                });
                kendo.bind(window, qmenuVM);

                $("#QuickMenuModal input[name=MenuItem]").on("keydown", function(e){
                    // Catch the Enter key as it is pressed.
                    if (e.keyCode === 13) {
                        if ((qmenuVM.menuItem.url || "") !== "") {
                            // Navigate to the current URL, if available.
                            app.navigateTo(qmenuVM.menuItem.url);
                        }
                        e.preventDefault();
                        e.stopPropagation();
                        window.getKendoWindow().close();
                        return false;
                    }
                });

                $("#QuickMenuModal input[name=MenuItem]").on("keyup", function(e){
                    // Evaluate after each key press is complete.
                    var val = $(this).val() || "";
                    if (val.length >= 2) {
                        // Search for menu item if 2 or more letters provided.
                        var item = findItem(menuData, val);
                        if (item) {
                            qmenuVM.set("menuItem", item);
                        }
                    } else {
                        qmenuVM.set("menuItem", {});
                    }
                });
            } else {
                // Open the existing window.
                window.getKendoWindow().open();
            }
            window.getKendoWindow().center();

            // Reset the values within the window.
            if ($("#QuickMenuModal input[name=MenuItem]")) {
                var vm = $("#QuickMenuModal input[name=MenuItem]").get(0).kendoBindingTarget.source;
                if (vm) {
                    vm.set("menuItem", {});
                    vm.set("menuSearch", "");
                }
                $("#QuickMenuModal input[name=MenuItem]").focus();
            }
        }
    }

    function getLanguageStrings(languagePref){
        // Update local variable with new (normalized) language code.
        switch(languagePref){
            case "es":
            case "es-ES":
                // Spanish
                langCode = "es-ES";
                break;
            case "fr":
            case "fr-FR":
                // French
                langCode = "fr-FR";
                break;
            default:
                // English
                langCode = "en-US";
                break;
        };
        spark.setCookie("language", langCode);

        // Determine the proper language abbreviation based on preference.
        if (langCode && !kendo.cultures[langCode]) {
            // Only load the appropriate culture files for KendoUI if not present.
            $.getScript("vendor/kendo/js/cultures/kendo.culture." + langCode + ".min.js")
                .done(function(){
                    kendo.culture(langCode);
                });
            $.getScript("vendor/kendo/js/messages/kendo.messages." + langCode + ".min.js")
                .done(function(){
                    kendo.culture(langCode);
                });
        }
        if (!window.local || !local.strings || !local.strings[langCode]) {
            // Append appropriate application strings as based on the current language.
            $.getScript("assets/js/local.strings." + langCode + ".js")
                .done(function(){
                    if (local && local.strings && local.strings[langCode]) {
                        local.strings.current = local.strings[langCode];
                    }
                });
        }

        // Load translated strings from server.
        var userJSDO = spark.createJSDO("user");
        userJSDO.invoke("translations", {"langCode": langCode})
            .then(function(jsdo, result, request){
                // Populate local variable with any translated strings.
                spark.strings.addTranslatedStrings((request.response || {}).langStrings || {});

                // Change culture as based on language preference of the user.
                kendo.culture(langCode);
            });
    }

    function getUserPrefs(){
        try{
            // Make an AJAX request to Corticon.
            var data = {
                "Objects": [{
                    "Username": spark.getSessionObject("username"),
                    "UserRole": "ROLE_EndUser",
                    "__metadata": {
                        "#id": "UserPrefs_id_1",
                        "#type": "UserPrefs"
                    }
                }
            ]};
            $.ajax({
                dataType: "json",
                data: JSON.stringify(data),
                contentType: "application/json; charset=utf-8",
                headers: {
                    "Content-Type": "application/json",
                    dsName: "UserPreferences"
                },
                type: "POST",
                url: "/corticon/execute",
                success: function(data){
                    var record = ((data || {}).Objects || [])[0];
                    if (record.PrimaryColor !== "") {
                        $("#mainHeader").css("backgroundColor", record.PrimaryColor);
                    }
                }
            });
        } catch(e){}
    }

    function getText(originalText){
        // Returns a translated string, if available.
        if (local && local.strings && local.strings.current) {
            if (local.strings.current.application[originalText]) {
                // Return a general application string from static data.
                return local.strings.current.application[originalText];
            }
        }

        // Return a translated string from the internal library.
        // If a string does not exist, return original text as-is.
        return spark.strings.getTranslatedString(originalText);
    }

    function showMessage(message, type){
        if (notify) {
            notify.showMessage(message, type);
        } else {
            console.log(message, type);
        }
    }

    function showMessages(responseObject){
        if (notify) {
            notify.showMessages(responseObject);
        }
    }

    function translateView(selector){
        // Run standard translation using a specific method.
        spark.form.translateForm(selector, getText, {showRequiredIndicator: true});
    }

    function getAppContext(){
        var context = spark.getSessionObject(contextName);
        if (!context || context === "") {
            context = {}; // Default to an empty object.
            spark.setSessionObject(contextName, {});
        }
        return context;
    }

    function setAppContext(data){
        var context = getAppContext();
        if (typeof(data) === "object") {
            $.each(data, function(name, value){
                // Update only the passed object properties.
                context[name] = value;
            });
        }
        spark.setSessionObject(contextName, context);
        return context;
    }

    /***** Initialization *****/

    // Create a VM to be used by the header.
    var headerVM = kendo.observable({
        headerTitle: "Demo Application",
        user: {
            fullName: "",
            emailAddr: ""
        },
        changePassword: function(e){
            $("#ModalPassword").modal("show");
            modalPasswordCtrl.init();
            modalPasswordCtrl.vm.doReset();
        },
        editProfile: function(e){
            $("#ModalProfile").modal("show");
            modalProfileCtrl.init();
            modalProfileCtrl.vm.doReset();
        },
        showQuickMenu: function(e){
            openQuickMenu();
        }
    });
    $("#QuickMenuModal").hide();

    $(document).ready(function(){
        // Show loading modal until page is ready.
        kendo.ui.progress($(document.body), true);

        // Load current culture.
        kendo.culture(langCode);

        // Load the change-password modal.
        spark.loader.loadExtInclude("app/common/Password.html", "passwordModal");

        // Load the edit-password modal.
        spark.loader.loadExtInclude("app/common/Profile.html", "profileModal");

        if (sessionReady) {
            // If object is available, check for fulfillment of promise.
            sessionReady.then(function(){
                kendo.bind($("#mainHeader"), headerVM); // Bind VM to header.
                getSessionInfo()
                    .done(function(latestSession, matches, loggedIn){
                        if (loggedIn && !matches) {
                            // Redirect user to index when sessionID changes.
                            spark.getJsdoSession().authProvider.logout()
                                .then(function(){
                                    app.doLogoutAction();
                                });
                        }

                        // Get text replacements based on language.
                        getLanguageStrings(latestSession.language || "en-US");

                        // Populate header with user information.
                        headerVM.set("user.fullName", latestSession.fullname);
                        headerVM.set("user.emailAddr", latestSession.emailAddr);

                        // Perform first menu load after successful session check.
                        refreshMenu(loggedIn)
                            .then(function(data){
                                router.loggedIn = loggedIn; // Authentication state.
                                router.menuData = data; // Set current menu data.
                                router.start(); // Start router when menu available.
                                setTimeout(function(){
                                    kendo.ui.progress($(document.body), false);
                                }, 200);
                            });
                    }); // Obtain initial session information.
                updateStyles(); // Load any default styles.

                // Sample features (Corticon and Node.js Messaging).
                getUserPrefs(); // Obtain user prefs from Corticon.
                startMessaging(); // Subscribe to Node.js for messages.
            }, function(){
                app.logMessage("Failed to make session ready, logging user out.", true);
                app.doLogoutAction(); // Perform follow-up action for logout.
            });
        }
    });

    /***** Public Object *****/

    return {
        currentPage: {
            ctrl: null,
            name: "",
            params: {},
            path: "",
            secure: false,
            url: ""
        },
        doLogoutAction: doLogoutAction,
        getLookupData: getLookupData,
        getSessionInfo: getSessionInfo,
        logMessage: logMessage,
        navigateTo: router.navigate,
        refreshMenu: refreshMenu,
        showMessage: showMessage,
        showMessages: showMessages,
        translateView: translateView,
        getText: getText,
        headerVM: headerVM,
        getAppContext: getAppContext,
        setAppContext: setAppContext
    };

})();