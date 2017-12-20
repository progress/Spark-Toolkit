/*------------------------------------------------------------------------
    File        : fixGen.p
    Purpose     : Make adjustments to .gen files, creating .map in result
    Description : Correct minor issues with generated metadata for 11.7.2
                  and earlier, notably for JSON Array/Object parameters.
    Author(s)   : Dustin Grau
    Created     : Tue Nov 28 08:26:43 EST 2017
    Notes       : Will examine project for .gen and correct as necessary
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */
&GLOBAL-DEFINE USE_INVOKE_ENVELOPE FALSE

block-level on error undo, throw.

using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Core.Collections.* from propath.
using Spark.Util.* from propath.

define variable oMap   as StringStringMap no-undo.
define variable oIter  as IIterator       no-undo.
define variable oFile  as IMapEntry       no-undo.
define variable oData  as JsonObject      no-undo.
define variable cPath  as character       no-undo.
define variable lFixed as logical         no-undo.

/* ***************************  Functions  *************************** */

function getFiles returns StringStringMap ( ):
    define variable ix         as integer         no-undo.
    define variable cRoot      as character       no-undo.
    define variable cFileName  as character       no-undo.
    define variable cFilePath  as character       no-undo.
    define variable oDirStruct as JsonArray       no-undo.
    define variable oFile      as JsonObject      no-undo.
    define variable oList      as StringStringMap no-undo.

    /* Find the PROPATH entry with "openedge" in the path. */
    ROOTBLK:
    do ix = 1 to num-entries(propath):
        if entry(ix, propath) matches "*\WEB-INF\openedge" then do:
            assign cRoot = entry(ix, propath).
            leave ROOTBLK.
        end. /* matches */
    end. /* ix */

    /* Get a recursive list of files from the specified directory. */
    assign oDirStruct = Spark.Core.Util.OSTools:recurseDir(cRoot, true).

    /* Create a new list for names/paths. */
    assign oList = new StringStringMap().

    DIRBLOCK:
    do ix = 1 to oDirStruct:Length:
        assign oFile = oDirStruct:GetJsonObject(ix).
        assign cFileName = oFile:GetCharacter("FileName").
        if cFileName matches "*.gen" then do:
            assign cFilePath = oFile:GetCharacter("FullPath").
            oList:Put(cFileName, cFilePath).
        end. /* matches */
    end. /* ix */

    return oList.
end function. /* getFiles */

function loadData returns JsonObject ( input pcFilePath as character ):
    define variable oGenData as JsonObject        no-undo.
    define variable oParser  as ObjectModelParser no-undo.

    assign oParser = new ObjectModelParser().
    assign oGenData = cast(oParser:parseFile(pcFilePath), JsonObject).

    return oGenData.
end function. /* loadData */

function fixCatalog returns logical ( input pcServiceName as character ):
    define variable oCatalog  as JsonObject no-undo.
    define variable oServices as JsonArray  no-undo.
    define variable oService  as JsonObject no-undo.
    define variable cServices as character  no-undo extent.
    define variable ix        as integer    no-undo.

    file-info:file-name = substitute("&1/../../static/&2.json", right-trim(cPath, "/"), pcServiceName).
    if file-info:full-pathname ne ? then do:
        assign oCatalog = loadData(file-info:full-pathname).
        assign oServices = oCatalog:GetJsonArray("services").
        do ix = 1 to oServices:Length:
            /* Currently this should be 1 service per file,
             * but just in case we should make it dynamic.
             */
            oService = oServices:GetJsonObject(ix).
            if oService:Has("useRequest") and
               oService:GetType("useRequest") eq JsonDataType:boolean and
               oService:GetLogical("useRequest") ne {&USE_INVOKE_ENVELOPE} then do:
                oService:Set("useRequest", {&USE_INVOKE_ENVELOPE}).
                message substitute("Fixed Catalog: &1.json", pcServiceName).
                oCatalog:WriteFile(file-info:full-pathname, true).
            end. /* Has useRequest */
        end. /* ix */
    end. /* catalog exists */
end function. /* fixCatalog */

function fixData returns logical ( input-output poGenData as JsonObject ):
    define variable oServices   as JsonObject no-undo.
    define variable oService    as JsonObject no-undo.
    define variable oOperations as JsonObject no-undo.
    define variable oMethods    as JsonObject no-undo.
    define variable oMethod     as JsonObject no-undo.
    define variable oOptions    as JsonObject no-undo.
    define variable oEntity     as JsonObject no-undo.
    define variable oArgs       as JsonArray  no-undo.
    define variable oArg        as JsonObject no-undo.
    define variable oElem       as JsonObject no-undo.
    define variable cServices   as character  no-undo extent.
    define variable cOperations as character  no-undo extent.
    define variable cMethods    as character  no-undo extent.
    define variable ia          as integer    no-undo.
    define variable ix          as integer    no-undo.
    define variable iy          as integer    no-undo.
    define variable iz          as integer    no-undo.
    define variable lFixed      as logical    no-undo initial false.

    assign oServices = poGenData:GetJsonObject("services").
    assign cServices = oServices:GetNames().
    do ix = 1 to extent(cServices):
        /* Currently this should be 1 service per file,
         * but just in case we should make it dynamic.
         */
        oService = oServices:GetJsonObject(cServices[ix]).
        oOperations = oService:GetJsonObject("operations").
        assign cOperations = oOperations:GetNames().
        do iy = 1 to extent(cOperations):
            oMethods = oOperations:GetJsonObject(cOperations[iy]).
            assign cMethods = oMethods:GetNames().
            do iz = 1 to extent(cMethods):
                oMethod = oMethods:GetJsonObject(cMethods[iz]).

                /**
                 * See OpenEdge/Web/DataObject/operationmap.schema.json for distinct values:
                 *  requestEnvelope: true | false | "name"
                 *  responseEnvelope: true | false | "name"
                 *  msgElem (msgElemValue): typically "field" or "body"
                 */

                if valid-object(oMethod) and oMethod:Has("options") then do:
                    oOptions = oMethod:GetJsonObject("options").
                    if valid-object(oOptions) then do:
                        if oOptions:Has("requestEnvelope") and
                           oOptions:GetType("requestEnvelope") eq JsonDataType:boolean and
                           oOptions:GetLogical("requestEnvelope") ne {&USE_INVOKE_ENVELOPE} then do:
                            oOptions:Set("requestEnvelope", {&USE_INVOKE_ENVELOPE}).
                            assign lFixed = fixCatalog(cServices[ix]).
                        end. /* requestEnvelope */

                        if oOptions:Has("responseEnvelope") and
                           oOptions:GetType("requestEnvelope") eq JsonDataType:boolean and
                           oOptions:GetLogical("responseEnvelope") ne {&USE_INVOKE_ENVELOPE} then do:
                            oOptions:Set("responseEnvelope", {&USE_INVOKE_ENVELOPE}).
                            assign lFixed = fixCatalog(cServices[ix]).
                        end. /* responseEnvelope */
                    end. /* Valid Object */
                end. /* Has Options */

                if valid-object(oMethod) and oMethod:Has("entity") then do:
                    oEntity = oMethod:GetJsonObject("entity").

                    if valid-object(oEntity) and oEntity:Has("arg") then do:
                        oArgs = oEntity:GetJsonArray("arg").

                        if valid-object(oArgs) then
                        do ia = 1 to oArgs:length:
                            oArg = oArgs:GetJsonObject(ia).

                            if oArg:Has("ablType") then do:
                                case oArg:GetCharacter("ablType"):

                                    when "JsonArray" or
                                    when "Progress.Json.ObjectModel.JsonArray" then do:
                                        oArg:Set("ablType", "class Progress.Json.ObjectModel.JsonArray").
                                        assign lFixed = true.
                                    end. /* JsonArray */

                                    when "JsonObject" or
                                    when "Progress.Json.ObjectModel.JsonObject" then do:
                                        oArg:Set("ablType", "class Progress.Json.ObjectModel.JsonObject").
                                        assign lFixed = true.
                                    end. /* JsonObject */

                                    when "dataset" then do:
                                        if oArg:Has("msgElem") then do:
                                            oElem = oArg:GetJsonObject("msgElem").
                                            if valid-object(oElem) and oElem:Has("type") and
                                               oElem:GetCharacter("type") eq "field" then do:
                                                oElem:Set("type", "body"). /* Change to body output. */
                                                assign lFixed = true.
                                            end.
                                        end. /* Has msgElem */
                                    end. /* dataset */

                                    when "table" then do:
                                        if oArg:Has("msgElem") then do:
                                            oElem = oArg:GetJsonObject("msgElem").
                                            if valid-object(oElem) and oElem:Has("type") and
                                               oElem:GetCharacter("type") eq "field" then do:
                                                oElem:Set("type", "body"). /* Change to body output. */
                                                assign lFixed = true.
                                            end.
                                        end. /* Has msgElem */
                                    end. /* table */

                                end case. /* ablType */
                            end. /* Has ablType */
                        end. /* ia */
                    end. /* Has arg */
                end. /* Has entity */
            end. /* iz */
            extent(cMethods) = ?.
        end. /* iy */
        extent(cOperations) = ?.
    end. /* ix */

    return lFixed.
end function. /* fixData */

/* ***************************  Main Block  *************************** */

assign oMap = getFiles().
assign oIter = oMap:EntrySet:Iterator().
do while oIter:HasNext():
    /* Iterate through the .gen files. */
    oFile = cast(oIter:Next(), IMapEntry).

    /* Load data from the file and fix values. */
    assign oData = loadData(string(oFile:value)).
    assign cPath = substring(string(oFile:value), 1, length(string(oFile:value)) - length(string(oFile:key))).
    assign lFixed = fixData(input-output oData).

    /* Output to a new .map file. */
    if lFixed then do:
        message substitute("Fixed Mapping: &1", string(oFile:key)).
        oData:WriteFile(replace(string(oFile:value), ".gen", ".map"), true).
        os-delete value(string(oFile:value)).
    end.
end. /* oIter */
