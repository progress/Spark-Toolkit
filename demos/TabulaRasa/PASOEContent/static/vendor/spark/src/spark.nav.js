/**
 * @file Singleton object for application navigation.
 * @author Progress Services
 * @copyright Progress Software 2015-2017
 * @license Apache-2.0
 */
(function($, kendo){
    "use strict";

    if ($ && kendo && window.spark) {

        /**
         * Navigation operations for PMFO.
         * @namespace spark.nav
         * @memberof spark
         */
        window.spark.nav = {

            /**
             * Create a simplistic path-based router for site navigation.
             * @method createSimpleRouter
             * @memberof spark.nav
             * @param {Object} options Properties object for widget
             * @param {string} options.filePathPrefix Relative location of physical files
             * @param {string} options.mainContentID ID for loading content dynamically
             * @param {method} options.getLandingPage Obtain name of landing page file
             * @param {method} options.onChange Event callback on each change of route
             * @param {method} options.onLoad Event callback after loading extra files
             * @returns {Object} [kendo.Router]{@link http://docs.telerik.com/kendo-ui/api/javascript/router}
             */
            createSimpleRouter: function(options){
                // Options property must be an object.
                if (!options) { options = {}; }

                // Make sure property is set with a default ID.
                if (!options.mainContentID || options.mainContentID === "") {
                    options.mainContentID = "mainContent";
                }

                // Define a new router with specific paths.
                var router = new kendo.Router({
                    change: options.onChange || function(ev){}
                });

                function loadPage(page, path, sec, sub){
                    // Loads the model/view files and initializes the new page.
                    window.spark.loader.loadExtScreen(path, options.mainContentID, page)
                        .complete(function(){
                            if (options.onLoad && typeof(options.onLoad) === "function") {
                                options.onLoad(page, path, sec, sub);
                            }
                        });
                }

                // Add custom properties and methods.
                router.loggedIn = false; // Denotes AuthN state.
                router.menuData = []; // Placeholder for menu data.
                router.isSecurePage = function(url){
                    var isSecure = false;
                    $.each(this.menuData || [], function(i, topItem){
                        if (topItem.items) {
                            $.each(topItem.items, function(i, menuItem){
                                if (menuItem.url == url) {
                                    // When found, mark as secure if property is explicitly set.
                                    isSecure = (menuItem.secure === true);
                                }
                            });
                        }
                    });
                    return isSecure;
                };

                // Define a simple routing patterns for this application.
                router.route("/", function(){
                    /**
                     * Returning to the index page may require the loading of a specific
                     * landing page. Therefore we must assume a callback will be required
                     * and so a promise will be used to track the result. This allows
                     * the getLandingPage method to be asynchronous as well. Possible
                     * values are either a physical page (View+Controller) or a URI.
                     * For a URI the router will navigate to the target location.
                     */
                    var promise = $.Deferred();
                    if (options.getLandingPage) {
                        // Replace local promise with returned promise.
                        promise = options.getLandingPage();
                    } else {
                        // Immediately resolve the local promise.
                        promise.resolve("");
                    }

                    // Setup for successful response from promise.
                    promise.done(function(page){
                        if ((page || "").startsWith("#/")) {
                            // Navigate to the relative route and load from there.
                            router.navigate(page);
                        } else if ((page || "") !== "") {
                            var path = options.filePathPrefix + page;

                            // Perform some action prior to loading the new screen.
                            if (options.onBeforeLoad && typeof(options.onBeforeLoad) === "function") {
                                options.onBeforeLoad(loadPage, page, path);
                            } else {
                                loadPage(page, path);
                            }
                        } else {
                            // Just initialize the landing page as-is.
                            if (options.onLoad && typeof(options.onLoad) === "function") {
                                options.onLoad("");
                            }
                        }
                    });
                });
                router.route("/logout", function(){
                    // Perform a logout and redirect to login page.
                    window.spark.getJsdoSession().logout()
                        .then(function(){
                            if (options.onLogout) {
                                options.onLogout(); // Perform post-logout action.
                            }
                        });
                });
                router.route("/:page", function(page){
                    var path = options.filePathPrefix + page;

                    // Perform some action prior to loading the new screen.
                    if (options.onBeforeLoad && typeof(options.onBeforeLoad) === "function") {
                        options.onBeforeLoad(loadPage, page, path);
                    } else {
                        loadPage(page, path);
                    }
                });
                router.route("/:sec/:page", function(sec, page){
                    var path = options.filePathPrefix + sec + "/" + page;

                    // Perform some action prior to loading the new screen.
                    if (options.onBeforeLoad && typeof(options.onBeforeLoad) === "function") {
                        options.onBeforeLoad(loadPage, page, path, sec);
                    } else {
                        loadPage(page, path, sec);
                    }
                });
                router.route("/:sec/:sub/:page", function(sec, sub, page){
                    var path = options.filePathPrefix + sec + "/" + sub + "/" + page;

                    // Perform some action prior to loading the new screen.
                    if (options.onBeforeLoad && typeof(options.onBeforeLoad) === "function") {
                        options.onBeforeLoad(loadPage, page, path, sec, sub);
                    } else {
                        loadPage(page, path, sec, sub);
                    }
                });

                return router;
            },

            /**
             * Create a collapsible, vertically-stacked menu.
             * @method createVerticalStackMenu
             * @memberof spark.nav
             * @param {string} selector Target DOM element as [jQuery selector]{@link https://api.jquery.com/category/selectors/}
             * @param {Array(Object)} menuData Array of menu objects (parents + children)
             * @param {string} menuData.text Parent item title
             * @param {string} menuData.icon Font-Awesome icon class
             * @param {Array(Object)} menuData.items Array of child items
             * @param {string} menuData.items.text Child item title
             * @param {string} menuData.items.url Child item URL
             * @returns void
             */
            createVerticalStackMenu: function(selector, menuData){
                var el = $(selector);
                if (el) {
                    // Destroy any previous contents.
                    el.empty();

                    // Cycle through menu data, building structure.
                    var navItem = $('<nav class="nav-primary hidden-xs" data-ride="collapse" role="navigation"></nav>');
                    var navList = $('<ul class="nav" data-ride="collapse"></ul>');
                    if (typeof(menuData) === "object") {
                        $.each(menuData, function(i, parent){
                            var currentPath = ""; // Identifies the current link in use.
                            if (window.app && window.app.currentPage.path && window.app.currentPage.path != "") {
                                currentPath = "#" + window.app.currentPage.path.replace("app/views", "");
                            }

                            // Construct the parent menu item.
                            var navParentLink = $('<a href="javascript:void(0)" class="auto nav-link"></a>');
                            if (parent.icon) {
                                navParentLink.append($('<i class="fa ' + parent.icon + ' m-r-xs"></i>'));
                            } else if (parent.spriteCssClass) {
                                navParentLink.append($('<i class="' + parent.spriteCssClass + ' m-r-xs"></i>'));
                            }

                            // Add parent link to new parent menu item.
                            var navParent = $('<li class="nav-item"></li>');
                            navParentLink.append($('<span>' + parent.text + '</span>'));
                            navParent.append(navParentLink);

                            // Build all child menu items.
                            var navChildList = $('<ul class="nav dker"></ul>');
                            if (typeof(parent.items) === "object") {
                                $.each(parent.items, function(j, child){
                                    // Create the menu link for this child.
                                    var navChildLink = $('<a class="nav-link"></a>');
                                    navChildLink.attr("href", child.url);
                                    if (child.url.indexOf("http") === 0) {
                                        navChildLink.attr("target", "_blank");
                                    }

                                    // Create new child menu item and append link.
                                    var navChild = $('<li class="nav-item"></li>');
                                    navChild.append(navChildLink.text(child.text));
                                    navChildList.append(navChild);

                                    // Mark parent and child as active when needed.
                                    if (currentPath != "" && currentPath == child.url) {
                                        navParent.addClass("active");
                                        navChildLink.addClass("active");
                                    }
                                });
                            }

                            // Add children to parent menu, add to navigation.
                            navParent.append(navChildList);
                            navList.append(navParent);
                        });
                    }
                    navItem.append(navList);
                    el.append(navItem);
                } else {
                    console.info("No menu element has been defined.");
                }

                // Collapse navigation on click (via jQuery).
                $(document).on("click", ".nav-primary a", function (e) {
                    var $this = $(e.target), $active;
                    $this.is("a") || ($this = $this.closest("a"));
                    if ($(".nav-vertical").length){
                        return;
                    }

                    $active = $this.parent().siblings(".active");
                    $active && $active.find("> a").toggleClass("active") && $active.toggleClass("active").find("> ul:visible").slideUp(200);

                    ($this.hasClass("active") && $this.next().slideUp(200)) || $this.next().slideDown(200);
                    $this.toggleClass("active").parent().toggleClass("active");
                    $this.next().is("ul") && e.preventDefault();

                    setTimeout(function(){ $(document).trigger("updateNav"); }, 300);
                });
            }

        }; // window.spark.nav

    } // if
})(window.jQuery, window.kendo);
