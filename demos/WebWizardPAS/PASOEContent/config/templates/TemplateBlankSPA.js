var <Spark_TemplateName>Ctrl = (function(){
    "use strict";

    var viewName = "#<Spark_TemplateName>View";

    var primaryVM = kendo.observable({
        context: {},
        params: {}
    });

    function init(){
        // Bind the observable to the view.
        kendo.bind($(viewName), primaryVM);
    }

    function loadTemplates(){
        // Load additional templates for header/footer.
    }

    return {
        init: init,
        loadTemplates: loadTemplates
    };

})();
