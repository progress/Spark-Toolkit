# Changelog


## OpenEdge 11.7

### v4.2.0

- Synchronized enhancements from v3.3.0 release.
- Update codebase to support the latest 11.7.2 service pack (adds more CCS integration).
- Implements better handling for multiple IWebHandler-based services, differentiation of classes.
- Supports new UnloadEntity event for DOH, will only utilize code when OE version matches.
- Add example of menu logic to output role-sensitive options for System management.
- Move some maintenance classes to a new System service (manage accounts, security, etc.).
- Add a maintenance screen for adjusting InterceptURI rules via oeablSecurity.csv file (in OE11.7).	
- Implement a copy of DynSports as just "Sports" using only DOH web services as available in PDS.


### v4.1.1

- Synchronized enhancements from v3.2.1 release.


### v4.1.0

- Synchronized enhancements from v3.2.0 release.


### v4.0.2

- Synchronized enhancements from v3.1.1 release.


### v4.0.1

- Synchronized enhancements from v3.1.1 release.
- Alter default security files to address a sessioning issue with 11.7


### v4.0.0

- First release of the framework compatible with OpenEdge 11.7.0 (new project/security metadata).
- Adjust configuration files for new security model in 11.7 (latest Spring Security Framework).


## OpenEdge 11.6

### v3.3.0

- NOTICE: This patch requires a schema change to WebState. Apply the Delta-DF file: delta-20171012.df
- Initial implementation of two-factor authentication (TFA) for users who opt-in for the feature.
- Modifications to account management screen to allow enabling of TFA and choice of token delivery.
- Added utility classes for conversions (Binary to Integer/Hex, etc.)
- Added utility class for Base32 encoding/decoding.
- Added security class for HMAC hashing via SHA-1.
- Added security classes one-time-password generation (hash or time-based).
- Reference implementation of 2-factor authentication in ABL, requires schema change.
- Implement profile management modal for DynSports to enable 2FA features, generate QR code.
- Ensure compatibility with Google Authenticator and others for standard TOTP code generation.
- Minor bugfixes throughout codebase to enhance stablility of the application.


### v3.2.1

- New patch to ensure all major fixes from the current minor release are captured and to prompt upgrade.
- Added support for a "params" property to the createInvokeLookup/createResourceLookup Spark UI methods.
- Made the Response object more receptive to inheritance and changing of error/return property names.
- Added a public property in the Spark DOH implementation to allow changing of the service prefix.
- Removed code from the Spark directory related to the FluidUI front-end, which is not actively maintained.
- Demo code added to widgets page, illustrates advanced pop-up search functionality (customized modal).
- Fix the spark.loader logic for JS/HTML files to redirect to the login when user session has expired.
- Add feature to store/retrieve grid state info for screens (DynSports demo and wizard templates).
- Allow use of any dataset name for CRUD+Submit methods, while reporting the proper entity name.
- Allow BE classes to have no list of capabilities for server-side operations (for plugin).
- Fix Spark.js logic to obtain URL params when using the #/ in the URL path.
- Various bugfixes and enhanced error handling/messages where necessary.


### v3.2.0

- Contains breaking changes for SparkEntity class!
- Changed numRecs, skip, and top values to INT64 variables, which altered class interface.
- Changed startRow and skip values to be returned as INT64 from filter criteria (read operation).
- Add support for serialize-name on temp-tables, reporting correctly in catalog and in data ouput.
- Update to latest JSDO library, which brought changes via a new AuthenticationProvider mechanism.
- Changes to spark.js library to support newest changes in JSDO for authentication/security.
- Adding support for foreignKeys property in catalog data (supplied by entity class property).
- Corrected templates for wizard to include new foreignKeys property--MUST IMPLEMENT IN EXISTING CLASSES!
- Simplify process of adding field property overrides by use of a new helper class (FieldInfo).
- Simplify process of adding foreign keys by use of a new helper class (ForeignKey).
- Provide support for duplicate URL params, which are to be interpreted as an array of values.
- Improvements to the catalog viewer to show better samples and report schema properly.
- Fixed several minor bugs in the Catalog Viewer, from display glitches to handling catalog features.
- Fixed a bug in the class serialization logic (for JSON/Binary input/output).
- Added a workaround with idProperty in catalog to avoid a problem with KUIB when creating records.
- Added a dummy account, "anonymous", in the users.properties file to allow login to work with form-local security.
- Adjusted template for WebWizard to implement latest login process for JSDO (with Auth Provider).
- Integrated a new FileUpload class as WebHandler to provide built-in upload abilities (used in DynSports).
- Integrated a new DataObjectHandler event handler class to allow automatic integration of PMFO with the DOH pattern.
- Added a project "Minimus" as a back-end example for use of DataObjectHandler pattern from PDSOE, found in 11.6.3+.
- Incorporated the sample Password class from DynSports into the framework (provides SHA-1 encryption, hash compare).


### v3.1.2

- Improved cleanup of managers during shutdown, destroy all instances properly.
- Enhancements to support running under ABLUnit, handle session type of 4GLClient.
- Transition API checking to pre-invoke method of RouteManager (where it should've been initially).


### v3.1.1

- Update templates with improved JSDO DataSource creation, using Spark JS library.
- Add more built-in logic to Spark JS extensions of DataSource creation, notably callbacks based on JSDO events.
- Update templates for SPA login/landing for WebWizard, allowing for responsive logo images and new header format.
- Enhance the screen destruction process when navigating to a new page or when refreshing the current page.
- Allow CUD methods against JSDO's to pass a flag to use the Submit() method.
- Minor bugfixes in catalog logic to adjust messaging during startup.
- Fixed some memory leaks, improved shutdown logic for managers (graceful ending of started managers).
- Adjust codepage of response longchar to UTF-8, use JsonObject clone for response instead of longchar parse.
- Added detecton of non-MSAS (4GLCLIENT) environment (for logging/startup) for use with ABLUnit testing.


### v3.1.0

- Altered format of the JS library to be more consistent across all files, primary reason for minor release.
- Added a JS compiler and process to the client-side libraries, refactored to resolve potential errors reported.
- Completed changes to WebWizard to make it a standalong project, with all configs bundled in the WebApp itself.


### v3.0.3

- Fixes to WebWizard, making more of a standalone webapp to add without project files.
- Add some more in-depth invoke debug messages when set to levels 6, 7, or higher.
- Output warning when duplicate methods found in API, but don't fail loading.
- Fixed enum issue in Connection Manager class, support username/password for APSV.
- Removed unused CPO reference in Remote Facade class.
- Mask password in debug output from OEUserRealm class.
- Minor whitespace fixes and additional code comments.
- Various minor bugfixes across the PMFO back-end.
- Improvements to devinfo and cataview helper pages.
- Add error checking to error properly if JSON request is not an object/array as expected.
- Obtain temp-table as an array, rather than an object (dataset remains an object).
- Fixed a major bug preventing inbound temp-table/dataset params from working with invokes.
- Adjusted catalog output to include any temp-table params as schema, even if part of a dataset.
- Created a new service for unit testing via the web, and a sample "params" test class.
- Corrected a memory leak due to not cleaning up DataAdmin objects in SessionManager.


### v3.0.2

- Rollup of all changes since 3.0.1, attempting to switch to a model of tagging releases AFTER significant changes.
- Created a "devinfo.html" dashboard to show info about JS libraries and PAS info, allow killing agents/sessions.
- Added "version" property to Spark JS library, with current release version and timestamp for build.
- Adjust schema logic to work with multiple temp-tables by the same name (from different datasets).
- Added more comments to code for improved ABLDoc output.
- Add ANT build target to produce ABLDoc output for PMFO.
- Add ANT build target to produce PCTDoc output for PMFO.
- Add launch scripts for PMFO Server framework in PDSOE.
- Generated documentation (ABL and PCT) for PMFO (Spark/CCS).


### v3.0.1

- Created to emphasize additional, non-breaking fixes to initial 3.0 release.
- Updated JSDO library, and added features to allow JSDO session to be restored after page refresh.
- Removed user credentials from sessionStorage to meet security needs of clients (was workaround for JSDO issue).
- Altered startup logic for login/application screens due to above JSDO and AuthN enhancements.
- Added new StatsManager class for tracking request information to back- end services.
- Fixed major bug in CatalogManager (when API contains more than 1 dataset).
- Updated KendoUI library to latest for 2017 (January release).
- Updated CSS to match latest KendoUI styles, and include new font options.
- Improved logic for SessionManager when loading database domains.
- Added support for databases to use the "Application Registry" for domains.
- Corrected catalog output of schema for non-primary objects (dataDefinitions).
- Added project for Java servlet for simple file upload abilities.
- Incorporated file upload examples into DynSports demo via new Widgets screen.
- Fixed API versioning by including WebHandler URI examples in DynSports demo.
- Added to demo project to include examples of API calls prior to authentication.
- Adjusted DynSports demo SportsRealm to allow for use of unauthenticated API calls.
- Changed WebWizardAdv logic to be non-reliant on any databases (more portable r- code).
- Improve build scripts for sample PAS deployment (TabulaRasa).
- Update font- awesome library to latest version.


### v3.0.0

- Started as placeholder for framework changes to support Common Community Standards based class integrations.
- WARNING: THIS RELEASE INCLUDES NUMEROUS BREAKING CHANGES! Implement carefully using the UPGRADE_CCS guidlines.
- Clarified the process for creating CP token/config for securing Hybrid Realm server requests.
- Added support for multiple domains/passcodes for Hybrid Realm validation (default: single domain).
- Moved logic to alter logging level from a sample activate.p to the LoggingManager class.
- Implemented an example of automatically changing logging level from within DataObjectHandler.
- Renamed the config.json to startup.json to match changes to StartupManager (from ConfigManager).
- Added better scripting for addition of domains and creation of necessary config files from that data.
- Various bugfixes, added after initial version creation.


## OpenEdge 11.5

### v2.3.0

- Added new demo SportsDOH to illustrate the DataObjectHandler example in OE 11.6.3.
- Added field annotation logic to provide extra schema attributes for temp-table fields.
- Corrected a bug that prevented before-image data from being sent in JSON output.
- Multiple bugfixes.


### v2.2.0

- Added a new Serialize class that illustrates class serialization to JSON or binary.
- Added custom InputStream/OutputStream classes for dealing with longchar data.
- Added support for user property values as longchar data (stored as a CLOB).
- Provide the request/response object to the MessageManager for easier access.
- Adjust response processing to be more consistent for both REST and Web transports.
- Provide a dedicated writeResponse method for creating the WebResponseWriter object.
- Adjusted config files to latest from 11.6.2 (if starting a new ABL Web App project).
- MAJOR BUGFIX: Clean up CP handles due to memory leak in GetClientPrincipal() calls!
- Added custom shutdown.p to remove old session data from the WebState table (DynSports).


### v2.1.0

- Modified the WebWizardPAS to be smarter about using the provides Service URI value to place BE classes within an additional subdirectory.
- | Only works when the path is prefixed as "/web/pdo" and is not referring to a "common" directory.
- | The 3rd URL element will become the new directory for your BE, and should reflect the name of the service to which that entity should belong.
- Fixed the menu logic in the wizard to update the correct file (and report the full path) after adding a UI screen.
- Added support for selecting a ProDataset as your schema object for a new Business Entity (requires selection of a matching DB table).
- Added support for custom Service URI, which affects the location of the generated BE and related class property.
- Began adding support for versioning of API's (requires a change to catalog.json config file).
- Fixed issue in catalog logic that would not allow schema with a CLOB to be exposed.
- Remove code that threw errors in OEUserRealm class, instead return appropriate values.
- MAJOR BUGFIX: Clean up CP handles due to memory leak in GetClientPrincipal() calls!
- Adjust wizard logic to permit UNC paths for generated file output.
- Various minor bug fixes and enhancements.


### v2.0.0

- Changed the format of the catalog.json configuration file to allow setting of multiple services for exposure, relating a service URI with a specific class path.
- Added initial support for new features in forthcoming JSDO Catalog version.
- Fixed various memory leaks (uncleaned DS/TT handles) leftover in memory when session is ended.
- Updated the vendor libraries, including jQuery and KendoUI.


### v1.4.0

- Added new PASOE projects (ABL Web App) to demonstrate both local code execution and a distributed environment (PASOE-Web for DMZ/Gateway, PASOE-APSV for logic).
- Added new parameter for facades to accept a path value representing the service being requested.
- | This allows for service, resource, and method to uniquely identify the code to be invoked.
- | It also provides namespacing of the registered BE classes to work only with a specific service entry point.
- | This is mainly for security purposes, since the front- end URL’s are already secured by path/service.
- Added ability to pass back a JSON object consisting of name/value pairs via the MessageManager, which can be headers for the web handler for WS- PAS.
- | This allows for custom headers to be set on the framework side and output automatically within the transport layer.
- Track the real resource (class) and method within the ConfigManager during dynamic invocation, so that any back- end code that needs to know the true values can access them.
- Add new facade classes to handle local or remote data execution, and to allow calling via an AppServer (PASOE- APSV).
- Return a standard error (502 Bad Gateway) when remote AppServer is unavailable (for use with RemoteFacade).
- Streamlined logging from Spark startup (dynamic resources, etc.) to make logs easier to read.
- Added better logging features to the Manager base class and implementation classes.
- Created a new dynamic resource interface/class without default CRUD/Submit methods (for non- JSDO use).
- | This new IDynamicResource/DynamicResource combo continues to work within the CatalogManager alongside the IDynamicEntity/DynamicEntity combo.
- | The difference is that a DynamicResource does not contain any data methods, and expects all defined methods to become invokes.
- | It can still report itself to the catalog and should be capable of being called like any other invoke method via the JSDO.
- Added ability to use separate config directories when using a multi-webapp PASOE instance.
- Enhanced the ConnectionManager class to track session context data, and to allow reconnecting to a server.
- Added a configuration file for handlers, allowing them to use either Direct or Remote facade. If using a Remote facade, allow setting of a default server and remote procedure to be run.
- Enhanced connection manager to support a new procedure handle as part of a remote AppServer connection.
- Added example of streaming a binary file back to the client using PASOE- WS.
- Modified wizard and framework to allow changing the idProperty value in generated catalogs.
- | This is the value that is used by the generated schema to hold the RowID of each record, as required by the JSDO for paging and other operations.
- | This is set via the JSON config files (wizard.json, catalog.json).
- Adjusted the way a generated catalog reports its URI, which affects the (newly added) logic for handling per- service resources.
- Changed URL prefix of "si" to "pdo" to better match the pattern from engineering, and to standardize on the name of "Progress Data Object" when referring to web- enabled business entities.
- Added example of a modal (Quick Menu) on the application header, ala. functionality from the old Evolution demo.
- Renamed the new- ish WebServiceInterface to SparkHandler (still abstract), to better illustrate its purpose as an inherited class for the other WebHandler classes.
- Removed all code that was sealing (or creating) the anonymous CP token, removed related config file and config- reading logic.
- Added a new RouteManager to handle dynamic location of Business Entities, now hands off to ServiceManager only to start the entity (which itself is a service).
- Refactored catalog requests to go through same RouteManager and execute via the same interface as all other requests.
- Simplified the initial WebHandler classes created for the project into a single DataObjectHandler that utilizes the new RouteManager and condensed runService call.


### v1.3.0

- Prepare for use with PASOE by adding some sample handlers (JSDO + Catalog).
- Created new facade for use with Web Handlers (PASOE WebSpeed).
- Various bugfixes and minor enhancements.


### v1.2.0

- Removed JS libraries for IE <=9 due to Microsoft kill- switch on browser.
- Updated to more recent jQuery and other vendor libraries.
- Add example of using Node.js to do pub/sub with messages.
- Added a Blank template for creating transactional screens.
- Added "use strict" to SPA templates, per typical IIFE practice.
- Added a new configuration file for custom template types.
- Simplified wizard/generator (based on new custom template config).


### v1.1.0

- Split the role of the wizard into only 2 options: generate BE or UI, not both.
- Integrated use of a JSDO catalog with wizard on the front-end for UI generation.
- Provided sample integration with Corticon for rules, using both an ABL and AJAX approach.
- Updated color scheme to prepare for the coming company changes in 2016 (no logo used at present).
- Moved plugins.js file from the /vendor/psc/ directory to /spark/lib/ to avoid confusion with the JSDO library.
    NOTE: This requires a replacement of "/psc/plugins.js" with "/spark/lib/plugins.js"


### v1.0.0

- First real "release" for use. Changelog officially started.