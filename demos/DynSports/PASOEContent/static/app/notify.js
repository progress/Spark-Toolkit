/**
 * Centralized notification logic, to be reused in different HTML page controllers as needed.
 */

var notify = (function(){
    "use strict";

    // Selector of element where notifications should be anchored.
    var notificationSelector = "#notification";

    var _notificationArea = null;
    function showMessage(message, type){
        if (!_notificationArea) {
            // Create notification widget as needed, when not present.
            // Override with extra properties as required for application.
            var options = {
                appendTo: null,
                position: {
                    pinned: false,
                    right: 30,
                    top: 50
                },
                stacking: "down",
                width: "30em"
            };
            _notificationArea = spark.notify.setNotificationArea(notificationSelector, options);
        }
        if (_notificationArea) {
            // Add wrapper style around message before display.
            message = '&nbsp;<span style="word-wrap:break-word;white-space:normal;">' + message + '</span>';
            _notificationArea.showNotification(message, type);
        }
    }

    function showMessages(responseObject){
        // Show multiple messages, given a response object.
        var errorArray = (responseObject || {})._errors || [];
        $.each(errorArray, function(i, error){
            switch(error._errorType){
                case "ERROR":
                case "FATAL":
                case "TRACE":
                    // Any error type.
                    showMessage(error._errorMsg, "error");
                    break;
                case "WARNING":
                    // Warnings only.
                    showMessage(error._errorMsg, "warning");
                    break;
                case "SUCCESS":
                    // Success only.
                    showMessage(error._errorMsg, "success");
                    break;
                default:
                    // INFORMATION or VALIDATION types.
                    showMessage(error._errorMsg, "info");
            }
        });
    }

    return {
        showMessage: showMessage,
        showMessages: showMessages
    };

})();