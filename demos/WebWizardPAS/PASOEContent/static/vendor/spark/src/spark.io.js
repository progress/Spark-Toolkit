/**
 * @file Singleton object for common file IO transformations.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($){
    "use strict";

    if ($ && window.spark) {

        /**
         * File IO operations for PMFO.
         * @namespace spark.io
         * @memberof spark
         */
        window.spark.io = {

            /**
             * Obtain a Font-Awesome icon class based on file extension.
             * @method addExtensionClass
             * @memberof spark.io
             * @param {string} extension File extension startubg with "."
             * @returns {string} Set of FA icon classes
             */
            addExtensionClass: function(extension){
                switch(extension){
                    case ".jpg":
                    case ".img":
                    case ".png":
                    case ".gif":
                        return "fa fa-file-image-o fa-3x";
                    case ".doc":
                    case ".docx":
                        return "fa fa-file-word-o fa-3x";
                    case ".xls":
                    case ".xlsx":
                        return "fa fa-file-excel-o fa-3x";
                    case ".pdf":
                        return "fa fa-file-pdf-o fa-3x";
                    case ".zip":
                    case ".rar":
                        return "fa fa-file-zip-o fa-3x";
                    default:
                        return "fa fa-file-o fa-3x";
                }
            },

            /**
             * Create a standard Kendo file upload widget.
             * @method createUpload
             * @memberof spark.io
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Object} uploadOptions Options for upload behavior
             * @param {Object} overrides Overrides for the upload widget
             * @returns {Object} [kendo.ui.Upload]{@link http://docs.telerik.com/kendo-ui/api/javascript/ui/upload}
             */
            createUpload: function(selector, uploadOptions, overrides){
                var el = $(selector);
                if (el) {
                    return el.kendoUpload($.extend({
                        async: {
                            // autoUpload: when true, uploads begin as soon as files are dropped/chosen.
                            autoUpload: uploadOptions.autoUpload || false,

                            // batch: when multiple files are selected or dropped TOGETHER, sent as single POST.
                            batch: uploadOptions.batchUpload || false,

                            // relative path to this page: http://[server]:[port]/upload.
                            saveUrl: uploadOptions.saveUrl || "upload",

                            // saveField: sets the Content-Disposition "name" attribute to "group" the upload.
                            saveField: uploadOptions.saveField || "files"
                        },

                        // Basic operations (enable selection button, multi-file upload).
                        enabled: uploadOptions.enableUpload || false,
                        multiple: uploadOptions.multiUpload || false,

                        // Enables the display of the listing of [to-be] uploaded files.
                        showFileList: uploadOptions.showFileList || false,

                        // Template used to render the file list
                        template: uploadOptions.template || null,

                        // These events are fired only in async mode.
                        cancel: uploadOptions.onCancel || null,     // Fires when the upload has been cancelled while in progress.
                        complete: uploadOptions.onComplete || null, // Fires when all active uploads completed either successfully or with errors.
                        error: uploadOptions.onError || null,       // Fires when an upload/remove operation has failed.
                        progress: uploadOptions.onProgress || null, // Fires when upload progress data is available [not fired in IE <10].
                        success: uploadOptions.onSuccess || null,   // Fires when an upload/remove operation has been completed successfully.
                        upload: uploadOptions.onUpload || null,     // Fires when files are about to be uploaded; canceling will prevent the upload.

                        // Sync and async events.
                        select: uploadOptions.onSelect || null, // Triggered when a file is selected; canceling will prevent selection from occurring.
                        remove: uploadOptions.onRemove || null  // Fires when uploaded file is about to be removed; canceling will prevent the remove.
                    }, overrides)).getKendoUpload();
                }
                return null;
            }

        }; // window.spark.io

    } // if
})(window.jQuery);
