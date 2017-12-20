/*------------------------------------------------------------------------
    File        : CrtTemplate
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Jagdish Pai and Dustin Grau
    Created     : Tue Sep 22 10:51:12 EDT 2015
    Notes       : Program to create BE and UI code using templates
  ----------------------------------------------------------------------*/

&global-define tab chr(9)
&global-define newline chr(13)
&global-define sequence_field seq
&global-define dirslash ~/
&global-define view_out app~/views~/

using Progress.Lang.*.
using OpenEdge.DataAdmin.* from propath.
using OpenEdge.DataAdmin.Error.* from propath.
using OpenEdge.DataAdmin.Lang.Collections.* from propath.
using Progress.Json.ObjectModel.*.

block-level on error undo, throw.

define temp-table ttParam before-table bttParam
    field ttName  as character
    field ttValue as character
    index IdxMain ttName.

define temp-table ttParamOld like ttParam.

/* File Parameters */
define input  parameter table for ttParam.
define input  parameter plForceCreate as logical no-undo.
define output parameter pcCreateList  as character no-undo.

/* Common Parameters */
define variable ipBEInputFolder        as character no-undo.
define variable ipUIInputFolder        as character no-undo.
define variable ipBEOutputFolder       as character no-undo.
define variable ipBECommonFolder       as character no-undo.
define variable ipUIOutputFolder       as character no-undo.
define variable ipBEOutputFilename     as character no-undo.
define variable ipUIOutputFilename     as character no-undo.
define variable ipBEMasterTemplateName as character no-undo.
define variable ipBEDetailTemplateName as character no-undo.
define variable ipCatalogURI           as character no-undo.
define variable ipCSSFile              as character no-undo.
define variable ipDataSource           as character no-undo.
define variable ipEntityName           as character no-undo.
define variable ipResourceMaster       as character no-undo.
define variable ipResourceDetail       as character no-undo.
define variable ipGenBE                as character no-undo.
define variable ipGenAuthor            as character no-undo.
define variable ipGenDate              as character no-undo.
define variable ipNamespace            as character no-undo.
define variable ipOption               as character no-undo.
define variable ipOutFile              as character no-undo.
define variable ipProjectName          as character no-undo.
define variable ipSaveConfigFile       as character no-undo.
define variable ipServiceURI           as character no-undo.
define variable ipBEFileChecksum       as character no-undo.
define variable ipSchemaChecksum       as character no-undo.
define variable ipUIFileChecksum       as character no-undo.
define variable ipControllerChecksum   as character no-undo.

/* CRUD Parameters */
define variable ipJFPSupport           as character no-undo.
define variable ipDatabase             as character no-undo.
define variable ipMasterTable          as character no-undo.
define variable ipDetailTable          as character no-undo.
define variable ipMasterFields         as character no-undo.
define variable ipMasterFieldsRaw      as character no-undo.
define variable ipDetailFields         as character no-undo.
define variable ipDetailFieldsRaw      as character no-undo.
define variable ipMasterDetailJoin     as character no-undo.
define variable ipSelFields            as character no-undo.
define variable ipSkipListArray        as character no-undo.
define variable ipTemplateName         as character no-undo.
define variable ipRecordIdField        as character no-undo.
define variable ipInheritedEntity      as character no-undo.

/* Invoke Parameters */
define variable ipInvokeDSName         as character no-undo.
define variable ipInvokeTTName         as character no-undo.
define variable ipSearchField1         as character no-undo.
define variable ipSearchField2         as character no-undo.
define variable ipSearchField3         as character no-undo.
define variable ipTTDefFileName        as character no-undo.

/* SPA Options */
define variable ipControllerSPA        as character no-undo.
define variable ipUseSPA               as character no-undo.

/* ADM/SDO Parameters */
define variable ipMasterSDONames       as character no-undo.
define variable ipDetailSDONames       as character no-undo.

/* Local Variables */
define variable oMasterFields    as JsonObject no-undo.
define variable oDetailFields    as JsonObject no-undo.
define variable cTTName          as character  no-undo.
define variable cGridAPI         as character  no-undo initial "GetGridData".
define variable cSchemaFile      as character  no-undo.
define variable cInputUITemplate as character  no-undo.
define variable cServiceName     as character  no-undo.
define variable cLine            as character  no-undo.
define variable iLine            as integer    no-undo.
define variable ix               as integer    no-undo.
define variable iFieldCount      as integer    no-undo initial 0.
define variable lHasRelation     as logical    no-undo.

define temp-table ttField no-undo
    field ttTableName     as character
    field ttSequence      as integer
    field ttSelectOrder   as integer
    field ttName          as character
    field ttNameAlt       as character
    field ttFieldType     as character
    field ttFieldDataType as character
    field ttDecimals      as integer
    field ttLabel         as character
    field ttWidth         as character
    field ttRec           as character
    field ttExtent        as integer
    index idxMain ttSequence.

define temp-table ttData no-undo
    field ttLineNum as integer
    field ttLine    as character
    index idxMain ttLineNum.


/************************* Functions *************************/

function fixDirPath returns character ( input pcPath as character ):
    assign pcPath = replace(pcPath, "~\", "{&dirslash}").
    assign pcPath = right-trim(pcPath, "{&dirslash}") + "{&dirslash}".
    return pcPath.
end function. /* fixDirPath */


function getParamValue returns character ( input pcName as character ):
    /* Extract param value from temp-table. */
    find first ttParam no-lock where ttParam.ttName = pcName no-error.
    if available ttParam then
        return ttParam.ttValue.
    else
        return "".
end function. /* getParamValue */


function getOldParamValue returns character ( input pcName as character ):
    /* Extract param value from temp-table. */
    find first ttParamOld no-lock where ttParamOld.ttName = pcName no-error.
    if available ttParamOld then
        return ttParamOld.ttValue.
    else
        return "".
end function. /* getOldParamValue */


function addLine returns logical ( input pcLine as character ):
    if pcLine eq "" then
        assign pcLine = " ".

    assign iLine = iLine + 1.

    create ttData.
    assign
        ttData.ttLineNum = iLine
        ttData.ttLine    = pcLine
        .
    release ttData.

    return true.
end function. /* addLine */


function checkDefaults returns logical ( ):
    /* Set defaults for critical parameters. */

    if (ipUIOutputFolder gt "") eq true then
        assign ipUIOutputFolder = fixDirPath(ipUIOutputFolder).
    else /* Cannot continue without output folder! */
        undo, throw new AppError("UI output folder was not specified.", -404).

    /* Use input folder if specified, otherwise same as output. */
    if (ipUIInputFolder gt "") eq true then
        assign ipUIInputFolder = fixDirPath(ipUIInputFolder).
    else
        assign ipUIInputFolder = ipUIOutputFolder.

    if (ipBEOutputFolder gt "") eq true then
        assign ipBEOutputFolder = fixDirPath(ipBEOutputFolder).
    else /* Cannot continue without output folder! */
        undo, throw new AppError("BE output folder was not specified.", -404).

    if (ipBECommonFolder gt "") eq true then
        assign ipBECommonFolder = fixDirPath(ipBECommonFolder).

    /* Use input folder if specified, otherwise same as output. */
    if (ipBEInputFolder gt "") eq true then
        assign ipBEInputFolder = fixDirPath(ipBEInputFolder).
    else
        assign ipBEInputFolder = ipBEOutputFolder.

    if ipGenBE begins "BE" or (ipInvokeDSName gt "") eq true or (ipInvokeTTName gt "") eq true then do:
        if ipServiceURI begins "/web/pdo" and
           num-entries(ipServiceURI, "/") ge 4 then do:
            /* Extend the existing class namespace with the newly-derived service directory. */
            assign cServiceName = entry(4, ipServiceURI, "/").
            if cServiceName ne "common" then do:
                /* Only adjust service/namespace for cases other than the default of "common". */
                assign cServiceName = caps(substring(cServiceName, 1, 1)) + lc(substring(cServiceName, 2)).
                assign ipNamespace = ipNamespace + cServiceName + ".".
            end.
            else
                assign cServiceName = "". /* Place "common" files in the business logic root. */
        end. /* ipServiceURI */

        if (cServiceName gt "") eq true then
            assign ipBEOutputFolder = fixDirPath(ipBEOutputFolder + cServiceName).

        if (ipBEMasterTemplateName gt "") ne true then
            assign ipBEMasterTemplateName = "TemplateBE.cls".

        if (ipBEDetailTemplateName gt "") ne true then
            assign ipBEDetailTemplateName = "TemplateBE.cls".

        if (ipBEOutputFilename gt "") eq true then
            assign ipBEOutputFilename = replace(ipBEOutputFilename, ".cls", "") + "BE.cls".
        else
            assign ipBEOutputFilename = replace(ipEntityName, "-", "") + "BE.cls".

        if (ipRecordIdField gt "") ne true then
            assign ipRecordIdField = "id".

        if (ipInheritedEntity gt "") ne true then
            assign ipInheritedEntity = "Common.ApplicationBE".

        if (ipInvokeDSName gt "") ne true then
            assign ipInvokeDSName = substitute("ds&1", replace(ipEntityName, "-", "")).
    end. /* BE Generation Only */
    else do:
        if (ipServiceURI gt "") ne true then
            assign
                ipServiceURI   = "/"
                ipInvokeDSName = substitute("ds&1", replace(ipEntityName, "-", ""))
                .
    end. /* UI Generation Only */

    if (ipCSSFile gt "") ne true then
        assign ipCSSFile = "app.css".

    if (ipUIOutputFilename gt "") eq true then
        assign ipUIOutputFilename = replace(ipUIOutputFilename, ".html", "") + ".html".

    if (ipControllerSPA gt "") eq true then
        assign ipControllerSPA = replace(ipControllerSPA, ".js", "") + ".js".

    if (ipSaveConfigFile gt "") ne true then
        assign ipSaveConfigFile = ipUIOutputFolder + ipEntityName + "Config.json".

    if (ipBEFileChecksum gt "") ne true then
        assign ipBEFileChecksum = getOldParamValue("ipBEFileChecksum").

    if (ipSchemaChecksum gt "") ne true then
        assign ipSchemaChecksum = getOldParamValue("ipSchemaChecksum").

    if (ipUIFileChecksum gt "") ne true then
        assign ipUIFileChecksum = getOldParamValue("ipUIFileChecksum").

    if (ipControllerChecksum gt "") ne true then
        assign ipControllerChecksum = getOldParamValue("ipControllerChecksum").

    if (ipResourceMaster gt "") ne true then
        assign ipResourceMaster = lc(ipEntityName).

    return true.
end function. /* checkDefaults */


function exportConfig returns logical ( ):
    /* Export parameters as JSON object file. */
    if (ipSaveConfigFile gt "") eq true then do:
        define variable oConfig as JsonObject no-undo.
        assign oConfig = new JsonObject().

        /* Common */
        oConfig:Add("ipBEInputFolder", ipBEInputFolder).
        oConfig:Add("ipUIInputFolder", ipUIInputFolder).
        oConfig:Add("ipBEOutputFolder", ipBEOutputFolder).
        oConfig:Add("ipBECommonFolder", ipBECommonFolder).
        oConfig:Add("ipUIOutputFolder", ipUIOutputFolder).
        oConfig:Add("ipBEOutputFilename", ipBEOutputFilename).
        oConfig:Add("ipUIOutputFilename", ipUIOutputFilename).
        oConfig:Add("ipCatalogURI", ipCatalogURI).
        oConfig:Add("ipCSSFile", ipCSSFile).
        oConfig:Add("ipDataSource", ipDataSource).
        oConfig:Add("ipEntityName", ipEntityName).
        oConfig:Add("ipResourceMaster", ipResourceMaster).
        oConfig:Add("ipResourceDetail", ipResourceDetail).
        oConfig:Add("ipGenBE", ipGenBE).
        oConfig:Add("ipGenAuthor", ipGenAuthor).
        oConfig:Add("ipGenDate", ipGenDate).
        oConfig:Add("ipNamespace", ipNamespace).
        oConfig:Add("ipOption", ipOption).
        oConfig:Add("ipOutFile", ipOutFile).
        oConfig:Add("ipProjectName", ipProjectName).
        oConfig:Add("ipSaveConfigFile", ipSaveConfigFile).
        oConfig:Add("ipServiceURI", ipServiceURI).
        oConfig:Add("ipBEFileChecksum", ipBEFileChecksum).
        oConfig:Add("ipSchemaChecksum", ipSchemaChecksum).
        oConfig:Add("ipUIFileChecksum", ipUIFileChecksum).
        oConfig:Add("ipControllerChecksum", ipControllerChecksum).

        /* CRUD */
        oConfig:Add("ipJFPSupport", ipJFPSupport).
        oConfig:Add("ipDatabase", ipDatabase).
        oConfig:Add("ipMasterTable", ipMasterTable).
        oConfig:Add("ipDetailTable", ipDetailTable).
        oConfig:Add("ipMasterFields", ipMasterFields).
        oConfig:Add("ipMasterFieldsRaw", ipMasterFieldsRaw).
        oConfig:Add("ipDetailFields", ipDetailFields).
        oConfig:Add("ipDetailFieldsRaw", ipDetailFieldsRaw).
        oConfig:Add("ipMasterDetailJoin", ipMasterDetailJoin).
        oConfig:Add("ipSkipListArray", ipSkipListArray).
        oConfig:Add("ipTemplateName", ipTemplateName).
        oConfig:Add("ipRecordIdField", ipRecordIdField).
        oConfig:Add("ipInheritedEntity", ipInheritedEntity).

        /* Invoke */
        oConfig:Add("ipInvokeDSName", ipInvokeDSName).
        oConfig:Add("ipInvokeTTName", ipInvokeTTName).
        oConfig:Add("ipSearchField1", ipSearchField1).
        oConfig:Add("ipSearchField2", ipSearchField2).
        oConfig:Add("ipSearchField3", ipSearchField3).
        oConfig:Add("ipTTDefFileName", ipTTDefFileName).

        /* SPA */
        oConfig:Add("ipControllerSPA", ipControllerSPA).
        oConfig:Add("ipUseSPA", ipUseSPA).

        /* ADM/SDO */
        oConfig:Add("ipBEMasterTemplateName", ipBEMasterTemplateName).
        oConfig:Add("ipBEDetailTemplateName", ipBEDetailTemplateName).
        oConfig:Add("ipMasterSDONames", ipMasterSDONames).
        oConfig:Add("ipDetailSDONames", ipDetailSDONames).

        /* Exports JSON object directly to file. */
        oConfig:WriteFile(ipSaveConfigFile, true).

        return true.
    end.

    return false.
end function. /* exportConfig */


function fileExists returns logical ( input pcFilePath as character ):
    if (pcFilePath gt "") ne true then
        undo, throw new AppError("Filename unavailable.", -404).

    /* Check if file exists by use of file-info. */
    file-info:file-name = pcFilePath.
    return (file-info:full-pathname ne ?) eq true.
end function. /* fileExists */


function getMD5 returns character ( input pcFilePath as character ):
    define variable mContent as memptr no-undo.
    define variable rDigest  as raw    no-undo.

    /* Import the entire file to a longchar value for MD5 digest. */
    copy-lob from file pcFilePath to mContent no-convert no-error.
    assign rDigest = md5-digest(mContent) no-error.

    return string(hex-encode(rDigest)).
end function. /* getMD5 */


function importFile returns logical ( input pcFilePath as character ):
    define variable cImportLine as character no-undo.

    /* Reset Values */
    assign iLine = 0.
    empty temp-table ttData.

    /* Import each line from the file and add to ttData. */
    input from value(pcFilePath).
    repeat while true:
        import unformatted cImportLine.
        addLine(cImportLine).
    end. /* repeat */

    return can-find(first ttData).
end function. /* importFile */


function matchesMD5 returns logical ( input pcFilePath as character,
                                      input pcOldMD5   as character ):
    if not fileExists(pcFilePath) then return true. /* No file, continue. */

    /* Should return true if matches, otherwise false. */
    return (getMD5(pcFilePath) eq pcOldMD5).
end function. /* matchesMD5 */


function outputFile returns logical ( input pcFilePath as character ):
    if (pcFilePath gt "") ne true then
        undo, throw new AppError("Filename unavailable.", -404).

    os-create-dir value(ipBEOutputFolder).
    /**
     * Typical Responses:
     * 0 = No Error
     * 1 = Not Owner
     * 2 = No Such File/Directory
     */
    if not pcFilePath begins "~\~\" and os-error ne 0 then
        return false. /* Fail here only if not UNC path. */

    /* Export each line of ttData table to target file. */
    output to value(pcFilePath).
    for each ttData:
        put unformatted ttData.ttLine skip.
    end.
    output close.

    /* Add to list of files created by output operation. */
    assign pcCreateList = trim(substitute("&1,&2", pcCreateList, pcFilePath), ",").

    return true.
end function. /* outputFile */


function canCreateFile returns logical ( input pcFilePath as character,
                                         input pcFileType as character ):
    define variable cOldMD5 as character no-undo.

    /* If existing file is not present, continue. */
    if not fileExists(pcFilePath) then return true.

    /* Otherwise assume file exists, so check if MD5 is present. */
    case pcFileType:
        when "Entity" then
            assign cOldMD5 = getOldParamValue("ipBEFileChecksum").
        when "Schema" then
            assign cOldMD5 = getOldParamValue("ipSchemaChecksum").
        when "Screen" then
            assign cOldMD5 = getOldParamValue("ipUIFileChecksum").
        when "Controller" then
            assign cOldMD5 = getOldParamValue("ipControllerChecksum").
        otherwise
            assign cOldMD5 = "".
    end.

    /* File present but no MD5 exists, return status of overwrite flag. */
    if cOldMD5 eq "" then return plForceCreate.

    /* Same MD5 indicates file was not changed since last generation from template. */
    if matchesMD5(pcFilePath, cOldMD5) then return true.

    /* Otherwise file present, MD5 does not match, return overwrite flag. */
    return plForceCreate.
end function. /* canCreateUI */


function pad returns character ( input piLength as integer ):
    return fill(" ", piLength). /* Return space-padded string of N length. */
end function. /* pad */


function replaceCommonTokens returns character ( input pcLineText as character ):
    assign pcLineText = replace(pcLineText, "<Spark_CodePath>", replace(ipNamespace, ".", "{&dirslash}")).
    assign pcLineText = replace(pcLineText, "<Spark_Namespace>", ipNamespace).
    assign pcLineText = replace(pcLineText, "<Spark_CatalogURI>", ipCatalogURI).
    assign pcLineText = replace(pcLineText, "<Spark_ServiceURI>", ipServiceURI).
    assign pcLineText = replace(pcLineText, "<Spark_GenAuthor>", ipGenAuthor).
    assign pcLineText = replace(pcLineText, "<Spark_GenDate>", ipGenDate).
    assign pcLineText = replace(pcLineText, "<Spark_CSSFile>", ipCSSFile).
    assign pcLineText = replace(pcLineText, "<Spark_ProjectName>", ipProjectName).
    return pcLineText.
end function. /* replaceCommonTokens */


function setSchemaFile returns character ( input pcTableName as character ):
    define variable cDir as character no-undo.
    define variable iCnt as integer   no-undo.

    assign iCnt = num-entries(ipBECommonFolder, "{&dirslash}").
    assign cDir = entry(iCnt - 1, ipBECommonFolder, "{&dirslash}").
    return substitute("&1{&dirslash}&2.i", cDir, lc(replace(pcTableName, "-", ""))).
end function. /* setSchemaFile */


function createGridFields returns character ( input pcTableName as character ):
    define variable cFieldList as character no-undo.

    for each ttField
       where ttField.ttTableName eq pcTableName
         and ttField.ttFieldType eq "Field"
         and ttField.ttSelectOrder gt 0
       break by ttField.ttSelectOrder:
        assign cFieldList = cFieldList + (if first(ttField.ttSelectOrder) then '' else pad(1))
                          + '~{' + {&newline}
                          + pad(12) + 'field: "' + ttField.ttNameAlt  + '", ' + {&newline}
                          + (if can-do("decimal,integer", ttField.ttFieldDataType) then
                              pad(12) + 'attributes: ~{class: "numbers"~},' + {&newline} else "")
                          + (if ttField.ttFieldDataType eq "decimal" then
                              pad(12) + substitute('template: "#=kendo.toString(&1, ~'n&2~')#",', ttField.ttNameAlt, ttField.ttDecimals) + {&newline} else "")
                          + (if ttField.ttFieldDataType eq "integer" then
                              pad(12) + substitute('template: "#=kendo.toString(&1, ~'n0~')#",', ttField.ttNameAlt) + {&newline} else "")
                          + (if ttField.ttFieldDataType eq "date" then
                              pad(12) + substitute('template: "#=kendo.toString(kendo.parseDate(&1, ~'yyyy-MM-dd~'), ~'MM/dd/yyyy~')#",', ttField.ttNameAlt) + {&newline} else "")
                          + pad(12) + 'title: "' + ttField.ttLabel + '",' + {&newline}
                          + pad(12) + (if can-do("decimal,integer", ttField.ttFieldDataType) then 'width: 120' else 'width: 150') + {&newline}
                          + pad(8) + '~}'
                          + (if not last(ttField.ttSelectOrder) then ',' else ',')
                            .
    end. /* ttField */

    return trim(cFieldList, ",").
end function. /* createGridFields */


function createFormFields returns character ( input pcTableName as character,
                                              input piColumns   as integer ):
    define variable cFieldList  as character no-undo.
    define variable cLabelTmpl  as character no-undo.
    define variable cFieldTmpl  as character no-undo.
    define variable cTempString as character no-undo.
    define variable iColCount   as integer   no-undo initial 1.
    define variable iPerColumn  as integer   no-undo.
    define variable iTotalField as integer   no-undo initial 0.
    define variable iFieldCount as integer   no-undo initial 0.

    /* Create templates for label and input lines. */
    assign cLabelTmpl = {&tab} + {&tab} + {&tab} + {&tab} + '<label for="<Spark_FieldName>"><Spark_FieldName></label>' + {&newline}.
    assign cFieldTmpl = {&tab} + {&tab} + {&tab} + {&tab} + '<input type="text" class="form-control m-b" name="<Spark_FieldName>" '
                      + 'placeholder="<Spark_FieldLabel>" data-bind="value:selectedRow.<Spark_FieldName>"/>' + {&newline}
                      .

    assign cFieldList = "<!-- Begin generated field output. -->" + {&newline}
                      + {&tab} + {&tab} + '<div class="col-xs-6">' + {&newline}
                      + {&tab} + {&tab} + {&tab} + '<fieldset>' + {&newline}
                      + {&tab} + {&tab} + {&tab} + {&tab} + '<legend class="text-lg">Column 1</legend>'
                      + {&newline}
                      .

    for each ttField
       where ttField.ttTableName eq pcTableName
         and ttField.ttFieldType eq "Field"
         and ttField.ttSelectOrder gt 0:
        assign iTotalField = iTotalField + 1.
    end.

    if piColumns gt 1 then
        assign
            iPerColumn  = round(iTotalField / piColumns, 0)
            iFieldCount = 0
            .

    for each ttField
       where ttField.ttTableName eq pcTableName
         and ttField.ttFieldType eq "Field"
         and ttField.ttSelectOrder gt 0
          by ttField.ttSelectOrder:
        /* Add the new label/field line and substitute as needed. */
        assign iFieldCount = iFieldCount + 1.
        assign cTempString = cLabelTmpl + cFieldTmpl.
        assign cTempString = replace(cTempString, "<Spark_FieldLabel>", ttField.ttLabel).
        assign cTempString = replace(cTempString, "<Spark_FieldName>", ttField.ttNameAlt).
        assign cFieldList = cFieldList + cTempString.

        /* Determine if a new columns must be started. */
        if piColumns gt 1 and iFieldCount eq iPerColumn then do:
            if (iColCount * iFieldCount) ge iTotalField then leave.
            assign
                iColCount   = iColCount + 1
                iFieldCount = 0
                .
            assign cFieldList = cFieldList
                              + {&tab} + {&tab} + {&tab} + "</fieldset>" + {&newline}
                              + {&tab} + {&tab} + "</div>" + {&newline}
                              + {&tab} + {&tab} + '<div class="col-xs-6">' + {&newline}
                              + {&tab} + {&tab} + {&tab} + "<fieldset>" + {&newline}
                              + {&tab} + {&tab} + {&tab} + {&tab} + '<legend class="text-lg">Column ' + string(iColCount) + '</legend>'
                              + {&newline}
                              .
        end. /* end/start column */
    end. /* for each */

    assign cFieldList = cFieldList + {&tab} + {&tab} + {&tab} + "</fieldset>"
                      + {&newline} + {&tab} + {&tab} + "</div>" + {&newline}
                      + {&tab} + {&tab} + "<!-- End generated field content. -->" + {&newline}
                      .

    return cFieldList.
end function. /* createGridFields */


function getFieldOper returns character ( input pcFieldName as character ):
    find first ttField
         where ttField.ttName eq pcFieldName
            or ttField.ttNameAlt eq pcFieldName no-error.
    if available(ttField) then
        return (if ttField.ttFieldDataType eq "character" then "startswith" else "equals").

    return "equals".
end function. /* getFieldOper */


function getFieldLabel returns character ( input pcFieldName as character ):
    find first ttField
         where ttField.ttName eq pcFieldName
            or ttField.ttNameAlt eq pcFieldName no-error.
    if available(ttField) then
        return replace(ttField.ttLabel, "_", " ").

    return pcFieldName.
end function. /* getFieldLabel */


function GenCRUDBE returns logical ( input pcEntityName   as character,
                                     input pcTableName    as character,
                                     input pcTemplatePath as character,
                                     input pcSDONames     as character ):
    importFile(pcTemplatePath).

    /* If given a temp-table name, strip the "tt" prefix. */
    if pcTableName begins "tt" then
        assign pcTableName = substring(pcTableName, 3).

    for each ttData:
        assign ttData.ttLine = replaceCommonTokens(ttData.ttLine).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_EntityName>", replace(pcEntityName, "-", "")).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_ResourceName>", lc(replace(pcEntityName, "-", ""))).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterTable>", pcTableName).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DatasetName>", ipInvokeDSName).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_InheritedEntity>", ipInheritedEntity).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SchemaFile>", cSchemaFile).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SkipListArray>", ipSkipListArray).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SDONames>", pcSDONames).
    end.

    if canCreateFile(ipBEOutputFolder + ipBEOutputFilename, "Entity") then do:
        outputFile(ipBEOutputFolder + ipBEOutputFilename).
        assign ipBEFileChecksum = getMD5(ipBEOutputFolder + ipBEOutputFilename).
        return true.
    end.
    return false.
end function. /* GenCRUDBE */


function GenInvokeBE returns logical ( input pcTemplatePath as character ):
    importFile(pcTemplatePath).

    for each ttData:
        assign ttData.ttLine = replaceCommonTokens(ttData.ttLine).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DatasetName>", ipInvokeDSName).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_EntityName>", ipEntityName).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_ResourceName>", ipResourceMaster).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterTable>", if ipMasterTable begins "tt" then
                                                                                substring(ipMasterTable, 3) else ipMasterTable).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DetailTable>", if ipDetailTable begins "tt" then
                                                                                substring(ipDetailTable, 3) else ipDetailTable).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_InheritedEntity>", ipInheritedEntity).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SchemaFile>", cSchemaFile).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_TempTableName>", cTTName).
    end.

    if canCreateFile(ipBEOutputFolder + ipBEOutputFilename, "Entity") then do:
        outputFile(ipBEOutputFolder + ipBEOutputFilename).
        assign ipBEFileChecksum = getMD5(ipBEOutputFolder + ipBEOutputFilename).
        return true.
    end.
    return false.
end function. /* GenInvokeBE */


function GenLandingSPA returns logical ( input pcTemplatePath as character ):
    importFile(pcTemplatePath).

    for each ttData:
        assign ttData.ttLine = replaceCommonTokens(ttData.ttLine).
    end.

    if canCreateFile(ipUIOutputFolder + ipUIOutputFilename, "Screen") then do:
        outputFile(ipUIOutputFolder + ipUIOutputFilename).
        assign ipUIFileChecksum = getMD5(ipUIOutputFolder + ipUIOutputFilename).
        return true.
    end.
    return false.
end function. /* GenLandingSPA */


function GenControllerSPA returns logical ( input pcTemplatePath as character ):
    define variable cControllerPath as character no-undo.
    define variable cMasterFormFields as character no-undo.
    define variable cDetailFormFields as character no-undo.
    define variable cMasterGridFields as character no-undo.
    define variable cDetailGridFields as character no-undo.

    assign cControllerPath = replace(pcTemplatePath, ".html", ".js").
    if (ipMasterTable gt "") eq true then do:
        assign cMasterFormFields = createFormFields(ipMasterTable, 2).
        assign cMasterGridFields = createGridFields(ipMasterTable).
    end.
    if (ipDetailTable gt "") eq true then do:
        assign cDetailFormFields = createFormFields(ipDetailTable, 2).
        assign cDetailGridFields = createGridFields(ipDetailTable).
    end.

    importFile(cControllerPath).

    for each ttData:
        assign ttData.ttLine = replaceCommonTokens(ttData.ttLine).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_EntityName>", ipEntityName).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_ResourceName>", ipResourceMaster).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_TemplateName>", replace(ipUIOutputFilename, ".html", "")).

        if (ipMasterTable gt "") eq true then do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterResource>", ipResourceMaster).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterTable>", if ipMasterTable begins "tt" then
                                                                                    substring(ipMasterTable, 3) else ipMasterTable).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_FormFields>", cMasterFormFields).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_GridFields>", cMasterGridFields).
        end.
        else do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterResource>", "").
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterTable>", "").
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_FormFields>", "").
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_GridFields>", "").
        end.

        if (ipDetailTable gt "") eq true then do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DetailResource>", ipResourceDetail).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DetailTable>", if ipDetailTable begins "tt" then
                                                                                    substring(ipDetailTable, 3) else ipDetailTable).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_FormFieldsDetail>", cDetailFormFields).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_GridFieldsDetail>", cDetailGridFields).
        end.
        else do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DetailResource>", "").
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DetailTable>", "").
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_FormFieldsDetail>", "").
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_GridFieldsDetail>", "").
        end.

        if lHasRelation then do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterKey1>", entry(1, ipMasterDetailJoin)).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DetailKey1>", entry(2, ipMasterDetailJoin)).
        end.
        else do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterKey1>", "").
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DetailKey1>", "").
        end.

        if (ipSearchField1 gt "") eq true then do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SearchField1>", ipSearchField1).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SearchField1Oper>", getFieldOper(ipSearchField1)).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SearchField1Title>", getFieldLabel(ipSearchField1)).
        end.
        else do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SearchField1>", "").
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SearchField1Oper>", "").
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SearchField1Title>", "").
        end.
    end.

    if canCreateFile(ipUIOutputFolder + ipControllerSPA, "Controller") then do:
        outputFile(ipUIOutputFolder + ipControllerSPA).
        assign ipControllerChecksum = getMD5(ipUIOutputFolder + ipControllerSPA).
        return true.
    end.
    return false.
end function. /* GenControllerSPA */


function GenScreenHTML returns logical ( input pcTemplatePath as character ):
    define variable cControllerPath as character no-undo.
    define variable cMasterFormFields as character no-undo.
    define variable cDetailFormFields as character no-undo.
    define variable cMasterGridFields as character no-undo.
    define variable cDetailGridFields as character no-undo.

    if (ipMasterTable gt "") eq true then do:
        assign cMasterFormFields = createFormFields(ipMasterTable, 2).
        assign cMasterGridFields = createGridFields(ipMasterTable).
    end.
    if (ipDetailTable gt "") eq true then do:
        assign cDetailFormFields = createFormFields(ipDetailTable, 2).
        assign cDetailGridFields = createGridFields(ipDetailTable).
    end.

    importFile(pcTemplatePath).

    for each ttData:
        assign ttData.ttLine = replaceCommonTokens(ttData.ttLine).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_EntityName>", ipEntityName).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_ResourceName>", ipResourceMaster).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_TemplateName>", replace(ipUIOutputFilename, ".html", "")).
        if (ipMasterTable gt "") eq true then do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterResource>", ipResourceMaster).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterTable>", if ipMasterTable begins "tt" then
                                                                                    substring(ipMasterTable, 3) else ipMasterTable).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_FormFields>", cMasterFormFields).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_GridFields>", cMasterGridFields).
        end.
        if (ipDetailTable gt "") eq true then do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DetailResource>", ipResourceDetail).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DetailTable>", if ipDetailTable begins "tt" then
                                                                                    substring(ipDetailTable, 3) else ipDetailTable).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_FormFieldsDetail>", cDetailFormFields).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_GridFieldsDetail>", cDetailGridFields).
        end.
        if lHasRelation then do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterKey1>", entry(1, ipMasterDetailJoin)).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DetailKey1>", entry(2, ipMasterDetailJoin)).
        end.
        if (ipSearchField1 gt "") eq true then do:
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SearchField1>", ipSearchField1).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SearchField1Oper>", getFieldOper(ipSearchField1)).
            assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SearchField1Title>", getFieldLabel(ipSearchField1)).
        end.
    end.

    if canCreateFile(ipUIOutputFolder + ipUIOutputFilename, "Screen") then do:
        outputFile(ipUIOutputFolder + ipUIOutputFilename).
        assign ipUIFileChecksum = getMD5(ipUIOutputFolder + ipUIOutputFilename).
        return true.
    end.
    return false.
end function. /* GenScreenHTML */


function GenInvokeGrid returns logical ( input pcTemplatePath as character ):
    define variable cFieldList     as character  no-undo.
    define variable cSearchFields  as character no-undo.
    define variable cFieldTemplate as character no-undo.

    importFile(pcTemplatePath).

    for each ttField
       where ttField.ttFieldType eq "Field"
         and ttField.ttSelectOrder gt 0
       break by ttField.ttSelectOrder:
        if first(ttField.ttSelectOrder) then
            assign cFieldTemplate = ' , template: "<div><a href=~'' + ipEntityname + 'Form.html?action=review&id=#='
                                  + ttField.ttNameAlt + '#~'>#=' + ttField.ttNameAlt + '#</a></div>"' + {&newline}.
        else
            assign cFieldTemplate = "".

        assign cFieldList = cFieldList + (if first(ttField.ttSelectOrder) then '' else pad(21)) + '~{' + {&newline}
                          + pad(25) + ' field: "' + ttField.ttNameAlt  + '", ' + {&newline}
                          + pad(25) + ' title: "' + ttField.ttLabel + '"'  + {&newline}
                          + pad(25) + cFieldTemplate
                          + pad(21) + '~}' + (if not last(ttField.ttSelectOrder) then ',' else ',')
                            .
    end. /* for each */

    assign cFieldTemplate = '<input type="text" name="<Spark_FieldName>" class="form-control input-sm" '
                          + 'placeholder="<Spark_FieldName>" style="width:150px;" data-bind="value:params.<Spark_FieldName>"/>'.

    if ipSearchField1 ne "" then
        assign cSearchFields = cSearchFields + pad(29) + replace(cFieldTemplate, "<Spark_FieldName>", ipSearchField1) + {&newline}.
    if ipSearchField2 ne "" then
        assign cSearchFields = cSearchFields + pad(29) + replace(cFieldTemplate, "<Spark_FieldName>", ipSearchField2) + {&newline}.
    if ipSearchField3 ne "" then
        assign cSearchFields = cSearchFields + pad(29) + replace(cFieldTemplate, "<Spark_FieldName>", ipSearchField3) + {&newline}.

    for each ttData:
        assign ttData.ttLine = replaceCommonTokens(ttData.ttLine).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_DatasetName>", ipInvokeDSName).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_EntityName>", ipEntityName).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_ResourceName>", ipResourceMaster).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_TemplateName>", replace(ipUIOutputFilename, ".html", "")).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_MasterTable>", ipMasterTable).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_TempTableName>", cTTName).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_GridAPI>", cGridAPI).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_GridFields>", cFieldList).
        assign ttData.ttLine = replace(ttData.ttLine, "<Spark_SearchFields>", cSearchFields).
    end.

    if canCreateFile(ipUIOutputFolder + ipUIOutputFilename, "Screen") then do:
        outputFile(ipUIOutputFolder + ipUIOutputFilename).
        assign ipUIFileChecksum = getMD5(ipUIOutputFolder + ipUIOutputFilename).
        return true.
    end.
    return false.
end function. /* GenInvokeGrid */


/*********************************************************************/


function StripKeywords returns character ( input pcString as character ):
    /* Compare concatinated string to internal keywords. */
    if keyword(replace(pcString, " ", "")) ne ? then
        assign pcString = pcString + "val".
    return pcString.
end function. /* StripKeywords */


function FixBadChars returns  character ( input pcString as character ):
    assign
        pcString = replace(pcString, "#", "num")
        pcString = replace(pcString, "&", "and")
        pcString = replace(pcString, "%", "pct")
        pcString = replace(pcString, "$", "amt")
        pcString = replace(pcString, "-", "")
        pcString = StripKeywords(pcString)
        .
    return pcString.
end function. /* FixBadChars */


function CreateTT returns logical ( input pcTableName as character,
                                    input pcSelected  as character ):
    define variable oService          as DataAdminService no-undo.
    define variable oTable            as ITable           no-undo.
    define variable oIndex            as IIndex           no-undo.
    define variable oIndexIter        as IIterator        no-undo.
    define variable oField            as IField           no-undo.
    define variable oFieldIter        as IIterator        no-undo.
    define variable fileBuffer        as handle           no-undo.
    define variable fieldBuffer       as handle           no-undo.
    define variable fieldHandle       as handle           no-undo.
    define variable hFileQuery        as handle           no-undo.
    define variable cPrimaryKeyFields as character        no-undo.
    define variable cIndexLine        as character        no-undo.
    define variable cNewLine          as character        no-undo.

    /* Reset Values */
    assign iLine = 0.
    empty temp-table ttData.

    if ipDataSource begins "Database" then do:
        /* Create structures from database tables. */
        assign ipTTDefFileName = ipBECommonFolder + lc(replace(pcTableName, "-", "")) + ".i".

        assign oService = new DataAdminService(ipDatabase).
        if valid-object(oService) then do on error undo, throw:
            assign oTable = oService:GetTable(pcTableName).
            if valid-object(oTable) then do:
                /* Create a buffer against this database. */
                create buffer fileBuffer for table substitute("&1._file", ipDatabase).

                create query hFileQuery.
                hFileQuery:set-buffers(fileBuffer).
                hFileQuery:query-prepare(substitute("for each &1 where &1._file-number gt 0 and &1._file-name eq '&2'", fileBuffer:name, pcTableName)).
                hFileQuery:query-open().

                if ipGenBE begins "BE" then do:
                    /* Prepare full path/name of schema file. */
                    assign cSchemaFile = setSchemaFile(pcTableName).

                    /* Output the include file header. */
                    addLine("/*------------------------------------------------------------------------").
                    addLine("   File        : " + pcTableName).
                    addLine("   Purpose     : ").
                    addLine("   Syntax      : ").
                    addLine("   Description : ").
                    addLine("   Author(s)   : " + ipGenAuthor).
                    addLine("   Created     : " + ipGenDate).
                    addLine("   Notes       : ").
                    addLine(" ----------------------------------------------------------------------*/").
                    addLine("").
                    addLine("/* ***************************  Main Block  *************************** */").
                    addLine("").
                    addLine("/* Dynamically generated schema file */").
                    addLine("").
                end. /* ipGenBE begins "BE" */

                /* Get primary key fields. */
                assign oIndexIter = oTable:Indexes:Iterator().
                do while oIndexIter:HasNext():
                    assign oIndex = cast(oIndexIter:Next(), IIndex).
                    if oIndex:IsPrimary then do:
                        assign oFieldIter = oIndex:Fields:Iterator().
                        do while oFieldIter:HasNext():
                            assign oField = cast(oFieldIter:Next(), IField).
                            assign cPrimaryKeyFields = trim(substitute("&1,&2", cPrimaryKeyFields, oField:Name), ",").
                        end. /* do while */
                    end. /* oIndex:IsPrimary */
                end. /* do while */

                if ipGenBE begins "BE" then do:
                    addLine('~@openapi.openedge.entity.primarykey(fields="' + cPrimaryKeyFields + '").').
                    addLine("").
                    addLine(substitute('DEFINE TEMP-TABLE tt&1 BEFORE-TABLE btt&1', replace(pcTableName, "-", ""))).

                    if ipJFPSupport = "True" then do:
                        addLine(substitute("    FIELD &1 AS CHARACTER", ipRecordIdField)).
                        addLine("    FIELD {&sequence_field} AS INTEGER INITIAL ?").
                    end.
                end. /* ipGenBE begins "BE" */

                /* Should only iterate once through the selected database + table. */
                TABLEBLK:
                do while hFileQuery:get-next() on error undo, throw:
                    /* Create a buffer against this database table. */
                    create buffer fieldBuffer for table substitute("&1.&2", ipDatabase, pcTableName).

                    /* Cycle through all fields for this table. */
                    FIELDBLK:
                    do iFieldCount = 1 to fieldBuffer:num-fields on error undo, throw:
                        assign fieldHandle = fieldBuffer:buffer-field(iFieldCount).

                        /* Create a new field record for this table. */
                        create ttField.
                        assign
                            ttField.ttSequence      = iLine
                            ttField.ttSelectOrder   = iLine /* Default to the natural order. */
                            ttField.ttTableName     = pcTableName
                            ttField.ttFieldType     = "Field"
                            ttField.ttName          = fieldHandle:name
                            ttField.ttNameAlt       = fixBadChars(fieldHandle:name)
                            ttField.ttFieldDataType = fieldHandle:data-type
                            ttField.ttDecimals      = fieldHandle:decimals
                            ttField.ttLabel         = if (fieldHandle:label gt "") eq true then fieldHandle:label else fieldHandle:name
                            ttField.ttExtent        = fieldBuffer:buffer-field(iFieldCount):extent
                            .

                        if ipGenBE begins "BE" then do:
                            assign cNewLine = substitute('    FIELD &1 AS &2 LABEL "&3"', ttField.ttName, caps(ttField.ttFieldDataType), ttField.ttLabel).
                            if ttField.ttExtent gt 0 then
                                assign cNewLine = substitute("&1 EXTENT &2", cNewLine, ttField.ttExtent).
                            if ttField.ttName ne ttField.ttNameAlt then
                                assign cNewLine = substitute('&1 SERIALIZE-NAME "&2"', cNewLine, ttField.ttNameAlt).
                            addLine(cNewLine).
                        end.
                        else
                            assign iLine = iLine + 1.

                        /* If provided a list of selected fields, denote order of display. */
                        if (pcSelected gt "") eq true then
                            assign ttField.ttSelectOrder = lookup(ttField.ttName, pcSelected). /* Lookup on real field name. */

                    end. /* num-fields */
                end. /* do while */

                if ipGenBE begins "BE" then do:
                    if ipJFPSupport eq "True" then
                        addLine("    INDEX pkSeq IS PRIMARY UNIQUE {&sequence_field}").

                    assign oIndexIter = oTable:Indexes:Iterator().
                    do while oIndexIter:HasNext():
                        assign oIndex = cast(oIndexIter:Next(), IIndex).
                        if oIndex:IsActive then do:
                            assign oFieldIter = oIndex:Fields:Iterator().

                            /* If no fields, just leave. */
                            if not oFieldIter:HasNext() then leave.

                            assign cIndexLine = "    INDEX idx" + replace(oIndex:Name, "idx", "").
                            if ipJFPSupport eq "True" then do:
                                /* For JFP, primary index should already be set on sequence field */
                                assign cIndexLine = cIndexLine + (if oIndex:IsUnique then " IS UNIQUE" else "").
                            end.
                            else do:
                                assign cIndexLine = cIndexLine + (if oIndex:IsPrimary or oIndex:IsUnique then " IS" else "").
                                assign cIndexLine = cIndexLine + (if oIndex:IsPrimary then " PRIMARY" else "").
                                assign cIndexLine = cIndexLine + (if oIndex:IsUnique then " UNIQUE" else "").
                            end.

                            do while oFieldIter:HasNext():
                                /* Add field name to index, along with direction. */
                                assign oField = cast(oFieldIter:Next(), IField).
                                assign cIndexLine = substitute("&1 &2", cIndexLine, oField:Name).
                                /* Note: Removed descending flag due to change in logic. */
                            end. /* do while */

                            addLine(cIndexLine). /* Append the line to the temp-table output. */
                        end. /* oIndex:IsActive */
                    end. /* do while */

                    addLine("    .").
                    addLine("").
                    addLine(substitute("DEFINE DATASET ds&1 FOR tt&1.", replace(pcTableName, "-", ""))).
                end. /* Gen BE */
            end. /* valid-object */
            else
                undo, throw new AppError(substitute("Table '&1' not found in connected databases.", pcTableName), -404).

            finally:
                delete object hFileQuery no-error.
                delete object oService no-error.
                delete object oTable no-error.
            end finally.
        end. /* valid-object */
        else
            undo, throw new AppError(substitute("Database '&1' is not a connected database.", ipDatabase), -404).

        if ipGenBE begins "BE" then do:
            if canCreateFile(ipTTDefFileName, "Schema") then do:
                outputFile(ipTTDefFileName).
                assign ipSchemaChecksum = getMD5(ipTTDefFileName).
                return true.
            end.
            return false.
        end.
    end. /* Using Database */
    else if ipGenBE begins "UI" and (ipResourceMaster gt "") eq true then
    do on error undo, throw:
        define variable cNames  as character  no-undo extent.
        define variable oFields as JsonObject no-undo.
        define variable oProps  as JsonObject no-undo.
        define variable iX      as integer    no-undo.

        if (pcTableName eq ipMasterTable) and valid-object(oMasterFields) then do:
            assign cNames = oMasterFields:GetNames().
            oFields = cast(oMasterFields:Clone(), JsonObject).
        end.
        else if (pcTableName eq ipDetailTable) and valid-object(oDetailFields) then do:
            assign cNames = oDetailFields:GetNames().
            oFields = cast(oDetailFields:Clone(), JsonObject).
        end.

        NAMEBLK:
        do iX = 1 to extent(cNames):
            if can-do(ipRecordIdField + ",{&sequence_field}", cNames[iX]) or cNames[iX] begins "_" then next NAMEBLK.
            assign oProps = oFields:GetJsonObject(cNames[iX]).

            create ttField.
            assign
                ttField.ttSequence      = iLine
                ttField.ttSelectOrder   = iLine /* Default to the natural order. */
                ttField.ttTableName     = pcTableName
                ttField.ttFieldType     = "Field"
                ttField.ttName          = cNames[iX]
                ttField.ttNameAlt       = cNames[iX]
                ttField.ttFieldDataType = if oProps:Has("ablType") then oProps:GetCharacter("ablType") else "character"
                ttField.ttDecimals      = if ttField.ttFieldDataType eq "decimal" then 2 else 0
                ttField.ttLabel         = if oProps:Has("title") then oProps:GetCharacter("title") else cNames[iX]
                ttField.ttExtent        = if oProps:Has("maxItems") then oProps:GetInteger("maxItems") else 0
                iFieldCount             = iFieldCount + 1
                iLine                   = iLine + 1
                .

            /* If provided a list of selected fields, denote order of display. */
            if (pcSelected gt "") eq true then
                assign ttField.ttSelectOrder = lookup(ttField.ttName, pcSelected). /* Lookup on real field name. */
        end.
        finally:
            delete object oFields no-error.
        end finally.
    end. /* Using Catalog */

    return true.
end function. /* CreateTT */


function importConfig return logical ( input pcConfigPath as character ):
    define variable oParser as ObjectModelParser no-undo.
    define variable oConfig as JsonObject        no-undo.
    define variable cNames  as character extent  no-undo.
    define variable iX      as integer           no-undo.

    empty temp-table ttParamOld.

    /* Import parameters from JSON object file. */
    file-info:file-name = pcConfigPath.
    if file-info:full-pathname ne ? then do:
        assign oParser = new ObjectModelParser().
        assign oConfig = cast(oParser:ParseFile(file-info:full-pathname), JsonObject).
        if oConfig:Has("ttParam") then do:
            /* Read table-formatted data to temp-table directly. */
            temp-table ttParamOld:read-json("JsonObject", oConfig, "empty").
        end. /* Old Config Format */
        else do:
            /* Create new ttParam records from each object property. */
            assign cNames = oConfig:GetNames().
            empty temp-table ttParam.
            do iX = 1 to extent(cNames):
                create ttParamOld.
                assign
                    ttParamOld.ttName  = cNames[iX]
                    ttParamOld.ttValue = oConfig:GetCharacter(cNames[iX])
                    no-error.
                release ttParamOld.
            end. /* Param Name */
        end. /* New Config Format */
    end. /* File Exists */

    return can-find(first ttParamOld).

    finally:
        delete object oParser no-error.
        delete object oConfig no-error.
    end finally.
end function. /* importConfig */


function importParams returns logical ( ):
    /* Get property values from the input temp-table records (params). */
    ipOption               = getParamValue("ipOption").
    ipGenBE                = getParamValue("ipGenBE").
    ipGenDate              = getParamValue("ipGenDate").
    ipGenAuthor            = getParamValue("ipGenAuthor").
    ipCatalogURI           = getParamValue("ipCatalogURI").
    ipServiceURI           = getParamValue("ipServiceURI").
    ipDataSource           = getParamValue("ipDataSource").
    ipEntityName           = getParamValue("ipEntityName").
    ipResourceMaster       = getParamValue("ipResourceMaster").
    ipResourceDetail       = getParamValue("ipResourceDetail").
    ipNamespace            = getParamValue("ipNamespace").
    ipJFPSupport           = getParamValue("ipJFPSupport").
    ipRecordIdField        = getParamValue("ipRecordIdField").
    ipInheritedEntity      = getParamValue("ipInheritedEntity").
    ipBEOutputFolder       = getParamValue("ipBEOutputFolder").
    ipBECommonFolder       = getParamValue("ipBECommonFolder").
    ipUIOutputFolder       = getParamValue("ipUIOutputFolder").
    ipBEOutputFilename     = getParamValue("ipBEOutputFilename").
    ipUIOutputFilename     = getParamValue("ipUIOutputFilename").
    ipSaveConfigFile       = getParamValue("ipSaveConfigFile").
    ipOutFile              = getParamValue("ipOutFile").
    ipProjectName          = getParamValue("ipProjectName").
    ipUIInputFolder        = getParamValue("ipUIInputFolder").
    ipBEInputFolder        = getParamValue("ipBEInputFolder").
    ipCSSFile              = getParamValue("ipCSSFile").
    ipTemplateName         = getParamValue("ipTemplateName").
    ipBEMasterTemplateName = getParamValue("ipBEMasterTemplateName").
    ipBEDetailTemplateName = getParamValue("ipBEDetailTemplateName").
    ipMasterSDONames       = getParamValue("ipMasterSDONames").
    ipDetailSDONames       = getParamValue("ipDetailSDONames").
    ipSkipListArray        = getParamValue("ipSkipListArray").
    ipDatabase             = getParamValue("ipDatabase").
    ipMasterTable          = getParamValue("ipMasterTable").
    ipDetailTable          = getParamValue("ipDetailTable").
    ipMasterDetailJoin     = getParamValue("ipMasterDetailJoin").
    ipMasterFields         = getParamValue("ipMasterFields").
    ipMasterFieldsRaw      = getParamValue("ipMasterFieldsRaw").
    ipDetailFields         = getParamValue("ipDetailFields").
    ipDetailFieldsRaw      = getParamValue("ipDetailFieldsRaw").
    ipSelFields            = getParamValue("ipSelFields").
    ipSearchField1         = getParamValue("ipSearchField1").
    ipSearchField2         = getParamValue("ipSearchField2").
    ipSearchField3         = getParamValue("ipSearchField3").
    ipInvokeDSName         = getParamValue("ipInvokeDSName").
    ipInvokeTTName         = getParamValue("ipInvokeTTName").
    ipTTDefFileName        = getParamValue("ipTTDefFileName").
    ipControllerSPA        = getParamValue("ipControllerSPA").
    ipUseSPA               = getParamValue("ipUseSPA").

    /* Maintain backwards-compatibility with older parameters. */
    define variable ipTableName as character no-undo.

    /* If ipMasterTable is not present but ipEntityName is, use the latter. */
    if (ipMasterTable gt "") ne true and (ipEntityName gt "") eq true then
        assign ipMasterTable = ipEntityName.

    /* If ipTableName is not present but ipDetailTable is, use the latter. */
    assign ipTableName = getParamValue("ipTableName").
    if (ipTableName gt "") ne true and (ipDetailTable gt "") eq true then
        assign ipTableName = ipDetailTable.

    /* Check if combined/selected fields were passed or not. */
    if (ipSelFields gt "") eq true then do:
        if num-entries(ipSelFields, "|") eq 2 then
            assign /* Split the selected fields into Master/Detail lists. */
                ipMasterFields = entry(1, ipSelFields, "|")
                ipDetailFields = entry(2, ipSelFields, "|")
                .
    end. /* Combined Master/Detail Fields */

    /* Set value to indicate when a table join is in use. */
    assign lHasRelation = num-entries(ipMasterDetailJoin) ge 2.

    if ipGenBE begins "UI" then
    do on error undo, throw:
        define variable oParser as ObjectModelParser no-undo.

        assign oParser = new ObjectModelParser().

        if (ipMasterFieldsRaw gt "") eq true then
            assign oMasterFields = cast(oParser:Parse(ipMasterFieldsRaw), JsonObject) no-error.
        if (ipDetailFieldsRaw gt "") eq true then
            assign oDetailFields = cast(oParser:Parse(ipDetailFieldsRaw), JsonObject) no-error.

        finally:
            delete object oParser no-error.
        end finally.
    end. /* Catalog Used */

    return true.
end function. /* importParams */


/************************* Main Block *************************/


importParams().                 /* Assign all parameters to local variables.   */
importConfig(ipSaveConfigFile). /* Load previous metadata file, if present.    */
checkDefaults().                /* Ensure defaults are set for certain values. */

if ipOption eq "Blank" then do:
    /* Assemble a default filename for the template. */
    assign cInputUITemplate = ipUIInputFolder + ipTemplateName + ".html".

    /* Default output is "<entity><template_type>.html" unless initially overridden. */
    if ipUIOutputFilename eq "" then
        assign ipUIOutputFilename = ipEntityName + replace(ipTemplateName, "Template", "") + ".html".

    /* Place UI files for SPA purposes in a special subdirectory. */
    if can-do("true,yes,1", ipUseSPA) then
        assign ipUIOutputFolder = ipUIOutputFolder + "{&view_out}".

    if not GenScreenHTML(cInputUITemplate) then
        undo, throw new AppError("Unable to generate UI file.", -205).

    if can-do("true,yes,1", ipUseSPA) then do:
        if not GenControllerSPA(cInputUITemplate) then
            undo, throw new AppError("Unable to generate controller file.", -205).
    end.
end. /* None */
else if ipOption eq "CRUD" then do:
    /* For all CRUD-capable template types, generate the schema for the master table. */
    if (ipMasterTable gt "") eq true then do:
        if not CreateTT(ipMasterTable, ipMasterFields) then /* Set schema file location and generate file for master table. */
            undo, throw new AppError("Unable to generate master include file.", -205).
    end. /* ipMasterTable Present */

    if ipDataSource eq "ProDataset" and (ipTTDefFileName gt "") eq true then do:
        define variable cDir as character no-undo.
        define variable iCnt as integer   no-undo.

        assign iCnt = num-entries(ipBECommonFolder, "{&dirslash}").
        assign cDir = entry(iCnt - 1, ipBECommonFolder, "{&dirslash}").
        assign ipTTDefFileName = replace(ipTTDefFileName, "~\", "{&dirslash}").
        assign cSchemaFile = substitute("&1{&dirslash}&2", cDir, replace(ipTTDefFileName, ipBECommonFolder, "")).
    end. /* ipTTDefFileName Present */

    if ipGenBE begins "BE" then do:
        /* If only generating backend BE, then save config and return once generated. */
        if not GenCRUDBE(ipEntityName, ipMasterTable, ipBEInputFolder + ipBEMasterTemplateName, ipMasterSDONames) then
            undo, throw new AppError("Unable to generate master entity file.", -205).

        exportConfig().
        return.
    end. /* ipGenBE begins "BE" */

    /* Generate Backend BE and UI  */
    if not lHasRelation then do:
        if ipGenBE begins "BE" then
            if not GenCRUDBE(ipEntityName, ipMasterTable, ipBEInputFolder + ipBEMasterTemplateName, ipMasterSDONames) then
                undo, throw new AppError("Unable to generate master entity file.", -205).
    end. /* Single-Table Templates */
    else if lHasRelation then do:
        /* When table relation is in use, generate schema for the detail table first. */
        if not CreateTT(ipDetailTable, ipDetailFields) then /* Set schema file location and generate file for detail table. */
            undo, throw new AppError("Unable to generate detail include file.", -205).

        if ipGenBE begins "BE" then do:
            /* Generate CRUD BE for master table. */
            assign
                cSchemaFile        = setSchemaFile(ipMasterTable)
                ipBEOutputFilename = replace(ipMasterTable, "-", "") + "BE.cls"
                .

            /* Note: This forces the name of the entity to be the same as the master table. */
            if not GenCRUDBE(ipMasterTable, ipMasterTable, ipBEInputFolder + ipBEMasterTemplateName, ipMasterSDONames) then
                undo, throw new AppError("Unable to generate master entity file.", -205).

            /* Generate CRUD BE for detail table. */
            assign
                cSchemaFile        = setSchemaFile(ipDetailTable)
                ipBEOutputFilename = replace(ipDetailTable, "-", "") + "BE.cls"
                .
            /* Note: This forces the name of the entity to be the same as the detail table. */
            if not GenCRUDBE(ipDetailTable, ipDetailTable, ipBEInputFolder + ipBEDetailTemplateName, ipDetailSDONames) then
                undo, throw new AppError("Unable to generate detail entity file.", -205).
        end. /* ipGenBE begins "BE" */
    end. /* Multi-Table Templates */

    /* Run code based on template name. Do not generate templates if code asks for BE. */
    if not (ipGenBE begins "BE") then do:
        /* Assemble a default filename for the template. */
        assign cInputUITemplate = ipUIInputFolder + ipTemplateName + ".html".

        /* Default output is "<entity><template_type>.html" unless initially overridden. */
        if ipUIOutputFilename eq "" then
            assign ipUIOutputFilename = ipEntityName + replace(ipTemplateName, "Template", "") + ".html".

        /* Place UI files for SPA purposes in a special subdirectory. */
        if can-do("true,yes,1", ipUseSPA) then
            assign ipUIOutputFolder = ipUIOutputFolder + "{&view_out}".

        /* Generate the HTML portion of the template (should always be present). */
        if not GenScreenHTML(cInputUITemplate) then
            undo, throw new AppError("Unable to generate UI file.", -205).

        /* If configured as an SPA template, generate the controller file. */
        if can-do("true,yes,1", ipUseSPA) then do:
            if not GenControllerSPA(cInputUITemplate) then
                undo, throw new AppError("Unable to generate controller file.", -205).
        end. /* ipUseSPA */
    end. /* not (ipGenBE begins "BE") */
end. /* CRUD */
else if ipOption eq "UI" then do:
    /* Strictly UI-only template types. */
    assign cInputUITemplate = ipUIInputFolder + ipTemplateName + ".html".
    case ipTemplateName:
        when "TemplateLoginSPA" or
        when "TemplateLandingSPA" then do:
            if not GenLandingSPA(cInputUITemplate) then
                undo, throw new AppError("Unable to generate SPA UI file.", -205).
        end. /* TemplateLandingSPA */
    end case. /* ipTemplateName */
end. /* UI */
else if ipOption eq "Invoke" then do:
    /* Strictly invoke-only template type. */
    if ipSearchField1 eq "" then assign ipSearchField1 = "ipSalesRep".
    if ipSearchField2 eq "" then assign ipSearchField2 = "ipCustNum".
    if ipSearchField3 eq "" then assign ipSearchField3 = "ipItemNum".

    assign cSchemaFile = setSchemaFile(ipEntityName).
    assign iLine = 0.

    empty temp-table ttData.
    input from value(ipTTDefFileName).

    REPEATLOOP:
    repeat while true:
        import unformatted cLine.
        assign cLine = trim(cLine).

        /* Handle extra spaces between words as we are using " " as delimiter */
        do ix = 1 to 40:
            assign cLine = replace(cLine, "  ", " ").
        end.

        if cLine matches "*End Temptable Definition*" then leave REPEATLOOP.

        if cLine begins "DEFINE TEMP-TABLE" or
           cLine begins "DEF TEMP-TABLE" then do:
            if ipInvokeTTName eq entry(3, cLine, " ") then do:
                assign cTTName = entry(3, cLine, " ").
                assign iLine = iLine + 1.

                create ttField.
                assign
                    ttField.ttTableName = cTTName
                    ttField.ttFieldType = "Table"
                    ttField.ttSequence  = iLine
                    ttField.ttRec       = cLine
                    .
            end.
            else
                assign cTTName = "".
        end. /* temp-table */

        if (cTTName gt "") eq true and cLine begins "FIELD " then do:
            assign iLine = iLine + 1.
            assign iFieldCount = iFieldCount + 1.

            create ttField.
            assign
                ttField.ttSequence      = iLine
                ttField.ttSelectOrder   = iLine
                ttField.ttTableName     = cTTName
                ttField.ttFieldType     = "Field"
                ttField.ttName          = trim(entry(2, cLine, " "))
                ttField.ttNameAlt       = trim(entry(2, cLine, " "))
                ttField.ttFieldDataType = trim(entry(4, cLine, " "))
                ttField.ttLabel         = trim(entry(6, cLine, " ")) when num-entries(cLine, " ") ge 6
                ttField.ttLabel         = replace(ttField.ttLabel, '"', "")
                ttField.ttWidth         = trim(entry(8, cLine, " ")) when num-entries(cLine, " ") ge 8
                ttField.ttWidth         = replace(ttField.ttWidth, "X(", "")
                ttField.ttWidth         = replace(ttField.ttWidth, ")", "")
                ttField.ttRec           = cLine
                .
        end. /* field */

        if (cTTName gt "") eq true and cLine begins "INDEX " then do:
            assign iLine = iLine + 1.

            create ttField.
            assign
                ttField.ttTableName = cTTName
                ttField.ttFieldType = "Index"
                ttField.ttSequence  = iLine
                ttField.ttRec       = cLine
                .
        end. /* index */

        if (cTTName gt "") eq true and
           (cLine begins "DEFINE DATASET " or
            cLine begins "DEF DATASET ") then do:
            assign ipInvokeDSName = entry(3, cLine, " ").
            assign iLine = iLine + 1.

            create ttField.
            assign
                ttField.ttTableName = cTTName
                ttField.ttFieldType = "Dataset"
                ttField.ttSequence  = iLine
                ttField.ttRec       = cLine
                .
        end. /* dataset */
    end. /* repeat */

    /* Output schema data to ttData, then to file. */
    assign cTTName = substitute("tt&1", ipEntityName).
    assign iLine = 0.
    addLine(substitute("define temp-table &1", cTTName)).

    for each ttField
       where ttRec begins "Field":
        addLine("    " + ttField.ttRec).
    end.

    for each ttField
       where ttRec begins "Index"
          by ttField.ttSequence:
        addLine("    " + ttField.ttRec).
    end.

    addLine("    .").
    addLine(substitute("define dataset ds&1 for &2.", ipEntityName, cTTName)).

    assign ipTTDefFileName = ipBECommonFolder + replace(ipEntityName, "-", "") + ".i".
    if canCreateFile(ipTTDefFileName, "Schema") then do:
        outputFile(ipTTDefFileName).
        assign ipSchemaChecksum = getMD5(ipTTDefFileName).
    end.
    else
        undo, throw new AppError("Unable to generate include file.", -205).

    if not GenInvokeBE(ipBEInputFolder + "TemplateInvoke.cls") then
        undo, throw new AppError("Unable to generate entity file.", -205).

    /* Run code based on template name */
    assign cInputUITemplate = ipUIInputFolder + ipTemplateName + ".html".

    assign ipUIOutputFilename = ipEntityName + "Invoke.html".
    if ipTemplateName eq "TemplateInvoke" then
        if not GenInvokeGrid(input cInputUITemplate) then
            undo, throw new AppError("Unable to generate UI file.", -205).
end. /* Invoke */

finally:
    exportConfig(). /* No matter what, write the current values out to a metadata file for examination. */
end finally.

