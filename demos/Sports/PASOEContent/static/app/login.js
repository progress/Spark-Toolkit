/**
 * Create an immediately-invoked function expression that returns a static object.
 * This is to be available globally via the variable "app" (aka "window.app").
 *
 * Assumes presence of the following global variables:
 *  var serviceURI = "/<webapp_name>/"; // Prefix to utilize for all REST requests.
 *  var catalogURI = "/[web/pdo|<catalog>.json]"; // Location of the JSDO catalog file.
 *  var authModel = progress.data.Session.AUTH_TYPE_FORM; // Authentication model for JSDO.
 */
var app = (function(){
    "use strict";

    // Clear session data for this user.
    spark.clearSessionObject("DynSportsContext");

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
                    // Trigger a translation of any available text on the page.
                    translateView();
                }
            });
    }

    function getLanguageStrings(){
        // Load translated strings from server.
        var userJSDO = spark.createJSDO("user");
        userJSDO.invoke("translations", {"langCode": langCode})
            .then(function(jsdo, result, request){
                // Populate local variable with any translated strings.
                spark.strings.addTranslatedStrings((request.response || {}).langStrings || {});

                // Change culture as based on language preference of the user.
                kendo.culture(langCode);

                // Trigger a translation of any available text on the page.
                translateView();
            });
    }

    function getText(originalText){
        // Returns a locally translated string, if available.
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

    function translateForm(formSelector){
        // Run standard translation on a form using a specific method.
        spark.form.translateForm(formSelector, getText);
    }

    function translateView(){
        // Update certain common elements using hard-coded strings.
        $("#loginForm input[name=Username]").attr("placeholder", local.strings.current.common.username);
        $("#loginForm input[name=Password]").attr("placeholder", local.strings.current.common.password);
        $("#loginForm button[name=login]").html(local.strings.current.common.login);
        $("#loginForm span[name=register]").html(local.strings.current.common.register);
        $("#loginForm span[name=forgotPass]").html(local.strings.current.common.forgotPass);

        // Convert the placeholders for all input types.
        translateForm("#loginForm");
    }

    function showMessage(message, type){
        if (notify) {
            notify.showMessage(message, type);
        } else {
            console.log(message, type);
        }
    }

    function startSession(getStrings){
        // Create authentication provider, obtains anonymous access to back-end.
        spark.checkAuthentication(serviceURI, authModel)
            .then(function(authProvider, result, info){
                // If able to get anonymous access, create JSDO session and obtain catalog.
                spark.createSession(serviceURI, catalogURI, authModel)
                    .then(function(){
                        if (getStrings) {
                            // Update languages after session created, catalog downloaded.
                            getLanguageStrings();                            
                        }
                    });
            }, function(){
                // Something went wrong, indicating that the server may not be responding as expected.
                app.showMessage("Unable to reach authentication endpoint. Please confirm that the server is running.", "error");
            });
    }

    function doSessionLogin(username, password){
        // Show an indicator that the login is proceeding.
        kendo.ui.progress($("#loginForm"), true);

        function doActualLogin(){
            // Clear session data and perform login.
            spark.clearSessionObject("sessionInfo");
            spark.getJsdoSession().authProvider.login(username, password)
                .then(function(authProvider, result, info){
                    // Redirect when session info returned.
                    var target = spark.getSessionObject("loginTarget");
                    if (target && target !== "") {
                        window.location.href = target;
                    } else {
                        window.location.href = "app.html";
                    }
                }, function(){
                    resetAttempt(); // Reset any prompts/flags.
    
                    // Clear the credentials if login failed.
                    spark.clearSessionObject("username");
                    showMessage(getText("Login Failed"), "error");
                });
        }

        function resetAttempt(){
            kendo.ui.progress($("#loginForm"), false);
            startSession(false); // Reinstate JSDO session.
        }

        if (spark.getJsdoSession().loginResult === progress.data.Session.LOGIN_SUCCESS) {
            // Make sure any previous session is logged out.
            spark.getJsdoSession().authProvider.logout()
                .then(doActualLogin, resetAttempt);
        } else {
            // Otherwise no existing login for session.
            doActualLogin();
        }
    }

    /***** Initialization *****/

    // Create an observable object for login.
    var _processing = null;
    var loginVM = kendo.observable({
        params: {
            username: "",
            password: ""
        },
        doLogin: function(ev){
            var params = this.toJSON().params;
            var validator = $("#loginForm").kendoValidator().data("kendoValidator");
            if (!_processing && validator.validate()) {
                _processing = true; // Denote the method is running.

                // Remember the credentials in case the user reloads the page.
                // This is necessary to log back in to access the JSDO catalog.
                spark.setSessionObject("username", params.username);

                // Show an indicator that the login is proceeding.
                kendo.ui.progress($("#loginForm"), true);

                function resetAttempt(){
                    kendo.ui.progress($("#loginForm"), false);
                    _processing = false;
                }

                // Attempt login through TFA process.
                var tfaJSDO = spark.createJSDO("tfa");
                tfaJSDO.invoke("login", params)
                    .then(function(jsdo, result, request){
                        // Proceed with processing based on TFA option for account.
                        var useTFA = (request.response || {}).useTFA || false;
                        if (useTFA) {
                            // Continue with challenge dialog.
                            $("#ModalChallenge").modal("show");
                            modalChallengeCtrl.init();
                            modalChallengeCtrl.vm.doReset();
                            resetAttempt();
                        } else {
                            // Simply do the standard login.
                            setTimeout(function(){
                                doSessionLogin(params.username, params.password);
                                _processing = false;
                            }, 0);
                        }
                    }, resetAttempt);
            } else {
                if (ev) {
                    ev.preventDefault();
                }
            }
        },
        doPasswordReset: function(ev){
            $("#ModalPassReset").modal("show");
            modalPassResetCtrl.init();
            modalPassResetCtrl.vm.doReset();
        }
    });

    $(document).ready(function(){
        startSession(true); // Begin JSDO session.

        // Bind login form to MVVM observable.
        kendo.bind($("#loginForm"), loginVM);

        // Perform login on "enter" keypress when on password field.
        var keyOptions = {
            onEnter: function(){
                // Perform immediate login attempt on Enter key.
                loginVM.set("params.password", $("#loginForm input[name=Password]").val());
                loginVM.doLogin();
            }
        }
        spark.field.addKeypressEvent("#loginForm input[name=Password]", keyOptions);

        // Load the TFA challenge modal.
        spark.loader.loadExtInclude("app/common/Challenge.html", "challengeModal")
            .then(function(){
                // When loading of HTML is complete, prepare to receive events from modal.
                modalChallengeCtrl.vm.bind("modalDataReady", function(ev){
                    // When event "modalDataReady" is triggered by the modal,
                    // complete the login process via the JSDO session.
                    doSessionLogin(loginVM.get("params.username"), ev.data.challenge);
                });
            });

        // Load the password reset modals.
        spark.loader.loadExtInclude("app/common/PassReset.html", "passResetModal")
	        .then(function(){
	            // When loading of HTML is complete, prepare to receive events from modal.
	        	modalPassResetCtrl.vm.bind("modalDataReady", function(ev){
	                // When event "modalDataReady" is triggered by the modal,
	                // open the modal for the code confirmation (with context).
	        		$("#ModalConfirmCode").modal("show");
	                modalConfirmCodeCtrl.init();
	                modalConfirmCodeCtrl.vm.doReset(ev.data);
	            });
	        });
        spark.loader.loadExtInclude("app/common/ConfirmCode.html", "confirmCodeModal");

        // Set the year in the footer.
        $("#year").html(new Date().getFullYear());
    });

    return {
        showMessage: showMessage,
        getText: getText
    };
})();