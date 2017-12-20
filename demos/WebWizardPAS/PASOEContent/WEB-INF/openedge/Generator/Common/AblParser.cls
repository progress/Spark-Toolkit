/*------------------------------------------------------------------------
    File        : AblParser
    Syntax      : File parser library
    Author(s)   : dugrau
    Created     : Thu Jan 14 16:32:23 EST 2016
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

block-level on error undo, throw.

class Generator.Common.AblParser final: 

    define temp-table ttData no-undo
        field ttLineNum as integer
        field ttLine    as character
        index idxMain ttLineNum.

    constructor AblParser ( input pcFilePath as character ):
        file-info:file-name = pcFilePath.
        if file-info:full-pathname ne ? then
            importFile(pcFilePath).
    end constructor.

    method private logical importFile ( input pcFilePath as character ):
        define variable cImportLine as character no-undo.
        define variable iLine       as integer   no-undo initial 0.

        empty temp-table ttData.

        /* Import each line from the file and add to ttData. */
        input from value(pcFilePath).
        repeat while true:
            import unformatted cImportLine.
            if (cImportLine gt "") eq true then do:
                assign iLine = iLine + 1.
                create ttData.
                assign
                    ttData.ttLineNum = iLine
                    ttData.ttLine    = prepLine(cImportLine)
                    .
                release ttData.
            end.
        end. /* repeat */

        return can-find(first ttData).
    end method. /* importFile */

    method private character prepLine ( input pcLine as character ):
        define variable iX as integer no-undo.

        do ix = 1 to 10:
            /* Collapse whitespace. */
            assign pcLine = replace(pcLine, "  ", " ").
        end.

        assign pcLine = replace(pcLine, "def dataset", "define dataset").
        assign pcLine = replace(pcLine, "def temp-table", "define temp-table").
        assign pcLine = replace(pcLine, "def private dataset", "define dataset").
        assign pcLine = replace(pcLine, "def private temp-table", "define temp-table").
        assign pcLine = replace(pcLine, "define private dataset", "define dataset").
        assign pcLine = replace(pcLine, "define private temp-table", "define temp-table").
        assign pcLine = replace(pcLine, "def input param ", "define input parameter ").
        assign pcLine = replace(pcLine, "def output param ", "define output parameter ").

        return trim(pcLine).
    end method. /* prepLine */

    method public JsonObject parseStats ( ):
        return parseStats(false).
    end method.

	method public JsonObject parseStats ( input plIncludeSchema as logical ):
        define variable oIncludeData  as JsonObject no-undo.
        define variable oSchemaObj    as JsonObject no-undo.
        define variable oSchema       as JsonObject no-undo.
        define variable oDatasets     as JsonObject no-undo.
        define variable oTempTables   as JsonArray  no-undo.
        define variable oInputParams  as JsonArray  no-undo.
        define variable oOutputParams as JsonArray  no-undo.
        define variable cName         as character  no-undo.
        define variable cLine         as character  no-undo.
        define variable iLine         as integer    no-undo.
        define variable lField        as logical    no-undo initial false.
        define variable lIndex        as logical    no-undo initial false.

        if plIncludeSchema then
            assign oSchema = new JsonObject().

        assign oDatasets = new JsonObject().
        assign oTempTables = new JsonArray().
        assign oInputParams = new JsonArray().
        assign oOutputParams = new JsonArray().

        for each ttData by ttData.ttLineNum:
            assign cLine = trim(ttData.ttLine).

            if cLine begins "define input parameter" then do:
                if entry(4, cLine, " ") eq "table" then
                    oInputParams:Add(trim(entry(6, cLine, " "))).
                else
                    oInputParams:Add(trim(entry(4, cLine, " "))).
            end. /* input */

            else if cLine begins "define output parameter" then do:
                if entry(4, cLine, " ") eq "table" then
                    oOutputParams:Add(trim(entry(6, cLine, " "))).
                else
                    oOutputParams:Add(trim(entry(4, cLine, " "))).
            end. /* output */

            else if cLine begins "define dataset" then do:
                assign cName = trim(entry(3, cLine, " ")).
                assign cLine = replace(cLine, ", ", ",").
                assign cLine = replace(cLine, ".", "").
                if not oDatasets:Has(cName) then do:
                    if num-entries(cLine, " ") ge 5 then
                        oDatasets:Add(cName, trim(entry(5, cLine, " "))).
                    else
                        oDatasets:Add(cName, new JsonObject()).
                end.
            end.

            else if cLine begins "define temp-table" then do:
                assign
                    lField = false
                    lIndex = false
                    .
                oTempTables:Add(trim(entry(3, cLine, " "))).
                if plIncludeSchema then
                    assign oSchemaObj = new JsonObject().
            end.

            else if cLine begins "field" then do:
                assign
                    lField = true
                    lIndex = false
                    .
                if plIncludeSchema then
                    oSchemaObj:Add(entry(2, cLine, " "), substring(cLine, 7)).
            end.

            else if cLine begins "index" then do:
                assign
                    lField = false
                    lIndex = true
                    .
                if plIncludeSchema then
                    oSchemaObj:Add(entry(2, cLine, " "), substring(cLine, 7)).
            end.

            else if length(cLine) gt 0 and substring(cLine, length(cLine)) eq "." then do:
                assign
                    lField = false
                    lIndex = false
                    .
                if plIncludeSchema and valid-object(oSchemaObj) then
                    oSchema:Add(oTempTables:GetCharacter(oTempTables:Length), oSchemaObj).
            end.
        end. /* for each */

        assign oIncludeData = new JsonObject().

        if plIncludeSchema then
            oIncludeData:Add("schema", oSchema).

        oIncludeData:Add("datasets", oDatasets).
        oIncludeData:Add("tables", oTempTables).
        oIncludeData:Add("inputs", oInputParams).
        oIncludeData:Add("outputs", oOutputParams).

        return oIncludeData.
	end method.

end class.