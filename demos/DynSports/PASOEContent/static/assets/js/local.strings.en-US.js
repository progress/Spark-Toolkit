(function(window){
    "use strict";

    if (typeof window.local === "undefined") {
        window.local = {};
    }

    if (typeof window.local.strings === "undefined") {
        window.local.strings = {};
    }

    window.local.strings["en-US"] = {
        name: "en-US",
        common: {
            login: "Login",
            logout: "Logout",
            submit: "Submit",
            password: "Password",
            username: "Username",
            register: "Register as New User",
            forgotPass: "Forgot Password?"
        },
        application: {}
    };
})(window);
