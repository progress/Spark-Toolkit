(function(window){
    "use strict";

    if (typeof window.local === "undefined") {
        window.local = {};
    }

    if (typeof window.local.strings === "undefined") {
        window.local.strings = {};
    }

    window.local.strings["es-ES"] = {
        name: "es-ES",
        common: {
            login: "Iniciar sesi&oacute;n",
            logout: "Cerrar sesi&oacute;n",
            submit: "Enviar",
            password: "Contrase&ntilde;a",
            username: "Nombre de usuario",
            register: "Registrarse como usuario nuevo",
            forgotPass: "¿Se te olvid&oacute; tu contrase&ntilde;a?"
        },
        application: {}
    };
})(window);
