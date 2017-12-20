var <Spark_EntityName>Ctrl = (function(){
    "use strict";

    var primaryVM = kendo.observable({
        params: {
        }
    });

    function init(){
        // Bind all models to screen content.
        kendo.bind($("#content"), primaryVM);
    }

    function loadTemplates(){
        // Load additional templates for header/footer.
    }

    return {
        init: init,
        loadTemplates: loadTemplates
    };

})();
