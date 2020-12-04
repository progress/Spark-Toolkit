/*------------------------------------------------------------------------
    File        : CatalogManager
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Dec 19 14:30:46 EST 2014
    Notes       : Setting the logging-level for your ABL Application to at
                  least 3 (verbose) will trigger additional messages in
                  the logs as well as output multiple files in the session
                  temp directory (eg. the service mapping files).

    This class provides 3 distinct functions at present:
        1) Discover any classes/procedures to be exposed as RESTful endpoints
            Performed by loadResources()
        2) Create a JSDO-compatible DataObject Catalog for public consumption
            Performed by getCatalog()
        3) Register all ABL resources as DataObjectServices for internal use
            Performed by registerService() via registerAllServices()

    In respect to the DataObject Catalog and the DataObjectServices these
    provide similar but limited sets of data about the exposed resources.
    While they draw upon the same sources of information, the artifacts
    describe this data differently for each of their intended purposes.
    Therefore, a "source of truth" is provided in the form of ProDatasets
    within this class which contains all necessary information gathered
    during the resource discovery process (stored in dsResource). 
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Progress.Json.ObjectModel.ObjectModelParser from propath.
using OpenEdge.Core.* from propath.
using OpenEdge.Core.Collections.* from propath.
using OpenEdge.Net.HTTP.MethodEnum from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using OpenEdge.Web.DataObject.* from propath.
using OpenEdge.Web.DataObject.Writer.* from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.ISchemaManager from propath.
using Spark.Core.Service.Service from propath.
using Spark.Core.Service.ISparkEntity from propath.
using Spark.Core.Service.IDynamicEntity from propath.
using Spark.Core.Service.IDynamicResource from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Util.OperationEnum from propath.
using Spark.Core.Util.OSTools from propath.
using Spark.Core.Util.Reflection from propath.

block-level on error undo, throw.

&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW
&GLOBAL-DEFINE ANNOTATIONS_FILE annotations.json

class Spark.Core.Manager.CatalogManager inherits Spark.Core.Manager.Manager implements Spark.Core.Manager.ICatalogManager use-widget-pool:

    define public property ApiVersion     as decimal   no-undo get. protected set.
    define public property IdProperty     as character no-undo get. protected set.
    define public property SeqProperty    as character no-undo get. protected set.
    define public property ReadFilter     as character no-undo get. protected set.
    define public property ServicePrefix  as character no-undo get. protected set.
    define public property CatalogService as character no-undo get. protected set.
    define public property UseRequestObj  as logical   no-undo get. protected set.

    define protected property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.

    define protected property oSchemaManager as ISchemaManager no-undo
        get:
            if not valid-object(oSchemaManager) then
                assign oSchemaManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ISchemaManager)), ISchemaManager).
            return oSchemaManager.
        end get.
        set.

    define protected property TemporaryDir as character no-undo initial ""
        get():
            if TemporaryDir eq "" then
                assign TemporaryDir = right-trim(replace(session:temp-directory, "~\", "~/"), "~/").
            return TemporaryDir.
        end get.
        set.

    define protected property Annotations as JsonObject no-undo
        get():
            if not valid-object(Annotations) then do:
                /* Look for a central annotations JSON file and parse this for use throughout the life of the CatalogManager. */
                file-info:filename = substitute("&1/&2", right-trim(OSTools:sparkConf, "/"), "{&ANNOTATIONS_FILE}").
                if file-info:full-pathname ne ? then do on error undo, throw:
                    define variable oParser as ObjectModelParser no-undo.

                    assign oParser = new ObjectModelParser().
                    Annotations = cast(oParser:ParseFile(file-info:full-pathname), JsonObject).

                    finally:
                        delete object oParser no-error.
                    end finally.
                end. /* file present */
            end. /* not valid-object */
            return Annotations.
        end get.
        set.

    define protected property ParamUUID as int64 no-undo initial 0
        get():
            /* Automatically increment value by 1 on each get. */
            assign ParamUUID = ParamUUID + 1.
            return ParamUUID.
        end get.
        set.

    define protected variable cPreLoader   as character  no-undo.
    define protected variable cDefaultUUID as character  no-undo.
    define protected variable lUseDebugs   as logical    no-undo initial false.
    define protected variable lHasOEBLBE   as logical    no-undo initial true.
    define protected variable oCatRegistry as JsonObject no-undo.

    /* General settings for the catalog manager. */
    define protected temp-table GeneralParam no-undo serialize-name "General"
        field ApiVersion     as decimal   /* Expected version to be used with all API's.              */
        field CatalogService as character /* Service class for delivering catalog output for clients. */
        field BusinessRoot   as character /* Starting location for reading all business entities.     */
        field IdProperty     as character /* Name of property to use for record ID purposes.          */
        field SeqProperty    as character /* Name of property to use for result sequence purposes.    */
        field PreLoader      as character /* Special procedure to run prior to loading resources.     */
        field ReadFilter     as character /* Name of URL parameter that will hold any filters.        */
        field ServicePrefix  as character /* URI prefix for services exposed by Spark (eg. pdo, api). */
        index idxEntity      is primary unique BusinessRoot
        .

    /* Pre-defined services to be exposed via the catalog manager. */
    define protected temp-table ServiceList no-undo serialize-name "ServiceSource"
        field ServiceUUID     as character serialize-hidden /* Unique ID for this service (Name + URI).          */
        field ServiceName     as character                  /* Name of the service as exposed via any catalog.   */
        field ServiceURI      as character                  /* Path for resources (relative to actual service).  */
        field ClassPath       as character                  /* Class path of related business entity classes.    */
        field SendOnlyChanges as logical   initial false    /* Only send the fields that change, not the record. */
        field UseRequest      as logical   initial false    /* Should invoke operations use request/response.    */
        index idxPrimary      is primary unique ServiceName ServiceURI
        index idxClassPath    is         unique ClassPath
        .

    /* Initial definitions or discovered resources to expose on a per-service basis. */
    define protected temp-table ResourceList no-undo serialize-name "ServiceResource"
        field ServiceName as character serialize-hidden        /* Name of the service as will be exposed via any catalog.      */
        field ServiceUUID as character serialize-hidden        /* Inherited UUID from the ServiceList.                         */
        field ClassPath   as character serialize-name "Object" /* Class package or procedure path or of this service resource. */
        index idxPrimary  is primary unique ClassPath
        .

    /* The configuration dataset as used by the catalog.json manager configuration file. */
    define protected dataset dsConfig serialize-name "Config" for GeneralParam, ServiceList, ResourceList
        data-relation ServiceResource for ServiceList, ResourceList relation-fields(ServiceName, ServiceName) nested
        .

    /**
     * ServiceList is our initial "service listing", but because tables cannot exist in more than
     * 1 dataset we use this as a clone for associating the ResourceInfo table and its children.
     */
    define protected temp-table ServiceInfo no-undo serialize-name "Service"
        field ServiceUUID     as character serialize-hidden
        field ServiceName     as character serialize-name "Name"
        field ServiceURI      as character serialize-name "URI"
        field ClassPath       as character
        field SendOnlyChanges as logical   initial false
        field UseRequest      as logical   initial false
        index idxPrimary      is primary unique ServiceName ServiceURI
        index idxName         is         unique ClassPath
        .

    define protected temp-table ResourceInfo no-undo serialize-name "Resource"
        field ServiceUUID  as character serialize-hidden         /* Identifier for service.                                     */
        field ResourceUUID as character serialize-hidden         /* Identifier for resource.                                    */
        field ClassPath    as character serialize-name "Package" /* Actual class path (aka. resource name) for API operations.  */
        field PublicName   as character serialize-name "Name"    /* Public name for resource, as used by the catalog generator. */
        field SourcePath   as character serialize-name "Source"  /* For all types, path to file on disk relative to propath.    */
        field ResourceURI  as character serialize-name "URI"     /* Explicit path element for this resource's final URI.        */
        field ApiVersion   as character serialize-name "Version" /* Semantic version to be used for methods of this resource.   */
        field ProcHandle   as handle    serialize-hidden         /* For procedures, a handle to the procedure run as a super.   */
        field IsClass      as logical   serialize-hidden         /* Denotes loaded resource is a class per rcode-info:is-class. */
        field ValidClass   as logical   serialize-hidden         /* For classes, denotes a valid interface implementation.      */
        field EntityName   as character serialize-hidden         /* For business entities, denotes the name of the dataset.     */
        field EntityKeys   as character serialize-hidden         /* For business entities, denotes any primary key fields.      */
        field ForeignKeys  as character serialize-hidden         /* For business entities, denotes any foreign key fields.      */
        field ClassSig     as character serialize-hidden         /* For business entities, holds full signature of class.       */
        field Security     as Progress.Lang.Object serialize-hidden /* Experimental Feature: Stores info about URI security.    */
        index idxPrimary   is primary unique ResourceUUID
        index idxPublic    is         unique ServiceUUID ClassPath
        index idxResource  is         unique ServiceUUID PublicName
        .

    define protected temp-table MethodInfo no-undo serialize-name "Operation"
        field ResourceUUID    as character serialize-hidden
        field MethodName      as character serialize-name "Method"
        field PublicName      as character serialize-name "Name"
        field MethodURI       as character serialize-name "URI"
        field MethodSignature as character serialize-name "Signature"
        field OperationType   as character serialize-name "Operation"
        field OperationVerb   as character serialize-name "HttpVerb"
        field ContentType     as character serialize-name "MediaType" initial "application/json"
        field Security        as Progress.Lang.Object serialize-hidden
        index idxPrimary      is primary unique ResourceUUID MethodName
        index idxPublic       is         unique ResourceUUID PublicName
        .

    define protected temp-table ParameterInfo no-undo serialize-name "Parameter"
        field ResourceUUID    as character serialize-hidden
        field ParamUUID       as int64     serialize-hidden
        field MethodName      as character serialize-name "Method"
        field ParamName       as character serialize-name "Name"
        field PublicName      as character serialize-name "Alias"
        field IOMode          as character serialize-name "Mode"
        field DataType        as character serialize-name "ABLType"
        field DataTypeExtent  as integer   serialize-name "Extent"  initial 0
        field ElementType     as character serialize-name "Element" initial "field"
        index pukOrder        is primary unique ParamUUID /* Must keep these in order of discovery. */
        .

    define protected temp-table ResourceProperty no-undo serialize-name "Property"
        field ResourceUUID  as character serialize-hidden
        field OperationType as character serialize-name "Operation" /* Type: create, read, update, delete, etc. */
        field PropertyName  as character serialize-name "Property"  /* Resource annotation property name.       */
        field PropertyType  as character serialize-name "DataType"  /* Resource annotation property datatype.   */
        field PropertyValue as character serialize-name "Value"     /* Resource annotation property value(s).   */
        index idxPrimary    is primary unique ResourceUUID OperationType PropertyName
        .

    define protected temp-table EntityProperty no-undo serialize-name "Entity"
        field EntityName as character            serialize-name "Entity"     /* Name of entity (dataset). */
        field TableName  as character            serialize-name "Table"      /* Name of table to modify.  */
        field FieldData  as Progress.Lang.Object serialize-name "Attributes" /* Attributes as JsonObject. */
        index idxPrimary is primary unique EntityName TableName
        .

    define protected dataset dsResource serialize-name "Mapping"
        for ServiceInfo, ResourceInfo, MethodInfo, ParameterInfo, ResourceProperty
        data-relation Service for ServiceInfo, ResourceInfo
        relation-fields(ServiceUUID, ServiceUUID)
        nested foreign-key-hidden
        data-relation Resource for ResourceInfo, MethodInfo
        relation-fields(ResourceUUID, ResourceUUID)
        nested foreign-key-hidden
        data-relation Operation for MethodInfo, ResourceProperty
        relation-fields(ResourceUUID, ResourceUUID, OperationType, OperationType)
        nested foreign-key-hidden
        data-relation Params for MethodInfo, ParameterInfo
        relation-fields(ResourceUUID, ResourceUUID, MethodName, MethodName)
        nested foreign-key-hidden
        .


    /**************************** Protected Helper Methods *****************************/


    method protected void clearResourceMethods ( input pcResourceUUID as character ):
        /* Resource Discovery Process */
        define buffer bMethod for MethodInfo.

        for each bMethod exclusive-lock
           where bMethod.ResourceUUID eq pcResourceUUID:
            assign bMethod.MethodSignature = "".
        end. /* for each bMethod */
    end method. /* clearResourceMethods */


    method protected character getJsonType ( input pcABLType as character ):
        /* DataObject Catalog Method */
        case pcABLType:
            when "DATE" or
            when "DATETIME" or
            when "DATETIME-TZ" or
            when "CLOB" or
            when "CHARACTER" then
                return "string".
            when "DECIMAL" then
                return "number".
            when "INTEGER" then
                return "integer".
            when "LOGICAL" then
                return "boolean".
        end case.
    end method. /* getJsonType */


    method protected character getList ( input poJsonArray as JsonArray ):
        define variable cString as character no-undo.
        define variable iCount  as integer   no-undo.
        define variable iX      as integer   no-undo.

        if valid-object(poJsonArray) then
            assign iCount = poJsonArray:length.

        do iX = 1 to iCount:
            if poJsonArray:GetType(iX) eq JsonDataType:String then
                assign cString = substitute("&1,&2", cString, poJsonArray:GetCharacter(iX)).
        end.

        return trim(cString, ",").
    end method. /* getList */


    method protected void processAnnotations ( input pcResourceUUID as character,
                                               input pcClassPath    as character,
                                               input pcSourcePath   as character ):
        /* Resource Discovery Process */
        define variable cAnnoName    as character no-undo.
        define variable cPublicName  as character no-undo.
        define variable cResourceURI as character no-undo.
        define variable lWriteBI     as logical   no-undo.
        define variable lIsClass     as logical   no-undo.

        define buffer bService  for ServiceList.
        define buffer bSrvcRes  for ResourceList.
        define buffer bResource for ResourceInfo.
        define buffer bMethod   for MethodInfo.
        define buffer bParam    for ParameterInfo.

        /* Get a default name and URI. */
        assign
            lIsClass     = (pcSourcePath gt "") ne true /* Is class when no source path is present. */
            cAnnoName    = if lIsClass then pcClassPath else entry(num-entries(pcSourcePath, "/"), pcSourcePath, "/")
            cPublicName  = if lIsClass then entry(num-entries(pcClassPath, "."), pcClassPath, ".") else entry(1, cAnnoName, ".")
            cResourceURI = "/" + cPublicName /* Set a default for URI using the derived public name. */
            .

        /* Get any annotations from this class and attempt to update any registered methods. */
        if valid-object(this-object:Annotations) then
        do on error undo, throw:
            define variable oAnnotation       as JsonObject         no-undo.
            define variable oProgram          as JsonObject         no-undo.
            define variable oData             as JsonObject         no-undo.
            define variable oMethods          as JsonObject         no-undo.
            define variable oMethod           as JsonObject         no-undo.
            define variable oSubArr           as JsonArray          no-undo.
            define variable oSubObj           as JsonObject         no-undo.
            define variable oResourceSecurity as JsonObject         no-undo.
            define variable cMethodName       as character          no-undo.
            define variable cMethods          as character extent   no-undo.
            define variable cAnnoNames        as character extent   no-undo.
            define variable cFields           as character          no-undo.
            define variable cName             as character          no-undo.
            define variable cOldServiceURI    as character          no-undo.
            define variable cNewServiceURI    as character          no-undo.
            define variable cNewServiceName   as character          no-undo.
            define variable cNewServiceUUID   as character          no-undo.
            define variable cSchemaName       as character          no-undo.
            define variable cMappingType      as character          no-undo.
            define variable cCapabilities     as character          no-undo.
            define variable iVersion          as integer   extent 3 no-undo.
            define variable iX                as integer            no-undo.
            define variable iY                as integer            no-undo.
            define variable iZ                as integer            no-undo.
            define variable oSemVersion       as SemanticVersion    no-undo.

            if valid-object(this-object:Annotations) and this-object:Annotations:Has(cAnnoName)
               and this-object:Annotations:GetType(cAnnoName) eq JsonDataType:Object then
                assign oAnnotation = this-object:Annotations:GetJsonObject(cAnnoName).
            else
                return. /* There are no annotations for this resource. */

            for first bResource no-lock
                where bResource.ResourceUUID eq pcResourceUUID,
                first bService no-lock
                where bService.ServiceUUID eq bResource.ServiceUUID:
                assign cOldServiceURI = bService.ServiceURI.
            end. /* first bResource, bService */

            /* Look for a valid "program" grouping of annotations, which might be in the "user" grouping. */
            if oAnnotation:Has("program") and oAnnotation:GetType("program") eq JsonDataType:Object then
                assign oProgram = oAnnotation:GetJsonObject("program").

            /* Parse annotations for this resource (program). */
            if valid-object(oProgram) and oProgram:Has("progress.service.resource FILE")
               and oProgram:GetType("progress.service.resource FILE") eq JsonDataType:Object then do:
                assign oSubObj = oProgram:GetJsonObject("progress.service.resource FILE").
                assign
                    cPublicName  = oSubObj:GetCharacter("name") when oSubObj:Has("name")
                    cResourceURI = oSubObj:GetCharacter("URI") when oSubObj:Has("URI")
                    cSchemaName  = oSubObj:GetCharacter("schemaName") when oSubObj:Has("schemaName")
                    .
            end. /* progress.service.resource FILE */

            if valid-object(oProgram) and oProgram:Has("openapi.openedge.service")
               and oProgram:GetType("openapi.openedge.service") eq JsonDataType:Object then do:
                assign oSubObj = oProgram:GetJsonObject("openapi.openedge.service").
                assign cNewServiceURI = oSubObj:GetCharacter("URI") when oSubObj:Has("URI").
                find first bService no-lock
                     where bService.ServiceURI eq cNewServiceURI no-error.
                if available(bService) then
                    assign
                        cNewServiceName = bService.ServiceName
                        cNewServiceUUID = bService.ServiceUUID
                        .
            end. /* openapi.openedge.service */

            if valid-object(oProgram) and oProgram:Has("openapi.openedge.resource.access")
               and oProgram:GetType("openapi.openedge.resource.access") eq JsonDataType:Object then do:
                assign oResourceSecurity = oProgram:GetJsonObject("openapi.openedge.resource.access").
            end. /* openapi.openedge.resource.access */

            if valid-object(oProgram) and oProgram:Has("openapi.openedge.resource.version")
               and oProgram:GetType("openapi.openedge.resource.version") eq JsonDataType:Object then do:
                assign oSubObj = oProgram:GetJsonObject("openapi.openedge.resource.version").
                assign
                    iVersion[1] = integer(oSubObj:GetCharacter("major")) when oSubObj:Has("major")
                    iVersion[2] = integer(oSubObj:GetCharacter("minor")) when oSubObj:Has("minor")
                    iVersion[3] = integer(oSubObj:GetCharacter("patch")) when oSubObj:Has("patch")
                    .

                assign oSemVersion = new SemanticVersion(iVersion[1], iVersion[2], iVersion[3]).
            end. /* openapi.openedge.resource.version */

            if oAnnotation:Has("data") and oAnnotation:GetType("data") eq JsonDataType:object then
            do on error undo, throw:
                extent(cAnnoNames) = ?.
                assign
                    oData      = oAnnotation:GetJsonObject("data")
                    cAnnoNames = oData:GetNames()
                    .

                do iX = 1 to extent(cAnnoNames):
                    case cAnnoNames[iX]:
                        when "openapi.openedge.entity.primarykey" then do:
                            if (cSchemaName gt "") eq true then do:
                                if oData:GetType(cAnnoNames[iX]) eq JsonDataType:Object then do:
                                    assign oSubArr = new JsonArray().
                                    oSubArr:Add(oData:GetJsonObject(cAnnoNames[iX])).
                                end.
                                else if oData:GetType(cAnnoNames[iX]) eq JsonDataType:Array then
                                    assign oSubArr = oData:GetJsonArray(cAnnoNames[iX]).

                                if valid-object(oSubArr) then
                                do iY = 1 to oSubArr:Length:
                                    assign
                                        oSubObj = oSubArr:GetJsonObject(iY)
                                        cFields = ""
                                        .

                                    if oSubObj:Has("fields") and oSubObj:GetType("fields") eq JsonDataType:Array then do:
                                        assign oSubArr = oSubObj:GetJsonArray("fields").
                                        do iY = 1 to oSubArr:Length:
                                            /* Turn the array of fields into a comma-delimited list. */
                                            assign cFields = trim(substitute("&1,&2", cFields, oSubArr:GetCharacter(iY)), ",").
                                        end.
                                    end.
                                    else if oSubObj:Has("fields") and oSubObj:GetType("fields") eq JsonDataType:String then
                                        assign cFields = oSubObj:GetCharacter("fields").
    
                                    if (cFields gt "") eq true then
                                        for first bResource exclusive-lock
                                            where bResource.ResourceUUID eq pcResourceUUID
                                              and bResource.EntityName eq cSchemaName:
                                            assign bResource.EntityKeys = cFields.
                                        end. /* for first bResource */
                                end. /* do iY */

                                delete object oSubArr no-error.
                            end. /* cSchemaName */
                        end. /* openapi.openedge.entity.primarykey */

                        when "openapi.openedge.entity.foreignkey" then do:
                            if (cSchemaName gt "") eq true then do:
                                define variable oFKeys as JsonArray  no-undo.
                                define variable oFKey  as JsonObject no-undo.

                                assign
                                    oSubObj = oData:GetJsonObject(cAnnoNames[iX])
                                    oFKeys  = new JsonArray()
                                    oFKey   = new JsonObject()
                                    .

                                /* Create an FK array as expected by the CatalogManager from Spark.Core.Util.ForeignKey. */
                                if oSubObj:Has("name") and oSubObj:GetType("name") eq JsonDataType:String then do:
                                    oFKey:Add("name", oSubObj:GetCharacter("name")).
                                    oFKey:Add("fields", new JsonArray()).
                                    oFKey:Add("parent", new JsonObject()).
    
                                    if oSubObj:Has("fields") and oSubObj:GetType("fields") eq JsonDataType:Array then do:
                                        assign oSubArr = oSubObj:GetJsonArray("fields").
                                        do iY = 1 to oSubArr:Length:
                                            oFKey:GetJsonArray("fields"):Add(oSubArr:GetCharacter(iY)).
                                        end.
                                    end.
                                    else if oSubObj:Has("fields") and oSubObj:GetType("fields") eq JsonDataType:String then
                                        oFKey:GetJsonArray("fields"):Add(oSubObj:GetCharacter("fields")).
    
                                    if oSubObj:Has("parent") and oSubObj:GetType("parent") eq JsonDataType:String then
                                        oFKey:GetJsonObject("parent"):Add("name", oSubObj:GetCharacter("parent")).
    
                                    oFKey:GetJsonObject("parent"):Add("fields", new JsonArray()).
                                    if oSubObj:Has("parentFields") and oSubObj:GetType("parentFields") eq JsonDataType:Array then do:
                                        assign oSubArr = oSubObj:GetJsonArray("parentFields").
                                        do iY = 1 to oSubArr:Length:
                                            oFKey:GetJsonObject("parent"):GetJsonArray("fields"):Add(oSubArr:GetCharacter(iY)).
                                        end.
                                    end.
                                    else if oSubObj:Has("parentFields") and oSubObj:GetType("parentFields") eq JsonDataType:String then
                                        oFKey:GetJsonObject("parent"):GetJsonArray("fields"):Add(oSubObj:GetCharacter("parentFields")).
    
                                    oFKeys:Add(oFKey).
                                    for first bResource exclusive-lock
                                        where bResource.ResourceUUID eq pcResourceUUID
                                          and bResource.EntityName eq cSchemaName:
                                        assign bResource.ForeignKeys = string(oFKeys:GetJsonText()).
                                    end. /* for first bResource */
                                end. /* name */

                                delete object oFKeys no-error.
                                delete object oFKey no-error.
                            end. /* cSchemaName */
                        end. /* openapi.openedge.entity.foreignkey */

                        when "openapi.openedge.entity.field.property" then do:
                            define variable oProps  as JsonObject no-undo.
                            define variable cTables as character  no-undo extent.
                            define variable cTable  as character  no-undo.
                            define variable cField  as character  no-undo.
                            define variable cValue  as character  no-undo.

                            assign oProps = new JsonObject().

                            if oData:GetType(cAnnoNames[iX]) eq JsonDataType:Object then do:
                                assign oSubArr = new JsonArray().
                                oSubArr:Add(oData:GetJsonObject(cAnnoNames[iX])).
                            end.
                            else if oData:GetType(cAnnoNames[iX]) eq JsonDataType:Array then
                                assign oSubArr = oData:GetJsonArray(cAnnoNames[iX]).

                            if valid-object(oSubArr) then
                            do iY = 1 to oSubArr:Length:
                                assign
                                    oSubObj = oSubArr:GetJsonObject(iY)
                                    cTable  = ""
                                    cField  = ""
                                    cName   = ""
                                    cValue  = ""
                                    .

                                assign
                                    cTable  = oSubObj:GetCharacter("table") when oSubObj:Has("table")
                                    cField  = oSubObj:GetCharacter("field") when oSubObj:Has("field")
                                    cName   = oSubObj:GetCharacter("name") when oSubObj:Has("name")
                                    cValue  = oSubObj:GetCharacter("value") when oSubObj:Has("value")
                                    .

                                if (cTable gt "") eq true then do:
                                    if not oProps:Has(cTable) then
                                        oProps:Add(cTable, new JsonObject()).
                                    if not oProps:GetJsonObject(cTable):Has(cField) then
                                        oProps:GetJsonObject(cTable):Add(cField, new JsonObject()).

                                    if cName eq "validation" and cValue eq "required" then do:
                                        oProps:GetJsonObject(cTable):GetJsonObject(cField):Add("validation", new JsonObject()).
                                        oProps:GetJsonObject(cTable):GetJsonObject(cField):GetJsonObject("validation"):Add("required", true).
                                    end.
                                    else if can-do("true,false", cValue) then
                                        oProps:GetJsonObject(cTable):GetJsonObject(cField):Add(cName, (cValue eq "true")).
                                    else
                                        oProps:GetJsonObject(cTable):GetJsonObject(cField):Add(cName, cValue).
                                end. /* Table Name Present */
                            end. /* do iY */

                            extent(cTables) = ?.
                            assign cTables = oProps:GetNames().
                            do iZ = 1 to extent(cTables):
                                this-object:describeFields(cSchemaName, cTable, oProps:GetJsonObject(cTable)).
                            end.

                            delete object oProps no-error.
                            delete object oSubArr no-error.
                        end. /* openapi.openedge.entity.field.property */
                    end case.
                end. /* do iX cAnnoNames */

                catch err as Progress.Lang.Error:
                    oLoggingManager:logError(substitute("Error in data/schema annotations for '&1'", pcClassPath), err, "SPARK-ERR", 0).
                    /* Do not throw error from this point, allow processing to continue. */
                end catch.
            end. /* has data */

            /* Methods and Procedures should be mutually exclusive, but the annotation parsing is the same. */
            if (oAnnotation:Has("method") and oAnnotation:GetType("method") eq JsonDataType:object) or
               (oAnnotation:Has("procedure") and oAnnotation:GetType("procedure") eq JsonDataType:object) then
            do on error undo, throw:
                /* Parse annotations for this resource's methods. */
                extent(cMethods) = ?.
                assign
                    oMethods = if oAnnotation:Has("method") then oAnnotation:GetJsonObject("method") else oAnnotation:GetJsonObject("procedure")
                    cMethods = oMethods:GetNames()
                    .

                /* Match up any available method (from reflection) to annotations. */
                do iX = 1 to extent(cMethods):
                    /* Isolate the method name from the annotation structure. */
                    assign cMethodName = trim(entry(1, cMethods[iX], "(")).

                    /* Locate an existing method/procedure for the resource. */
                    find first bMethod exclusive-lock
                         where bMethod.ResourceUUID eq pcResourceUUID
                           and bMethod.MethodName eq cMethodName no-error.
                    if available(bMethod) then do:
                        extent(cAnnoNames) = ?.
                        assign
                            oMethod       = oMethods:GetJsonObject(cMethods[iX])
                            cAnnoNames    = oMethod:GetNames()
                            cMappingType  = "" /* Reset for each method. */
                            cCapabilities = "" /* Reset for each method. */
                            lWriteBI      = false /* Default for each method. */
                            .

                        if oMethod:Has("openapi.openedge.export") and oMethod:GetType("openapi.openedge.export") eq JsonDataType:Object then do:
                            assign oSubObj = oMethod:GetJsonObject("openapi.openedge.export").
                            assign lWriteBI = can-do("true,yes,1", oSubObj:GetCharacter("writeDataSetBeforeImage")) when oSubObj:Has("writeDataSetBeforeImage").
                        end. /* openapi.openedge.export */

                        do iY = 1 to extent(cAnnoNames):
                            case cAnnoNames[iY]:
                                when "progress.service.resourceMapping" then do:
                                    assign oSubObj = oMethod:GetJsonObject(cAnnoNames[iY]).
                                    if oSubObj:GetCharacter("type") eq "REST" then
                                        assign
                                            bMethod.OperationType = lc(oSubObj:GetCharacter("operation")) when oSubObj:Has("operation")
                                            bMethod.PublicName    = oSubObj:GetCharacter("alias") when oSubObj:Has("alias") and oSubObj:GetCharacter("alias") gt ""
                                            bMethod.MethodURI     = oSubObj:GetCharacter("URI") when oSubObj:Has("URI")
                                            bMethod.ContentType   = oSubObj:GetCharacter("mediaType") when oSubObj:Has("mediaType")
                                            .

                                    /* Override method attributes for certain operations. */
                                    case bMethod.OperationType:
                                        when OperationEnum:read:toString() then
                                            assign
                                                bMethod.PublicName    = bMethod.OperationType
                                                bMethod.OperationVerb = lc(MethodEnum:get:toString())
                                                .
                                        when OperationEnum:create:toString() then
                                            assign
                                                bMethod.PublicName    = bMethod.OperationType
                                                bMethod.OperationVerb = lc(MethodEnum:post:toString())
                                                .
                                        when OperationEnum:update:toString() then
                                            assign
                                                bMethod.PublicName    = bMethod.OperationType
                                                bMethod.OperationVerb = lc(MethodEnum:put:toString())
                                                .
                                        when OperationEnum:delete:toString() then
                                            assign
                                                bMethod.PublicName    = bMethod.OperationType
                                                bMethod.OperationVerb = lc(MethodEnum:delete:toString())
                                                .
                                        when OperationEnum:submit:toString() then
                                            assign
                                                bMethod.PublicName    = bMethod.OperationType
                                                bMethod.OperationVerb = lc(MethodEnum:put:toString())
                                                .
                                        when OperationEnum:count:toString() then
                                            assign
                                                bMethod.PublicName    = bMethod.OperationType
                                                bMethod.MethodURI     = "/" + OperationEnum:count:toString()
                                                bMethod.OperationVerb = lc(MethodEnum:get:toString())
                                                .
                                        otherwise
                                            assign /* Assume invoke for any other operations. */
                                                bMethod.OperationVerb = lc(MethodEnum:put:toString())
                                                .
                                    end case. /* bMethod.OperationType */

                                    if lWriteBI and can-do("read,create,update,delete,submit", bMethod.OperationType) then do:
                                        if (cNewServiceURI gt "") then
                                            find first bService no-lock
                                                 where bService.ServiceURI eq cNewServiceURI no-error.
                                        else
                                            find first bService no-lock
                                                 where bService.ServiceURI eq cOldServiceURI no-error.

                                        if available(bService) then
                                            this-object:addProperty(bService.ServiceURI, pcClassPath, bMethod.OperationType, "useBeforeImage", "logical", "true").
                                    end.
                                end. /* progress.service.resourceMapping */

                                when "openapi.openedge.method.access" then do:
                                    /* Store the annotation as an object when a "role" property is present. */
                                    if oMethod:GetJsonObject(cAnnoNames[iY]):Has("role") then
                                        assign bMethod.Security = oMethod:GetJsonObject(cAnnoNames[iY]).
                                end. /* openapi.openedge.method.access */

                                when "openapi.openedge.method.property" then do:
                                    if oMethod:GetType(cAnnoNames[iY]) eq JsonDataType:Object then do:
                                        assign oSubObj = oMethod:GetJsonObject(cAnnoNames[iY]).
                                        case oSubObj:GetCharacter("name"):
                                            when "verb" then
                                                assign bMethod.OperationVerb = lc(oSubObj:GetCharacter("value")) when oSubObj:Has("value").
                                            when "mappingType" then
                                                assign cMappingType = oSubObj:GetCharacter("value").
                                            when "capabilities" then do:
                                                assign cCapabilities = this-object:getList(oSubObj:GetJsonArray("value")).
                                            end.
                                        end case.
                                    end. /* Annotation Object */
                                    else if oMethod:GetType(cAnnoNames[iY]) eq JsonDataType:Array then do:
                                        assign oSubArr = oMethod:GetJsonArray(cAnnoNames[iY]).
                                        do iZ = 1 to oSubArr:length:
                                            assign oSubObj = oSubArr:GetJsonObject(iZ).
                                            case oSubObj:GetCharacter("name"):
                                                when "verb" then
                                                    assign bMethod.OperationVerb = lc(oSubObj:GetCharacter("value")) when oSubObj:Has("value").
                                                when "mappingType" then
                                                    assign cMappingType = oSubObj:GetCharacter("value").
                                                when "capabilities" then do:
                                                    assign cCapabilities = this-object:getList(oSubObj:GetJsonArray("value")).
                                                end.
                                            end case.
                                        end. /* do iZ oSubArr */
                                    end. /* Annotation Array */
                                end. /* openapi.openedge.method.property */

                                when "openapi.openedge.method.parameter" then do:
                                    if oMethod:GetType(cAnnoNames[iY]) eq JsonDataType:Object then do:
                                        assign oSubArr = new JsonArray().
                                        oSubArr:Add(oMethod:GetJsonObject(cAnnoNames[iY])).
                                    end.
                                    else if oMethod:GetType(cAnnoNames[iY]) eq JsonDataType:Array then
                                        assign oSubArr = oMethod:GetJsonArray(cAnnoNames[iY]).

                                    if valid-object(oSubArr) then
                                    do iZ = 1 to oSubArr:length:
                                        assign
                                            oSubObj = oSubArr:GetJsonObject(iZ)
                                            cName   = oSubObj:GetCharacter("name") when oSubObj:Has("name")
                                            .

                                        for first bParam exclusive-lock
                                            where bParam.ResourceUUID eq pcResourceUUID
                                              and bParam.MethodName eq bMethod.MethodName
                                              and bParam.ParamName eq cName:
                                            assign
                                                bParam.PublicName  = oSubObj:GetCharacter("alias") when oSubObj:Has("alias") and oSubObj:GetCharacter("alias") gt ""
                                                bParam.ElementType = oSubObj:GetCharacter("type") when oSubObj:Has("type")
                                                .
                                        end. /* for first bParam */
                                    end. /* do iZ oSubArr */

                                    delete object oSubArr no-error.
                                end. /* openapi.openedge.method.parameter */
                            end case. /* cAnnoNames */
                        end. /* do iY cAnnoNames */
                    end. /* available(bMethod) */

                    if (cMappingType gt "") eq true then do:
                        if (cNewServiceURI gt "") then
                            find first bService no-lock
                                 where bService.ServiceURI eq cNewServiceURI no-error.
                        else
                            find first bService no-lock
                                 where bService.ServiceURI eq cOldServiceURI no-error.
    
                        if available(bService) then do:
                            this-object:addProperty(bService.ServiceURI, pcClassPath, OperationEnum:read:toString(), "mappingType", "character", cMappingType).

                            if (cCapabilities gt "") eq true then
                                this-object:addProperty(bService.ServiceURI, pcClassPath, OperationEnum:read:toString(), "capabilities", "character", cCapabilities).
                        end.
                    end.

                    release bMethod no-error.
                end. /* do iX cMethods */

                catch err as Progress.Lang.Error:
                    oLoggingManager:logError(substitute("Error in method/procedure annotations for '&1'", pcClassPath), err, "SPARK-ERR", 0).
                    /* Do not throw error from this point, allow processing to continue. */
                end catch.
            end. /* has method */

            finally:
                /* Always create and return a version for this resource, even if set as "0.0.0". */
                if not valid-object(oSemVersion) then
                    assign oSemVersion = new SemanticVersion(0, 0, 0).

                /* Make sure the resource is updated with any changes discovered above. */
                for first bResource exclusive-lock
                    where bResource.ResourceUUID eq pcResourceUUID:

                    /* Check if there has been a change in service, and modify related records accordingly. */
                    if (cNewServiceUUID gt "") eq true then do:
                        if lIsClass then
                            for first bSrvcRes exclusive-lock
                                where bSrvcRes.ServiceUUID eq bResource.ServiceUUID
                                  and bSrvcRes.ClassPath eq bResource.ClassPath:
                                assign
                                    bSrvcRes.ServiceName = cNewServiceName
                                    bSrvcRes.ServiceUUID = cNewServiceUUID
                                    .
                            end. /* for first bSrvcRes */
                        else
                            for first bSrvcRes exclusive-lock
                                where bSrvcRes.ServiceUUID eq bResource.ServiceUUID
                                  and bSrvcRes.ClassPath eq bResource.SourcePath:
                                assign
                                    bSrvcRes.ServiceName = cNewServiceName
                                    bSrvcRes.ServiceUUID = cNewServiceUUID
                                    .
                            end. /* for first bSrvcRes */

                        assign bResource.ServiceUUID = cNewServiceUUID.
                    end. /* cNewServiceUUID */

                    assign /* Update properties for this resource. */
                        bResource.PublicName  = cPublicName
                        bResource.ResourceURI = cResourceURI
                        bResource.ApiVersion  = oSemVersion:ToString()
                        bResource.EntityName  = cSchemaName when cSchemaName gt "" /* Assign the entity name, if there was schema declared. */
                        bResource.Security    = cast(oResourceSecurity:Clone(), JsonObject) when valid-object(oResourceSecurity)
                        .
                end. /* for first bResource */

                delete object oResourceSecurity no-error.
                delete object oSemVersion no-error.
                delete object oAnnotation no-error.
                delete object oProgram no-error.
                delete object oData no-error.
                delete object oMethods no-error.
                delete object oMethod no-error.
                delete object oSubArr no-error.
                delete object oSubObj no-error.
            end finally.
        end. /* Has Annotation File */

        catch err as Progress.Lang.Error:
            oLoggingManager:logError(substitute("Error processing annotations for '&1'", pcClassPath), err, "SPARK-ERR", 0).
            /* Do not throw error from this point, allow resource registration to fail with only logging. */
        end catch.
    end method. /* processAnnotations */


    method protected void loadDynamicResource ( input pcResourceUUID as character ):
        /* Resource Discovery Process */
        define variable cClassPath   as character       no-undo.
        define variable cSourcePath  as character       no-undo.
        define variable cServiceUUID as character       no-undo.
        define variable cServiceURI  as character       no-undo.
        define variable cPublicName  as character       no-undo.
        define variable cResourceURI as character       no-undo.
        define variable cNewService  as character       no-undo.
        define variable lIsClass     as logical         no-undo.

        define buffer bService  for ServiceList.
        define buffer bResource for ResourceInfo.

        /* Destroy any previous procedure handles for this resource. */
        for each bResource exclusive-lock
           where not bResource.IsClass
             and bResource.ResourceUUID eq pcResourceUUID
             and valid-handle(bResource.ProcHandle):
            apply "close" to bResource.ProcHandle.
            delete procedure bResource.ProcHandle no-error.
        end. /* for each */

        /* First attempt to locate an existing record by resource name. */
        find first bResource no-lock
             where bResource.ResourceUUID eq pcResourceUUID no-error.
        if not available(bResource) then return.
        else
            assign
                cServiceUUID = bResource.ServiceUUID
                cClassPath   = bResource.ClassPath
                cSourcePath  = bResource.SourcePath
                lIsClass     = bResource.IsClass
                .

        /* First attempt to locate an existing service by UUID. */
        find first bService no-lock
             where bService.ServiceUUID eq cServiceUUID no-error.
        if not available(bService) then return.
        else
            assign cServiceURI = bService.ServiceURI.

        if not lIsClass and cSourcePath gt "" then
        do on error undo, throw
           on stop  undo, retry:
            if retry then
                undo, throw new AppError("A STOP condition occurred while setting persistent handle.", -500).

            /* Run procedures and save handle in resource table. */
            define variable hProcHandle as handle no-undo.
            run value(cSourcePath) persistent set hProcHandle.
            if valid-handle(hProcHandle) then do {&THROW}:
                /* Load (or re-load) service procedure internal methods, as needed. */
                this-object:registerProcedures( pcResourceUUID,
                                                cClassPath,
                                                hProcHandle ).

                /* Check for annotations to help override certain aspects of this registered procedure. */
                this-object:processAnnotations(pcResourceUUID, cClassPath, cSourcePath ).

                /* Assign the procedure handle and other values to the resource record. */
                for first bResource exclusive-lock
                    where bResource.ResourceUUID eq pcResourceUUID:
                    assign
                        bResource.ProcHandle = hProcHandle
                        cServiceUUID         = bResource.ServiceUUID
                        cPublicName          = bResource.PublicName
                        cResourceURI         = bResource.ResourceURI
                        .

                    for first bService no-lock
                        where bService.ServiceUUID eq cServiceUUID:
                        assign cServiceURI = bService.ServiceURI.
                    end. /* for first bService */
                end. /* for first bResource */

                if lUseDebugs then
                    oLoggingManager:logMessage(substitute("Loaded Procedure &1 as '&2&3'",
                                                          cSourcePath,
                                                          cServiceURI,
                                                          cResourceURI), "SPARK-LOAD", 3).
            end. /* valid-handle */
            else
                oLoggingManager:logMessage(substitute("Could not create persistent handle: '&1'", cSourcePath), "SPARK-WARN", 2).
        end. /* Procedures Only */
        else
        do on error undo, throw
           on stop  undo, retry:
            define variable oImplement   as Progress.Lang.Class no-undo.
            define variable oService     as Service             no-undo.
            define variable oEntity      as ISparkEntity        no-undo.
            define variable oDynEntity   as IDynamicEntity      no-undo.
            define variable oDynResource as IDynamicResource    no-undo.
            define variable phDataSet    as handle              no-undo.

            /* Create a valid implementation of the advertised class, which really should be an OE.BL.BusinessEntity class. */
            assign oImplement = Progress.Lang.Class:GetClass(cClassPath) no-error. /* Must keep this no-error. */
            if error-status:error then do:
                /* If error is due to a missing super-class, and the OE.BL.BE is not available, then let's report that specifically. */
                if error-status:get-number(1) eq 12932 and not lHasOEBLBE then
                    undo, throw new AppError("- Missing super-class OpenEdge.BusinessLogic.BusinessEntity", -500).
                else
                    undo, throw new AppError(substitute("@ Implementation: &1", GenTools:getAblError()), -500).
            end.
            else if not valid-object(oImplement) then
                undo, throw new AppError(substitute("- Invalid Implementation: &1", cClassPath), -500).

            /* Confirm whether the specified class is of type ISparkEntity, IDynamicEntity, or IDynamicResource. */
            if not (oImplement:IsA(get-class(IDynamicEntity)) or
                    oImplement:IsA(get-class(IDynamicResource))) then do:
                /* When an known entity class has been provided, register and check for a dataset. */
                if oImplement:IsA(get-class(ISparkEntity)) then do:
                    oEntity = cast(oImplement:New(), ISparkEntity) no-error.
                    if error-status:error then
                        undo, throw new AppError(GenTools:getAblError(), -500).

                    /* Get the dataset handle which should be available via this helper method in SparkEntity. */
                    oEntity:getDataset(output dataset-handle phDataSet) no-error. /* Must keep this no-error. */
                    if error-status:error then
                        oLoggingManager:logMessage(substitute("Error obtaining dataset schema for class '&1': &2",
                                                              oImplement:TypeName,
                                                              error-status:get-message(1)), "SPARK-LOAD", 0).
                    if valid-handle(phDataSet) and phDataSet:type eq "dataset" then
                        oSchemaManager:registerDataset(input phDataSet).
                end. /* IsA SparkEntity */

                /**
                 * Load (or re-load) service class internal methods, using default assumptions:
                 * - All exposed methods will be of "invoke" type and use the "PUT" verb.
                 * - All names of methods and parameters will be used as-is from code.
                 * - Any Business Entity (CRUD+Submit) operation defaults will be set.
                 */
                this-object:registerMethods(pcResourceUUID).

                /**
                 * Attempt to treat the class as annotated and proceed with registration of any methods.
                 * Should this class fail to have any annotations, then it will be ultimately skipped.
                 */
                this-object:processAnnotations(pcResourceUUID, cClassPath, "" ).

                /* Assign values to the resource record. */
                for first bResource exclusive-lock
                    where bResource.ResourceUUID eq pcResourceUUID:
                    assign
                        bResource.ValidClass = true
                        cServiceUUID         = bResource.ServiceUUID
                        cPublicName          = bResource.PublicName
                        cResourceURI         = bResource.ResourceURI
                        .

                    for first bService no-lock
                        where bService.ServiceUUID eq cServiceUUID:
                        assign cServiceURI = bService.ServiceURI.
                    end. /* for first bService */
                end. /* for first bResource */

                /* If class implements the Service class, then run the expected initialize method. */
                if oImplement:IsA(get-class(Service)) then do:
                    if valid-object(oEntity) then
                        oEntity:initialize(). /* Entities inherit Service, so just run initialize. */
                    else do:
                        oService = cast(oImplement:New(), Service) no-error.
                        if not error-status:error then
                            oService:initialize(). /* Run any code which may register datasets, etc. */
                    end. /* Service */
                end. /* Initialize Service */

                if lUseDebugs then
                    oLoggingManager:logMessage(substitute("Loaded Class &1 as '&2&3'",
                                                          cClassPath, cServiceURI, cResourceURI), "SPARK-LOAD", 3).
            end. /* Explicitly NOT a Dynamic* Class */

            /* For the Dynamic* classes, create new class instance and run the built-in initialize method. */
            else if oImplement:IsA(get-class(IDynamicEntity)) then do:
                oDynEntity = cast(oImplement:New(), IDynamicEntity) no-error.
                if error-status:error then
                    undo, throw new AppError(GenTools:getAblError(), -500).

                if valid-object(oDynEntity) then do:
                    if (oDynEntity:resourceName gt "") ne true then do:
                        /* Do not keep resources that lack a public name. */
                        oLoggingManager:logMessage(substitute("Removing resource '&1' due to missing public name.", cClassPath), "SPARK-LOAD", 3).
                        for first bResource exclusive-lock
                            where bResource.ResourceUUID eq pcResourceUUID:
                            delete bResource.
                        end. /* for first bResource */
                        leave.
                    end. /* No Resource Name */

                    /* Denote that this is a valid class. */
                    for first bResource exclusive-lock
                        where bResource.ResourceUUID eq pcResourceUUID:
                        assign
                            bResource.PublicName  = oDynEntity:resourceName
                            bResource.ResourceURI = "/" + oDynEntity:resourceName
                            bResource.ValidClass  = true
                            .
                    end. /* for first bResource */

                    /* When an entity name has been provided, register and check for a dataset. */
                    if (oDynEntity:entityName gt "") eq true then do:
                        /* Since we should know the entity and keys, register this information against this resource/class combination. */
                        this-object:describeEntity(pcResourceUUID, cClassPath, oDynEntity:EntityName, oDynEntity:primaryKeys, oDynEntity:foreignKeys).

                        oDynEntity:getDataset(output dataset-handle phDataSet) no-error. /* Must keep this no-error. */
                        if error-status:error then
                            oLoggingManager:logMessage(substitute("Error obtaining dataset schema for entity '&1': &2",
                                                                  oDynEntity:EntityName,
                                                                  error-status:get-message(1)), "SPARK-LOAD", 0).
                        if valid-handle(phDataSet) and phDataSet:type eq "dataset" then
                            oSchemaManager:registerDataset(input phDataSet).
                    end. /* entityName */

                    /* Load (or re-load) service class internal methods, as needed. */
                    this-object:registerMethods(pcResourceUUID, oDynEntity:Operations).

                    /* Load annotations and other prerequisite data through initialize method. */
                    /* MUST do this after registering methods, as it can alter which will be treated as the READ operation. */
                    oDynEntity:initialize().

                    /* Apply properties for the read operation, when they are present. */
                    if (oDynEntity:mappingType gt "") eq true then do:
                        /* Provide the name of the plugin to be used with the JSDO, aka the Mapping Type. */
                        this-object:addProperty(cServiceURI, cClassPath, OperationEnum:read:toString(), "mappingType", "character", oDynEntity:mappingType).

                        /* Only when a mapping type is present, check if server-side capabilities exist. */
                        if (oDynEntity:capabilities gt "") eq true then
                            this-object:addProperty(cServiceURI, cClassPath, OperationEnum:read:toString(), "capabilities", "character", oDynEntity:capabilities).
                        else
                            this-object:addProperty(cServiceURI, cClassPath, OperationEnum:read:toString(), "capabilities", "character", "").
                    end. /* mappingType */

                    if lUseDebugs then
                        oLoggingManager:logMessage(substitute("Loaded Entity &1 as '&2&3'",
                                                              cClassPath, cServiceURI, cResourceURI), "SPARK-LOAD", 3).
                end. /* valid-object */
            end. /* IDynamicEntity */

            else if oImplement:IsA(get-class(IDynamicResource)) then do:
                oDynResource = cast(oImplement:New(), IDynamicResource) no-error.
                if error-status:error then
                    undo, throw new AppError(GenTools:getAblError(), -500).

                if valid-object(oDynResource) then do:
                    if (oDynResource:resourceName gt "") ne true then do:
                        /* Do not keep resources that lack a public name. */
                        oLoggingManager:logMessage(substitute("Removing resource '&1' due to missing public name.", cClassPath), "SPARK-LOAD", 3).
                        for first bResource exclusive-lock
                            where bResource.ResourceUUID eq pcResourceUUID:
                            delete bResource no-error.
                        end. /* for first bResource */
                        leave.
                    end. /* No Resource Name */

                    /* Denote that this is a valid class. */
                    for first bResource exclusive-lock
                        where bResource.ResourceUUID eq pcResourceUUID:
                        assign
                            bResource.PublicName  = oDynResource:resourceName
                            bResource.ResourceURI = "/" + oDynResource:resourceName
                            bResource.ValidClass  = true
                            .
                    end. /* for first bResource */

                    /* Load (or re-load) service class internal methods, as needed. */
                    this-object:registerMethods(pcResourceUUID, cClassPath).

                    /* Load annotations and other prerequisite data. */
                    oDynResource:initialize().

                    if lUseDebugs then
                        oLoggingManager:logMessage(substitute("Loaded Resource &1 as '&2&3'",
                                                              cClassPath, cServiceURI, cResourceURI), "SPARK-LOAD", 3).
                end. /* valid-object */
            end. /* IDynamicResource */

            finally:
                if valid-object(phDataSet) then
                    delete object phDataSet no-error.

                if valid-object(oImplement) then
                    delete object oImplement no-error.

                if valid-object(oService) then
                    delete object oService no-error.

                if valid-object(oEntity) then
                    delete object oEntity no-error.

                if valid-object(oDynEntity) then
                    delete object oDynEntity no-error.

                if valid-object(oDynResource) then
                    delete object oDynResource no-error.
            end finally.
        end. /* Non-Procedure */

        catch err as Error:
            oLoggingManager:logError(substitute("Error loading resource '&1'", cClassPath), err, "SPARK-ERR", 0).

            /* Failure to load should mean removal from the list of resources. */
            if available(bResource) then do:
                oLoggingManager:logMessage(substitute("Removing resource '&1' due to loading error.", cClassPath), "SPARK-LOAD", 3).
                for first bResource exclusive-lock
                    where bResource.ResourceUUID eq pcResourceUUID:
                    delete bResource.
                end. /* for first bResource */
            end. /* Available bResource */

            /* Do not throw error from this point, allow resource registration to fail with only logging. */
        end catch.
    end method. /* loadDynamicResource */


    method protected void registerMethods ( input pcResourceUUID  as character ):
        /* Call method with blank list of operations. Typical for the DynamicResource class. */
        this-object:registerMethods(pcResourceUUID, "").
    end method. /* registerMethods */


    method protected void registerMethods ( input pcResourceUUID as character,
                                            input pcOperations   as character ):
        /* Resource Discovery Process */
        define variable oClassSig as JsonObject no-undo.
        define variable oMethods  as JsonObject no-undo.
        define variable cSigPath  as character  no-undo.
        define variable cMethods  as character  no-undo extent.
        define variable ix        as integer    no-undo.

        define buffer bResource for ResourceInfo.

        /* Remove any previous class method signatures. */
        this-object:clearResourceMethods(pcResourceUUID).

        /* Register methods according to the Spark.Core.Service.IDynamicEntity class. */
        find first bResource
             where bResource.ResourceUUID eq pcResourceUUID no-error.
        if available(bResource) then do:
            /* Generate class signature (in JSON) using reflection. */
            assign oClassSig = Reflection:getClassSignature(bResource.ClassPath).

            if lUseDebugs then do:
                /* Output the full class reflection data to a file for debugging purposes. */
                assign cSigPath = substitute("&1/signatures", right-trim(OSTools:sparkConf, "/")).
                file-info:file-name = cSigPath.
                if file-info:full-pathname eq ? then
                    os-create-dir value(cSigPath).
                oClassSig:WriteFile(substitute("&1/&2.json", cSigPath, bResource.ClassPath), true).
            end. /* lUseDebugs */

            /* Extract the specific class signature from the file. */
            if oClassSig:Has(bResource.ClassPath) then
                oClassSig = oClassSig:GetJsonObject(bResource.ClassPath).

            /* Register all methods for the current class. */
            if oClassSig:Has("methods") then do:
                oMethods = oClassSig:GetJsonObject("methods").
                cMethods = oMethods:GetNames().
                do iX = 1 to extent(cMethods) {&throw}:
                    /* Skip standard method if not allowed by list of operations for this resource. */
                    if can-do("readData,createData,updateData,deleteData,submitData", cMethods[iX]) then do:
                        /* Disallow CRUD+Submit methods if entity name was not provided. */
                        if bResource.EntityName eq "" then next.

                        /* Disallow CUD methods if operations contain "ReadOnly". */
                        if can-do("createData,updateData,deleteData", cMethods[iX]) and
                           can-do(pcOperations, "ReadOnly") then next.

                        /* Disallow Submit method if operation does not include "Submit". */
                        if cMethods[iX] eq "submitData" and not can-do(pcOperations, OperationEnum:submit:toString()) then next.

                        /* Disallow certain methods if explicitly denied. */
                        if cMethods[iX] eq "createData" and can-do(pcOperations, "NoCreate") then next.
                        if cMethods[iX] eq "updateData" and can-do(pcOperations, "NoUpdate") then next.
                        if cMethods[iX] eq "deleteData" and can-do(pcOperations, "NoDelete") then next.
                    end. /* Standard CRUD/Submit */

                    /* If not skipped by above code, register the resource method. */
                    this-object:setResourceMethod( input pcResourceUUID,
                                                   input cMethods[iX],
                                                   input bResource.EntityName,
                                                   input oMethods:GetJsonObject(cMethods[ix]):GetJsonArray("params") ).

                    catch err as Progress.Lang.Error:
                        oLoggingManager:logError(substitute("Unable to register method '&1:&2'",
                                                            bResource.ClassPath,
                                                            cMethods[iX]), err, "SPARK-ERR", 0).
                        undo, throw err.
                    end catch.
                end. /* Method[iX] */
            end. /* Has Methods */
        end. /* available */

        catch err as Progress.Lang.Error:
            oLoggingManager:logError(substitute("Unable to register &1 (&2) methods",
                                                pcResourceUUID,
                                                bResource.ClassPath), err, "SPARK-ERR", 0).
            undo, throw err.
        end catch.
        finally:
            delete object oClassSig no-error.
            delete object oMethods  no-error.
        end finally.
    end method. /* registerMethods */


    method protected void registerProcedures ( input pcResourceUUID as character,
                                               input pcResourceName as character,
                                               input phProcHandle   as handle ):
        /* Resource Discovery Process */
        define variable iCount           as integer   no-undo.
        define variable cMethodName      as character no-undo.
        define variable cInternalEntries as character no-undo.

        /* Remove previous internal procedure signatures. */
        this-object:clearResourceMethods(pcResourceUUID).

        cInternalEntries = phProcHandle:internal-entries.
        if (cInternalEntries gt "") ne true then return.

        /* Register the internal procedures for this resource. */
        do iCount = 1 to num-entries(cInternalEntries):
            assign cMethodName = entry(iCount, cInternalEntries).
            this-object:setResourceProcedure( input pcResourceUUID,
                                              input cMethodName,
                                              input phProcHandle:get-signature(cMethodName) ).
        end.

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Unable to register procedures", err, "SPARK-ERR", 0).
            undo, throw err.
        end catch.
    end method. /* registerProcedures */


    method protected void runPreloader ( ):
        /* Resource Discovery Process - Special procedure for application startup. */
        if (cPreLoader gt "") eq true then do:
            file-info:file-name = cPreLoader. /* First try filename as-is, which should be a .p file. */
            if file-info:full-pathname eq ? then
                file-info:file-name = this-object:stripFileExtensions(cPreLoader) + ".r". /* Try looking for a .r file. */
            if file-info:full-pathname ne ? then
            do on error undo, throw
               on stop  undo, retry:
                if retry then
                    undo, throw new AppError("A STOP condition occurred while running preloader", -500).

                define variable hProc as handle no-undo.
                run value(file-info:full-pathname) persistent set hProc.
                if valid-handle(hProc) then
                    oLoggingManager:logMessage(substitute("Registered preloader procedure: &1", cPreLoader), "SPARK-LOAD", 3).
                else
                    oLoggingManager:logMessage(substitute("Could not create persistent handle: '&1'", cPreLoader), "SPARK-WARN", 2).
            end. /* file-info:full-pathname */
            else
                oLoggingManager:logMessage(substitute("Preloader specified (&1), but could not be found.", cPreLoader), "SPARK-WARN", 2).
        end. /* Preloader Present */

        finally:
            if valid-handle(hProc) then do:
                apply "close" to hProc.
                delete procedure hProc no-error.
            end.
        end finally.
    end method. /* runPreloader */


    method protected void setResourceMethod ( input pcResourceUUID as character,
                                              input pcMethodName   as character,
                                              input pcEntityName   as character,
                                              input poMethodParams as JsonArray ):
        /* Resource Discovery Process */
        define variable oParamObj  as JsonObject no-undo.
        define variable cParamName as character no-undo.
        define variable iTotal     as integer    no-undo.
        define variable iParam     as integer    no-undo.

        define buffer bService  for ServiceList.
        define buffer bResource for ResourceInfo.
        define buffer bMethod   for MethodInfo.
        define buffer bParam    for ParameterInfo.


        for first bResource no-lock
            where bResource.ResourceUUID eq pcResourceUUID,
            first bService no-lock
            where bService.ServiceUUID eq bResource.ServiceUUID:
            /* Create a default description if none specified yet. */
            this-object:describeResource( bService.ServiceURI,
                                          bResource.ClassPath,
                                          pcMethodName,
                                          "",
                                          "",
                                          "" ).
        end. /* for first */

        /* No params, no update needed. Just leave. */
        if poMethodParams:Length eq 0 then return.

        for first bMethod exclusive-lock
            where bMethod.ResourceUUID eq pcResourceUUID
              and bMethod.MethodName eq pcMethodName:
            assign iTotal = poMethodParams:length.

            /* Do some pre-processing and adjustments for entity resources with CRUD+Submit methods. */
            if can-do("read,create,update,delete,submit", bMethod.OperationType) then do:
                do iParam = 1 to iTotal:
                    /* For parameters of an entity operation, add the entity name as a public name for the parameter. */
                    assign oParamObj = poMethodParams:GetJsonObject(iParam).
                    if oParamObj:GetCharacter("type") begins "dataset" then
                        oParamObj:Add("publicName", pcEntityName).
                end. /* do iParam */

                for first bResource no-lock
                    where bResource.ResourceUUID eq bMethod.ResourceUUID,
                    first bService no-lock
                    where bService.ServiceUUID eq bResource.ServiceUUID:
                    /* Add default property to enable use of before-image for CRUD+Submit as necessary. */
                    this-object:addProperty(bService.ServiceURI, bResource.ClassPath, bMethod.OperationType, "useBeforeImage", "logical", "true").
                end. /* for first */
            end. /* CRUD+Submit */

            /* Add the parameters as records in the ParameterInfo table. */
            do iParam = 1 to iTotal:
                assign
                    oParamObj  = poMethodParams:GetJsonObject(iParam)
                    cParamName = oParamObj:GetCharacter("name")
                    .

                /* Don't proceed if a param already exists for this service/resource/method. */
                if can-find(first bParam
                            where bParam.ResourceUUID eq bMethod.ResourceUUID
                              and bParam.MethodName eq bMethod.MethodName
                              and bParam.ParamName eq cParamName no-lock) then next.

                /* Create a parameter information record for this service/resource/method. */
                create bParam.
                assign
                    bParam.ParamUUID      = this-object:ParamUUID
                    bParam.ResourceUUID   = bMethod.ResourceUUID
                    bParam.MethodName     = pcMethodName
                    bParam.ParamName      = cParamName
                    bParam.PublicName     = if oParamObj:Has("publicName") and oParamObj:GetCharacter("publicName") gt ""
                                            then oParamObj:GetCharacter("publicName") else cParamName
                    bParam.IOMode         = oParamObj:GetCharacter("mode")
                    bParam.DataType       = oParamObj:GetCharacter("type")
                    bParam.DataTypeExtent = oParamObj:GetInteger("extent")
                    bParam.ElementType    = if bParam.DataType begins "table" or bParam.DataType begins "dataset" then "body" else "field"
                    .

                /* Adjust parameter mode if using a non-standard name. */
                if bParam.IOMode eq "inputoutput" then
                    assign bParam.IOMode = "input-output".

                /* Adjust parameter type based on name or format. */
                case true:
                    when bParam.DataType eq "datetimetz" then
                        assign bParam.DataType = "datetime-tz".
                    when bParam.DataType begins "dataset" then
                        assign bParam.DataType = "dataset".
                    when bParam.DataType begins "table" then
                        assign bParam.DataType = "table".
                    when index(bParam.DataType, ".") gt 0 then
                        assign bParam.DataType = substitute("class &1", bParam.DataType).
                end case.

                release bParam no-error.
            end. /* do iParam */

            /* Udpate the signature with any modifications determined above. */
            assign bMethod.MethodSignature = string(poMethodParams:GetJsonText()).
        end. /* for first */

        finally:
            delete object oParamObj no-error.
        end finally.
    end method. /* setResourceMethod */


    method protected void setResourceProcedure ( input pcResourceUUID    as character,
                                                 input pcMethodName      as character,
                                                 input pcMethodSignature as character ):
        define variable oParamArr as JsonArray  no-undo.
        define variable oParamObj as JsonObject no-undo.
        define variable iX        as integer    no-undo.
        define variable cParamSig as character  no-undo.
        define variable cParam2   as character  no-undo.
        define variable cParam3   as character  no-undo.

        define buffer bService  for ServiceList.
        define buffer bResource for ResourceInfo.
        define buffer bMethod   for MethodInfo.
        define buffer bParam    for ParameterInfo.

        for first bResource no-lock
            where bResource.ResourceUUID eq pcResourceUUID,
            first bService no-lock
            where bService.ServiceUUID eq bResource.ServiceUUID:
            /* Create a default description if none specified yet. */
            this-object:describeResource( bService.ServiceURI,
                                          bResource.ClassPath,
                                          pcMethodName,
                                          pcMethodName,
                                          "",
                                          "" ).
        end. /* for first */

        assign oParamArr = new JsonArray().
        do iX = 3 to num-entries(pcMethodSignature):
            assign
                oParamObj = new JsonObject()
                cParamSig = entry(iX, pcMethodSignature)
                .

            /* Create a new ParameterInfo record. */
            create bParam.
            assign
                bParam.ParamUUID    = this-object:ParamUUID
                bParam.ResourceUUID = pcResourceUUID
                bParam.MethodName   = pcMethodName
                .

            if num-entries(cParamSig, " ") ge 3 then do {&THROW}:
                assign bParam.IOMode = lc(entry(1, cParamSig, " ")).

                case entry(1, cParamSig, " "):
                    when "input" then
                        oParamObj:Add("mode", "Input").
                    when "input-output" then
                        oParamObj:Add("mode", "InputOutput").
                    when "output" then
                        oParamObj:Add("mode", "Output").
                end case.

                assign
                    cParam2 = entry(2, cParamSig, " ")
                    cParam3 = entry(3, cParamSig, " ")
                    .

                if cParam2 eq "table" or cParam2 eq "table-handle" or
                   cParam2 eq "dataset" or cParam2 eq "dataset-handle" then do:
                    assign
                        bParam.ParamName = cParam3
                        bParam.DataType  = lc(cParam2)
                        .

                    oParamObj:Add("name", cParam3).
                    oParamObj:Add("type", lc(replace(cParam2, "-", ""))).
                end. /* dataset/table */
                else do:
                    assign
                        bParam.ParamName = cParam2
                        bParam.DataType  = lc(cParam3)
                        .

                    /* Adjust parameter type based on name or format. */
                    case true:
                        when bParam.DataType eq "datetimetz" then
                            assign bParam.DataType = "datetime-tz".
                        when bParam.DataType begins "dataset" then
                            assign bParam.DataType = "dataset".
                        when bParam.DataType begins "table" then
                            assign bParam.DataType = "table".
                        when index(bParam.DataType, ".") gt 0 then
                            assign bParam.DataType = substitute("class &1", bParam.DataType).
                    end case.

                    oParamObj:Add("name", cParam2).
                    oParamObj:Add("type", lc(cParam3)).

                    if num-entries(cParamSig, " ") ge 4 and lc(entry(4, cParamSig, " ")) eq "extent" then do:
                        /* Extent is present, determine if variable or fixed. */
                        if num-entries(cParamSig, " ") ge 5 and entry(5, cParamSig, " ") gt "" then
                            oParamObj:Add("extent", integer(entry(5, cParamSig, " "))).
                        else
                            oParamObj:AddNull("extent").
                    end.
                    else
                        oParamObj:Add("extent", 0). /* Default is an extent of 0. */
                end. /* other primitive */

                oParamArr:Add(oParamObj).

                assign
                    bParam.PublicName     = bParam.ParamName /* Default the public (element) name to the param name. */
                    bParam.DataTypeExtent = if oParamObj:IsNull("extent") then ? else oParamObj:GetInteger("extent")
                    .
                release bParam no-error.
            end. /* num-entries */
        end. /* iX */

        /**
         * Write the procedure signatures back to the method table using a format similar to what
         * is generated for class reflection, just to maintain some consistency within this field.
         */
        if oParamArr:Length gt 0 then
            for first bMethod exclusive-lock
                where bMethod.ResourceUUID eq pcResourceUUID
                  and bMethod.MethodName eq pcMethodName:
                assign bMethod.MethodSignature = string(oParamArr:GetJsonText()).
            end. /* for first bMethod */
    end method. /* setResourceProcedure */


    /***************************** Catalog Helper Methods *****************************/


    method protected logical getBeforeImageFlag ( input pcResourceUUID  as character,
                                                  input pcOperationType as character ):
        define buffer bResource for ResourceInfo.
        define buffer bProperty for ResourceProperty.

        for first bResource no-lock
            where bResource.ResourceUUID eq pcResourceUUID:
            find first bProperty no-lock
                 where bProperty.ResourceUUID eq bResource.ResourceUUID
                   and bProperty.OperationType eq pcOperationType
                   and bProperty.PropertyName eq "useBeforeImage" no-error.
            if available(bProperty) then
                return logical(bProperty.propertyValue).
        end. /* for first */

        return false.
    end method. /* getBeforeImageFlag */


    method protected JsonArray getServices ( input pcServiceUUID  as character,
                                             input pcResourceName as character ):
        /* DataObject Catalog Method */
        define variable serviceArr as JsonArray no-undo.
        assign serviceArr = new JsonArray().

        define buffer bService for ServiceInfo.

        for each bService no-lock:
            /* If no service given (is blank) return all services for this webapp. */
            /* If incoming service URI without the WebApp name matches, use that. */
            if pcServiceUUID eq "" or bService.ServiceUUID eq pcServiceUUID then do:
                /* Create a new service. */
                define variable serviceObj  as JsonObject no-undo.
                define variable settingsObj as JsonObject no-undo.

                assign serviceObj = new JsonObject().
                assign settingsObj = new JsonObject().

                /* Service Options */
                serviceObj:Add("name", bService.ServiceName).
                serviceObj:Add("address", bService.ServiceURI).

                /**
                 * Optional Properties - Not typically used in existing patterns.
                 * serviceObj:Add("tenantId", "").
                 * serviceObj:Add("appId", "").
                 */

                /* Specify Settings */
                settingsObj:Add("useRequest", bService.UseRequest).           /* Use request object for invoke operations. */
                settingsObj:Add("sendOnlyChanges", bService.SendOnlyChanges). /* Only send fields that have been changed.  */
                settingsObj:Add("unwrapped", false).                          /* Does server expect an enclosing object?   */
                settingsObj:Add("useXClientProps", false).                    /* Does server expect a clientProps header?  */

                /* Add settings and resources for service. */
                serviceObj:Add("settings", settingsObj).
                serviceObj:Add("resources", this-object:getResources(bService.ServiceUUID, pcResourceName)).

                /* Add main service to array. */
                serviceArr:Add(serviceObj).
            end.
        end. /* for each bService */

        return serviceArr.
    end method. /* getServices */


    method protected JsonArray getResources ( input pcServiceUUID  as character,
                                              input pcResourceName as character ):
        /* DataObject Catalog Method */
        define variable resourceArr as JsonArray  no-undo.
        define variable resourceObj as JsonObject no-undo.

        define buffer bResource for ResourceInfo.

        /* Create resources for service. */
        assign resourceArr = new JsonArray().
        if (pcResourceName gt "") eq true then
            for first bResource no-lock
                where bResource.ServiceUUID eq pcServiceUUID
                  and bResource.PublicName eq pcResourceName:
                /* Break on unique resource name. */
                assign resourceObj = new JsonObject().
                resourceObj:Add("name", bResource.PublicName).
                resourceObj:Add("path", bResource.ResourceURI).
                resourceObj:Add("autoSave", false).
                if this-object:IdProperty ne "id" then
                    resourceObj:Add("recIdProperty", this-object:IdProperty).
                if this-object:SeqProperty ne "seq" then
                    resourceObj:Add("seqProperty", this-object:SeqProperty).
                resourceObj:Add("displayName", bResource.PublicName).

                /* Only return for the associated entity, which should always be on a ReadData method. */
                resourceObj:Add("schema", this-object:getSchema(bResource.ResourceUUID, true)).
                resourceObj:Add("relations", this-object:getRelations(bResource.ResourceUUID)).

                /* Add operations for the resource. */
                resourceObj:Add("operations", this-object:getOperations(bResource.ResourceUUID)).

                /* Add data definitions for invoke operations. */
                resourceObj:Add("dataDefinitions", this-object:getDataDefs(bResource.ResourceUUID)).
                resourceArr:Add(resourceObj).
            end. /* for first bResource (exact) */
        else
            for each bResource no-lock
               where bResource.ServiceUUID eq pcServiceUUID
               break by bResource.PublicName:
                if first-of(bResource.PublicName) then do:
                    /* Break on unique resource name. */
                    assign resourceObj = new JsonObject().
                    resourceObj:Add("name", bResource.PublicName).
                    resourceObj:Add("path", bResource.ResourceURI).
                    resourceObj:Add("autoSave", false).
                    if this-object:IdProperty ne "id" then
                        resourceObj:Add("recIdProperty", this-object:IdProperty).
                    if this-object:SeqProperty ne "seq" then
                        resourceObj:Add("seqProperty", this-object:SeqProperty).
                    resourceObj:Add("displayName", bResource.PublicName).

                    /* Only return for the associated entity, which should always be on a ReadData method. */
                    resourceObj:Add("schema", this-object:getSchema(bResource.ResourceUUID, true)).
                    resourceObj:Add("relations", this-object:getRelations(bResource.ResourceUUID)).

                    /* Add operations for the resource. */
                    resourceObj:Add("operations", this-object:getOperations(bResource.ResourceUUID)).

                    /* Add data definitions for invoke operations. */
                    resourceObj:Add("dataDefinitions", this-object:getDataDefs(bResource.ResourceUUID)).
                    resourceArr:Add(resourceObj).
                end.
            end. /* for first bResource (all) */

        return resourceArr.
    end method. /* getResources */


    method protected JsonObject getSchema ( input pcResourceUUID  as character,
                                            input plPrimaryEntity as logical ):
        /* DataObject Catalog Method */
        define variable oSchemaObj    as JsonObject no-undo.
        define variable oProperty     as JsonObject no-undo.
        define variable cDatasetNames as character  no-undo.
        define variable cTableNames   as character  no-undo.
        define variable cParamName    as character  no-undo.
        define variable iX            as integer    no-undo.
        define variable iY            as integer    no-undo.
        define variable iZ            as integer    no-undo.

        define buffer bResource for ResourceInfo.
        define buffer bMethod   for MethodInfo.
        define buffer bParam    for ParameterInfo.

        assign oSchemaObj = new JsonObject().

        if plPrimaryEntity then do:
            /* Meant for obtaining the primary entity (READ operation) for this resource. */
            for first bMethod no-lock
                where bMethod.ResourceUUID eq pcResourceUUID
                  and bMethod.OperationType eq OperationEnum:read:toString():
                for each bParam no-lock
                   where bParam.ResourceUUID eq pcResourceUUID
                     and bParam.MethodName eq bMethod.MethodName:
                    assign cParamName = bParam.PublicName.

                    if bParam.DataType begins "dataset" and
                       not can-do(cDatasetNames, cParamName) then
                        assign cDatasetNames = trim(substitute("&1,&2", cDatasetNames, cParamName), ",").

                    if bParam.DataType begins "table" and
                       not can-do(cTableNames, cParamName) then
                        assign cTableNames = trim(substitute("&1,&2", cTableNames, cParamName), ",").
                end. /* for each bParam */
            end. /* for first */
        end. /* plPrimaryEntity */
        else do:
            /* Obtain all non-primary schema (eg. INVOKE operation tables and datasets). */
            for each bMethod no-lock
               where bMethod.ResourceUUID eq pcResourceUUID
                 and bMethod.OperationType eq OperationEnum:invoke:toString()
                  by bMethod.MethodName:
                for each bParam no-lock
                   where bParam.ResourceUUID eq pcResourceUUID
                     and bParam.MethodName eq bMethod.MethodName:
                    assign cParamName = bParam.PublicName.

                    if bParam.DataType begins "dataset" and
                       not can-do(cDatasetNames, cParamName) then
                        assign cDatasetNames = trim(substitute("&1,&2", cDatasetNames, cParamName), ",").

                    if bParam.DataType begins "table" and
                       not can-do(cTableNames, cParamName) then
                        assign cTableNames = trim(substitute("&1,&2", cTableNames, cParamName), ",").
                end. /* for each bParam */
            end. /* for each */
        end. /* not plPrimaryEntity */

        assign oProperty = new JsonObject().
        oSchemaObj:Add("type", "object").
        oSchemaObj:Add("additionalProperties", false).

        if (cDatasetNames gt "") eq true or (cTableNames gt "") eq true then do:
            define variable datasetObj   as JsonObject no-undo.
            define variable tableObj     as JsonObject no-undo.
            define variable schemaObj    as JsonObject no-undo.
            define variable cTableList   as character  no-undo.
            define variable cFKData      as character  no-undo.
            define variable cPKName      as character  no-undo.
            define variable cDataSetName as character  no-undo.
            define variable cTableName   as character  no-undo.
            define variable lKeepDupes   as logical    no-undo initial true.

            do iX = 1 to num-entries(cDatasetNames):
                /* Obtain a list of tables that exist within this dataset. */
                assign cDataSetName = entry(iX, cDatasetNames).
                oSchemaManager:getObjectChildren(input cDataSetName, output cTableList).
                if (cTableList gt "") eq true then do:
                    if not lKeepDupes then do:
                        /* If we should not keep duplicate tables (read: temp-tables that also appear within a dataset),
                         * then set this flag as false to have those stripped out. Otherwise it is assumed that any table
                         * that occurs both within a dataset and as it's own parameter for a method should be added to the
                         * list of schema objects produced from this method.
                         */
                        define variable cTempNames as character no-undo.
                        assign
                            cTempNames  = cTableNames
                            cTableNames = ""
                            .

                        do iY = 1 to num-entries(cTempNames):
                            /* Keep only table names that will be not included by this dataset. */
                            if not can-do(cTableList, entry(iY, cTempNames)) then
                                assign cTableNames = substitute("&1,&2", cTableNames, entry(iY, cTempNames)).
                        end.
                        assign cTableNames = trim(cTableNames, ",").
                    end. /* not lKeepDupes */

                    /* Create dataset object and populate with table schema. */
                    assign datasetObj = new JsonObject().
                    datasetObj:Add("type", "object").
                    datasetObj:Add("additionalProperties", false).
                    assign tableObj = new JsonObject().
                    do iZ = 1 to num-entries(cTableList):
                        /* Obtain primary/foreign keys for table (by resource). */
                        for first bResource
                            where bResource.ResourceUUID eq pcResourceUUID
                              and bResource.EntityName eq cDataSetName:
                            do iY = 1 to num-entries(bResource.EntityKeys):
                                if cPKName eq "" then do:
                                    if entry(iY, bResource.EntityKeys) begins (entry(iZ, cTableList) + ".") then
                                        assign cPKName = substring(entry(iY, bResource.EntityKeys), length(entry(iZ, cTableList) + ".") + 1).
                                    else
                                        assign cPKName = entry(iY, bResource.EntityKeys).
                                end.
                            end. /* iY */
                            assign cFKData = bResource.ForeignKeys.
                        end. /* for first */

                        /* Add each table as a property of object. */
                        oLoggingManager:logMessage(substitute("Adding schema to catalog for '&1.&2'",
                                                              cDataSetName,
                                                              entry(iZ, cTableList)), "SPARK-CTLG", 6).
                        assign schemaObj = this-object:getTable(entry(iX, cDatasetNames), entry(iZ, cTableList), cPKName, cFKData, output cTableName).
                        if (cTableName gt "") eq true then
                            tableObj:Add(cTableName, schemaObj).
                        else
                            oLoggingManager:logMessage(substitute("Unresolved table name, cannot add schema [&1.&2].", entry(iX, cDatasetNames), entry(iZ, cTableList)), "SPARK-CTLG", 3).
                    end. /* Tables */
                    datasetObj:Add("properties", tableObj).
                    oProperty:Add(cDataSetName, datasetObj).
                end.
            end. /* Datasets */

            do iX = 1 to num-entries(cTableNames):
                /* Obtain primary key for table (by resource). */
                for first bResource
                    where bResource.ResourceUUID eq pcResourceUUID:
                    do iY = 1 to num-entries(bResource.EntityKeys):
                        if entry(iY, bResource.EntityKeys) begins (entry(iX, cTableNames) + ".") then
                            assign cPKName = substring(entry(iY, bResource.EntityKeys), length(entry(iX, cTableNames) + ".") + 1).
                    end.
                    assign cFKData = bResource.ForeignKeys.
                end. /* for first */

                /* Add each table directly to schema properties. */
                oLoggingManager:logMessage(substitute("Adding schema to catalog for '&1'",
                                                      entry(iX, cTableNames)), "SPARK-CTLG", 6).
                assign schemaObj = this-object:getTable("", entry(iX, cTableNames), cPKName, cFKData, output cTableName).
                if (cTableName gt "") eq true then
                    oProperty:Add(cTableName, schemaObj).
                else
                    oLoggingManager:logMessage(substitute("Unresolved table name, cannot add schema [&1].", entry(iX, cTableNames)), "SPARK-CTLG", 3).
            end. /* Tables */
        end. /* Has Dataset(s) or Temp-Table(s) */

        oSchemaObj:Add("properties", oProperty). /* Always add a properties object. */

        return oSchemaObj.
    end method. /* getSchema */


    method protected JsonArray getRelations ( input pcResourceUUID as character ):
        /* DataObject Catalog Method */
        define variable oRelationArr  as JsonArray  no-undo.
        define variable oRelationObj  as JsonObject no-undo.
        define variable oFieldArr     as JsonArray  no-undo.
        define variable oFieldObj     as JsonObject no-undo.
        define variable cDatasetNames as character  no-undo.
        define variable cParamName    as character  no-undo.
        define variable iX            as integer    no-undo.
        define variable iY            as integer    no-undo.
        define variable iZ            as integer    no-undo.

        define buffer bMethod for MethodInfo.
        define buffer bParam  for ParameterInfo.

        assign oRelationArr = new JsonArray().

        for first bMethod no-lock
            where bMethod.ResourceUUID eq pcResourceUUID
              and bMethod.OperationType eq OperationEnum:read:toString():
            for each bParam no-lock
               where bParam.ResourceUUID eq pcResourceUUID
                 and bParam.MethodName eq bMethod.MethodName:
                assign cParamName = bParam.PublicName.

                if bParam.DataType begins "dataset" and
                   not can-do(cDatasetNames, cParamName) then
                    assign cDatasetNames = trim(substitute("&1,&2", cDatasetNames, cParamName), ",").
            end. /* for each bParam */
        end. /* for first */

        if (cDatasetNames gt "") eq true then do:
            define variable hDataset   as handle  no-undo.
            define variable hRelation  as handle  no-undo.
            define variable iRelCount  as integer no-undo.
            define variable cRelFields as character no-undo.

            do iX = 1 to num-entries(cDatasetNames) {&throw}:
                /* Obtain a list of tables that exist within this dataset. */
                oSchemaManager:getDataset(entry(iX, cDatasetNames), dataset-handle hDataset) no-error.
                if error-status:error then
                    oLoggingManager:logMessage(substitute("Error obtaining dataset schema for '&1': &2",
                                                          entry(iX, cDatasetNames),
                                                          error-status:get-message(1)), "SPARK-LOAD", 0).

                /* Get relationship information from dataset. */
                if valid-handle(hDataset) then do:
                    assign iRelCount = hDataset:num-relations.

                    RELATIONBLK:
                    do iY = 1 to iRelCount:
                        /* Only proceed if relation is active. */
                        assign hRelation = hDataset:get-relation(iRelCount).
                        if not hRelation:active then next RELATIONBLK.

                        assign
                            cRelFields   = hRelation:relation-fields
                            oRelationObj = new JsonObject()
                            oFieldArr    = new JsonArray()
                            .

                        oRelationObj:Add("relationName", hRelation:name).
                        oRelationObj:Add("parentName", hRelation:parent-buffer:name).
                        oRelationObj:Add("childName", hRelation:child-buffer:name).
                        do iZ = 1 to num-entries(cRelFields):
                            /* Fields are in pairs, so break accordingly. */
                            if (iZ mod 2) eq 1 then do:
                                assign oFieldObj = new JsonObject().
                                oFieldObj:Add("parentFieldName", entry(iZ, cRelFields)).
                            end.
                            if (iZ mod 2) eq 0 then do:
                                oFieldObj:Add("childFieldName", entry(iZ, cRelFields)).
                                oFieldArr:Add(oFieldObj).
                            end.
                        end.
                        oRelationObj:Add("relationFields", oFieldArr).
                        oRelationArr:Add(oRelationObj).
                        delete object hRelation no-error.
                    end.
                end. /* valid-handle */

                assign hDataset = ?. /* Re-initialize for next dataset. */
                delete object hDataset no-error.

                catch err as Progress.Lang.Error:
                    message substitute("Unable to get relation data for dataset &1: &2", entry(iX, cDatasetNames), err:GetMessage(1)).
                end catch.
            end. /* Datasets */
        end. /* Has Dataset(s) */

        return oRelationArr.
    end method. /* getRelations */


    method protected JsonObject getTable ( input  pcDatasetName as character,
                                           input  pcTableName   as character,
                                           input  pcPrimaryKey  as character,
                                           input  pcForeignKey  as character,
                                           output pcSerialized  as character ):
        /* DataObject Catalog Method */
        define variable tableObj    as JsonObject no-undo.
        define variable fkArray     as JsonArray  no-undo.
        define variable pkArray     as JsonArray  no-undo.
        define variable itemsObj    as JsonObject no-undo.
        define variable propsObj    as JsonObject no-undo.
        define variable idObj       as JsonObject no-undo.
        define variable fieldObj    as JsonObject no-undo.
        define variable extentObj   as JsonObject no-undo.
        define variable extraObj    as JsonObject no-undo.
        define variable cFieldName  as character  no-undo.
        define variable cObjectType as character  no-undo.
        define variable cSchemaXML  as longchar   no-undo.
        define variable hTable      as handle     no-undo.
        define variable hBuffer     as handle     no-undo.
        define variable hField      as handle     no-undo.
        define variable iX          as integer    no-undo.

        define buffer bEntity for EntityProperty.

        assign tableObj = new JsonObject().
        oSchemaManager:getObject(input pcDatasetName, input pcTableName, output pcSerialized, output cObjectType, output cSchemaXML).
        if cObjectType eq "temp-table" then do:
            /* Create table from XML schema data. */
            create temp-table hTable.
            hTable:read-xmlschema("longchar", cSchemaXML, false).

            /* Set the correct table name for serialization. */
            assign hTable:serialize-name = pcSerialized.

            /* Create the initial table/items objects. */
            tableObj:Add("type", "array").
            assign pkArray = new JsonArray().

            /* Primary Key(s) */
            pkArray:Add(pcPrimaryKey).
            tableObj:Add("primaryKey", pkArray).

            /* Foreign Key(s) */
            if pcForeignKey begins "[~{" then
            do on error undo, leave:
                define variable oParser as ObjectModelParser no-undo.

                assign oParser = new ObjectModelParser().
                assign fkArray = cast(oParser:Parse(pcForeignKey), JsonArray).
                tableObj:Add("foreignKeys", fkArray).

                catch err as Progress.Json.JsonParserError:
                    message err:GetMessage(1).
                    tableObj:Add("foreignKeys", new JsonArray()).
                end catch.
                finally:
                    delete object oParser no-error.
                end finally.
            end. /* FK is a JSON string */
            else do:
                tableObj:Add("foreignKeys", new JsonArray()).
            end.

            /* Fields (as "items") */
            assign itemsObj = new JsonObject().
            itemsObj:Add("additionalProperties", false).
            assign idObj = new JsonObject().
            idObj:Add("type", "string").
            assign propsObj = new JsonObject().
            propsObj:Add("_id", idObj).
            propsObj:Add("_errorString", idObj).
            assign hBuffer = hTable:default-buffer-handle.

            /* Look for additional field properties for this dataset/table. */
            for first bEntity no-lock
                where bEntity.EntityName eq pcDatasetName
                  and bEntity.TableName eq pcTableName:
                if valid-object(bEntity.FieldData) then
                    assign extraObj = cast(bEntity.FieldData, JsonObject).
            end. /* for first bEntity */

            /* Populate the table object with all fields. */
            do iX = 1 to hBuffer:num-fields:
                assign hField = hBuffer:buffer-field(iX) no-error.
                if valid-handle(hField) then do:
                    /* Create the new field object. */
                    assign fieldObj = new JsonObject().
                    if hField:extent gt 0 then do:
                        fieldObj:Add("type", "array").
                        fieldObj:Add("ablType", caps(hField:data-type)).
                        fieldObj:Add("title", hField:label).
                        fieldObj:Add("maxItems", hField:extent).
                        assign extentObj = new JsonObject().
                        extentObj:Add("type", getJsonType(hField:data-type)).
                        fieldObj:Add("items", extentObj).
                    end. /* Extent */
                    else do:
                        fieldObj:Add("type", getJsonType(hField:data-type)).
                        fieldObj:Add("ablType", caps(hField:data-type)).
                        if hField:data-type eq "clob" then
                            fieldObj:Add("default", "").
                        else
                            fieldObj:Add("default", hField:default-value).
                        fieldObj:Add("title", hField:label).
                    end. /* Normal */

                    /* Remove hyphens from date formats. */
                    if hField:data-type begins "date" then
                        fieldObj:Add("format", lc(replace(hField:data-type, "-", ""))).

                    /* Use appropriate field name. */
                    if (hField:xml-node-name gt "") eq true then
                        assign cFieldName = hField:xml-node-name.
                    else if (hField:serialize-name gt "") eq true then
                        assign cFieldName = hField:serialize-name.
                    else
                        assign cFieldName = hField:name.

                    /**
                     * To provide support for a "semanticType" property on your fields, utilize the "describeFields"
                     * in the Annotate class, from your business entity's initialize method to provide any extra
                     * properties on a field level for any dataset and temp-table combination. This feature also
                     * allows for specifying any other additional properties needed by your table fields.
                     * https://wiki.progress.com/display/Pacific/Catalog+for+the+Semantic+Type
                     * https://wiki.progress.com/display/Pacific/Semantic+Type
                     * https://wiki.progress.com/display/Pacific/Foreign+Key+Support
                     */
                    if valid-object(extraObj) and extraObj:GetClass():IsA("Progress.Json.ObjectModel.JsonObject") then do:
                        if extraObj:Has(cFieldName) then do:
                            oLoggingManager:logMessage(substitute("Adding extra properties to field '&1.&2.&3'",
                                                                  pcDatasetName,
                                                                  pcTableName,
                                                                  cFieldName), "SPARK-LOAD", 3).
                            assign fieldObj = Spark.Core.Util.Strings:mergeProperties(fieldObj, extraObj:GetJsonObject(cFieldName)).
                        end. /* has field */
                    end. /* extraObj */

                    /* Add field object as new field in properties object. */
                    propsObj:Add(cFieldName, fieldObj).
                end. /* valid-handle */
                delete object hField no-error.
            end. /* num-fields */
            itemsObj:Add("properties", propsObj).
            tableObj:Add("items", itemsObj).
        end. /* temp-table */

        return tableObj.

        finally:
            delete object hTable  no-error.
            delete object hBuffer no-error.
            assign cSchemaXML = "".
        end finally.
    end method. /* getTable */


    method protected JsonArray getOperations ( input pcResourceUUID as character ):
        /* DataObject Catalog Method */
        define variable operationArr as JsonArray  no-undo.
        define variable operationObj as JsonObject no-undo.
        define variable oParamArr    as JsonArray  no-undo.
        define variable oParamObj    as JsonObject no-undo.
        define variable iX           as integer    no-undo.

        define buffer bMethod   for MethodInfo.
        define buffer bParam    for ParameterInfo.
        define buffer bProperty for ResourceProperty.

        assign operationArr = new JsonArray().

        for each bMethod no-lock
           where bMethod.ResourceUUID eq pcResourceUUID
              by bMethod.PublicName
              by bMethod.MethodName:
            assign operationObj = new JsonObject().

            if can-do("invoke,submit", bMethod.OperationType) then do:
                operationObj:Add("name", bMethod.PublicName).
                operationObj:Add("path", bMethod.MethodURI).
            end. /* Invoke/Submit */
            else do:
                operationObj:Add("name", bMethod.OperationType).
                operationObj:AddNull("path"). /* Supply a null property, as we'll update this next. */
            end. /* CRUD */

            /* Supply default property for special methods. */
            if can-do("read,create,update,delete,submit,invoke,count", bMethod.OperationType) then
                operationObj:Add("useBeforeImage", this-object:getBeforeImageFlag(bMethod.ResourceUUID, bMethod.OperationType)).

            /* Look for additional properties to provide on this operation. */
            for each bProperty no-lock
               where bProperty.ResourceUUID eq pcResourceUUID
                 and bProperty.OperationType eq bMethod.OperationType:
                if bProperty.PropertyType eq "logical" then do:
                    if operationObj:Has(bProperty.PropertyName) then
                        operationObj:Set(bProperty.PropertyName, logical(bProperty.PropertyValue)).
                    else
                        operationObj:Add(bProperty.PropertyName, logical(bProperty.PropertyValue)).
                end. /* logical */
                else do:
                    /* Only set the mergeMode property for invoke operations. */
                    if bProperty.PropertyName eq "mergeMode" and
                       bMethod.OperationType ne OperationEnum:invoke:toString() then next.

                    if operationObj:Has(bProperty.PropertyName) then
                        operationObj:Set(bProperty.PropertyName, bProperty.PropertyValue).
                    else
                        operationObj:Add(bProperty.PropertyName, bProperty.PropertyValue).
                end. /* non-logical */
            end. /* for each */

            operationObj:Add("type", lc(bMethod.OperationType)).
            operationObj:Add("verb", lc(bMethod.OperationVerb)).

            /* Create a JSON array of parameters from the temp-table data. */
            assign oParamArr = new JsonArray().
            for each bParam no-lock
               where bParam.ResourceUUID eq pcResourceUUID
                 and bParam.MethodName eq bMethod.MethodName:
                assign oParamObj = new JsonObject().

                oParamObj:Add("mode", bParam.IOMode).
                oParamObj:Add("name", bParam.PublicName).
                oParamObj:AddNull("type"). /* Will be ElementType */
                oParamObj:Add("extent", bParam.DataTypeExtent).
                oParamObj:Add("xType", bParam.DataType).

                /* Override the [ABL] xType as needed. */
                case oParamObj:GetCharacter("xType"):
                    when "dataset" or
                    when "datasethandle" or
                    when "dataset-handle" then
                        oParamObj:Set("xType", "dataset").
                    when "table" or
                    when "tablehandle" or
                    when "table-handle" then
                        oParamObj:Set("xType", "table").
                    otherwise do:
                        /* Apply path property as needed. */
                        if oParamObj:GetCharacter("mode") eq "input" and
                           oParamObj:GetCharacter("name") eq this-object:ReadFilter then do:
                            if bMethod.OperationType eq OperationEnum:invoke:toString() then
                                operationObj:Set("path", substitute("&1?&2=~{&2~}", bMethod.MethodURI, this-object:ReadFilter)).
                            else if bMethod.OperationType eq OperationEnum:count:toString() then
                                operationObj:Set("path", substitute("&1?&2=~{&2~}", bMethod.MethodURI, this-object:ReadFilter)).
                            else
                                operationObj:Set("path", substitute("?&1=~{&1~}", this-object:ReadFilter)).
                            oParamObj:Set("type", "QUERY"). /* Set any INPUT for a READ to use the Query parameter type. */
                        end. /* INPUT + READ */

                        if oParamObj:GetCharacter("xType") eq "datetimetz" then
                            oParamObj:Set("xType", "datetime-tz"). /* Correct the name of the ABL datatype for datetime-tz. */
                    end.
                end case.

                /* Determine how a parameter should be obtained, based on the mode of the parameter and the operation verb. */
                if oParamObj:GetCharacter("mode") eq "input" and bMethod.OperationVerb eq MethodEnum:get:toString() then
                    oParamObj:Set("type", "QUERY"). /* For INPUT on a GET, we should only obtain from the Query Parameters. */
                else if oParamObj:GetCharacter("mode") eq "input-output" then
                    oParamObj:Set("type", "REQUEST_BODY,RESPONSE_BODY"). /* Any INPUT-OUTPUT should use the BODY by default. */
                else if oParamObj:GetCharacter("mode") eq "input" then
                    oParamObj:Set("type", "REQUEST_BODY"). /* For INPUT on a non-GET, assume the parameter to be in the BODY. */
                else
                    oParamObj:Set("type", "RESPONSE_BODY"). /* Anything non-INPUT should be an OUTPUT, and returned via BODY. */

                oParamArr:Add(oParamObj). /* Add parameter to the array. */
            end. /* for each bParam */

            /* Add params to operation, and operation to array. */
            operationObj:Add("params", oParamArr).
            operationArr:Add(operationObj).
        end. /* for each */

        return operationArr.
    end method. /* getOperations */


    method protected JsonObject getDataDefs ( input pcResourceUUID as character ):
        /* DataObject Catalog Method */
        define variable oSchema as JsonObject no-undo.

        /* Obtain all non-primary schema (tables, datasets). */
        assign oSchema = this-object:getSchema(pcResourceUUID, false).
        if oSchema:Has("properties") then
            return oSchema:GetJsonObject("properties").
        else
            return new JsonObject().
    end method. /* getDataDefs */


    /**************************** Public Helper Methods ****************************/


    method override public void initialize ( ):
        /* Read catalog configuration file and register values in properties. */
        define variable cFullCfgFileName as character no-undo.
        file-info:file-name = OSTools:sparkConf + "catalog.json".
        cFullCfgFileName = file-info:full-pathname.
        if cFullCfgFileName ne ? then
            dataset dsConfig:read-json("file", cFullCfgFileName, "empty").
        else
            undo, throw new AppError(substitute("Catalog config file [catalog.json] not found in [&1]", OSTools:sparkConf), -500).

        assign lUseDebugs = log-manager:logging-level ge 3.

        for first GeneralParam:
            /* First attempt to gather defaults from the catalog config file. */
            this-object:ApiVersion = GeneralParam.ApiVersion.
            this-object:IdProperty = GeneralParam.IdProperty.
            this-object:SeqProperty = GeneralParam.SeqProperty.
            this-object:ReadFilter = GeneralParam.ReadFilter.
            this-object:ServicePrefix = GeneralParam.ServicePrefix.
            this-object:CatalogService = GeneralParam.CatalogService.

            /* Provide a known default interface class for the catalog output. */
            if (this-object:CatalogService gt "") ne true then
                this-object:CatalogService = "Spark.Core.Service.ICatalog".

            assign /* Obtain defaults for general operation. */
                cPreLoader = GeneralParam.PreLoader /* Executes code prior to anything else. */
                .
        end. /* for first */

        /* Set default name for ID property. */
        if (this-object:IdProperty gt "") ne true then
            this-object:IdProperty = "id".

        /* Set default name for Sequence property. */
        if (this-object:SeqProperty gt "") ne true then
            this-object:SeqProperty = "seq".

        /* Set default name for Read filter param. */
        if (this-object:ReadFilter gt "") ne true then
            this-object:ReadFilter = "filter".

        /**
         * Set default name for Service Prefix.
         * The default for Spark Toolkit is "api".
         */
        if (this-object:ServicePrefix gt "") ne true then
            this-object:ServicePrefix = "api".

        /* Assign a unique ID for each service defined. */
        for each ServiceList exclusive-lock:
            assign ServiceList.ServiceUUID = substring(base64-encode(generate-uuid), 1, 22).
        end. /* for each ServiceList */

        /* Obtain a default service name (first from list). */
        find first ServiceList no-error.
        if available(ServiceList) then
            assign cDefaultUUID = ServiceList.ServiceUUID.

        /* Create the initial object to hold the catalog registry. */
        assign oCatRegistry = new JsonObject().
    end method. /* initialize */


    method override public void dispose ( ):
        for each EntityProperty:
            /* Delete entity properties when manager is disposed. */
            delete object EntityProperty.FieldData no-error.
        end.

        define variable oDOS as DataObjectService no-undo extent.
        define variable cCat as character         no-undo extent.
        define variable iX   as integer           no-undo.

        assign oDOS = ServiceRegistry:Registry:GetServices().
        do iX = 1 to extent(oDOS):
            message substitute("Deregistering Service: '&1' v&2", oDOS[iX]:Name, oDOS[iX]:version:ToString()).
            ServiceRegistry:Registry:DeregisterService(oDOS[iX]:Name, oDOS[iX]:Version).
        end. /* do iX */

        assign cCat = oCatRegistry:GetNames().
        do iX = 1 to extent(cCat):
            oCatRegistry:Remove(cCat[iX]). /* Remove cached catalog. */
        end. /* do iX */
        delete object oCatRegistry no-error. /* Clear the catalog registry. */

        empty temp-table GeneralParam.
        empty temp-table ServiceList.
        empty temp-table ResourceList.
        empty temp-table ServiceInfo.
        empty temp-table ResourceInfo.
        empty temp-table MethodInfo.
        empty temp-table ParameterInfo.
        empty temp-table ResourceProperty.
        empty temp-table EntityProperty.
    end method. /* dispose */


    method protected character stripFileExtensions ( input pcFileName as character ):
        assign
            pcFileName = substring(pcFileName, 1, length(pcFileName) - 4) when pcFileName matches "*.cls"
            pcFileName = substring(pcFileName, 1, length(pcFileName) - 2) when pcFileName matches "*.p"
            pcFileName = substring(pcFileName, 1, length(pcFileName) - 2) when pcFileName matches "*.r"
            .
        return pcFileName.
    end method. /* stripFileExtension */


    method protected void checkForResources ( ):
        /* Resource Discovery Process */
        define variable ix         as integer   no-undo.
        define variable cClassPath as character no-undo.
        define variable cPath      as character no-undo.
        define variable cRoot      as character no-undo.
        define variable oDirStruct as JsonArray no-undo.

        define buffer bGenParam for GeneralParam.
        define buffer bService  for ServiceList.
        define buffer bSrvcRes  for ResourceList.
        define buffer bResource for ResourceInfo.

        for first bGenParam no-lock:
            assign cRoot = "".

            /* Determine how resources will be discovered: by config or by disk. */
            if bGenParam.BusinessRoot matches "*.pl" or bGenParam.BusinessRoot eq "" then do:
                oLoggingManager:logMessage(substitute("Discovering resource options from config file (&1).", bGenParam.BusinessRoot), "SPARK-LOAD", 3).

                /* Value is blank or points to a PL, so we must use the given config data. */
                for each bService no-lock:
                    /* Search through each listed service for available resources. */
                    for each bSrvcRes exclusive-lock
                       where bSrvcRes.ServiceName eq bService.ServiceName:
                        assign bSrvcRes.ServiceUUID = bService.ServiceUUID.

                        /*
                         * Make sure any path ending in ".p" is changed to end in ".r"
                         * (we should expect to find compiled code only in a PL file).
                         */
                        if bSrvcRes.ClassPath matches "*.p" then
                            assign cClassPath = this-object:stripFileExtensions(bSrvcRes.ClassPath) + ".r".
                        else
                            assign cClassPath = bSrvcRes.ClassPath.

                        /* Create resource info about each found service resource. */
                        create bResource. /* ResourceInfo */
                        assign
                            bResource.ServiceUUID  = bService.ServiceUUID
                            bResource.ResourceUUID = substring(base64-encode(generate-uuid), 1, 22)
                            bResource.ApiVersion   = "0.0.0"
                            .

                        if not (cClassPath matches "*.r") then
                            assign /* Create information about a class. */
                                bResource.ClassPath   = bSrvcRes.ClassPath /* Remains a class package. */
                                bResource.PublicName  = entry(num-entries(bSrvcRes.ClassPath, "."), bSrvcRes.ClassPath, ".") /* Last element of class package. */
                                bResource.ResourceURI = "/" + bResource.PublicName
                                bResource.SourcePath  = replace(bSrvcRes.ClassPath, ".", "/") + ".cls" /* Convert to path to class file. */
                                bResource.IsClass     = true
                                .
                        else
                            assign /* Create information about a procedure. */
                                bResource.ClassPath   = this-object:stripFileExtensions(entry(num-entries(cClassPath, "/"), cClassPath, "/"))
                                bResource.PublicName  = bResource.ClassPath /* Remains the full path to procedure, for now. */
                                bResource.ResourceURI = "/" + bResource.PublicName
                                bResource.SourcePath  = cClassPath /* Use the path with .r extension. */
                                bResource.IsClass     = false
                                .
                    end. /* bSrvcRes */
                end. /* bService */
            end. /* PL or Blank */
            else do ix = 1 to num-entries(propath):
                /* BusinessRoot is a folder, so we must find a matching directory in the PROPATH. */
                assign cPath = replace(entry(ix, propath), "~\", "/").
                file-info:file-name = substitute("&1/&2", cPath, bGenParam.BusinessRoot).
                if file-info:full-pathname ne ? then do:
                    assign cRoot = replace(file-info:full-pathname, "~\", "/").
                    oLoggingManager:logMessage(substitute("Discovering resource options from filesystem (&1).", cRoot), "SPARK-LOAD", 3).
                    leave. /* Found our root, so leave. */
                end.
            end. /* Physical Folders */
        end. /* for first bGenParam */

        /* Go down the rabbit hole, Alice... */
        if (cRoot gt "") eq true then do:
            /* Proceed with resource discovery using a physical path. */
            define variable cFileName as character  no-undo.
            define variable cFilePath as character  no-undo.
            define variable cRootPath as character  no-undo.
            define variable cResource as character  no-undo.
            define variable cTempName as character  no-undo.
            define variable oFile     as JsonObject no-undo.

            /* Get a recursive list of files from the specified directory. */
            assign oDirStruct = Spark.Core.Util.OSTools:recurseDir(cRoot, true).

            DIRBLOCK:
            do ix = 1 to oDirStruct:Length on error undo, throw:
                /* Inspect each file found. */
                assign oFile = oDirStruct:GetJsonObject(ix).

                assign /* Reset variables on each loop. */
                    cFileName = oFile:GetCharacter("FileName")
                    cFilePath = oFile:GetCharacter("FullPath")
                    cRootPath = replace(cRoot, "/" + bGenParam.BusinessRoot, "") + "/"
                    cResource = "" /* Reset on each iteration through the files. */
                    cTempName = "" /* Reset on each iteration through the files. */
                    .

                if error-status:error then leave DIRBLOCK. /* Leave if any error encountered so far. */
                rcode-info:file-name = cFilePath. /* Obtain any R-code information, if available. */

                /* Only investigate files that are explicitly classes, procedures, or r-code. */
                if (cFileName matches "*.cls" or cFileName matches "*.p" or cFileName matches "*.r") then
                    assign /* Convert from file paths to class package. */
                        cTempName = this-object:stripFileExtensions(cFileName)
                        cResource = this-object:stripFileExtensions(cFilePath)
                        cResource = replace(cResource, "/", ".")
                        cResource = substring(cResource, index(cFilePath, bGenParam.BusinessRoot))
                        .

                /* The full service path using the relative URI. */
                if (cTempName gt "") eq true then
                    assign cClassPath = right-trim(cResource, cTempName).
                assign cClassPath = trim(cClassPath, ".").

                /* Class path may be part of 1 or more paths for a service. */
                for first bService no-lock
                    where bService.ClassPath eq cClassPath:

                    /* Create a record using the service and resource, if not present. */
                    if (cResource gt "") eq true and (cTempName gt "") eq true then do:
                       if can-find(first bSrvcRes no-lock
                                   where bSrvcRes.ServiceUUID eq bService.ServiceUUID
                                     and bSrvcRes.ClassPath eq cResource) or
                          can-find(first bSrvcRes no-lock
                                   where bSrvcRes.ServiceUUID eq bService.ServiceUUID
                                     and bSrvcRes.ClassPath eq cTempName) or
                          can-find(first bResource no-lock
                                   where bResource.ServiceUUID eq bService.ServiceUUID
                                     and bResource.ClassPath eq cResource) or
                          can-find(first bResource no-lock
                                   where bResource.ServiceUUID eq bService.ServiceUUID
                                     and bResource.ClassPath eq cTempName) then
                        next DIRBLOCK.

                        /* ServiceResource, used for main config data. */
                        create bSrvcRes.
                        assign
                            bSrvcRes.ServiceUUID = bService.ServiceUUID
                            bSrvcRes.ServiceName = bService.ServiceName
                            .

                        /* ResourceInfo, used for catalog metadata. */
                        create bResource.
                        assign
                            bResource.ServiceUUID  = bService.ServiceUUID
                            bResource.ResourceUUID = substring(base64-encode(generate-uuid), 1, 22)
                            bResource.ApiVersion   = "0.0.0"
                            .

                        if rcode-info:is-class or cFileName matches "*.cls" then
                            assign /* Create information about a class. */
                                bSrvcRes.ClassPath     = cResource
                                bResource.ClassPath    = cResource
                                bResource.PublicName   = cTempName
                                bResource.ResourceURI  = "/" + cTempName
                                bResource.SourcePath   = replace(cFilePath, cRootPath, "")
                                bResource.IsClass      = true
                                .
                        else
                            assign /* Create information about a procedure. */
                                bSrvcRes.ClassPath     = replace(cFilePath, cRootPath, "")
                                bResource.ClassPath    = cTempName
                                bResource.PublicName   = cTempName
                                bResource.ResourceURI  = "/" + cTempName
                                bResource.SourcePath   = replace(cFilePath, cRootPath, "")
                                bResource.IsClass      = false
                                .

                        release bSrvcRes no-error.
                        release bResource no-error.
                    end. /* cResource */
                end. /* bService */

                catch err as Progress.Lang.Error:
                    message substitute("Error Processing Found Resource: &1 [&2]", err:GetMessage(1), cFilePath).
                    next DIRBLOCK.
                end catch.
            end. /* do */
        end. /* cRoot */
    end method. /* checkForResources */


    method public void loadResources ( ):
        /* Resource Discovery Process */
        empty temp-table ServiceInfo.
        empty temp-table ResourceInfo.
        empty temp-table MethodInfo.
        empty temp-table ParameterInfo.
        empty temp-table ResourceProperty.
        empty temp-table EntityProperty.

        /* Confirm whether the necessary OE.BL.BE class exists for the current environment. */
        define variable oBusinessEntity as Progress.Lang.Object no-undo.
        assign oBusinessEntity = Progress.Lang.Class:GetClass("OpenEdge.BusinessLogic.BusinessEntity") no-error.
        if not valid-object(oBusinessEntity) then
            assign lHasOEBLBE = false. /* Signal that the required class was not found. */

        /* Before loading the (dynamic) resources run a preloader, if configured. */
        oLoggingManager:logMessage("Running Preloader...", "SPARK-LOAD", 4).
        this-object:runPreloader().

        /* Look for any available classes/procedures at the expected location(s), including PL files. */
        oLoggingManager:logMessage("Checking Resources...", "SPARK-LOAD", 4).
        this-object:checkForResources().

        /* Load all dynamic resources as specified by config file. */
        for each ResourceInfo:
            oLoggingManager:logMessage(substitute("Loading Resource: '&1'", ResourceInfo.ClassPath), "SPARK-LOAD", 4).
            this-object:loadDynamicResource(ResourceInfo.ResourceUUID).
        end. /* for each ResourceInfo */

        /* Update the ServiceInfo table (for dsResource) using the original config table ServiceList. */
        for each ServiceList no-lock:
            create ServiceInfo. /* Dummy table record incoming. */
            buffer-copy ServiceList to ServiceInfo no-error.
        end. /* for each ServiceList */

        if lUseDebugs then do:
            /* Write out our internal datsets for further debugging/confirmation. */
            dataset dsConfig:write-json("file", substitute("&1/CatalogDetail.json", this-object:TemporaryDir), true).
            dataset dsResource:write-json("file", substitute("&1/ResourceMetadata.json", this-object:TemporaryDir), true).
            oSchemaManager:dumpObjects().
        end. /* lUseDebugs */

        finally:
            if valid-object(oBusinessEntity) then
                delete object oBusinessEntity no-error.
        end finally.
    end method. /* loadResources */


    method public void addProperty ( input pcServiceURI    as character,
                                     input pcClassPath     as character,
                                     input pcOperationType as character,
                                     input pcPropertyName  as character,
                                     input pcPropertyType  as character,
                                     input pcPropertyValue as character ):
        /* Resource Discovery Process */
        define buffer bService  for ServiceList.
        define buffer bResource for ResourceInfo.
        define buffer bMethod   for MethodInfo.
        define buffer bProperty for ResourceProperty.

        /* Use default service if none provided. */
        if (pcServiceURI gt "") ne true then
            find first bService no-lock
                 where bService.ServiceUUID eq cDefaultUUID no-error.
        else
            find first bService no-lock
                 where bService.ServiceURI eq pcServiceURI no-error.

        if available(bService) then
            find first bResource no-lock
                 where bResource.ServiceUUID eq bService.ServiceUUID
                   and bResource.ClassPath eq pcClassPath no-error.

        if available(bResource) and
           can-find(first bMethod no-lock
                    where bMethod.ResourceUUID eq bResource.ResourceUUID
                      and bMethod.OperationType eq pcOperationType) then do:
            /* Add/Update property only if resource+operation defined. */
            find first bProperty
                 where bProperty.ResourceUUID eq bResource.ResourceUUID
                   and bProperty.OperationType eq pcOperationType
                   and bProperty.PropertyName eq pcPropertyName no-error.
            if not available(bProperty) then do:
                create bProperty.
                assign
                    bProperty.ResourceUUID  = bResource.ResourceUUID
                    bProperty.OperationType = pcOperationType
                    bProperty.PropertyType  = pcPropertyType
                    bProperty.PropertyName  = pcPropertyName
                    .
            end.
            assign bProperty.PropertyValue = pcPropertyValue.
        end.
    end method. /* addProperty */


    method public void describeEntity ( input pcServiceUUID  as character,
                                        input pcResClassPath as character,
                                        input pcEntityName   as character,
                                        input pcPrimaryKeys  as character,
                                        input pcForeignKeys  as character ):
        /* Resource Discovery Process */

        /* Use default service if none provided. */
        if (pcServiceUUID gt "") ne true then pcServiceUUID = cDefaultUUID.

        for first ResourceInfo
            where ResourceInfo.ServiceUUID eq pcServiceUUID
              and ResourceInfo.ClassPath eq pcResClassPath:
            assign
                ResourceInfo.EntityName  = pcEntityName
                ResourceInfo.EntityKeys  = pcPrimaryKeys
                ResourceInfo.ForeignKeys = pcForeignKeys
                .
        end.
    end method. /* describeEntity */


    method public void describeFields ( input pcEntityName as character,
                                        input pcTableName  as character,
                                        input poFieldData  as JsonObject ):
        /* Resource Discovery Process */
        define buffer bEntity for EntityProperty.

        if (pcEntityName gt "") eq true and (pcTableName gt "") eq true then do:
            find first bEntity exclusive-lock
                 where bEntity.EntityName eq pcEntityName
                   and bEntity.TableName eq pcTableName no-error.

            if not available(bEntity) then do:
                create bEntity.
                assign
                    bEntity.EntityName = pcEntityName
                    bEntity.TableName  = pcTableName
                    .
            end.

            if valid-object(poFieldData) then
                assign bEntity.FieldData = cast(poFieldData:Clone(), JsonObject).

            release bEntity no-error.
        end. /* pcEntityName / pcTableName  */
    end method. /* describeFields */


    method public void describeResource ( input pcServiceURI    as character,
                                          input pcClassPath     as character,
                                          input pcMethodName    as character,
                                          input pcPublicName    as character,
                                          input pcOperationType as character,
                                          input pcOperationVerb as character ):
        /* Resource Discovery Process */
        define buffer bService  for ServiceList.
        define buffer bResource for ResourceInfo.
        define buffer bMethod   for MethodInfo.

        /* Use default service if none provided. */
        if (pcServiceURI gt "") ne true then
            find first bService no-lock
                 where bService.ServiceUUID eq cDefaultUUID no-error.
        else
            find first bService no-lock
                 where bService.ServiceURI eq pcServiceURI no-error.

        if available(bService) then
            find first bResource no-lock
                 where bResource.ServiceUUID eq bService.ServiceUUID
                   and bResource.ClassPath eq pcClassPath no-error.

        if available(bResource) then do:
            /* If another method for these particular operations exists, delete it first. */
            if can-do("create,read,update,delete,submit", pcOperationType) then
                for first bMethod exclusive-lock
                    where bMethod.ResourceUUID eq bResource.ResourceUUID
                      and bMethod.OperationType eq pcOperationType:
                    delete bMethod. /* Remove the method as we'll re-create it. */
                end. /* for first bMethod */

            find first bMethod exclusive-lock
                 where bMethod.ResourceUUID eq bResource.ResourceUUID
                   and bMethod.MethodName eq pcMethodName no-error.
            if not available(bMethod) then do:
                create bMethod.
                assign
                    bMethod.ResourceUUID = bResource.ResourceUUID
                    bMethod.MethodName   = pcMethodName
                    bMethod.PublicName   = pcMethodName /* Default until overridden. */
                    pcPublicName         = ""      /* Reset override on each method. */
                    .

                /* Set default attributes for certain entity class methods. */
                case pcMethodName:
                    when "readData" then
                        assign
                            pcPublicName          = OperationEnum:read:toString()
                            bMethod.OperationType = lc(OperationEnum:read:toString())
                            bMethod.OperationVerb = lc(MethodEnum:get:toString())
                            .
                    when "createData" then
                        assign
                            pcPublicName          = OperationEnum:create:toString()
                            bMethod.OperationType = lc(OperationEnum:create:toString())
                            bMethod.OperationVerb = lc(MethodEnum:post:toString())
                            .
                    when "updateData" then
                        assign
                            pcPublicName          = OperationEnum:update:toString()
                            bMethod.OperationType = lc(OperationEnum:update:toString())
                            bMethod.OperationVerb = lc(MethodEnum:put:toString())
                            .
                    when "deleteData" then
                        assign
                            pcPublicName          = OperationEnum:delete:toString()
                            bMethod.OperationType = lc(OperationEnum:delete:toString())
                            bMethod.OperationVerb = lc(MethodEnum:delete:toString())
                            .
                    when "submitData" then
                        assign
                            pcPublicName          = OperationEnum:submit:toString()
                            bMethod.OperationType = lc(OperationEnum:submit:toString())
                            bMethod.OperationVerb = lc(MethodEnum:put:toString())
                            .
                    otherwise
                        assign /* Default for all other operations. */
                            bMethod.OperationType = lc(OperationEnum:invoke:toString())
                            bMethod.OperationVerb = lc(MethodEnum:put:toString())
                            .
                end case.
            end. /* not available */

            assign
                bMethod.PublicName    = pcPublicName when (pcPublicName gt "")
                bMethod.MethodURI     = "/" + bMethod.PublicName
                bMethod.OperationType = lc(pcOperationType) when (pcOperationType gt "")
                bMethod.OperationVerb = lc(pcOperationVerb) when (pcOperationVerb gt "")
                .

            if pcOperationType eq OperationEnum:read:toString() then
                assign bMethod.MethodURI = "?filter=~{filter~}".

            if pcOperationType eq OperationEnum:count:toString() then
                assign bMethod.MethodURI = "/count?filter=~{filter~}".

            if can-do("read,create,update,delete,submit", bMethod.OperationType) then
                this-object:addProperty(bService.ServiceURI, bResource.ClassPath, bMethod.OperationType, "useBeforeImage", "logical", "true").

            release bMethod no-error.
        end. /* available */

        catch err as Progress.Lang.Error:
            oLoggingManager:logError(substitute("Unable to describe method '&1:&2' (&3)",
                                                pcClassPath,
                                                pcMethodName,
                                                pcServiceURI), err, "SPARK-ERR", 0).
        end catch.
    end method. /* describeResource */


    method public JsonObject getCatalog ( input pcServiceURI   as character,
                                          input pcResourceName as character ):
        /* DataObject Catalog Method */
        define variable cHash as character no-undo.

        define buffer bService for ServiceInfo.

        /* Use a simple hash to identify this combination of URI and Resource Name. */
        assign cHash = encode(pcServiceURI + pcResourceName).

        if not oCatRegistry:Has(cHash) then do:
            /**
             * Catalog data should be static after first generation by URI/Resource,
             * and only changes when MSAS sessions are started or when data is first
             * requested. Therefore we should be able to cache this data for speed.
             */
            define variable oCatalog as JsonObject no-undo.

            /* Check if service exists for the given URI. */
            find first bService no-lock
                 where bService.ServiceURI eq pcServiceURI no-error.

            assign oCatalog = new JsonObject().
            oCatalog:Add("version", 1.5).
            oCatalog:Add("lastModified", now).
            if available(bService) then
                oCatalog:Add("services", this-object:getServices(bService.ServiceUUID, pcResourceName)).
            else
                oCatalog:Add("services", new JsonObject()).

            oLoggingManager:logMessage(substitute("Caching catalog data for URI '&1' Resource '&2'",
                                                  pcServiceURI, pcResourceName), "SPARK-CTLG", 3).

            oCatRegistry:Add(cHash, oCatalog). /* Add to local registry for this combination. */
        end. /* oCatalog Exists */

        return oCatRegistry:GetJsonObject(cHash).
    end method. /* getCatalog */


    method public void stopProcedures ( ):
        define buffer bResource for ResourceInfo.

        /* Destroy any previous procedure handles. */
        for each bResource exclusive-lock
           where not bResource.IsClass
             and valid-handle(bResource.ProcHandle):
            apply "close" to bResource.ProcHandle.
            delete procedure bResource.ProcHandle no-error.
        end. /* for each */
    end method. /* stopProcedures */


    method public void registerAllServices ( input poRegistry as IServiceRegistry ):
        /* DataObjectService Registration */
        define buffer bService for ServiceInfo.

        for each bService no-lock:
            /**
             * Register each known service configured for this application.
             * Uses any discovered classes/procedures from loadResources().
             */
            this-object:registerService(poRegistry, lc(bService.ServiceName), SemanticVersion:Parse("")).
        end. /* for each bService */
    end method. /* registerAllServices */


    method public DataObjectService registerService ( input poRegistry       as IServiceRegistry,
                                                      input pcServiceName    as character,
                                                      input poServiceVersion as SemanticVersion ):
        /* DataObjectService Registration */
        define variable cServiceURI  as character           no-undo.
        define variable cContentType as character           no-undo.
        define variable cTargetType  as character           no-undo.
        define variable cTargetName  as character           no-undo.
        define variable cEntityType  as character           no-undo.
        define variable cFuncMethod  as character           no-undo.
        define variable cParamName   as character           no-undo.
        define variable cPublicName  as character           no-undo.
        define variable cParamType   as character           no-undo.
        define variable iStatusCode  as integer             no-undo.
        define variable iX           as integer             no-undo.
        define variable lIsEntity    as logical             no-undo.
        define variable hSchema      as handle              no-undo.
        define variable dExecTime    as datetime extent 2   no-undo.
        define variable oParamArr    as JsonArray           no-undo.
        define variable oParamObj    as JsonObject          no-undo.
        define variable oHttpMethod  as MethodEnum          no-undo.
        define variable oElementType as ElementTypeEnum     no-undo.
        define variable oResource    as Progress.Lang.Class no-undo.
        define variable oService     as DataObjectService   no-undo.
        define variable oOperation   as MappedOperation     no-undo.
        define variable oOperOpts    as OperationOptions    no-undo.
        define variable oParam       as OperationParameter  no-undo.
        define variable oSvcJson     as JsonObject          no-undo.
        define variable oRoleArray   as JsonArray           no-undo.
        define variable cRoleVal     as character           no-undo.
        define variable cRoleExt     as character extent    no-undo.

        define buffer bService  for ServiceInfo.
        define buffer bResource for ResourceInfo.
        define buffer bMethod   for MethodInfo.
        define buffer bParam    for ParameterInfo.

        find first bService no-lock
             where bService.ServiceName eq pcServiceName no-error.
        if available(bService) then do:
            /* Leave if the name of the service does not actually match the last element of the Service URI. */
            if pcServiceName ne entry(num-entries(bService.ServiceURI, "/"), bService.ServiceURI, "/") then return ?.

            /* Denote start of operation mapping. */
            oLoggingManager:logMessage(substitute("Registering Service: '&1' v&2",
                                                  pcServiceName, poServiceVersion:ToString()),
                                                  "SPARK-SVC", 3).

            /* Register the service using the name and version discovered. */
            assign oService = poRegistry:RegisterService(pcServiceName, poServiceVersion, ?, ?).

            /* Store the Progress-default Cloud Data Object catalog data within the DOS instance. */
            oService:Catalog = this-object:getCatalog(bService.ServiceURI, "").

            for each bResource no-lock
               where bResource.ServiceUUID eq bService.ServiceUUID,
                each bMethod no-lock
               where bMethod.ResourceUUID eq bResource.ResourceUUID:
                /* Prepare the common values for this operation mapping. */
                assign
                    cServiceURI  = (if (bMethod.MethodURI gt "") eq true then substitute("&1&2", bResource.ResourceURI, bMethod.MethodURI) else bResource.ResourceURI)
                    oHttpMethod  = MethodEnum:GetEnum(bMethod.OperationVerb) /* The HTTP verb to be used for URI access. */
                    cContentType = if (bMethod.ContentType gt "") then bMethod.ContentType else "application/json" /* MIME Type */
                    cTargetType  = (if bResource.IsClass then TargetTypeEnum:Class:ToString() else TargetTypeEnum:Procedure:ToString())
                    cTargetName  = (if bResource.IsClass then bResource.ClassPath else bResource.SourcePath)
                    cEntityType  = (if bResource.IsClass then "Progress.Lang.Object" else ?)
                    cFuncMethod  = bMethod.MethodName /* The class method or internal procedure to be run. */
                    iStatusCode  = integer(StatusCodeEnum:ok) /* Default to HTTP-200/OK */
                    lIsEntity    = false
                    dExecTime[1] = now
                    .

                if bResource.IsClass then do:
                    /* If resource is a class, determine if used as a business entity. */
                    assign oResource = Progress.Lang.Class:GetClass(bResource.ClassPath).

                    /* If the OE.BL.BE class is not present this will throw an error, hence we must also check if the class even exists. */
                    if valid-object(oResource) and lHasOEBLBE and oResource:IsA(get-class(OpenEdge.BusinessLogic.BusinessEntity)) then
                        assign lIsEntity = true.
                end. /* Is Class */

                /* Just use name of the resource for CRUD operations. */
                if lIsEntity and can-do("Create,read,update,delete", bMethod.OperationType) then
                    assign cServiceURI = bResource.ResourceURI. /* Should just be "/<resource>" with no method in the URI. */

                /* Denote start of operation mapping. */
                oLoggingManager:logMessage(substitute("Mapping &1 &2&3 to &4:&5",
                                                      oHttpMethod:ToString(),
                                                      pcServiceName,
                                                      cServiceURI,
                                                      cTargetName,
                                                      cFuncMethod),
                                                      "SPARK-SVC", 4).

                /* Set any options for the current operation. */
                assign oOperOpts = new OperationOptions().
                oOperOpts:WriteBI = this-object:getBeforeImageFlag(bMethod.ResourceUUID, bMethod.OperationType).
                oOperOpts:HasErrorEnvelope = false. /* Default is false for the Spark implementation. */
                oOperOpts:HasRequestEnvelope = false. /* Default is false for the Spark implementation. */
                oOperOpts:HasResponseEnvelope = false. /* Default is false for the Spark implementation. */

                /* Create a new mapped operation for this service. */
                assign oOperation = new MappedOperation( cServiceURI,
                                                         oHttpMethod,
                                                         cContentType,
                                                         cTargetType,
                                                         cTargetName,
                                                         cEntityType,
                                                         cFuncMethod,
                                                         oOperOpts,
                                                         iStatusCode ).

                /* Supply a public name for this operation. */
                oOperation:Name = bMethod.PublicName.

                /* If method security is present, set the access control for the operation. */
                if valid-object(bMethod.Security) then
                do on error undo, throw:
                    if cast(bMethod.Security, JsonObject):GetType("role") eq JsonDataType:Array then do:
                        /* Use a JSON array as the entries for the access list. */
                        oRoleArray = cast(bMethod.Security, JsonObject):GetJsonArray("role").

                        if valid-object(oRoleArray) then do:
                            extent(cRoleExt) = oRoleArray:Length.
                            do iX = 1 to oRoleArray:Length:
                                cRoleExt[iX] = oRoleArray:GetCharacter(iX).
                            end.
                        end. /* valid role array */
                    end. /* array */
                    else if cast(bMethod.Security, JsonObject):GetType("role") eq JsonDataType:String then do:
                        /* Use a comma-delimited list as the entries for the access list. */
                        assign cRoleVal = cast(bMethod.Security, JsonObject):GetCharacter("role").
                        extent(cRoleExt) = num-entries(cRoleVal).

                        do iX = 1 to num-entries(cRoleVal):
                            cRoleExt[iX] = entry(iX, cRoleVal).
                        end.
                    end. /* string */

                    if extent(cRoleExt) ne ? then
                        oOperation:AccessControl = cRoleExt.

                    finally:
                        delete object oRoleArray no-error.
                        extent(cRoleExt) = ?.
                    end finally.
                end. /* Has Security Object */

                for each bParam no-lock
                   where bParam.ResourceUUID eq bResource.ResourceUUID
                     and bParam.MethodName eq bMethod.MethodName:
                    assign
                        cParamName  = bParam.ParamName
                        cPublicName = bParam.PublicName
                        cParamType  = bParam.DataType
                        hSchema     = ?
                        .

                    /* Obtain the schema for a dataset parameter. */
                    if cParamType begins "dataset" then do:
                        if lIsEntity and cPublicName ne bResource.EntityName then
                            assign cPublicName = if bResource.EntityName gt "" then bResource.EntityName else cParamName.

                        if not oService:HasSchema(cParamName) then do:
                            oSchemaManager:getDataset(cParamName, dataset-handle hSchema by-reference).
                            if valid-handle(hSchema) then do:
                                oService:PutSchema(cParamName, hSchema). /* Add schema to service. Do not delete the hSchema handle! */
                                oLoggingManager:logMessage(substitute("| Schema: &1 as dataset", cParamName), "SPARK-SVC", 4).
                            end. /* valid-handle */
                            else
                                oLoggingManager:logMessage(substitute("| Schema: no dataset handle for &1", cParamName), "SPARK-SVC", 2).
                        end. /* not HasSchema */
                    end. /* dataset */

                    /* Obtain the schema for a table parameter. */
                    if cParamType begins "table" then do:
                        if not oService:HasSchema(cParamName) then do:
                            oSchemaManager:getTempTable(cParamName, table-handle hSchema by-reference).
                            if valid-handle(hSchema) then do:
                                oService:PutSchema(cParamName, hSchema). /* Add schema to service. Do not delete the hSchema handle! */
                                oLoggingManager:logMessage(substitute("| Schema: &1 as table", cParamName), "SPARK-SVC", 4).
                            end. /* valid-handle */
                            else
                                oLoggingManager:logMessage(substitute("| Schema: no table handle for &1", cParamName), "SPARK-SVC", 2).
                        end. /* not HasSchema */
                    end. /* table */

                    /* If the param has an unknown or non-zero extent, then the datatype should be treated as an extent/array. */
                    if bParam.DataTypeExtent ne 0 then
                        assign cParamType = substitute("&1 extent", cParamType).

                    /* Create the parameter for this method. */
                    assign oParam = new OperationParameter(IOModeEnum:GetEnum(bParam.IOMode), cParamType, cParamName).

                    /* Assign message elements based on the parameter IO mode. */

                    if bParam.IOMode eq "input" then do:
                        if oHttpMethod eq MethodEnum:GET then
                            assign oElementType = ElementTypeEnum:Query. /* Use query parameters for GET. */
                        else
                            assign oElementType = ElementTypeEnum:Field. /* Otherwise, use field of body. */

                        if cParamName eq "bodyInput" then
                            assign oElementType = ElementTypeEnum:Body. /* Special name indicates use of body. */

                        extent(oParam:InputElement) = 1.
                        assign oParam:InputElement[1] = new MessageElement(oElementType, cPublicName, IOModeEnum:Input).
                    end. /* input */

                    else if bParam.IOMode eq "output" then do:
                        if can-do("dataset,table", cParamType) then
                            assign oElementType = ElementTypeEnum:Body. /* Output dataset/table as body. */
                        else
                            assign oElementType = ElementTypeEnum:Field. /* Otherwise, use field of body. */

                        if cParamName eq "bodyOutput" then
                            assign oElementType = ElementTypeEnum:Body. /* Special name indicates use of body. */

                        extent(oParam:OutputElement) = 1.
                        assign oParam:OutputElement[1] = new MessageElement(oElementType, cPublicName, IOModeEnum:Output).
                    end. /* output */

                    else if bParam.IOMode eq "input-output" then do:
                        if can-do("dataset,table", cParamType) then
                            assign oElementType = ElementTypeEnum:Body. /* Output dataset/table as body. */
                        else
                            assign oElementType = ElementTypeEnum:Field. /* Otherwise, use field of body. */

                        if cParamName eq "bodyInputOutput" then
                            assign oElementType = ElementTypeEnum:Body. /* Special name indicates use of body. */

                        extent(oParam:InputElement) = 1.
                        extent(oParam:OutputElement) = 1.
                        assign oParam:InputElement[1] = new MessageElement(oElementType, cPublicName, IOModeEnum:InputOutput).
                        assign oParam:OutputElement[1] = new MessageElement(oElementType, cPublicName, IOModeEnum:InputOutput).
                    end. /* output/input-output */

                    /* Add parameter to the operation. */
                    oOperation:Parameters:Add(oParam).

                    /* Log creation of each parameter. */
                    oLoggingManager:logMessage(substitute("| &1: &2 as &3 [&4]",
                                                          bParam.IOMode,
                                                          cParamName,
                                                          cParamType,
                                                          oElementType:ToString()), "SPARK-SVC", 4).
                end. /* for each bParam */

                /* Add the new mapped operation to the current service. */
                oService:PutOperation(oOperation).

                /* Denote end of operation mapping. */
                assign dExecTime[2] = now.
                oLoggingManager:logMessage(substitute("| Completed in &1ms",
                                                      interval(dExecTime[2], dExecTime[1], string(DateTimeAddIntervalEnum:Milliseconds))),
                                                      "SPARK-SVC", 4).

                finally:
                    delete object oParamArr no-error.
                end finally.
            end. /* for each bResource, each bMethod */
        end. /* available bService */
        else do:
            /* Create a special service for the ROOT if not already found. */
            if pcServiceName eq "ROOT" then do:
                assign dExecTime[1] = now. /* Mark start of mapping. */

                /* Register the service using the name and version discovered. */
                assign oService = poRegistry:RegisterService(pcServiceName, SemanticVersion:Parse(""), ?, ?).

                /* Create a new mapped operation for this service, which MUST implement the ICatalog interface. */
                define variable oServiceClass as Progress.Lang.Class  no-undo.
                define variable oServiceImpl  as Progress.Lang.Object no-undo.

                assign oServiceClass = Progress.Lang.Class:GetClass(this-object:CatalogService).
                if valid-object(oServiceClass) then
                    assign oServiceImpl = Ccs.Common.Application:ServiceManager:getService(oServiceClass) no-error.

                if valid-object(oServiceImpl) then do:
                    /* This will use a common method to access the catalog data from the Data Object Servics. */
                    assign oOperation = new MappedOperation( "/",
                                                             MethodEnum:GET,
                                                             "application/json",
                                                             TargetTypeEnum:Class:ToString(),
                                                             oServiceImpl:GetClass():TypeName,
                                                             "Progress.Lang.Object", /* Must use the most basic type. */
                                                             "getCatalog", /* Should be a known method in ICatalog. */
                                                             ?, /* No operation options required for this endpoint. */
                                                             integer(StatusCodeEnum:ok) ).

                    /* Create a single "catalog" parameter as body output and add to list. */
                    assign oParam = new OperationParameter( IOModeEnum:Output, "class Progress.Json.ObjectModel.JsonObject", "catalog" ).
                    extent(oParam:OutputElement) = 1.
                    assign oParam:OutputElement[1] = new MessageElement(ElementTypeEnum:Body, "catalog", IOModeEnum:Output).
                    oOperation:Parameters:Add(oParam).

                    /* Add a mapped operation to the current service. */
                    oService:PutOperation(oOperation).
                end. /* Valid Implementation */
                else
                    undo, throw new AppError(substitute("Service implementation not configured for catalog (&1).", this-object:CatalogService), -500).

                /* Log values to be used for mapping. */
                assign dExecTime[2] = now.
                oLoggingManager:logMessage(substitute("Mapped GET ROOT (/) to Spark.Core.Service.Catalog:getCatalog in &1ms",
                                                      interval(dExecTime[2], dExecTime[1], string(DateTimeAddIntervalEnum:Milliseconds))),
                                                      "SPARK-SVC", 4).
            end. /* ROOT Service */
            else
                oLoggingManager:logMessage(substitute("Unable to locate service for '&1'", pcServiceName), "SPARK-SVC", 1).
        end. /* not avaialble bService */

        /* Debug the current service by dumping to a JSON file when logging level is verbose. */
        if lUseDebugs and valid-object(oService) then do on error undo, leave:
            define variable oSvcWriter as MappingFileServiceWriter no-undo.

            assign oSvcWriter = new MappingFileServiceWriter().

            oSvcWriter:open().
            oSvcWriter:write(oService).
            oSvcWriter:close().
            oSvcJson = cast(oSvcWriter:Value, JsonObject).
            oSvcJson:WriteFile(substitute("&1/&2.map", this-object:TemporaryDir, pcServiceName), yes).

            catch err as Progress.Lang.Error:
                oLoggingManager:logError("Error while dumping service.", err, "SPARK-SVC", 2).
            end catch.
            finally:
                delete object oSvcWriter no-error.
                delete object oSvcJson no-error.
            end finally.
        end. /* MAP Output */

        if valid-object(oService) then
            return oService. /* Return the service created by the method. */
        else
            return ?. /* Return unknown rather than an invalid object. */

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Error while creating service.", err, "SPARK-SVC", 1).
            undo, throw err.
        end catch.
    end method. /* registerService */

end class.