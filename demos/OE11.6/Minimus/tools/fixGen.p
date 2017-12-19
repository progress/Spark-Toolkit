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

block-level on error undo, throw.

using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Core.Collections.* from propath.
using Spark.Util.* from propath.

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

function fixData returns logical ( input-output poGenData as JsonObject ):
    define variable oServices   as JsonObject no-undo.
    define variable oService    as JsonObject no-undo.
    define variable oOperations as JsonObject no-undo.
    define variable oMethods    as JsonObject no-undo.
    define variable oMethod     as JsonObject no-undo.
    define variable oEntity     as JsonObject no-undo.
    define variable oArgs       as JsonArray  no-undo.
    define variable oArg        as JsonObject no-undo.
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
        oService = oServices:GetJsonObject(cServices[ix]).
        oOperations = oService:GetJsonObject("operations").
        assign cOperations = oOperations:GetNames().
        do iy = 1 to extent(cOperations):
            oMethods = oOperations:GetJsonObject(cOperations[iy]).
            assign cMethods = oMethods:GetNames().
            do iz = 1 to extent(cMethods):
                oMethod = oMethods:GetJsonObject(cMethods[iz]).
                if valid-object(oMethod) and oMethod:Has("entity") then
                    oEntity = oMethod:GetJsonObject("entity").

                if valid-object(oEntity) and oEntity:Has("arg") then
                    oArgs = oEntity:GetJsonArray("arg").

                if valid-object(oArgs) then
                do ia = 1 to oArgs:length:
                    oArg = oArgs:GetJsonObject(ia).
                    if oArg:Has("ablType") then do:
                        case oArg:GetCharacter("ablType"):
                            when "JsonArray" then do:
                                oArg:Set("ablType", "class Progress.Json.ObjectModel.JsonArray").
                                assign lFixed = true.
                            end. /* JsonArray */
                            when "JsonObject" then do:
                                oArg:Set("ablType", "class Progress.Json.ObjectModel.JsonObject").
                                assign lFixed = true.
                            end. /* JsonObject */
                        end case.
                    end. /* Has ablType */
                end. /* ia */
            end. /* iz */
            extent(cMethods) = ?.
        end. /* iy */
        extent(cOperations) = ?.
    end. /* ix */

    return lFixed.
end function. /* fixData */

/* ***************************  Main Block  *************************** */

define variable oMap   as StringStringMap no-undo.
define variable oIter  as IIterator       no-undo.
define variable oFile  as IMapEntry       no-undo.
define variable oData  as JsonObject      no-undo.
define variable lFixed as logical         no-undo.

assign oMap = getFiles().
assign oIter = oMap:EntrySet:Iterator().
do while oIter:HasNext():
    /* Iterate through the .gen files. */
    oFile = cast(oIter:Next(), IMapEntry).

    /* Load data from the file and fix values. */
    assign oData = loadData(string(oFile:value)).
    assign lFixed = fixData(input-output oData).

    /* Output to a new .map file. */
    if lFixed then do:
        message substitute("Fixed file: &1", string(oFile:key)).
        oData:WriteFile(replace(string(oFile:value), ".gen", ".map"), true).
        os-delete value(string(oFile:value)).
    end.
end. /* oIter */
