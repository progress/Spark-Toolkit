/**
 * @file Singleton object for external file loading.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($, kendo){
    "use strict";

    if ($ && kendo && window.spark) {

        /**
         * File loading operations for PMFO.
         * @namespace spark.loader
         * @memberof spark
         */
        window.spark.loader = {

            /**
             * Loads an external screen (JS + HTML) from path into the DOM.
             * @method loadExtScreen
             * @memberof spark.loader
             * @param {string} rootPath Base name of file to be loaded
             * @param {string} contentID Unique DOM ID for anchoring loaded content
             * @param {string} pageName User-friendly name of page to load
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            loadExtScreen: function(rootPath, contentID, pageName){
                // Use jQuery Ajax to fetch the JS model file.
                return $.ajax({
                    dataType: "script",
                    url: rootPath + ".js",
                    success: function(jsResult){
                        // Use jQuery Ajax to fetch the HTML view file.
                        return $.ajax({
                            dataType: "html",
                            url: rootPath + ".html",
                            success: function(htmlResult){
                                // On success, add contents to DOM where specified.
                                kendo.destroy($("#" + contentID).children());
                                $("#" + contentID).empty();
                                $("#" + contentID).html(htmlResult);
                            },
                            error: function(jqXHR, textStatus, errorThrown){
                                if (jqXHR.status === 404) {
                                    // Requested file was not found.
                                    alert("Error locating HTML file " + rootPath + ".html");
                                } else {
                                    // Otherwise assume an error with security.
                                    if (window.loginScreenURI) {
                                        window.location.href = window.loginScreenURI;
                                    } else {
                                        window.location.href = "/";
                                    }
                                }
                            }
                        });
                    },
                    error: function(jqXHR, textStatus, errorThrown){
                        if (jqXHR.status === 404) {
                            // Requested file was not found.
                            alert("Error locating JavaScript file " + rootPath + ".js");
                        } else {
                            // Otherwise assume an error with security.
                            if (window.loginScreenURI) {
                                window.location.href = window.loginScreenURI;
                            } else {
                                window.location.href = "/";
                            }
                        }
                    }
                });
            },

            /**
             * Loads an external HTML modal from a specific location into the DOM.
             * @method loadExtInclude
             * @memberof spark.loader
             * @param {string} filePath Base path of file to be loaded
             * @param {string} contentID Unique DOM ID for anchoring loaded content
             * @param {string} templateID DOM ID of template in loaded file
             * @param {Object} options Data to be applied to the template
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            loadExtInclude: function(filePath, contentID, modalName, options){
                // Use jQuery Ajax to fetch the modal content.
                return $.ajax({
                    dataType: "html",
                    url: filePath,
                    success: function(htmlResult){
                        // On success, add contents to DOM where specified.
                        kendo.destroy($("#" + contentID).children());
                        $("#" + contentID).empty();
                        $("#" + contentID).html(htmlResult);
                        $("[data-toggle=tooltip]").tooltip();
                    },
                    error: function(result){
                        alert("Error loading template file " + filePath);
                    }
                });
            },

            /**
             * Loads an external [Kendo Template]{@link http://docs.telerik.com/kendo-ui/framework/templates/overview} from a specific location into the DOM.
             * @method loadExtTemplate
             * @memberof spark.loader
             * @param {string} filePath Base path of file to be loaded
             * @param {string} contentID Unique DOM ID for anchoring loaded content
             * @param {string} templateID DOM ID of template in loaded file
             * @param {Object} options Data to be applied to the template
             * @returns {Object} [Promise/Deferred object instance]{@link https://api.jquery.com/category/deferred-object/}
             */
            loadExtTemplate: function(filePath, contentID, templateID, options){
                // Use jQuery Ajax to fetch the template script.
                return $.ajax({
                    dataType: "html",
                    url: filePath,
                    success: function(tmplResult){
                        // On success, add contents to DOM where specified.
                        $("#" + contentID).append(tmplResult);
                        var template = kendo.template($("#" + templateID).html());
                        var htmlBody = template(options || {});
                        kendo.destroy($("#" + contentID).children());
                        $("#" + contentID).empty();
                        $("#" + contentID).html(htmlBody);
                    },
                    error: function(result){
                        alert("Error loading template file " + filePath);
                    }
                });
            }

        }; // window.spark.loader

    } // if
})(window.jQuery, window.kendo);
