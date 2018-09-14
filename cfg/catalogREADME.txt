When utilizing the Spark version of the "Data Object Handler" methodology for accessing business logic,
the CatalogManager serves as gateway for discovery of those resources. This is driven by the catalog.json
file and is dependent on certain configuration options to be set according to your application.

Within the master "Config" object, should be at least 2 child objects: General and ServiceSource.

General Options:
    ApiVersion    [decimal]   Expected version to be used with all API's.
    BusinessRoot  [character] Starting location for reading all business entities.
    EnableDebugs  [logical]   Display additional info as resources are loaded.
    IdProperty    [character] Name of property to use for record ID purposes.
    SeqProperty   [character] Name of property to use for result sequence purposes.
    PreLoader     [character] Special procedure to run prior to loading resources.
    ReadFilter    [character] Name of URL parameter that will hold any filters.
    ServicePrefix [character] Name of URL prefix (after transport) for all services.
    EnableDebugs  [logical]   Flag to enable debug messages related to the handler.

ServiceSource Options:
    ServiceName     [character] Name of the service as exposed via the catalog.
    ServiceURI      [character] Path for resources (relative to actual service).
    ClassPath       [character] Class path of related business entity classes.
    SendOnlyChanges [logical]   Only send the fields that change, not the record (false).
    UseRequest      [logical]   Should invoke operations use request/response (false).

By default, the BusinessRoot property above represents a folder on disk from which all resources will
be discovered. To change this to utilize a procedure library (PL), simply change the value of BusinessRoot
to be the full name of your PL file (eg. something.pl). However, because a PL file cannot be recursively
searched, any resources to be discovered must at least be stated by providing an extra property in each
of the ServiceSource entries called "ServiceResource".

If intending to support any out-of-the-box services using the OE.Web.DataObject.DataObjectHandler class,
the default service prefix of /pdo will be a point of conflict. To that end the Spark framework allows you
to override this value and use any prefix you wish. An example would be "api" which will result in the
typical URL path becoming /web/api[/<service>[/resource[/method]]]

ServiceResource Options:
    Object [character] Class package or procedure path or of this service resource.

Note: To quickly build an initial catalog.json for use with a PL file, first run the application with code
on disk (using a folder name for the BusinessRoot option), and either the EnableDebugs option set to true
or the logging-level at 4 or above. This will produce a Config.json file in your CATALINA_BASE/work folder.
You may then use the contents of that file to help establish a pattern for specifying the array of options
to be provided within the ServiceResource property. Alternatively, see the sample below:

{
 "Config": {
  "General": [
    {
      "ApiVersion": 4.3,
      "CatalogService": "Spark.Core.Service.ICatalog",
      "BusinessRoot": "Business.pl",
      "EnableDebugs": false,
      "IdProperty": "id",
      "SeqProperty": "",
      "PreLoader": "",
      "ReadFilter": "filter",
      "ServicePrefix": "api",
      "EnableDebugs": false
    }
  ],
  "ServiceSource": [
    {
      "ServiceName": "Common",
      "ServiceURI": "\/web\/pdo\/common",
      "ClassPath": "Business",
      "SendOnlyChanges": false,
      "UseRequest": true,
      "ServiceResource": [
        {
          "Object": "Business.Locality"
        },
        {
          "Object": "Business.UserData"
        },
        {
          "Object": "Business\/HelloWorld.p"
        }
      ]
    }
  ]
 }
}
