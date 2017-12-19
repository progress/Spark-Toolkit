/*------------------------------------------------------------------------
    File        : Wizard.cls
    Syntax      : Code generation wizard
    Author(s)   : dugrau
    Created     : Mon Sep 14 10:21:57 EDT 2015
    Notes       :
  ----------------------------------------------------------------------*/

&GLOBAL-DEFINE CSS_DIR "/PASOEContent/static/assets/css"

@program FILE(name="CodeGen.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="wizard", URI="/wizard", schemaName="dsCodeGen", schemaFile="").

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.DataAdmin.* from propath.
using OpenEdge.DataAdmin.Error.* from propath.
using OpenEdge.DataAdmin.Lang.Collections.* from propath.
using OpenEdge.BusinessLogic.BusinessEntity from propath.
using Generator.Common.AblParser from propath.

block-level on error undo, throw.

class Generator.Business.Wizard inherits BusinessEntity:
	/*------------------------------------------------------------------------------
			Purpose: Provide API's for screen generation wizard.
			Notes:
	------------------------------------------------------------------------------*/

    /* Public Variables/Tables/Datasets */

    @openapi.openedge.entity.primarykey (fields="ttName").
    define temp-table ttParam before-table bttParam
        field ttName  as character
        field ttValue as character
        index IdxMain ttName.

    @openapi.openedge.entity.primarykey (fields="schemaType,schemaSeq,tableName,fieldName").
    define temp-table ttSchema before-table bttSchema
        field schemaType   as character
        field schemaSeq    as integer
        field tableName    as character
        field fieldName    as character
        field logicalName  as character
        field fieldLabel   as character
        field fieldExtent  as integer
        field dataType     as character
        field fieldDefault as character
        field fieldFormat  as character
        field fieldWidth   as decimal
        field isIndexed    as logical
        index idxSeq is primary schemaType schemaSeq tableName fieldName
        .

    define dataset dsCodeGen for ttParam, ttSchema.

    /* Private Variables/Tables/Datasets */

    define private variable cConfigRoot  as character no-undo.
    define private variable cIdProperty  as character no-undo.
    define private variable cInheritedBE as character no-undo.
    define private variable cNamespace   as character no-undo.
    define private variable cCommonDir   as character no-undo.
    define private variable cConfOutput  as character no-undo.
    define private variable cCatalogPath as character no-undo.
    define private variable cProjectName as character no-undo.
    define private variable cProjectRoot as character no-undo.
    define private variable lSkipHome    as logical   no-undo.
    define private variable lSkipLogout  as logical   no-undo.
    define private variable lUseDebugs   as logical   no-undo.
    define private variable lUseJFP      as logical   no-undo.

    define private variable cBEInputFolder  as character no-undo.
    define private variable cUIInputFolder  as character no-undo.
    define private variable cBEOutputFolder as character no-undo.
    define private variable cBECommonFolder as character no-undo.
    define private variable cUIOutputFolder as character no-undo.
    define private variable cMetadataOutput as character no-undo.

    @openapi.openedge.entity.primarykey (fields="BusinessEntity").
    define private temp-table GeneralParam no-undo serialize-name "General"
        field BusinessEntity as character /* Name of default business entity class template.   */
        field BusinessOutput as character /* Output directory for business entity classes.     */
        field ClientOutput   as character /* Output directory for client-side screens (HTML).  */
        field CommonDir      as character /* Directory to use for common include files.        */
        field DefaultCatalog as character /* Default catalog to use with UI templates.         */
        field EnableDebugs   as logical   /* Display additional info as resources are loaded.  */
        field IdProperty     as character /* Field name to be used for record ID purposes.     */
        field InheritedBE    as character /* Class path of application entity to inherit.      */
        field MetadataPath   as character /* Path to metadata files, relative to config dir.   */
        field Namespace      as character /* Namespace/Dir to use for business entity classes. */
        field OmitDashboard  as logical   /* Should dashboard menu option be omitted?          */
        field OmitLogout     as logical   /* Should logout menu option be omitted?             */
        field OutputBase     as character /* Base output directory (optional, autodetected).   */
        field OutputConf     as character /* Conf output directory (optional, autodetected).   */
        field TemplatePath   as character /* Path to template files, relative to config dir.   */
        field UseJFP         as logical   /* Should JFP support be enabled for entities.       */
        .

    @openapi.openedge.entity.primarykey (fields="DisplayOrder").
    define private temp-table Template no-undo
        field DisplayOrder  as integer             /* Order in which to display this template.      */
        field TemplateID    as character           /* System name of template for generator script. */
        field TemplateLabel as character           /* User-friendly template name for display.      */
        field TemplateIcon  as character           /* Thumbnail image for template when selected.   */
        field TemplatePath  as character           /* Non-standard path for template files.         */
        field TemplateUI    as character           /* UI Template, relative to the template folder. */
        field EntityClass   as character           /* BE Template, relative to the template folder. */
        field EntityType    as character           /* Is entity to generate a CRUD or Invoke type.  */
        field NameTemplate  as character           /* Custom template for filename generation.      */
        field HasRelation   as logical             /* Does entity require a field relation to work. */
        field IsSPA         as logical             /* Denotes template is meant for SPA use.        */
        field RoleSPA       as character           /* Role in SPA: [landing|screen|template]        */
        field Defaults      as character extent 10 /* Is entity to generate a CRUD or Invoke type.  */
        index idxDisplay  is primary DisplayOrder
        index idxTemplate is unique  TemplateID
        .

    define private dataset dsConfig serialize-name "Config"
        for GeneralParam, Template.

	/*------------------------------------------------------------------------------
            Purpose: Set handle to dataset and set default configuration values.
            Notes:
    ------------------------------------------------------------------------------*/
    constructor public Wizard ( ):
    	define variable hDataSourceArray as handle    no-undo extent 1.
        define variable cSkipListArray   as character no-undo extent 1.
        super(dataset dsCodeGen:handle).
     	this-object:ProDataSource = hDataSourceArray.
        this-object:SkipList = cSkipListArray.
        readConfig(). /* Set default values. */
        getPaths(). /* Get directory paths. */
    end constructor.

	/*------------------------------------------------------------------------------
	 Purpose: Read any config files, and determine default paths from environment.
	 Notes:
	------------------------------------------------------------------------------*/
	method private void readConfig ( ):
        define variable cWizardConfDir as character no-undo.
        assign cWizardConfDir = os-getenv("CATALINA_BASE") + "/webapps/WebWizard/config".

        if (cWizardConfDir gt "") eq true then do:
            assign cWizardConfDir = replace(cWizardConfDir, "~\", "/").

            /* Read the standard wizard config file into the dataset. */
            file-info:file-name = right-trim(cWizardConfDir, "/") + "/wizard.json".
            if file-info:full-pathname ne ? then do:
                dataset dsConfig:read-json("FILE", file-info:full-pathname, "EMPTY").
                assign cConfigRoot = right-trim(cWizardConfDir, "/").
            end. /* File Exists */

            /* Read the custom templates config file. */
            file-info:file-name = right-trim(cWizardConfDir, "/") + "/templates/custom/templates.json".
            if file-info:full-pathname ne ? then
                dataset dsConfig:read-json("FILE", file-info:full-pathname, "APPEND").

            /* Set variables for certain flags. */
            find first GeneralParam no-lock no-error.
            if available(GeneralParam) then
                assign
                    cIdProperty  = GeneralParam.IdProperty
                    cInheritedBE = GeneralParam.InheritedBE
                    cNamespace   = GeneralParam.Namespace
                    cCommonDir   = GeneralParam.CommonDir
                    cCatalogPath = GeneralParam.DefaultCatalog
                    lSkipHome    = GeneralParam.OmitDashboard eq true
                    lSkipLogout  = GeneralParam.OmitLogout eq true
                    lUseDebugs   = GeneralParam.EnableDebugs eq true
                    lUseJFP      = GeneralParam.UseJFP eq true
                    .

            /* Ensure a namespace value ends with a dot. */
            if (cNamespace gt "") eq true then
                assign cNamespace = right-trim(GeneralParam.Namespace, ".") + ".".
        end. /* cWizardConfDir */

        /* Use the specified output dir for any project configs. */
        if (GeneralParam.OutputConf gt "") eq true then
            assign cConfOutput = GeneralParam.OutputConf.

        if (GeneralParam.OutputBase gt "") eq true then do:
            /* Use the specified output base as the project root. */
            assign
                cProjectRoot = GeneralParam.OutputBase
                cProjectName = entry(num-entries(cProjectRoot, "/"), cProjectRoot, "/")
                .
        end. /* Given Base */
        else do:
            /* Search the propath for a valid AppServer directory. */
            define variable ix    as integer   no-undo.
            define variable cPath as character no-undo.
            PATHBLK:
            do ix = 1 to num-entries(propath):
                assign cPath = right-trim(replace(entry(ix, propath), "~\", "/"), "/").
                file-info:file-name = cPath + "/Spark/startup.p".
                if file-info:full-pathname ne ? then do:
                    assign
                        cProjectRoot = replace(cPath, "/WEB-INF/openedge", "")
                        cProjectName = entry(num-entries(cProjectRoot, "/"), cProjectRoot, "/")
                        .
                    leave PATHBLK.
                end. /* found startup.p */
                else do:
                    file-info:file-name = cPath + "/Spark/startup.r".
                    if file-info:full-pathname ne ? then do:
                        assign
                            cProjectRoot = replace(cPath, "/WEB-INF/openedge", "")
                            cProjectName = entry(num-entries(cProjectRoot, "/"), cProjectRoot, "/")
                            .
                        leave PATHBLK.
                    end.
                end. /* found startup.r */
            end. /* propath */
        end. /* Autodetect Base */
	end method. /* readConfig */


    /*------------------------------------------------------------------------------
     Purpose: Get path names for generator, creating any that don't exist.
     Notes:
    ------------------------------------------------------------------------------*/
    method private void getPaths ( ):
        find first GeneralParam no-lock no-error.
        assign
            cBEInputFolder  = cConfigRoot + (if available(GeneralParam) then GeneralParam.TemplatePath else "/templates/")
            cUIInputFolder  = cConfigRoot + (if available(GeneralParam) then GeneralParam.TemplatePath else "/templates/")
            cBEOutputFolder = cProjectRoot + (if available(GeneralParam) then GeneralParam.BusinessOutput else "/AppServer/")
            cBECommonFolder = cProjectRoot + (if available(GeneralParam) then GeneralParam.BusinessOutput else "/AppServer/")
            cUIOutputFolder = cProjectRoot + (if available(GeneralParam) then GeneralParam.ClientOutput else "/WebContent/")
            cMetadataOutput = cConfigRoot + (if available(GeneralParam) then GeneralParam.MetadataPath else "/metadata/")
            .

        if (cNamespace gt "") eq true then /* Append given namespace to output path. */
            cBEOutputFolder = substitute("&1/&2", right-trim(cBEOutputFolder, "/"), replace(cNamespace, ".", "/")).

        if (cCommonDir gt "") eq true then /* Append given common dir to output path. */
            cBECommonFolder = substitute("&1/&2/", right-trim(cBECommonFolder, "/"), cCommonDir).
        else
            cBECommonFolder = cBEOutputFolder. /* Otherwise use same directory as BE output. */

        file-info:file-name = cBEOutputFolder.
        if file-info:full-pathname eq ? then
            os-create-dir value(file-info:full-pathname).
    end method. /* getPaths */

    /*------------------------------------------------------------------------------
     Purpose: Import parameters from existing metadata (config) file.
     Notes:
    ------------------------------------------------------------------------------*/
    method private void importConfig ( input pcConfigPath as character ):
        define variable oParser as ObjectModelParser no-undo.
        define variable oConfig as JsonObject        no-undo.
        define variable cNames  as character extent  no-undo.
        define variable iX      as integer           no-undo.

        empty temp-table ttParam.

        /* Import parameters from JSON object file. */
        file-info:file-name = pcConfigPath.
        if file-info:full-pathname ne ? then do:
            assign oParser = new ObjectModelParser().
            assign oConfig = cast(oParser:ParseFile(file-info:full-pathname), JsonObject).
            if oConfig:Has("ttParam") then do:
                /* Read table-formatted data to temp-table directly. */
                temp-table ttParam:read-json("JsonObject", oConfig, "empty").
            end. /* Old Config Format */
            else do:
                /* Create new ttParam records from each object property. */
                assign cNames = oConfig:GetNames().
                empty temp-table ttParam.
                do iX = 1 to extent(cNames):
                    create ttParam.
                    assign
                        ttParam.ttName  = cNames[iX]
                        ttParam.ttValue = oConfig:GetCharacter(cNames[iX])
                        no-error.
                    release ttParam.
                end. /* Param Name */
            end. /* New Config Format */
        end. /* File Exists */

        finally:
            delete object oParser no-error.
            delete object oConfig no-error.
        end finally.
    end method. /* importConfig */

    /*------------------------------------------------------------------------------
     Purpose: Create a basic menu and merge with current options.
     Notes:
    ------------------------------------------------------------------------------*/
    method private JsonArray getMenuItems ( input poMenuData as JsonArray,
                                            input pcMenuName as character ):
        define variable oMenuObj as JsonObject no-undo.
        define variable iX       as integer    no-undo.

        do iX = 1 to poMenuData:length:
            oMenuObj = poMenuData:GetJsonObject(iX).
            if oMenuObj:GetCharacter("text") eq pcMenuName and
               oMenuObj:Has("items") then
                return oMenuObj:GetJsonArray("items").
        end.

        return new JsonArray().
    end method. /* getMenuItems */


    /*------------------------------------------------------------------------------
     Purpose: Create a basic menu and merge with current options.
     Notes:
    ------------------------------------------------------------------------------*/
    method private logical hasMenuItem ( input poMenuData as JsonArray,
                                         input pcMenuName as character ):
        define variable iX as integer no-undo.

        do iX = 1 to poMenuData:length:
            if poMenuData:GetJsonObject(iX):GetCharacter("text") eq pcMenuName then
                return true.
        end.

        return false.
    end method. /* hasMenuItem */

    /*------------------------------------------------------------------------------
     Purpose: Create a basic menu and merge with current options.
     Notes:
    ------------------------------------------------------------------------------*/
    method private JsonArray genMenu ( output pcMenuFile as character ):
        define variable oParser    as ObjectModelParser no-undo.
        define variable oPrevData  as JsonArray         no-undo.
        define variable oMenuData  as JsonArray  no-undo.
        define variable oFirstItem as JsonObject no-undo.
        define variable oMenuItem  as JsonObject no-undo.
        define variable oLastItem  as JsonObject no-undo.

        /* Read and parse existing menu data. */
        oPrevData = new JsonArray().

        /* Determine correct menu file to use. */
        file-info:file-name = cConfOutput + "/menu.json".
        if file-info:full-pathname eq ? then
            file-info:file-name = cConfigRoot + "/menu.json".

        /* Parse the existing menu structure. */
        if file-info:full-pathname ne ? then do:
            assign pcMenuFile = file-info:full-pathname.
            oParser = new ObjectModelParser().
            oPrevData = cast(oParser:parseFile(pcMenuFile), JsonArray).
        end.

        /* Create the menu array. */
        oMenuData = new JsonArray().

        if not lSkipHome then do:
            /* Create first entry. */
            oFirstItem = new JsonObject().
            oFirstItem:Add("text", "Dashboard").
            oFirstItem:Add("spriteCssClass", "fa fa-home").
            oFirstItem:Add("url", "#/").
            oMenuData:Add(oFirstItem).
        end.

        /* Create parent for each SPA role (except Landing). */
        for each Template
           where Template.IsSPA
             and Template.RoleSPA gt ""
             and Template.RoleSPA ne "Landing"
           break by Template.RoleSPA:
            if first-of(Template.RoleSPA) then do:
                /* Create child list from existing data or just a new empty array. */
                oMenuItem = new JsonObject().
                oMenuItem:Add("text", Template.RoleSPA).
                oMenuItem:Add("items", getMenuItems(oPrevData, oMenuItem:GetCharacter("text"))).
                oMenuData:Add(oMenuItem).
            end.
        end. /* for each */

        if not lSkipLogout then do:
            /* Create last entry. */
            oLastItem = new JsonObject().
            oLastItem:Add("text", "Logout").
            oLastItem:Add("url", "#/logout").
            oMenuData:Add(oLastItem).
        end.

        return oMenuData.
    end method. /* genMenu */

    /*------------------------------------------------------------------------------
     Purpose: Get a param value, returning blank if it does not exist.
     Notes:
    ------------------------------------------------------------------------------*/
    method private character getParam ( input paramName as character ):
        find first ttParam no-lock
             where ttParam.ttName eq paramName no-error.
        if available(ttParam) then
            return ttParam.ttValue.
        else
            return "".
    end method. /* getParam */

    /*------------------------------------------------------------------------------
     Purpose: Set a param value, creating it if it does not exist yet.
     Notes:
    ------------------------------------------------------------------------------*/
    method private void setParam ( input paramName  as character,
                                   input paramValue as character ):
        find first ttParam exclusive-lock
             where ttParam.ttName eq paramName no-error.
        if not available(ttParam) then do:
            create ttParam.
            assign ttParam.ttName = paramName.
        end.
        assign ttParam.ttValue = paramValue.
    end method. /* setParam */

    /*------------------------------------------------------------------------------
     Purpose: Obtain a list of all indexed fields for this table.
     Notes:
    ------------------------------------------------------------------------------*/
    method private character getKeys ( input poTable    as ITable,
                                       input primesOnly as logical ):
        define variable oIndex     as IIndex    no-undo.
        define variable oIndexIter as IIterator no-undo.
        define variable oField     as IField    no-undo.
        define variable oFieldIter as IIterator no-undo.
        define variable cKeyFields as character no-undo.

        if valid-object(poTable) then do:
            assign oIndexIter = poTable:Indexes:Iterator().
            do while oIndexIter:HasNext():
                assign oIndex = cast(oIndexIter:Next(), IIndex).

                if primesOnly then do:
                    if oIndex:IsPrimary then do:
                        assign oFieldIter = oIndex:Fields:Iterator().
                        do while oFieldIter:HasNext():
                            assign oField = cast(oFieldIter:Next(), IField).
                            assign cKeyFields = trim(substitute("&1,&2", cKeyFields, oField:Name), ",").
                        end. /* do while */
                    end. /* oIndex:IsPrimary */
                end. /* primary only */
                else do:
                    if oIndex:IsActive then do:
                        assign oFieldIter = oIndex:Fields:Iterator().
                        do while oFieldIter:HasNext():
                            assign oField = cast(oFieldIter:Next(), IField).
                            assign cKeyFields = trim(substitute("&1,&2", cKeyFields, oField:Name), ",").
                        end. /* do while */
                    end. /* oIndex:IsActive */
                end. /* non-primary */
            end. /* do while */
        end. /* valid-object */

        return cKeyFields.
    end method. /* getKeys */

    /*------------------------------------------------------------------------------
     Purpose: Obtain a list of all indexed fields for this table.
     Notes:
    ------------------------------------------------------------------------------*/
    method private character getKeys ( input databaseName as character,
                                       input tableName    as character,
                                       input primesOnly   as logical ):
        define variable oService as DataAdminService no-undo.
        define variable oTable   as ITable           no-undo.

        /* Create a service against this database. */
        assign oService = new DataAdminService(databaseName).
        if valid-object(oService) then do:
            assign oTable = oService:GetTable(tableName).
            if valid-object(oTable) then do:
                return getKeys(oTable, primesOnly).
            end. /* valid-object */
        end. /* valid-object */

        return "".

        finally:
            delete object oService no-error.
            delete object oTable no-error.
        end finally.
    end method. /* getKeys */

    /*------------------------------------------------------------------------------
     Purpose: Obtain a list of CSS files for the application.
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/css", alias="css", mediaType="application/json").
    method public void GetCSS ( output cssList as character ):
        define variable oCSSList  as JsonArray no-undo.
        define variable cFileName as character no-undo.
        define variable cFilePath as character no-undo.
        define variable cFileType as character no-undo.

        assign oCSSList = new JsonArray().
        file-info:file-name = right-trim(cProjectRoot, "/") + {&CSS_DIR}.

        DIRBLOCK:
        do on error undo DIRBLOCK, leave DIRBLOCK
           on stop  undo DIRBLOCK, leave DIRBLOCK:
            if file-info:full-pathname eq ? then leave DIRBLOCK.
            input from os-dir(file-info:full-pathname).
            repeat:
                import cFileName cFilePath cFileType no-error.
                if error-status:error then leave DIRBLOCK.
                if cFileType eq "F" and cFileName matches "*.css" then
                    oCSSList:add(cFileName).
            end.
        end.

        assign cssList = string(oCSSList:GetJsonText()).
    end method. /* GetCSS */

    /*------------------------------------------------------------------------------
     Purpose: Get list of standard templates for the wizard.
     Notes: Should return a temp-table.
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/templates", alias="templates", mediaType="application/json").
    method public void GetTemplates ( output DefaultCatalog as character,
                                      output table for Template ):
        /* No code needed for returning Template table, just uses the current table contents from the config file. */
        assign DefaultCatalog = cCatalogPath. /* Assign and return the default catalog path to be used. */
    end method. /* GetTemplates */

    /*------------------------------------------------------------------------------
     Purpose: Get list of metadata (config) files available.
     Notes: Should return a stringified JSON object.
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/metadata", alias="metadata", mediaType="application/json").
    method public void GetMetadata ( output metadataList as character ):
        define variable oMetaItem as JsonObject no-undo.
        define variable oMetaList as JsonArray  no-undo.
        define variable cFileName as character  no-undo.
        define variable cFilePath as character  no-undo.
        define variable cFileType as character  no-undo.

        assign oMetaList = new JsonArray().
        file-info:file-name = right-trim(cConfigRoot, "/") + "/metadata".

        DIRBLOCK:
        do on error undo DIRBLOCK, leave DIRBLOCK
           on stop  undo DIRBLOCK, leave DIRBLOCK:
            if file-info:full-pathname eq ? then leave DIRBLOCK.
            input from os-dir(file-info:full-pathname).
            repeat:
                import cFileName cFilePath cFileType no-error.
                if error-status:error then leave DIRBLOCK.
                if cFileType eq "F" and cFileName matches "*.json" then do:
                    assign oMetaItem = new JsonObject().
                    oMetaItem:Add("fileName", cFileName).
                    oMetaItem:Add("filePath", replace(cFilePath, "~\", "/")).
                    oMetaList:add(oMetaItem).
                end. /* HTML File */
            end. /* repeat */
        end. /* do */

        assign metadataList = string(oMetaList:GetJsonText()).
    end method. /* GetMetadata */

    /*------------------------------------------------------------------------------
     Purpose: Get list of include files available.
     Notes: Should return a stringified JSON object.
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/includes", alias="includes", mediaType="application/json").
    method public void GetIncludes ( output includeList as character ):
        define variable oMetaItem as JsonObject no-undo.
        define variable oMetaList as JsonArray  no-undo.
        define variable cFileName as character  no-undo.
        define variable cFilePath as character  no-undo.
        define variable cFileType as character  no-undo.

        assign oMetaList = new JsonArray().

        /* This will only search for includes in the "Common" output directory. */
        file-info:file-name = cBECommonFolder.

        DIRBLOCK:
        do on error undo DIRBLOCK, leave DIRBLOCK
           on stop  undo DIRBLOCK, leave DIRBLOCK:
            if file-info:full-pathname eq ? then leave DIRBLOCK.
            input from os-dir(file-info:full-pathname).
            repeat:
                import cFileName cFilePath cFileType no-error.
                if error-status:error then leave DIRBLOCK.
                if cFileType eq "F" and (cFileName matches "*.i") then do:
                    assign oMetaItem = new JsonObject().
                    oMetaItem:Add("fileName", cFileName).
                    oMetaItem:Add("filePath", replace(cFilePath, "~\", "/")).
                    oMetaList:Add(oMetaItem).
                end. /* HTML File */
            end. /* repeat */
        end. /* do */

        assign includeList = string(oMetaList:GetJsonText()).
    end method. /* GetIncludes */

    /*------------------------------------------------------------------------------
     Purpose: Parse an include file for usable information.
     Notes: Should return a stringified JSON object.
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/parse", alias="parse", mediaType="application/json").
    method public void ParseInclude ( input  includePath as character,
                                      output includeData as character ):
        define variable oParser as AblParser  no-undo.
        define variable oIncObj as JsonObject no-undo.

        oParser = new AblParser(includePath).
        assign oIncObj = oParser:parseStats().

        if valid-object(oIncObj) then
            assign includeData = string(oIncObj:GetJsonText()).

        finally:
            delete object oParser no-error.
        end finally.
    end method. /* ParseInclude */

    /*------------------------------------------------------------------------------
     Purpose: Get list of connected databases.
     Notes: Should return a stringified JSON array.
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/databases", alias="databases", mediaType="application/json").
    method public void GetDatabases ( output databaseList as character ):
        define variable oDBList as JsonArray no-undo.
        define variable iX      as integer   no-undo.

        assign oDBList = new JsonArray().
        do iX = 1 to num-dbs:
            oDBList:Add(ldbname(iX)).
        end. /* dbs */

        assign databaseList = string(oDBList:GetJsonText()).
    end method. /* GetDatabases */

    /*------------------------------------------------------------------------------
     Purpose: Get list of tables for a selected database.
     Notes: Should return a temp-table.
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/tables", alias="tables", mediaType="application/json").
    method public void GetTables ( input  databaseName as character,
                                   output table for ttSchema ):
        define variable oService   as DataAdminService no-undo.
        define variable oTable     as ITable           no-undo.
        define variable oTables    as ITableSet        no-undo.
        define variable oTableIter as IIterator        no-undo.
        define variable iTable     as integer          no-undo initial 1.
        define variable cKeyFields as character        no-undo.

        empty temp-table ttSchema.

        /* Create a service against this database. */
        assign oService = new DataAdminService(databaseName).
        if valid-object(oService) then do:
            assign oTables = oService:GetTables().
            assign oTableIter = oTables:Iterator().
            do while oTableIter:HasNext():
                assign oTable = cast(oTableIter:Next(), ITable).
                create ttSchema.
                assign
                    ttSchema.schemaType   = "Table"
                    ttSchema.schemaSeq    = iTable
                    ttSchema.tableName    = oTable:Name
                    ttSchema.logicalName  = "tt" + oTable:Name
                    iTable                = iTable + 1
                    .
                release ttSchema.
            end. /* do while */
        end. /* valid-object */

        finally:
            delete object oService no-error.
            delete object oTables no-error.
            delete object oTable no-error.
        end finally.
    end method. /* GetTables */

    /*------------------------------------------------------------------------------
     Purpose: Get list of fields for a selected database and table.
     Notes: Should return a temp-table.
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/fields", alias="fields", mediaType="application/json").
    method public void GetFields ( input  databaseName as character,
                                   input  tableName as character,
                                   output table for ttSchema ):
        define variable oService    as DataAdminService no-undo.
        define variable oTable      as ITable           no-undo.
        define variable fileBuffer  as handle           no-undo.
        define variable fieldBuffer as handle           no-undo.
        define variable fieldHandle as handle           no-undo.
        define variable hFileQuery  as handle           no-undo.
        define variable iField      as integer          no-undo.
        define variable cKeyFields  as character        no-undo.

        empty temp-table ttSchema.

        /* Create a service against this database. */
        assign oService = new DataAdminService(databaseName).
        if valid-object(oService) then do:
            assign oTable = oService:GetTable(tableName).
            if valid-object(oTable) then do:
                /* Create a buffer against this database. */
                create buffer fileBuffer for table substitute("&1._file", databaseName).

                create query hFileQuery.
                hFileQuery:set-buffers(fileBuffer).
                hFileQuery:query-prepare(substitute("for each &1 where &1._file-number gt 0 and &1._file-name eq '&2'", fileBuffer:name, tableName)).
                hFileQuery:query-open().

                /* Should only iterate once through the selected database + table. */
                TABLEBLK:
                do while hFileQuery:get-next() on error undo, throw:
                    /* Create a buffer against this database table. */
                    create buffer fieldBuffer for table substitute("&1.&2", databaseName, tableName).

                    /* Get all indexed fields for this table. */
                    assign cKeyFields = getKeys(oTable, false).

                    /* Cycle through all fields for this table. */
                    FIELDBLK:
                    do iField = 1 to fieldBuffer:num-fields on error undo, throw:
                        assign fieldHandle = fieldBuffer:buffer-field(iField).
                        create ttSchema.
                        assign
                            ttSchema.schemaType   = "Field"
                            ttSchema.schemaSeq    = iField
                            ttSchema.tableName    = tableName
                            ttSchema.fieldName    = fieldHandle:name
                            ttSchema.logicalName  = fieldHandle:name
                            ttSchema.fieldLabel   = fieldHandle:label
                            ttSchema.fieldExtent  = fieldBuffer:buffer-field(iField):extent
                            ttSchema.dataType     = caps(fieldHandle:data-type)
                            ttSchema.fieldDefault = fieldHandle:default-string
                            ttSchema.fieldFormat  = fieldHandle:format
                            ttSchema.fieldWidth   = fieldHandle:width-chars
                            ttSchema.isIndexed    = can-do(cKeyFields, fieldHandle:name)
                            .
                        release ttSchema.
                    end. /* num-fields */
                end. /* do while */
            end. /* valid-object */
        end. /* valid-object */

        finally:
            delete object hFileQuery no-error.
            delete object oService no-error.
            delete object oTable no-error.
        end finally.
    end method. /* GetFields */

    /*------------------------------------------------------------------------------
     Purpose: Return the tooltip data for the web-based wizard UI.
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/tooltips", alias="tooltips", mediaType="application/json").
    method public void GetTooltips ( output tooltipData as character ):
        define variable oParser as ObjectModelParser no-undo.
        define variable oTTips  as JsonObject        no-undo.

        /* Import tooltips from JSON object file. */
        file-info:file-name = cConfigRoot + "/tooltips.json".

        if file-info:full-pathname ne ? then do:
            assign oParser = new ObjectModelParser().
            assign oTTips = cast(oParser:ParseFile(file-info:full-pathname), JsonObject).
            assign tooltipData = string(oTTips:GetJsonText()).
        end. /* File Exists */

        finally:
            delete object oParser no-error.
            delete object oTTips no-error.
        end finally.
    end method. /* GetTooltips */

    /*------------------------------------------------------------------------------
     Purpose: Generate the BE and/or UI from the given template parameters.
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/generate", alias="generate", mediaType="application/json").
    method public void Generate ( input  paramObject   as longchar,
                                  input  forceCreate   as logical,
                                  output resultMessage as character,
                                  output resultCode    as integer ):
        define variable cCurrentTable  as character no-undo.
        define variable cDatabaseName  as character no-undo.
        define variable cEntityName    as character no-undo.
        define variable cEntityTable   as character no-undo.
        define variable cTemplateID    as character no-undo.
        define variable cTemplateLabel as character no-undo.
        define variable cMasterKey     as character no-undo.
        define variable cDetailKey     as character no-undo.
        define variable cFileList      as character no-undo.
        define variable cMenuFile      as character no-undo.
        define variable cMenuName      as character no-undo.
        define variable cSPAType       as character no-undo.
        define variable cSPAURL        as character no-undo.
        define variable iX             as integer   no-undo.
        define variable oMenuData      as JsonArray no-undo.
        define variable oMenuItems     as JsonArray no-undo.
        define variable lcParams       as longchar  no-undo.

        /* Clear the temp-table. */
        empty temp-table ttParam.

        assign
            cMenuName = ""
            cSPAType  = ""
            cSPAURL   = ""
            .

        /* Obtain parameters supplied by the user (wizard interface). */
        if (paramObject gt "") eq true then do on error undo, throw:
            define variable oParser as ObjectModelParser no-undo.
            define variable oParams as JsonObject        no-undo.
            define variable oValues as JsonArray         no-undo.
            define variable cNames  as character extent  no-undo.
            define variable cValues as character         no-undo.
            define variable cFiles  as character         no-undo.
            define variable iCount  as integer           no-undo.
            define variable iParam  as integer           no-undo.

            /* Parse params object from client and get list of properties. */
            assign oParser = new ObjectModelParser().
            assign oParams = cast(oParser:Parse(paramObject), JsonObject).
            assign cNames = oParams:GetNames().

            do iParam = 1 to extent(cNames):
                /* Set ttParam table entries from object properties. */
                if oParams:GetType(cNames[iParam]) eq JsonDataType:array then do:
                    assign
                        cValues = "" /* Reset on each property. */
                        oValues = oParams:GetJsonArray(cNames[iParam])
                        .
                    do iCount = 1 to oValues:length:
                        assign cValues = substitute("&1,&2", cValues, oValues:GetCharacter(iCount)).
                    end.
                    setParam(cNames[iParam], trim(cValues, ",")).
                end.
                else
                    setParam(cNames[iParam], oParams:GetCharacter(cNames[iParam])).
            end. /* param extent */

            finally:
                delete object oParser no-error.
                delete object oParams no-error.
            end finally.
        end. /* paramObject */

        /* Get the selected template name. */
        assign cTemplateID = getParam("ipTemplateName").
        find first Template no-lock
             where Template.TemplateID eq cTemplateID no-error.

        if (getParam("ipMetadata") gt "") eq true then do:
            /* Import existing metadata (params) and set local vars as needed. */
            importConfig(getParam("ipMetadata")).
            assign cEntityName = getParam("ipEntityName").
        end. /* From Metadata */
        else do:
            /* Provide defaults for several parameters not set via direct user input. */
            setParam("ipNamespace", cNamespace).
            setParam("ipBEInputFolder", cBEInputFolder).
            setParam("ipUIInputFolder", cUIInputFolder + (if available(Template) then Template.TemplatePath else "")).
            setParam("ipBEOutputFolder", cBEOutputFolder).
            setParam("ipBECommonFolder", cBECommonFolder).
            setParam("ipUIOutputFolder", cUIOutputFolder).
            for first GeneralParam no-lock:
                setParam("ipBEMasterTemplateName", GeneralParam.BusinessEntity).
                setParam("ipBEDetailTemplateName", GeneralParam.BusinessEntity).
            end.
            setParam("ipRecordIdField", cIdProperty).
            setParam("ipInheritedEntity", cInheritedBE).
            setParam("ipCatalogURI", "/web/pdo").
            setParam("ipJFPSupport", string(lUseJFP, "true/false")).
            setParam("ipGenAuthor", "Code Wizard").
            setParam("ipGenDate", string(today)).
            setParam("ipProjectName", cProjectName).

            assign cEntityName = getParam("ipEntityName").
            if (cEntityName gt "") ne true then do:
                /* The master table is the default entity name. */
                assign cEntityName = getParam("ipMasterTable").
                setParam("ipEntityName", cEntityName).
            end.

            /* Use the entity name as the master resource name. */
            if getParam("ipDataSource") ne "ProDataset" and
              (getParam("ipResourceMaster") gt "") ne true then
                setParam("ipResourceMaster", lc(cEntityName)).

            /* Obtain current menu data. */
            assign oMenuData = genMenu(output cMenuFile).

            /* Set the generation type as based on the template. */
            for first Template no-lock
                where Template.TemplateID eq cTemplateID:
                setParam("ipOption", Template.EntityType).
                setParam("ipUIOutputFilename", replace(Template.NameTemplate, "[PREFIX]", cEntityName)).
                setParam("ipUseSPA", trim(string(Template.IsSPA, "true/false"))).

                /* Remember certain values for SPA screens. */
                if Template.IsSPA then do:
                    setParam("ipSPAType", Template.RoleSPA).
                    assign cSPAType = Template.RoleSPA.
                    if Template.RoleSPA gt "" and Template.RoleSPA ne "Landing" then do:
                        setParam("ipControllerSPA", replace(Template.NameTemplate, "[PREFIX]", cEntityName)).
                        if (getParam("ipDetailTable") gt "") eq true then
                            assign cMenuName = (if getParam("ipMasterTable") begins "tt" then substring(getParam("ipMasterTable"), 3) else getParam("ipMasterTable"))
                                             + "/"
                                             + (if getParam("ipDetailTable") begins "tt" then substring(getParam("ipDetailTable"), 3) else getParam("ipDetailTable"))
                                             .
                        else
                            assign cMenuName = cEntityName.
                        assign cMenuName = cMenuName + " " + replace(Template.TemplateLabel, " (SPA)", "").
                        assign cTemplateLabel = replace(Template.TemplateLabel, " (SPA)", "").
                        assign cSPAURL = "#/" + getParam("ipUIOutputFilename").
                    end.
                end.
                else
                    setParam("ipSPAType", ""). /* Ensure value is blank for non-SPA. */

                /* Handle special relations based on master/detail selection. */
                if Template.HasRelation then do:
                    /* Join the selected fields as a comma-delimited pair. */
                    assign cMasterKey = getParam("ipMasterKey").
                    assign cDetailKey = getParam("ipDetailKey").
                    setParam("ipMasterDetailJoin", substitute("&1,&2", cMasterKey, cDetailKey)).
                end.
                else
                    setParam("ipMasterDetailJoin", ""). /* Ensure value is blank for non-related tables. */
            end. /* Template */

            /* Set correct search field param when present. */
            if (getParam("ipSearchField") gt "") eq true then
                setParam("ipSearchField1", getParam("ipSearchField")).

            /* Obtain only the prime index fields for this table. */
            assign cDatabaseName = getParam("ipDatabase").
            if (cDatabaseName gt "") eq true and (getParam("ipMasterTable") gt "") eq true then
                setParam("ipSkipListArray", getKeys(cDatabaseName, getParam("ipMasterTable"), true)).
        end. /* Not From Metadata */

        /* Generate whatever needs to be generated from templates. */
        if getParam("ipGenBE") begins "BE" then do:
            /* Repeat CRUD-BE generation for all tables. */
            setParam("ipOption", "CRUD").
            assign cEntityTable = getParam("ipEntityTable").

            if (cDatabaseName gt "") eq true then do:
                case getParam("ipDataSource"):
                    when "Database Table" then do:
                        /* Use all tables if database selected, but no tables selected. */
                        if (cEntityTable gt "") ne true then do:
                            /* Use existing method to return a list of available tables for database. */
                            GetTables ( input  cDatabaseName,
                                        output table ttSchema by-reference ).

                            for each ttSchema no-lock: /* Add all tables when list is blank. */
                                assign cEntityTable = trim(substitute("&1,&2", cEntityTable, ttSchema.tableName), ",").
                            end.
                        end. /* Blank cEntityTable */

                        /* Run the template creator on each table using the parameters given. */
                        do iX = 1 to num-entries(cEntityTable):
                            assign cCurrentTable = entry(iX, cEntityTable).
                            setParam("ipEntityName", cCurrentTable).
                            setParam("ipMasterTable", cCurrentTable).
                            setParam("ipSkipListArray", getKeys(cDatabaseName, cCurrentTable, true)).
                            setParam("ipInvokeDSName", substitute("ds&1", replace(cCurrentTable, "-", ""))).
                            setParam("ipSaveConfigFile", right-trim(cMetadataOutput, "/") + "/" + cCurrentTable + "EntityConfig.json").
                            temp-table ttParam:write-json("longchar", lcParams). /* Retain param data for later. */
                            run Generator/Common/CrtTemplate.p (input table ttParam by-reference, input forceCreate, output cFileList).
                            temp-table ttParam:read-json("longchar", lcParams). /* Restore param data to table. */
                            assign cFiles = trim(substitute("&1,&2", cFiles, cFileList), ",").
                        end. /* do iX cEntityTable */
                    end. /* Database Table */

                    when "ProDataset" then do:
                        /* Run the template creator on first table using the parameters given. */
                        assign cCurrentTable = entry(1, cEntityTable).
                        setParam("ipMasterTable", cCurrentTable).
                        setParam("ipSkipListArray", getKeys(cDatabaseName, cCurrentTable, true)).
                        setParam("ipSaveConfigFile", right-trim(cMetadataOutput, "/") + "/" + cCurrentTable + "EntityConfig.json").
                        temp-table ttParam:write-json("longchar", lcParams). /* Retain param data for later. */
                        run Generator/Common/CrtTemplate.p (input table ttParam by-reference, input forceCreate, output cFileList).
                        temp-table ttParam:read-json("longchar", lcParams). /* Restore param data to table. */
                        assign cFiles = trim(substitute("&1,&2", cFiles, cFileList), ",").
                    end. /* ProDataset */
                end case.

                assign resultMessage = "Files generated successfully, check output in expected locations:<br/>&bull;&nbsp;" + replace(cFiles, ",", "<br/>&bull;&nbsp;").
                assign resultMessage = resultMessage + "<br/>Next, refresh your project and republish to Tomcat before creating UI screens.".
            end. /* cDatabaseName */
            else
                assign resultMessage = "No database selected, unable to generate business entity class(es).".
        end. /* BE Only */
        else do:
            /* Set the save path if using a template (not applicable for BE-only generation). */
            if (cTemplateID gt "") eq true then
                setParam("ipSaveConfigFile", right-trim(cMetadataOutput, "/") + "/" + cEntityName + replace(cTemplateID, "Template", "") + "Config.json").
            else
                setParam("ipSaveConfigFile", right-trim(cMetadataOutput, "/") + "/" + cEntityName + "EntityConfig.json").

            /* Run for just a single table. */
            run Generator/Common/CrtTemplate.p (input table ttParam by-reference, input forceCreate, output cFileList).
            assign resultMessage = "Files generated successfully, check output in expected locations:<br/>&bull;&nbsp;" + replace(cFileList, ",", "<br/>&bull;&nbsp;").

            /* Export any existing menu data to file. */
            if valid-object(oMenuData) and oMenuData:Length gt 0 then do:
                if (cSPAType gt "") eq true then do:
                    define variable oNewItem as JsonObject no-undo.

                    /* Determine if new menu entry should be added. */
                    oMenuItems = getMenuItems(oMenuData, cSPAType).
                    if not hasMenuItem(oMenuItems, cMenuName) then do:
                        oNewItem = new JsonObject().
                        oNewItem:Add("text", cMenuName).
                        oNewItem:Add("url", cSPAURL).
                        oMenuItems:Add(oNewItem).
                    end.
                end.

                /* Write menu data back to the correct file. */
                if (cMenuFile gt "") eq true then do:
                    oMenuData:WriteFile(cMenuFile, true).
                    assign resultMessage = resultMessage + "<br/>Note: Menu data has been updated at " + cMenuFile.
                end.
            end. /* oMenuData */
        end. /* UI Only */

        catch err as Progress.Lang.Error:
    		assign
    		  resultMessage = substitute("Error: &1", err:GetMessage(1))
    		  resultCode    = err:GetMessageNum(1)
    		  .
        end catch.
    end method. /* Generate */

end class.
