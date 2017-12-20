(function(window){
    "use strict";

    if (typeof window.local === "undefined") {
        window.local = {};
    }

    if (typeof window.local.strings === "undefined") {
        window.local.strings = {};
    }

    window.local.strings["fr-FR"] = {
        name: "fr-FR",
        common: {
            login: "S'identifier",
            logout: "Se d&eacute;connecter",
            submit: "Soumettre",
            password: "Mot de passe",
            username: "Nom d'utilisateur",
            register: "S'inscrire en tant que nouvel utilisateur",
            forgotPass: "Mot de passe oubli&eacute;?"
        },
        application: {}
    };
})(window);
