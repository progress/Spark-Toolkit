var HomeCtrl = (function(){
    "use strict";

    var viewName = "#HomeView";

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
