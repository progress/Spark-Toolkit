/*------------------------------------------------------------------------
    File        : CatalogManager
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Dec 19 14:30:46 EST 2014
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Progress.Json.ObjectModel.ObjectModelParser.* from propath.
using OpenEdge.Core.* from propath.
using OpenEdge.Core.Collections.* from propath.
using OpenEdge.Net.HTTP.MethodEnum from propath.
using OpenEdge.Net.HTTP.StatusCodeEnum from propath.
using OpenEdge.Web.DataObject.* from propath.
using OpenEdge.Web.DataObject.Writer.* from propath.
using Spark.Core.Manager.ICatalogManager from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.IMessageManager from propath.
using Spark.Core.Manager.ISchemaManager from propath.
using Spark.Core.Service.IDynamicEntity from propath.
using Spark.Core.Service.IDynamicResource from propath.
using Spark.Core.Util.ApplicationError from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Util.OperationEnum from propath.
using Spark.Core.Util.OSTools from propath.
using Spark.Core.Util.Reflection from propath.

block-level on error undo, throw.

&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW

class Spark.Core.Manager.CatalogManager inherits Spark.Core.Manager.Manager implements ICatalogManager use-widget-pool:

    define public property ApiVersion     as decimal   no-undo get. private set.
    define public property IdProperty     as character no-undo get. private set.
    define public property SeqProperty    as character no-undo get. private set.
    define public property ReadFilter     as character no-undo get. private set.
    define public property ServicePrefix  as character no-undo get. private set.
    define public property CatalogService as character no-undo get. private set.
    define public property UseRequestObj  as logical   no-undo get. private set.

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

    define private variable cPreLoader   as character  no-undo.
    define private variable cDefaultURI  as character  no-undo.
    define private variable lUseDebugs   as logical    no-undo.
    define private variable oCatRegistry as JsonObject no-undo.

    define private temp-table GeneralParam no-undo serialize-name "General"
        field ApiVersion     as decimal   /* Expected version to be used with all API's.              */
        field CatalogService as character /* Service class for delivering catalog output for clients. */
        field BusinessRoot   as character /* Starting location for reading all business entities.     */
        field EnableDebugs   as logical   /* Display additional info as resources are loaded.         */
        field IdProperty     as character /* Name of property to use for record ID purposes.          */
        field SeqProperty    as character /* Name of property to use for result sequence purposes.    */
        field PreLoader      as character /* Special procedure to run prior to loading resources.     */
        field ReadFilter     as character /* Name of URL parameter that will hold any filters.        */
        field ServicePrefix  as character /* URI prefix for services exposed by Spark (eg. pdo, api). */
        index idxEntity      is primary unique BusinessRoot
        .

    define private temp-table ServiceList no-undo serialize-name "ServiceSource"
        field ServiceName     as character               /* Name of the service as exposed via the catalog.   */
        field ServiceURI      as character               /* Path for resources (relative to actual service).  */
        field ClassPath       as character               /* Class path of related business entity classes.    */
        field SendOnlyChanges as logical   initial false /* Only send the fields that change, not the record. */
        field UseRequest      as logical   initial false /* Should invoke operations use request/response.    */
        index idxPrimary      is primary unique ServiceName ServiceURI
        index idxClassPath    is         unique ClassPath
        .

    define private temp-table ResourceList no-undo serialize-name "ServiceResource"
        field ServiceName as character serialize-hidden        /* Name of the service as exposed via the catalog.              */
        field ClassPath   as character serialize-name "Object" /* Class package or procedure path or of this service resource. */
        index idxPrimary  is primary unique ClassPath
        .

    define private dataset dsConfig serialize-name "Config" for GeneralParam, ServiceList, ResourceList
        data-relation ServiceResource for ServiceList, ResourceList relation-fields(ServiceName,ServiceName) nested
        .

    define private temp-table ServiceInfo no-undo serialize-name "Service"
        field ServiceName as character serialize-name "Name"
        field ServiceURI  as character serialize-name "URI"
        index idxPrimary  is primary unique ServiceURI
        index idxName     is         unique ServiceName
        .

    define private temp-table ResourceInfo no-undo serialize-name "Resource"
        field ServiceURI  as character serialize-name "Service" /* Relative URI for service (as a path) for API resources.     */
        field ClassPath   as character serialize-name "Package" /* Actual class path (aka. resource name) for API operations.  */
        field PublicName  as character serialize-name "Name"    /* Public name for resource, as used by the catalog generator. */
        field SourcePath  as character serialize-name "Source"  /* For all types, path to file on disk relative to propath.    */
        field ProcHandle  as handle    serialize-hidden         /* For procedures, a handle to the procedure run as a super.   */
        field IsClass     as logical   serialize-hidden         /* Denotes loaded resource is a class per rcode-info:is-class. */
        field ValidClass  as logical   serialize-hidden         /* For classes, denotes a valid interface implementation.      */
        field EntityName  as character serialize-hidden         /* For business entities, denotes the name of the dataset.     */
        field EntityKeys  as character serialize-hidden         /* For business entities, denotes any primary key fields.      */
        field ForeignKeys as character serialize-hidden         /* For business entities, denotes any foreign key fields.      */
        field ClassSig    as character serialize-hidden         /* For business entities, holds full signature of class.       */
        index idxPrimary  is primary unique ServiceURI ClassPath
        index idxPublic   is unique         ServiceURI PublicName
        .

    define private temp-table MethodInfo no-undo serialize-name "Operation"
        field ServiceURI      as character serialize-name "Service"
        field ClassPath       as character serialize-name "Package"
        field MethodName      as character serialize-name "Method"
        field PublicName      as character serialize-name "Name"
        field MethodSignature as character serialize-name "Signature"
        field OperationType   as character serialize-name "Operation"
        field OperationVerb   as character serialize-name "HttpVerb"
        index idxPrimary      is primary unique ServiceURI ClassPath MethodName
        index idxPublic       is unique         ServiceURI ClassPath PublicName
        .

    define private temp-table ResourceProperty no-undo serialize-name "Annotation"
        field ServiceURI    as character serialize-name "Service"   /* Associated service URI for resource.     */
        field ClassPath     as character serialize-name "Package"   /* Full class path to business entity.      */
        field OperationType as character serialize-name "Operation" /* Type: create, read, update, delete, etc. */
        field PropertyName  as character serialize-name "Property"  /* Resource annotation property name.       */
        field PropertyType  as character serialize-name "DataType"  /* Resource annotation property datatype.   */
        field PropertyValue as character serialize-name "Value"     /* Resource annotation property value(s).   */
        index idxPrimary    is primary unique ServiceURI ClassPath OperationType PropertyName
        .

    define private temp-table EntityProperty no-undo serialize-name "Entity"
        field EntityName as character            serialize-name "Entity"     /* Name of entity (dataset). */
        field TableName  as character            serialize-name "Table"      /* Name of table to modify.  */
        field FieldData  as Progress.Lang.Object serialize-name "Attributes" /* Attributes as JsonObject. */
        index idxPrimary is primary unique EntityName TableName
        .

    define private dataset dsResource serialize-name "Mapping"
        for ServiceInfo, ResourceInfo, MethodInfo, ResourceProperty
        data-relation Service for ServiceInfo, ResourceInfo
        relation-fields(ServiceURI, ServiceURI)
        nested foreign-key-hidden
        data-relation Resource for ResourceInfo, MethodInfo
        relation-fields(ServiceURI, ServiceURI, ClassPath, ClassPath)
        nested foreign-key-hidden
        data-relation Operation for MethodInfo, ResourceProperty
        relation-fields(ServiceURI, ServiceURI, ClassPath, ClassPath, OperationType, OperationType)
        nested foreign-key-hidden.


    /**************************** Private Helper Methods *****************************/


    method private void clearResourceMethods ( input pcServiceURI as character,
                                               input pcClassPath  as character ):
        for each MethodInfo exclusive-lock
           where MethodInfo.ServiceURI eq pcServiceURI
             and MethodInfo.ClassPath eq pcClassPath:
            assign MethodInfo.MethodSignature = "".
        end. /* for each */
    end method. /* clearResourceMethods */


    method private character getJsonType ( input pcABLType as character ):
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


    method private character getAction ( input pcHttpMethod as character ):
        case pcHttpMethod:
            when MethodEnum:get:toString() then
                return OperationEnum:read:toString().
            when MethodEnum:post:toString() then
                return OperationEnum:create:toString().
            when MethodEnum:put:toString() then
                return OperationEnum:update:toString().
            when MethodEnum:delete:toString() then
                return OperationEnum:delete:toString().
            otherwise
                return "".
        end case.
    end method. /* getAction */


    method private character getVerb ( input pcAction as character ):
        case pcAction:
            when OperationEnum:read:toString() then
                return MethodEnum:get:toString().
            when OperationEnum:create:toString() then
                return MethodEnum:post:toString().
            when OperationEnum:update:toString() then
                return MethodEnum:put:toString().
            when OperationEnum:delete:toString() then
                return MethodEnum:delete:toString().
            otherwise
                return "".
        end case.
    end method. /* getVerb */


    method private void getMethod ( input  pcServiceURI   as character,
                                    input  pcResourceName as character,
                                    input  pcMethodName   as character,
                                    input  pcHttpMethod   as character,
                                    output pcValidMethod  as character,
                                    output phProcHandle   as handle,
                                    output pcEntityName   as character ):
        assign /* Obtain the actual method name from the descriptors table. */
            pcMethodName  = getMethodName(pcServiceURI, pcResourceName, pcMethodName, pcHttpMethod)
            pcValidMethod = ""
            phProcHandle  = ?
            pcEntityName  = ""
            .
        if (pcMethodName gt "") ne true then return.

        define buffer bResource for ResourceInfo.

        find first bResource
             where not bResource.IsClass
               and bResource.ServiceURI eq pcServiceURI
               and bResource.ClassPath eq pcResourceName
               and valid-handle(bResource.ProcHandle) no-error.
        if available(bResource) then do:
            define variable cInternalMethods as character no-undo.
            assign cInternalMethods = bResource.ProcHandle:internal-entries.

            /* Confirm that the requested method exists within procedure. */
            if can-do(cInternalMethods, pcMethodName) then
                assign
                    pcValidMethod = pcMethodName
                    phProcHandle  = bResource.ProcHandle
                    .
        end. /* Procedure */
        else do:
            find first bResource
                 where bResource.ServiceURI eq pcServiceURI
                   and bResource.PublicName eq pcResourceName
                   and bResource.ValidClass no-error.
            if available(bResource) then
                assign
                    pcValidMethod = pcMethodName
                    pcEntityName  = bResource.EntityName
                    .
        end. /* Class */
    end method. /* getMethod */


    method private character getMethodName ( input pcServiceURI   as character,
                                             input pcResourceName as character,
                                             input pcMethodName   as character,
                                             input pcHttpMethod   as character ):
        define variable cClassPath as character no-undo.
        assign cClassPath = getClassPath(pcServiceURI, pcResourceName).

        define buffer bMethod  for MethodInfo.

        find first bMethod /* Find by public name and verb. */
             where bMethod.ServiceURI eq pcServiceURI
               and bMethod.ClassPath eq cClassPath
               and bMethod.PublicName eq pcMethodName
               and bMethod.OperationVerb eq pcHttpMethod no-error.
        if available(bMethod) then
            return bMethod.MethodName.

        find first bMethod /* Find by actual name and verb. */
             where bMethod.ServiceURI eq pcServiceURI
               and bMethod.ClassPath eq cClassPath
               and bMethod.MethodName eq pcMethodName
               and bMethod.OperationVerb eq pcHttpMethod no-error.
        if available(bMethod) then
            return bMethod.MethodName.

        find first bMethod /* Find by operation type and verb. */
             where bMethod.ServiceURI eq pcServiceURI
               and bMethod.ClassPath eq cClassPath
               and bMethod.OperationType eq pcMethodName
               and bMethod.OperationVerb eq pcHttpMethod no-error.
        if available(bMethod) then
            return bMethod.MethodName.

        return "".
    end method. /* getMethodName */


    method private JsonArray getMethodSignature ( input pcServiceURI as character,
                                                  input pcClassPath  as character,
                                                  input pcMethodName as character ):
        define variable oParser as ObjectModelParser no-undo.

        define buffer bMethod for MethodInfo.

        for first bMethod
            where bMethod.ServiceURI eq pcServiceURI
              and bMethod.ClassPath eq pcClassPath
              and bMethod.MethodName eq pcMethodName:
            if (bMethod.MethodSignature gt "") eq true then do {&THROW}:
                assign oParser = new ObjectModelParser().
                return cast(oParser:Parse(bMethod.MethodSignature), JsonArray).

                finally:
                    delete object oParser no-error.
                end finally.
            end. /* Signature Present */
        end. /* for first */

        return new JsonArray().
    end method. /* getMethodSignature */


    method private character getClassPath ( input pcServiceURI   as character,
                                            input pcResourceName as character ):
        define buffer bResource for ResourceInfo.

        /* Locate classes by service URI and public name. */
        for first bResource
            where bResource.ServiceURI eq pcServiceURI
              and bResource.PublicName eq pcResourceName:
            return bResource.ClassPath.
        end.

        /* Locate procedure by service URI and full path. */
        for first bResource
            where bResource.ServiceURI eq pcServiceURI
              and bResource.SourcePath eq pcResourceName:
            return bResource.ClassPath.
        end.

        return "".
    end method. /* getClassPath */


    method private character getResourcePath ( input pcServiceURI   as character,
                                               input pcResClassPath as character ):
        define buffer bResource for ResourceInfo.

        for first bResource
            where bResource.ServiceURI eq pcServiceURI
              and bResource.ClassPath eq pcResClassPath:
            return bResource.SourcePath.
        end.

        return "".
    end method. /* getResourcePath */


    method private void loadDynamicResource ( input pcServiceURI as character,
                                              input pcClassPath  as character ):
        define buffer bResource for ResourceInfo.

        /* Destroy any previous procedure handles. */
        for each bResource exclusive-lock
           where not bResource.IsClass
             and bResource.ServiceURI eq pcServiceURI
             and bResource.ClassPath eq pcClassPath
             and valid-handle(bResource.ProcHandle):
            apply "close" to bResource.ProcHandle.
            delete procedure bResource.ProcHandle no-error.
        end. /* for each */

        /* First attempt to locate an existing record by resource name. */
        find first bResource no-lock
             where bResource.ServiceURI eq pcServiceURI
               and bResource.ClassPath eq pcClassPath no-error.
        if not available(bResource) then return.

        if not bResource.IsClass and bResource.SourcePath gt "" then
        do on error undo, throw
           on stop  undo, retry:
            if retry then
                undo, throw new AppError("A STOP condition occurred while setting persistent handle.", -500).

            /* Run procedures and save handle in resource table. */
            define variable hProcHandle as handle no-undo.
            run value(bResource.SourcePath) persistent set hProcHandle.
            if valid-handle(hProcHandle) then do {&THROW}:
                find current bResource exclusive-lock.
                assign bResource.ProcHandle = hProcHandle.

                /* Load (or re-load) service procedure internal methods, as needed. */
                registerProcedures( bResource.ServiceURI,
                                    bResource.ClassPath,
                                    bResource.ProcHandle ).

                if lUseDebugs and available(bResource) then
                    oLoggingManager:logMessage(substitute("Loaded &1 as '&2/&3'",
                                                          bResource.SourcePath,
                                                          bResource.ServiceURI,
                                                          bResource.PublicName), "SPARK-LOAD", 3).
            end. /* valid-handle */
            else
                oLoggingManager:logMessage(substitute("Could not create persistent handle: '&1'", bResource.SourcePath), "SPARK-WARN", 2).
        end. /* Procedures Only */
        else
        do on error undo, throw
           on stop  undo, retry:
            define variable oImplement as Progress.Lang.Class no-undo.
            define variable oEntity    as IDynamicEntity      no-undo.
            define variable oResource  as IDynamicResource    no-undo.
            define variable phDataSet  as handle              no-undo.

            /* Confirm that specified class is of type IDynamicEntity. */
            assign oImplement = Progress.Lang.Class:GetClass(pcClassPath) no-error.
            if error-status:error then
                undo, throw new AppError(GenTools:getAblError(), -500).
            else if not valid-object(oImplement) or
                 not (oImplement:IsA(get-class(IDynamicEntity)) or
                      oImplement:IsA(get-class(IDynamicResource))) then
                undo, throw new AppError(substitute("Resource '&1' (&2) is not a Spark Entity class.", pcClassPath, pcServiceURI), -500).

            /* Create new class instance and run initialization method. */
            if oImplement:IsA(get-class(IDynamicEntity)) then do:
                assign oEntity = cast(oImplement:New(), IDynamicEntity) no-error.
                if error-status:error then
                    undo, throw new AppError(GenTools:getAblError(), -500).

                if valid-object(oEntity) then do:
                    find current bResource exclusive-lock.
                    if (oEntity:resourceName gt "") ne true then do:
                        /* Do not keep resources that lack a public name. */
                        delete bResource.
                        leave.
                    end. /* No Resource Name */

                    /* Denote that this is a valid class. */
                    assign
                        bResource.PublicName = oEntity:resourceName
                        bResource.ValidClass = true
                        .

                    /* When an entity name has been provided, register and check for a dataset. */
                    if (oEntity:entityName gt "") eq true then do:
                        describeEntity(pcServiceURI, pcClassPath, oEntity:entityName, oEntity:primaryKeys, oEntity:foreignKeys).

                        oEntity:getDataset(output dataset-handle phDataSet) no-error.
                        if error-status:error then
                            oLoggingManager:logMessage(substitute("Error obtaining dataset schema for '&1': &2",
                                                                  oEntity:entityName,
                                                                  error-status:get-message(1)), "SPARK-LOAD", 0).
                        if valid-handle(phDataSet) and phDataSet:type eq "dataset" then
                            oSchemaManager:registerDataset(input phDataSet).
                    end. /* entityName */

                    /* Load (or re-load) service procedure internal methods, as needed. */
                    this-object:registerMethods(pcServiceURI, pcClassPath, oEntity:operations).

                    /* Apply properties for the read operation, when they are present. */
                    if (oEntity:mappingType gt "") eq true then do:
                        /* Provide the name of the plugin to be used with the JSDO, aka the Mapping Type. */
                        this-object:addProperty(pcServiceURI, pcClassPath, OperationEnum:read:toString(), "mappingType", "character", oEntity:mappingType).

                        /* Only when a mapping type is present, check if server-side capabilities exist. */
                        if (oEntity:capabilities gt "") eq true then
                            this-object:addProperty(pcServiceURI, pcClassPath, OperationEnum:read:toString(), "capabilities", "character", oEntity:capabilities).
                        else
                            this-object:addProperty(pcServiceURI, pcClassPath, OperationEnum:read:toString(), "capabilities", "character", "").
                    end. /* mappingType */

                    /* Load annotations and other prerequisite data through initialize method. */
                    oEntity:initialize().

                    if lUseDebugs and available(bResource) then
                        oLoggingManager:logMessage(substitute("Loaded Entity &1 as '&2/&3'",
                                                              bResource.ClassPath,
                                                              bResource.ServiceURI,
                                                              bResource.PublicName), "SPARK-LOAD", 3).
                end. /* valid-object */
            end. /* IDynamicEntity */
            else if oImplement:IsA(get-class(IDynamicResource)) then do:
                assign oResource = cast(oImplement:New(), IDynamicResource) no-error.
                if error-status:error then
                    undo, throw new AppError(GenTools:getAblError(), -500).

                if valid-object(oResource) then do:
                    find current bResource exclusive-lock.
                    if (oResource:resourceName gt "") ne true then do:
                        /* Do not keep resources that lack a public name. */
                        delete bResource.
                        leave.
                    end. /* No Resource Name */

                    /* Denote that this is a valid class. */
                    assign
                        bResource.PublicName = oResource:resourceName
                        bResource.ValidClass = true
                        .

                    /* Load (or re-load) service procedure internal methods, as needed. */
                    this-object:registerMethods(pcServiceURI, pcClassPath).

                    /* Load annotations and other prerequisite data. */
                    oResource:initialize().

                    if lUseDebugs and available(bResource) then
                        oLoggingManager:logMessage(substitute("Loaded Resource &1 as '&2/&3'",
                                                              bResource.ClassPath,
                                                              bResource.ServiceURI,
                                                              bResource.PublicName), "SPARK-LOAD", 3).
                end. /* valid-object */
            end. /* IDynamicResource */

            finally:
                delete object phDataSet  no-error.
                delete object oImplement no-error.
                delete object oEntity    no-error.
                delete object oResource  no-error.
            end finally.
        end. /* Non-Procedure */

        catch err as Error:
            oLoggingManager:logError(substitute("Error loading resource '&1'", pcClassPath), err, "SPARK-ERR", 0).
            /* Do not throw error from this point, allow resource registration to fail with only logging. */
        end catch.
    end method. /* loadDynamicResource */


    method private void registerMethods ( input pcServiceURI   as character,
                                          input pcResClassPath as character ):
        /* Call method with blank list of operations. Typical for the Dynamicresource class. */
        this-object:registerMethods(pcServiceURI, pcResClassPath, "").
    end method. /* registerMethods */


    method private void registerMethods ( input pcServiceURI   as character,
                                          input pcResClassPath as character,
                                          input pcOperations   as character ):
        define variable oParser   as ObjectModelParser no-undo.
        define variable oClassSig as JsonObject        no-undo.
        define variable oMethods  as JsonObject        no-undo.
        define variable cMethods  as character         no-undo extent.
        define variable ix        as integer           no-undo.

        oParser = new ObjectModelParser().

        /* Remove previous method signatures. */
        this-object:clearResourceMethods(pcServiceURI, pcResClassPath).

        define buffer bResource for ResourceInfo.

        /* Register methods according to the Spark.Core.Service.IDynamicEntity class. */
        find first bResource
             where bResource.ServiceURI eq pcServiceURI
               and bResource.ClassPath eq pcResClassPath no-error.
        if available(bResource) then do:
            /* Generate class signature (in JSON) using reflection. */
            oClassSig = Reflection:getClassSignature(pcResClassPath).
            if lUseDebugs then do:
                file-info:file-name = substitute("&1signatures", OSTools:sparkConf).
                if file-info:full-pathname eq ? then
                    os-create-dir value(substitute("&1signatures", OSTools:sparkConf)).
                oClassSig:WriteFile(substitute("&1signatures/&2.json", OSTools:sparkConf, pcResClassPath), true).
            end.


            /* Extract the specific class signature from the file. */
            if oClassSig:Has(pcResClassPath) then
                oClassSig = oClassSig:GetJsonObject(pcResClassPath).

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
                    this-object:setResourceMethod( input pcServiceURI,
                                                   input pcResClassPath,
                                                   input cMethods[iX],
                                                   input bResource.EntityName,
                                                   input oMethods:GetJsonObject(cMethods[ix]):GetJsonArray("params") ).

                    catch err as Progress.Lang.Error:
                        oLoggingManager:logError(substitute("Unable to register method '&1:&2'",
                                                            pcResClassPath,
                                                            cMethods[iX]), err, "SPARK-ERR", 0).
                        undo, throw err.
                    end catch.
                end. /* Method[iX] */
            end. /* Has Methods */
        end. /* available */

        catch err as Progress.Lang.Error:
            oLoggingManager:logError(substitute("Unable to register &1 (&2) methods",
                                                pcServiceURI,
                                                pcResClassPath), err, "SPARK-ERR", 0).
            undo, throw err.
        end catch.
        finally:
            delete object oParser   no-error.
            delete object oClassSig no-error.
            delete object oMethods  no-error.
        end finally.
    end method. /* registerMethods */


    method private void registerProcedures ( input pcServiceURI   as character,
                                             input pcResourceName as character,
                                             input phProcHandle   as handle ):
        define variable iCount           as integer   no-undo.
        define variable cMethodName      as character no-undo.
        define variable cInternalEntries as character no-undo.

        /* Remove previous method signatures. */
        this-object:clearResourceMethods(pcServiceURI, pcResourceName).

        cInternalEntries = phProcHandle:internal-entries.
        if (cInternalEntries gt "") ne true then return.

        /* Register the internal procedures for this resource. */
        do iCount = 1 to num-entries(cInternalEntries):
            assign cMethodName = entry(iCount, cInternalEntries).
            this-object:setResourceProcedure( input pcServiceURI,
                                              input pcResourceName,
                                              input cMethodName,
                                              input phProcHandle:get-signature(cMethodName) ).
        end.

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Unable to register procedures", err, "SPARK-ERR", 0).
            undo, throw err.
        end catch.
    end method. /* registerProcedures */


    method private void runPreloader ( ):
        /* Special procedure for application startup. */
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


    method private void setResourceMethod ( input pcServiceURI   as character,
                                            input pcResourceName as character,
                                            input pcMethodName   as character,
                                            input pcEntityName   as character,
                                            input poMethodParams as JsonArray ):
        define variable oParamObj as JsonObject no-undo.
        define variable iParam    as integer    no-undo.

        define buffer bMethod for MethodInfo.

        /* Create a default description if none specified yet. */
        this-object:describeResource( pcServiceURI,
                                      pcResourceName,
                                      pcMethodName,
                                      "",
                                      "",
                                      "" ).

        /* No params, no update needed. Just leave. */
        if poMethodParams:Length eq 0 then return.

        for first bMethod exclusive-lock
            where bMethod.ServiceURI eq pcServiceURI
              and bMethod.ClassPath eq pcResourceName
              and bMethod.MethodName eq pcMethodName:
            if can-do("read,create,update,delete,submit", bMethod.OperationType) then do:
                do iParam = 1 to poMethodParams:Length:
                    /* For parameters of an entity operation, add the entity name as a public name for the parameter. */
                    assign oParamObj = poMethodParams:GetJsonObject(iParam).
                    if oParamObj:GetCharacter("type") begins "dataset" then
                        oParamObj:Add("publicName", pcEntityName).
                end. /* do iParam */

                /* Add default property to enable use of before-image for CRUD+Submit as necessary. */
                this-object:addProperty(pcServiceURI, pcResourceName, bMethod.OperationType, "useBeforeImage", "logical", "true").
            end.
            assign bMethod.MethodSignature = string(poMethodParams:GetJsonText()).
        end. /* for first */
    end method. /* setResourceMethod */


    method private void setResourceProcedure ( input pcServiceURI      as character,
                                               input pcResourceName    as character,
                                               input pcMethodName      as character,
                                               input pcMethodSignature as character ):
        define variable oParamArr as JsonArray  no-undo.
        define variable oParamObj as JsonObject no-undo.
        define variable iX        as integer    no-undo.
        define variable cParam    as character  no-undo.

        define buffer bMethod for MethodInfo.

        /* Create a default description if none specified yet. */
        this-object:describeResource( pcServiceURI,
                                      pcResourceName,
                                      pcMethodName,
                                      pcMethodName,
                                      "",
                                      "" ).

        assign oParamArr = new JsonArray().
        do iX = 3 to num-entries(pcMethodSignature):
            assign
                oParamObj = new JsonObject()
                cParam    = entry(iX, pcMethodSignature)
                .

            if num-entries(cParam, " ") eq 3 then do {&THROW}:
                oParamObj:Add("mode", lc(replace(entry(1, cParam, " "), "-", ""))).

                if entry(2, cParam, " ") eq "table" or entry(2, cParam, " ") eq "table-handle" or
                   entry(2, cParam, " ") eq "dataset" or entry(2, cParam, " ") eq "dataset-handle" then do:
                    oParamObj:Add("name", entry(3, cParam, " ")).
                    oParamObj:Add("type", lc(replace(entry(2, cParam, " "), "-", ""))).
                end. /* dataset/table */
                else do:
                    oParamObj:Add("name", entry(2, cParam, " ")).
                    oParamObj:Add("type", lc(entry(3, cParam, " "))).
                end. /* other */

                oParamArr:Add(oParamObj).
            end. /* num-entries */
        end. /* iX */

        if oParamArr:Length gt 0 then
            for first bMethod exclusive-lock
                where bMethod.ServiceURI eq pcServiceURI
                  and bMethod.ClassPath eq pcResourceName
                  and bMethod.MethodName eq pcMethodName:
                assign bMethod.MethodSignature = string(oParamArr:GetJsonText()).
            end.
    end method. /* setResourceProcedure */


    /***************************** Catalog Helper Methods *****************************/


    method private logical getBeforeImageFlag ( input pcServiceURI    as character,
                                                input pcClassPath     as character,
                                                input pcOperationType as character ):
        define buffer bResource for ResourceInfo.
        define buffer bProperty for ResourceProperty.

        for first bResource no-lock
            where bResource.ServiceURI eq pcServiceURI
              and bResource.ClassPath eq pcClassPath:
            find first bProperty no-lock
                 where bProperty.ClassPath eq bResource.ClassPath
                   and bProperty.OperationType eq pcOperationType
                   and bProperty.PropertyName eq "useBeforeImage" no-error.
            if available(bProperty) then
                return logical(bProperty.propertyValue).
        end.

        return false.
    end method. /* getBeforeImageFlag */


    method private JsonArray getServices ( input pcServiceURI   as character,
                                           input pcResourceName as character ):
        define variable serviceArr as JsonArray no-undo.
        assign serviceArr = new JsonArray().

        define buffer bService for ServiceList.

        for each bService no-lock:
            /* If no service given (is blank) return all services for this webapp. */
            /* If incoming service URI without the WebApp name matches, use that. */
            if pcServiceURI eq "" or bService.ServiceURI eq pcServiceURI then do:
                /* Create a new service. */
                define variable serviceObj  as JsonObject no-undo.
                define variable settingsObj as JsonObject no-undo.

                assign serviceObj = new JsonObject().
                assign settingsObj = new JsonObject().

                /* Service Options */
                serviceObj:Add("name", bService.ServiceName).
                serviceObj:Add("address", bService.ServiceURI).

                /** Optional Properties
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
                serviceObj:Add("resources", this-object:getResources(bService.ServiceURI, pcResourceName)).

                /* Add main service to array. */
                serviceArr:Add(serviceObj).
            end.
        end. /* for each bService */

        return serviceArr.
    end method. /* getServices */


    method private JsonArray getResources ( input pcServiceURI   as character,
                                            input pcResourceName as character ):
        define variable resourceArr as JsonArray  no-undo.
        define variable resourceObj as JsonObject no-undo.

        define buffer bResInfo for ResourceInfo.

        /* Create resources for service. */
        assign resourceArr = new JsonArray().
        if (pcResourceName gt "") eq true then
            for first bResInfo
                where bResInfo.ServiceURI eq pcServiceURI
                  and bResInfo.PublicName eq pcResourceName:
                /* Break on unique resource name. */
                assign resourceObj = new JsonObject().
                resourceObj:Add("name", bResInfo.PublicName).
                resourceObj:Add("path", "/" + bResInfo.PublicName).
                resourceObj:Add("autoSave", false).
                if this-object:IdProperty ne "id" then
                    resourceObj:Add("recIdProperty", this-object:IdProperty).
                if this-object:SeqProperty ne "seq" then
                    resourceObj:Add("seqProperty", this-object:SeqProperty).
                resourceObj:Add("displayName", bResInfo.PublicName).

                /* Only return for the associated entity, which should always be on a ReadData method. */
                resourceObj:Add("schema", this-object:getSchema(pcServiceURI, bResInfo.ClassPath, true)).
                resourceObj:Add("relations", this-object:getRelations(pcServiceURI, bResInfo.ClassPath)).

                /* Add operations for resource. */
                resourceObj:Add("operations", this-object:getOperations(pcServiceURI, bResInfo.ClassPath)).
                /* Add data definitions for invoke operations. */
                resourceObj:Add("dataDefinitions", this-object:getDataDefs(pcServiceURI, bResInfo.ClassPath)).
                resourceArr:Add(resourceObj).
            end. /* for first bResInfo (exact) */
        else
            for each bResInfo
               where bResInfo.ServiceURI eq pcServiceURI
               break by bResInfo.PublicName:
                if first-of(bResInfo.PublicName) then do:
                    /* Break on unique resource name. */
                    assign resourceObj = new JsonObject().
                    resourceObj:Add("name", bResInfo.PublicName).
                    resourceObj:Add("path", "/" + bResInfo.PublicName).
                    resourceObj:Add("autoSave", false).
                    if this-object:IdProperty ne "id" then
                        resourceObj:Add("recIdProperty", this-object:IdProperty).
                    if this-object:SeqProperty ne "seq" then
                        resourceObj:Add("seqProperty", this-object:SeqProperty).
                    resourceObj:Add("displayName", bResInfo.PublicName).

                    /* Only return for the associated entity, which should always be on a ReadData method. */
                    resourceObj:Add("schema", this-object:getSchema(pcServiceURI, bResInfo.ClassPath, true)).
                    resourceObj:Add("relations", this-object:getRelations(pcServiceURI, bResInfo.ClassPath)).

                    /* Add operations for resource. */
                    resourceObj:Add("operations", this-object:getOperations(pcServiceURI, bResInfo.ClassPath)).

                    /* Add data definitions for invoke operations. */
                    resourceObj:Add("dataDefinitions", this-object:getDataDefs(pcServiceURI, bResInfo.ClassPath)).
                    resourceArr:Add(resourceObj).
                end.
            end. /* for first bResInfo (all) */

        return resourceArr.
    end method. /* getResources */


    method private JsonObject getSchema ( input pcServiceURI   as character,
                                          input pcResClassPath as character ):
        return this-object:getSchema(pcServiceURI, pcResClassPath, false).
    end method. /* getSchema */


    method private JsonObject getSchema ( input pcServiceURI    as character,
                                          input pcResClassPath  as character,
                                          input plPrimaryEntity as logical ):
        define variable oSchemaObj    as JsonObject no-undo.
        define variable oProperty     as JsonObject no-undo.
        define variable oParamArr     as JsonArray  no-undo.
        define variable oParamObj     as JsonObject no-undo.
        define variable cDatasetNames as character  no-undo.
        define variable cTableNames   as character  no-undo.
        define variable cParamName    as character  no-undo.
        define variable iX            as integer    no-undo.
        define variable iY            as integer    no-undo.
        define variable iZ            as integer    no-undo.

        define buffer bResource for ResourceInfo.
        define buffer bMethod   for MethodInfo.

        assign oSchemaObj = new JsonObject().

        if plPrimaryEntity then do:
            /* Meant for obtaining the primary entity for this resource. */
            for first bMethod no-lock
                where bMethod.ServiceURI eq pcServiceURI
                  and bMethod.ClassPath eq pcResClassPath
                  and bMethod.OperationType eq OperationEnum:read:toString():
                assign oParamArr = this-object:getMethodSignature( pcServiceURI,
                                                                   pcResClassPath,
                                                                   bMethod.MethodName ).

                do iX = 1 to oParamArr:Length:
                    assign oParamObj = oParamArr:GetJsonObject(iX).
                    if oParamObj:Has("type") then do {&THROW}:
                        /* Check and use public name for parameter, if present. */
                        if oParamObj:Has("publicName") then
                            assign cParamName = oParamObj:GetCharacter("publicName").
                        else
                            assign cParamName = oParamObj:GetCharacter("name").

                        if oParamObj:GetCharacter("type") begins "dataset" and
                           not can-do(cDatasetNames, cParamName) then
                            assign cDatasetNames = trim(substitute("&1,&2", cDatasetNames, cParamName), ",").

                        if oParamObj:GetCharacter("type") begins "table" and
                           not can-do(cTableNames, cParamName) then
                            assign cTableNames = trim(substitute("&1,&2", cTableNames, cParamName), ",").
                    end. /* Has Type */
                end. /* iX */
            end. /* for first */
        end. /* plPrimaryEntity */
        else do:
            for each bMethod no-lock
               where bMethod.ServiceURI eq pcServiceURI
                 and bMethod.ClassPath eq pcResClassPath
                 and bMethod.OperationType eq OperationEnum:invoke:toString()
                  by bMethod.MethodName:
                assign oParamArr = this-object:getMethodSignature( pcServiceURI,
                                                                   pcResClassPath,
                                                                   bMethod.MethodName ).

                do iX = 1 to oParamArr:Length:
                    assign oParamObj = oParamArr:GetJsonObject(iX).
                    if oParamObj:Has("type") then do {&THROW}:
                        /* Check and use public name for parameter, if present. */
                        if oParamObj:Has("publicName") then
                            assign cParamName = oParamObj:GetCharacter("publicName").
                        else
                            assign cParamName = oParamObj:GetCharacter("name").

                        if oParamObj:GetCharacter("type") begins "dataset" and
                           not can-do(cDatasetNames, cParamName) then
                            assign cDatasetNames = trim(substitute("&1,&2", cDatasetNames, cParamName), ",").

                        if oParamObj:GetCharacter("type") begins "table" and
                           not can-do(cTableNames, cParamName) then
                            assign cTableNames = trim(substitute("&1,&2", cTableNames, cParamName), ",").
                    end. /* Has Type */
                end. /* iX */
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
                            where bResource.ServiceURI eq pcServiceURI
                              and bResource.ClassPath eq pcResClassPath
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
                        tableObj:Add(cTableName, schemaObj).
                    end. /* Tables */
                    datasetObj:Add("properties", tableObj).
                    oProperty:Add(cDataSetName, datasetObj).
                end.
            end. /* Datasets */

            do iX = 1 to num-entries(cTableNames):
                /* Obtain primary key for table (by resource). */
                for first bResource
                    where bResource.ServiceURI eq pcServiceURI
                      and bResource.ClassPath eq pcResClassPath:
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
                oProperty:Add(cTableName, schemaObj).
            end. /* Tables */
        end. /* Has Dataset(s) or Temp-Table(s) */

        oSchemaObj:Add("properties", oProperty). /* Always add a properties object. */

        return oSchemaObj.
    end method. /* getSchema */


    method private JsonArray getRelations ( input pcServiceURI   as character,
                                            input pcResClassPath as character ):
        define variable oRelationArr  as JsonArray  no-undo.
        define variable oRelationObj  as JsonObject no-undo.
        define variable oFieldArr     as JsonArray  no-undo.
        define variable oFieldObj     as JsonObject no-undo.
        define variable cDatasetNames as character  no-undo.
        define variable oParamArr     as JsonArray  no-undo.
        define variable oParamObj     as JsonObject no-undo.
        define variable cParamName    as character  no-undo.
        define variable iX            as integer    no-undo.
        define variable iY            as integer    no-undo.
        define variable iZ            as integer    no-undo.

        define buffer bMethod for MethodInfo.

        assign oRelationArr = new JsonArray().

        for first bMethod no-lock
            where bMethod.ServiceURI eq pcServiceURI
              and bMethod.ClassPath eq pcResClassPath
              and bMethod.OperationType eq OperationEnum:read:toString():
            assign oParamArr = this-object:getMethodSignature( pcServiceURI,
                                                               pcResClassPath,
                                                               bMethod.MethodName ).

            do iX = 1 to oParamArr:Length:
                assign oParamObj = oParamArr:GetJsonObject(iX).
                if oParamObj:Has("type") then do {&THROW}:
                    if oParamObj:Has("publicName") then
                        assign cParamName = oParamObj:GetCharacter("publicName").
                    else
                        assign cParamName = oParamObj:GetCharacter("name").

                    if oParamObj:GetCharacter("type") begins "dataset" and
                       not can-do(cDatasetNames, cParamName) then
                        assign cDatasetNames = trim(substitute("&1,&2", cDatasetNames, cParamName), ",").
                end. /* Has Type */
            end. /* iX */
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
                delete object hDataset no-error.
                assign hDataset = ?. /* Re-initialize for next dataset. */

                catch err as Progress.Lang.Error:
                    message substitute("Unable to get relation data for dataset &1: &2", entry(iX, cDatasetNames), err:GetMessage(1)).
                end catch.
            end. /* Datasets */
        end. /* Has Dataset(s) */

        return oRelationArr.
    end method. /* getRelations */


    method private JsonObject getTable ( input  pcDatasetName as character,
                                         input  pcTableName   as character,
                                         input  pcPrimaryKey  as character,
                                         input  pcForeignKey  as character,
                                         output pcSerialized  as character ):
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
                        cFieldName = hField:xml-node-name.
                    else if (hField:serialize-name gt "") eq true then
                        cFieldName = hField:serialize-name.
                    else
                        cFieldName = hField:name.

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


    method private JsonArray getOperations ( input pcServiceURI   as character,
                                             input pcResourceName as character ):
        define variable operationArr as JsonArray  no-undo.
        define variable operationObj as JsonObject no-undo.
        define variable oParamArr    as JsonArray  no-undo.
        define variable oParamObj    as JsonObject no-undo.
        define variable iX           as integer    no-undo.

        define buffer bMethod   for MethodInfo.
        define buffer bProperty for ResourceProperty.

        assign operationArr = new JsonArray().

        for each bMethod no-lock
           where bMethod.ServiceURI eq pcServiceURI
             and bMethod.ClassPath eq pcResourceName
              by bMethod.PublicName
              by bMethod.MethodName:
            assign operationObj = new JsonObject().

            if can-do("invoke,submit", bMethod.OperationType) then do:
                operationObj:Add("name", bMethod.PublicName).
                operationObj:Add("path", "/" + bMethod.PublicName).
            end. /* Invoke/Submit */
            else do:
                operationObj:Add("name", bMethod.OperationType).
                operationObj:Add("path", ""). /* Supply default property. */
            end. /* CRUD */

            /* Supply default property for special methods. */
            if can-do("create,update,delete,submit,invoke", bMethod.OperationType) then
                operationObj:Add("useBeforeImage", false).

            for each bProperty no-lock
               where bProperty.ServiceURI eq pcServiceURI
                 and bProperty.ClassPath eq pcResourceName
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

            /* Obtain parameters for operation (cloned to prevent altering of the original signature. */
            assign oParamArr = cast(this-object:getMethodSignature( pcServiceURI,
                                                                    bMethod.ClassPath,
                                                                    bMethod.MethodName ):Clone(), JsonArray).

            /* Add parameters for operation. */
            if valid-object(oParamArr) then
            do iX = 1 to oParamArr:Length:
                assign oParamObj = oParamArr:GetJsonObject(iX).

                /* Set a default for the ablType property. */
                if not oParamObj:Has("xType") then
                    oParamObj:Add("xType", oParamObj:GetCharacter("type")).

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
                            operationObj:Remove("path"). /* Remove previous property. */
                            if bMethod.OperationType eq OperationEnum:invoke:toString() then
                                operationObj:Add("path", substitute("/&1?&2=~{&2~}", bMethod.PublicName, this-object:ReadFilter)).
                            else
                                operationObj:Add("path", substitute("?&1=~{&1~}", this-object:ReadFilter)).
                            oParamObj:Set("type", "QUERY").
                        end.

                        if oParamObj:GetCharacter("xType") eq "datetimetz" then
                            oParamObj:Set("xType", "datetime-tz").
                    end.
                end case.

                /* Use the public name for the name property. */
                if oParamObj:Has("publicName") then do:
                    oParamObj:Set("name", oParamObj:GetCharacter("publicName")).
                    oParamObj:Remove("publicName").
                end. /* Has publicName */

                /* Reset the type property according to the mode of the parameter. */
                if oParamObj:Has("type") then
                    oParamObj:Remove("type").
                if oParamObj:GetCharacter("mode") eq "input" and bMethod.OperationVerb eq MethodEnum:get:toString() then
                    oParamObj:Add("type", "QUERY").
                else if oParamObj:GetCharacter("mode") eq "inputoutput" then
                    oParamObj:Add("type", "REQUEST_BODY,RESPONSE_BODY").
                else if oParamObj:GetCharacter("mode") eq "input" then
                    oParamObj:Add("type", "REQUEST_BODY").
                else
                    oParamObj:Add("type", "RESPONSE_BODY").
            end. /* iX */

            /* Add params to operation, and operation to array. */
            operationObj:Add("params", oParamArr).
            operationArr:Add(operationObj).
        end. /* for each */

        return operationArr.
    end method. /* getOperations */


    method private JsonObject getDataDefs ( input pcServiceURI   as character,
                                            input pcResClassPath as character):
        define variable oSchema       as JsonObject        no-undo.
        define variable definitionObj as JsonObject        no-undo.

        assign oSchema = getSchema(pcServiceURI, pcResClassPath).
        if oSchema:Has("properties") then
            assign definitionObj = oSchema:GetJsonObject("properties").
        else
            assign definitionObj = new JsonObject().

        return definitionObj.
    end method. /* getDataDefs */


    /**************************** Public Helper Methods ****************************/


    method override public void initialize ( ):
        /* Read catalog configuration file and register values in properties. */
        define variable cFullCfgFileName as character no-undo.
        file-info:file-name = OSTools:sparkConf + "catalog.json".
        cFullCfgFileName = file-info:full-pathname.
        if cFullCfgFileName ne ? then
            dataset dsConfig:read-json("FILE", cFullCfgFileName, "EMPTY").
        else
            undo, throw new AppError(substitute("Catalog config file [catalog.json] not found in [&1]", OSTools:sparkConf), -500).

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
                lUseDebugs = (GeneralParam.EnableDebugs eq true) or log-manager:logging-level ge 4
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

        /* Obtain a default service name (first from list). */
        find first ServiceList no-error.
        if available(ServiceList) then
            assign cDefaultURI = ServiceList.ServiceURI.

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
    end method. /* dispose */


    method private character stripFileExtensions ( input pcFileName as character ):
        assign
            pcFileName = substring(pcFileName, 1, length(pcFileName) - 4) when pcFileName matches "*.cls"
            pcFileName = substring(pcFileName, 1, length(pcFileName) - 2) when pcFileName matches "*.p"
            pcFileName = substring(pcFileName, 1, length(pcFileName) - 2) when pcFileName matches "*.r"
            .
        return pcFileName.
    end method. /* stripFileExtension */


    method private void checkForResources ( ):
        define variable ix         as integer   no-undo.
        define variable cClassPath as character no-undo.
        define variable cPath      as character no-undo.
        define variable cRoot      as character no-undo.
        define variable oDirStruct as JsonArray no-undo.

        define buffer bGenParam for GeneralParam.
        define buffer bResource for ResourceInfo.
        define buffer bService  for ServiceList.
        define buffer bSrvcRes  for ResourceList.

        empty temp-table bResource.

        for first bGenParam no-lock:
            assign cRoot = "".

            /* Determine how resources will be discovered: by config or by disk. */
            if bGenParam.BusinessRoot matches "*.pl" or bGenParam.BusinessRoot eq "" then do:
                oLoggingManager:logMessage(substitute("Discovering resource options from config file (&1).", bGenParam.BusinessRoot), "SPARK-LOAD", 3).

                /* Value is blank or points to a PL, so we must use the given config data. */
                for each bService:
                    /* Search through each listed service for available resources. */
                    for each bSrvcRes
                       where bSrvcRes.ServiceName eq bService.ServiceName:
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
                        if not (cClassPath matches "*.r") then
                            assign /* Create information about a class. */
                                bResource.ServiceURI = bService.ServiceURI
                                bResource.ClassPath  = bSrvcRes.ClassPath
                                bResource.PublicName = entry(num-entries(bSrvcRes.ClassPath, "."), bSrvcRes.ClassPath, ".")
                                bResource.SourcePath = replace(bSrvcRes.ClassPath, ".", "~/") + ".cls" /* Convert to path to class file. */
                                bResource.IsClass    = true
                                .
                        else
                            assign /* Create information about a procedure. */
                                bResource.ServiceURI = bService.ServiceURI
                                bResource.ClassPath  = this-object:stripFileExtensions(entry(num-entries(cClassPath, "~/"), cClassPath, "~/"))
                                bResource.PublicName = bResource.ClassPath
                                bResource.SourcePath = cClassPath /* Use the path with .r extension. */
                                bResource.IsClass    = false
                                .
                    end. /* bSrvcRes */
                end. /* bService */
            end. /* PL or Blank */
            else do ix = 1 to num-entries(propath):
                /* BusinessRoot is a folder, so we must find a matching directory in the PROPATH. */
                assign cPath = replace(entry(ix, propath), "~\", "/").
                file-info:file-name = substitute("&1/&2", cPath, bGenParam.BusinessRoot).
                if file-info:full-pathname ne ? then do:
                    assign cRoot = replace(file-info:full-pathname, "~\", "~/").
                    oLoggingManager:logMessage(substitute("Discovering resource options from filesystem (&1).", cRoot), "SPARK-LOAD", 3).
                    leave.
                end.
            end. /* Physical Folders */
        end. /* for first */

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
            do ix = 1 to oDirStruct:Length:
                /* Inspect each file found. */
                assign oFile = oDirStruct:GetJsonObject(ix).

                assign /* Reset variables on each loop. */
                    cFileName = oFile:GetCharacter("FileName")
                    cFilePath = oFile:GetCharacter("FullPath")
                    cRootPath = replace(cRoot, "~/" + bGenParam.BusinessRoot, "") + "~/"
                    cResource = ""
                    cTempName = ""
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
                for first bService
                    where bService.ClassPath eq cClassPath:
                    /* Create a record using the service and resource, if not present. */
                    if (cResource gt "") eq true and
                       not can-find(first bResource no-lock
                                    where bResource.ServiceURI eq bService.ServiceURI
                                      and bResource.ClassPath eq cResource) and
                       not can-find(first bResource no-lock
                                    where bResource.ServiceURI eq bService.ServiceURI
                                      and bResource.ClassPath eq cTempName) then do:
                        create bSrvcRes. /* ServiceResource, used for main config data. */
                        create bResource. /* ResourceInfo, used for catalog metadata. */

                        if rcode-info:is-class or cFileName matches "*.cls" then
                            assign /* Create information about a class. */
                                bSrvcRes.ServiceName = bService.ServiceName
                                bSrvcRes.ClassPath   = cResource
                                bResource.ServiceURI = bService.ServiceURI
                                bResource.ClassPath  = cResource
                                bResource.PublicName = cTempName
                                bResource.SourcePath = replace(cFilePath, cRootPath, "")
                                bResource.IsClass    = true
                                .
                        else
                            assign /* Create information about a procedure. */
                                bSrvcRes.ServiceName = bService.ServiceName
                                bSrvcRes.ClassPath   = replace(cFilePath, cRootPath, "")
                                bResource.ServiceURI = bService.ServiceURI
                                bResource.ClassPath  = cTempName
                                bResource.PublicName = cTempName
                                bResource.SourcePath = replace(cFilePath, cRootPath, "")
                                bResource.IsClass    = false
                                .

                        release bSrvcRes no-error.
                        release bResource no-error.
                    end. /* cResource */
                end. /* bService */
            end. /* do */
        end. /* cRoot */
    end method. /* checkForResources */


    method public void loadResources ( ):
        empty temp-table ResourceInfo.
        empty temp-table ResourceProperty.

        /* Before loading the (dynamic) resources, run a preloader if configured. */
        oLoggingManager:logMessage("Running Preloader...", "SPARK-LOAD", 4).
        runPreloader().

        /* Look for any available entity classes at the expected */
        oLoggingManager:logMessage("Checking Resources...", "SPARK-LOAD", 4).
        checkForResources().

        /* Load all dynamic resources as specified by config file. */
        for each ResourceInfo:
            oLoggingManager:logMessage(substitute("Loading Resource: '&1'", ResourceInfo.ClassPath), "SPARK-LOAD", 4).
            this-object:loadDynamicResource(ResourceInfo.ServiceURI, ResourceInfo.ClassPath).
        end.

        if lUseDebugs then do:
            empty temp-table ServiceInfo.
            for each ServiceList:
                create ServiceInfo.
                buffer-copy ServiceList to ServiceInfo no-error.
            end. /* for each */
            dataset dsConfig:write-json("file", substitute("&1/CatalogDetail.json", right-trim(replace(session:temp-directory, "~\", "~/"), "~/")), true).
            dataset dsResource:write-json("file", substitute("&1/ResourceMetadata.json", right-trim(replace(session:temp-directory, "~\", "~/"), "~/")), true).
            oSchemaManager:dumpObjects().
        end. /* lUseDebugs */
    end method. /* loadResources */


    method public void addProperty ( input pcServiceURI    as character,
                                     input pcClassPath     as character,
                                     input pcOperationType as character,
                                     input pcPropertyName  as character,
                                     input pcPropertyType  as character,
                                     input pcPropertyValue as character ):
        define buffer bMethod   for MethodInfo.
        define buffer bProperty for ResourceProperty.

        /* Use default service if none provided. */
        if (pcServiceURI gt "") ne true then pcServiceURI = cDefaultURI.

        if can-find(first bMethod no-lock
                    where bMethod.ServiceURI eq pcServiceURI
                      and bMethod.ClassPath eq pcClassPath
                      and bMethod.OperationType eq pcOperationType) then do:
            /* Add/Update property only if resource+operation defined. */
            find first bProperty
                 where bProperty.ServiceURI eq pcServiceURI
                   and bProperty.ClassPath eq pcClassPath
                   and bProperty.OperationType eq pcOperationType
                   and bProperty.PropertyName eq pcPropertyName no-error.
            if not available(bProperty) then do:
                create bProperty.
                assign
                    bProperty.ServiceURI    = pcServiceURI
                    bProperty.ClassPath     = pcClassPath
                    bProperty.OperationType = pcOperationType
                    bProperty.PropertyType  = pcPropertyType
                    bProperty.PropertyName  = pcPropertyName
                    .
            end.
            assign bProperty.PropertyValue = pcPropertyValue.
        end.
    end method. /* addProperty */


    method public void describeEntity ( input pcServiceURI   as character,
                                        input pcResClassPath as character,
                                        input pcEntityName   as character,
                                        input pcPrimaryKeys  as character,
                                        input pcForeignKeys  as character ):
        /* Use default service if none provided. */
        if (pcServiceURI gt "") ne true then pcServiceURI = cDefaultURI.

        for first ResourceInfo
            where ResourceInfo.ServiceURI eq pcServiceURI
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
        define variable cOpType as character no-undo.

        define buffer bResource for ResourceInfo.
        define buffer bMethod   for MethodInfo.

        /* Use default service if none provided. */
        if (pcServiceURI gt "") ne true then pcServiceURI = cDefaultURI.

        find first bResource
             where bResource.ServiceURI eq pcServiceURI
               and bResource.ClassPath eq pcClassPath no-error.
        if available(bResource) then do:
            /* If another method for these particular operations exists, delete it first. */
            if can-do("create,read,update,delete,submit", pcOperationType) then
                for first bMethod exclusive-lock
                    where bMethod.ServiceURI eq pcServiceURI
                      and bMethod.ClassPath eq pcClassPath
                      and bMethod.OperationType eq pcOperationType:
                    delete bMethod.
                end. /* for first bMethod */

            find first bMethod exclusive-lock
                 where bMethod.ServiceURI eq pcServiceURI
                   and bMethod.ClassPath eq pcClassPath
                   and bMethod.MethodName eq pcMethodName no-error.
            if not available(bMethod) then do:
                create bMethod.
                assign
                    bMethod.ServiceURI = pcServiceURI
                    bMethod.ClassPath  = pcClassPath
                    bMethod.MethodName = pcMethodName
                    bMethod.PublicName = ""
                    .

                /* Set default attributes for certain entity class methods. */
                case pcMethodName:
                    when "readData" then
                        assign
                            pcPublicName          = OperationEnum:read:toString()
                            bMethod.OperationType = OperationEnum:read:toString()
                            bMethod.OperationVerb = MethodEnum:get:toString()
                            .
                    when "createData" then
                        assign
                            pcPublicName          = OperationEnum:create:toString()
                            bMethod.OperationType = OperationEnum:create:toString()
                            bMethod.OperationVerb = MethodEnum:post:toString()
                            .
                    when "updateData" then
                        assign
                            pcPublicName          = OperationEnum:update:toString()
                            bMethod.OperationType = OperationEnum:update:toString()
                            bMethod.OperationVerb = MethodEnum:put:toString()
                            .
                    when "deleteData" then
                        assign
                            pcPublicName          = OperationEnum:delete:toString()
                            bMethod.OperationType = OperationEnum:delete:toString()
                            bMethod.OperationVerb = MethodEnum:delete:toString()
                            .
                    when "submitData" then
                        assign
                            pcPublicName          = OperationEnum:submit:toString()
                            bMethod.OperationType = OperationEnum:submit:toString()
                            bMethod.OperationVerb = MethodEnum:put:toString()
                            .
                    otherwise
                        assign /* Default for all other operations. */
                            pcPublicName          = pcMethodName when (pcPublicName eq "")
                            bMethod.OperationType = OperationEnum:invoke:toString()
                            bMethod.OperationVerb = MethodEnum:put:toString()
                            .
                end case.
            end. /* not available */

            assign
                bMethod.PublicName    = pcPublicName when (pcPublicName gt "")
                bMethod.OperationType = pcOperationType when (pcOperationType gt "")
                bMethod.OperationVerb = pcOperationVerb when (pcOperationVerb gt "")
                .

            assign cOpType = bMethod.OperationType.
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
        define variable cHash as character no-undo.

        /* Use a simple hash to identify this combination of URI and Resource Name. */
        assign cHash = encode(pcServiceURI + pcResourceName).

        if not oCatRegistry:Has(cHash) then do:
            /**
             * Catalog data should be static after first generation by URI/Resource,
             * and only changes when MSAS sessions are started or when data is first
             * requested. Therefore we should be able to cache this data for speed.
             */
            define variable oCatalog as JsonObject no-undo.

            assign oCatalog = new JsonObject().
            oCatalog:Add("version", 1.5).
            oCatalog:Add("lastModified", now).
            oCatalog:Add("services", this-object:getServices(pcServiceURI, pcResourceName)).

            oLoggingManager:logMessage(substitute("Caching catalog data for URI '&1' Resource '&2'",
                                                  pcServiceURI, pcResourceName), "SPARK-CTLG", 3).

            oCatRegistry:Add(cHash, oCatalog). /* Add to local registry for this combination. */
        end. /* oCatalog Exists */

        return oCatRegistry:GetJsonObject(cHash).
    end method. /* getCatalog */


    method public Progress.Lang.Object getResourceMetadata ( input  pcServiceURI   as character,
                                                             input  pcResourceName as character,
                                                             input  pcMethodName   as character,
                                                             output phProcHandle   as handle,
                                                             output pcEntityName   as character,
                                                             output plUseTableBI   as logical ):
        define variable cClassPath   as character no-undo.
        define variable cClassMethod as character no-undo.
        define variable cHttpMethod  as character no-undo.
        define variable oParamArr    as JsonArray no-undo.

        /* Check if object contains method (using action). */
        assign cHttpMethod = cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):HttpMethod.

        /* Use default service if none provided. */
        if (pcServiceURI gt "") ne true then pcServiceURI = cDefaultURI.

        /* Set any public properties with information about this service. */
        for first ServiceList no-lock
            where ServiceList.ServiceURI eq pcServiceURI:
            UseRequestObj = ServiceList.UseRequest.
        end. /* for first */

        /* Obtain procedure handle and entity name (if applicable) as well as true method name. */
        this-object:getMethod( input  pcServiceURI,
                               input  pcResourceName,
                               input  pcMethodName,
                               input  cHttpMethod,
                               output cClassMethod,
                               output phProcHandle,
                               output pcEntityName ).

        if (cClassMethod gt "") ne true then /* If method cannot be determined, then resource cannot be invoked. */
            undo, throw new ApplicationError(substitute("Requested method '&1:&2' (&3) not available via &4.", pcResourceName, pcMethodName, pcServiceURI, upper(cHttpMethod)), -404).

        /* Make sure we have the real name (class path) of this resource. */
        assign cClassPath = this-object:getClassPath(pcServiceURI, pcResourceName).

        case cClassMethod:
            when "readData" then
                assign plUseTableBI = this-object:getBeforeImageFlag(pcServiceURI, cClassPath, OperationEnum:read:toString()).
            when "createData" then
                assign plUseTableBI = this-object:getBeforeImageFlag(pcServiceURI, cClassPath, OperationEnum:create:toString()).
            when "updateData" then
                assign plUseTableBI = this-object:getBeforeImageFlag(pcServiceURI, cClassPath, OperationEnum:update:toString()).
            when "deleteData" then
                assign plUseTableBI = this-object:getBeforeImageFlag(pcServiceURI, cClassPath, OperationEnum:delete:toString()).
            when "submitData" then
                assign plUseTableBI = this-object:getBeforeImageFlag(pcServiceURI, cClassPath, OperationEnum:submit:toString()).
            otherwise
                assign plUseTableBI = false.
        end case.

        /* Obtain the method signature from this resource. */
        assign oParamArr = this-object:getMethodSignature( pcServiceURI,
                                                           cClassPath,
                                                           cClassMethod ).

        /* Prepare signature object with parsed values. */
        return new Spark.Core.Util.MethodSignature(cClassPath, cClassMethod, oParamArr).

        finally:
            delete object oParamArr no-error.
        end finally.
    end method. /* getResourceMetadata */


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
        define buffer bService for ServiceList.

        for each bService no-lock:
            /* Register each known service for this application. */
            this-object:registerService(poRegistry, lc(bService.ServiceName), SemanticVersion:Parse("")).
        end. /* for each bService */
    end method. /* registerAllServices */


    method public DataObjectService registerService ( input poRegistry       as IServiceRegistry,
                                                      input pcServiceName    as character,
                                                      input poServiceVersion as SemanticVersion ):
        define variable cServiceURI  as character           no-undo.
        define variable cContentType as character           no-undo initial "application/json".
        define variable cTargetType  as character           no-undo.
        define variable cTargetName  as character           no-undo.
        define variable cEntityType  as character           no-undo.
        define variable cFuncMethod  as character           no-undo.
        define variable cParamMode   as character           no-undo.
        define variable cParamName   as character           no-undo.
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

        define buffer bService  for ServiceList.
        define buffer bResource for ResourceInfo.
        define buffer bMethod   for MethodInfo.

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

            /* Store the catalog data within the DOS instance. */
            oService:Catalog = this-object:getCatalog(bService.ServiceURI, "").

            for each bResource no-lock
               where bResource.ServiceURI eq bService.ServiceURI,
                each bMethod no-lock
               where bMethod.ServiceURI eq bResource.ServiceURI
                 and bMethod.ClassPath eq bResource.ClassPath:
                /* Prepare the common values for this operation mapping. */
                assign
                    cServiceURI  = (if (bMethod.PublicName gt "") eq true then substitute("&1/&2", bResource.PublicName, bMethod.PublicName) else bResource.PublicName)
                    oHttpMethod  = MethodEnum:GetEnum(bMethod.OperationVerb)
                    cTargetType  = (if bResource.IsClass then TargetTypeEnum:Class:ToString() else TargetTypeEnum:Procedure:ToString())
                    cTargetName  = (if bResource.IsClass then bMethod.ClassPath else bResource.SourcePath)
                    cEntityType  = (if bResource.IsClass then "Progress.Lang.Object" else ?)
                    cFuncMethod  = bMethod.MethodName
                    iStatusCode  = integer(StatusCodeEnum:ok)
                    lIsEntity    = false
                    dExecTime[1] = now
                    .

                if bResource.IsClass then do:
                    /* If resource is a class, determine if used as a business entity. */
                    assign oResource = Progress.Lang.Class:GetClass(bResource.ClassPath).
                    if valid-object(oResource) and oResource:IsA(get-class(OpenEdge.BusinessLogic.BusinessEntity)) then
                        assign lIsEntity = true.
                end. /* Is Class */

                /* Just use name of the resource for CRUD operations. */
                if lIsEntity and can-do("Create,Read,Update,Delete", bMethod.OperationType) then
                    assign cServiceURI = bResource.PublicName. /* Should just be "/<resource>" */

                /* Denote start of operation mapping. */
                oLoggingManager:logMessage(substitute("Mapping &1 &2/&3 to &4:&5",
                                                      oHttpMethod:ToString(),
                                                      pcServiceName,
                                                      cServiceURI,
                                                      cTargetName,
                                                      cFuncMethod),
                                                      "SPARK-SVC", 4).

                /* Set any options for the current operation. */
                assign oOperOpts = new OperationOptions().
                oOperOpts:WriteBI = lIsEntity. /* Should be true for entities, otherwise false. */

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

                /* Obtain the method signature for this resource. */
                assign oParamArr = this-object:getMethodSignature( bResource.ServiceURI,
                                                                   bResource.ClassPath,
                                                                   bMethod.MethodName ).

                /* Add the individual parameters for this operation. */
                if valid-object(oParamArr) then
                do iX = 1 to oParamArr:Length
                on error undo, throw:
                    /* Obtain parameter information. */
                    assign oParamObj = oParamArr:GetJsonObject(iX).
                    assign
                        cParamMode = oParamObj:GetCharacter("mode") when oParamObj:Has("mode")
                        cParamName = oParamObj:GetCharacter("name") when oParamObj:Has("name")
                        cParamType = oParamObj:GetCharacter("type") when oParamObj:Has("type")
                        hSchema    = ?
                        .

                    /* Adjust parameter mode if using a non-standard name. */
                    if cParamMode eq "inputoutput" then
                        assign cParamMode = "Input-Output".

                    /* Adjust parameter type based on name or format. */
                    case true:
                        when cParamType eq "datetimetz" then
                            assign cParamType = "datetime-tz".
                        when cParamType begins "dataset" then
                            assign cParamType = "dataset".
                        when cParamType begins "table" then
                            assign cParamType = "table".
                        when index(cParamType, ".") gt 0 then
                            assign cParamType = substitute("class &1", cParamType).
                    end case.

                    if cParamType eq "dataset" then do:
                        if lIsEntity and cParamName ne bResource.EntityName then
                            assign cParamName = bResource.EntityName.

                        if not oService:HasSchema(cParamName) then do:
                            oSchemaManager:getDataset(cParamName, dataset-handle hSchema by-reference).
                            if valid-handle(hSchema) then do:
                                oService:PutSchema(cParamName, hSchema). /* Add schema to service. Do not delete hSchema handle!. */
                                oLoggingManager:logMessage(substitute("| Schema: &1 as dataset", cParamName), "SPARK-SVC", 4).
                            end. /* valid-handle */
                            else
                                oLoggingManager:logMessage(substitute("| Schema: no dataset handle for &1", cParamName), "SPARK-SVC", 2).
                        end. /* not HasSchema */
                    end. /* dataset */

                    if cParamType eq "table" then do:
                        if not oService:HasSchema(cParamName) then do:
                            oSchemaManager:getTempTable(cParamName, table-handle hSchema by-reference).
                            if valid-handle(hSchema) then do:
                                oService:PutSchema(cParamName, hSchema). /* Add schema to service. Do not delete hSchema handle!. */
                                oLoggingManager:logMessage(substitute("| Schema: &1 as table", cParamName), "SPARK-SVC", 4).
                            end. /* valid-handle */
                            else
                                oLoggingManager:logMessage(substitute("| Schema: no table handle for &1", cParamName), "SPARK-SVC", 2).
                        end. /* not HasSchema */
                    end. /* table */

                    /* Create the parameter for this method. */
                    assign oParam = new OperationParameter( IOModeEnum:GetEnum(cParamMode), cParamType, cParamName ).

                    /* Assign message elements based on the parameter IO mode. */

                    if cParamMode eq "input" then do:
                        if oHttpMethod eq MethodEnum:GET then
                            assign oElementType = ElementTypeEnum:Query. /* Use query parameters for GET. */
                        else
                            assign oElementType = ElementTypeEnum:Field. /* Otherwise, use field of body. */

                        if cParamName eq "bodyInput" then
                            assign oElementType = ElementTypeEnum:Body. /* Special name indicates use of body. */

                        extent(oParam:InputElement) = 1.
                        assign oParam:InputElement[1] = new MessageElement(oElementType, cParamName, IOModeEnum:Input).
                    end. /* input */

                    else if cParamMode eq "output" then do:
                        if can-do("dataset,table", cParamType) then
                            assign oElementType = ElementTypeEnum:Body. /* Output dataset/table as body. */
                        else
                            assign oElementType = ElementTypeEnum:Field. /* Otherwise, use field of body. */

                        if cParamName eq "bodyOutput" then
                            assign oElementType = ElementTypeEnum:Body. /* Special name indicates use of body. */

                        extent(oParam:OutputElement) = 1.
                        assign oParam:OutputElement[1] = new MessageElement(oElementType, cParamName, IOModeEnum:Output).
                    end. /* output */

                    else if cParamMode eq "input-output" then do:
                        if can-do("dataset,table", cParamType) then
                            assign oElementType = ElementTypeEnum:Body. /* Output dataset/table as body. */
                        else
                            assign oElementType = ElementTypeEnum:Field. /* Otherwise, use field of body. */

                        if cParamName eq "bodyInputOutput" then
                            assign oElementType = ElementTypeEnum:Body. /* Special name indicates use of body. */

                        extent(oParam:InputElement) = 1.
                        extent(oParam:OutputElement) = 1.
                        assign oParam:InputElement[1] = new MessageElement(oElementType, cParamName, IOModeEnum:InputOutput).
                        assign oParam:OutputElement[1] = new MessageElement(oElementType, cParamName, IOModeEnum:InputOutput).
                    end. /* output/input-output */

                    /* Add parameter to the operation. */
                    oOperation:Parameters:Add(oParam).

                    /* Log creation of each parameter. */
                    oLoggingManager:logMessage(substitute("| &1: &2 as &3 [&4]",
                                                          cParamMode,
                                                          cParamName,
                                                          cParamType,
                                                          oElementType:ToString()), "SPARK-SVC", 4).

                    finally:
                        delete object oParamObj no-error.
                    end finally.
                end. /* do iX */

                /* Add a mapped operation to the current service. */
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
                    assign oOperation = new MappedOperation( "/",
                                                             MethodEnum:GET,
                                                             "application/json",
                                                             TargetTypeEnum:Class:ToString(),
                                                             oServiceImpl:GetClass():TypeName,
                                                             "Progress.Lang.Object",
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
        if log-manager:logging-level ge 3 and valid-object(oService) then do on error undo, leave:
            define variable oSvcWriter as MappingFileServiceWriter no-undo.

            assign oSvcWriter = new MappingFileServiceWriter().

            oSvcWriter:open().
            oSvcWriter:write(oService).
            oSvcWriter:close().
            oSvcJson = cast(oSvcWriter:Value, JsonObject).
            oSvcJson:WriteFile(substitute("&1/&2.map", right-trim(replace(session:temp-directory, "~\", "~/"), "~/"), pcServiceName), yes).

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