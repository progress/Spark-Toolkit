/*------------------------------------------------------------------------
    File        : parseLog.p
    Purpose     : Parse the agent (CAS) or session (PAS) log file. 
    Syntax      :
    Description : Based on leakcheck.p from Progress KB
    Author(s)   : dugrau
    Created     : Fri Apr 29 10:19:03 EDT 2016
    Notes       : Expects an agentLoggingLevel of at least 3, with
                : use of the agentLogEntryTypes 4GLTrace/DynObjects.*
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

define temp-table ttLogEntries no-undo
    field LineNum      as integer
    field Timestamp    as datetime
    field ProcessID    as character
    field SessionID    as character
    field LogLevel     as character
    field LogText      as character
    index pkLine       as primary unique LineNum
    index idxTime      Timestamp
    index idxSession   ProcessID SessionID
    .

define temp-table ttLogDynObj no-undo
    field LineNum      as integer
    field Timestamp    as datetime
    field ProcessID    as character
    field SessionID    as character
    field Operation    as character format "X(10)" label "Operation"
    field OpStart      as logical
    field OpEnd        as logical
    field ObjectType   as character format "X(30)" label "Object"
    field ObjectHandle as character format "X(14)" label "Handle"
    field ExtraInfo    as character format "X(30)" label "Details"
    field CodePoint    as character format "X(40)" label "Location"
    index pkLine       as primary unique LineNum
    index idxTime      Timestamp
    index idxSession   ProcessID SessionID
    index idxHandle    OpEnd ObjectHandle
    .

define temp-table ttLogTrace no-undo
    field LineNum      as integer
    field Timestamp    as datetime
    field ProcessID    as character
    field SessionID    as character
    field Operation    as character format "X(10)" label "Operation"
    field OpStart      as logical
    field OpEnd        as logical
    field ObjectName   as character format "X(40)" label "Object"
    field ExtraInfo    as character format "X(40)" label "Details"
    field CodePoint    as character format "X(40)" label "Location"
    field ElapsedMS    as decimal format ">,>>9.99" label "Time (ms)"
    index pkLine       as primary unique LineNum
    index idxTime      Timestamp
    index idxSession   ProcessID SessionID
    index idxHandle    OpEnd ObjectName
    .

define buffer ttLogDynObj2 for ttLogDynObj.
define buffer ttLogTrace2  for ttLogTrace.

define variable cFilename    as character no-undo.
define variable iLine        as integer   no-undo initial 1.
define variable cTime        as character no-undo.
define variable cLine        as character no-undo.
define variable cEntry       as character no-undo.
define variable cSegment     as character no-undo.
define variable lParseDynObj as logical   no-undo initial false.
define variable lParseTrace  as logical   no-undo initial false.

function collapseWhitespace returns character ( input pcString as character ):
    define variable ix as integer no-undo.
    
    do ix = 1 to 5:
        assign pcString = replace(pcString, "  ", " ").
    end.

    return trim(pcString).
end function. /* collapseWhitespace */

/* ***************************  Main Block  *************************** */

/* Prompt for file to parse. */
system-dialog get-file cFilename.

empty temp-table ttLogEntries.
empty temp-table ttLogDynObj.
empty temp-table ttLogTrace.

/* Read the log, keeping only the entries we need. */
input from value(cFilename).
repeat:
    import unformatted cLine.

    assign
        cTime = replace(replace(entry(1, cLine, " "), "[", ""), "]", "")
        cTime = substring(cTime, 1, r-index(cTime, "-") - 1)
        cTime = replace(replace(cTime, "@", "T"), "/", "-")
        .
    if not (cTime begins "20") then assign cTime = "20" + cTime.
/*    if r-index(cTime, ":") lt 24 then assign cTime = replace(cTime, "0400", "04:00").*/

    create ttLogEntries.
    assign       
        ttLogEntries.LineNum   = iLine
        ttLogEntries.Timestamp = OpenEdge.Core.TimeStamp:ToABLDateTimeFromISO(cTime)
        ttLogEntries.ProcessID = entry(2, cLine, " ")
        ttLogEntries.SessionID = entry(3, cLine, " ")
        ttLogEntries.LogLevel  = entry(4, cLine, " ")
        ttLogEntries.LogText   = substring(cLine, 50)
        cEntry                 = ttLogEntries.LogText
        iLine                  = iLine + 1
        .

    if cEntry begins "AS-Aux -- Log entry types activated:" then
        assign
            lParseDynObj = cEntry matches "*DynObjects*"
            lParseTrace  = cEntry matches "*4GLTrace*"
            .

    if lParseDynObj and entry(2, cEntry, " ") eq "DYNOBJECTS" then do:
        create ttLogDynObj. /* Create with basic info. */
        buffer-copy ttLogEntries to ttLogDynObj no-error.

        assign /* Add operation information with start/stop flags. */
            cSegment              = trim(substring(cEntry, index(cEntry, "DYNOBJECTS") + 10))
            ttLogDynObj.Operation = trim(entry(1, cSegment, " "))
            ttLogDynObj.OpStart   = can-do("Allocated,Cached,Created,Creating", ttLogDynObj.Operation)
            ttLogDynObj.OpEnd     = can-do("Deallocated,Deleted,Deleted-by-gc,Deleting,Purged", ttLogDynObj.Operation)
            .

        assign /* Shrink the string by removing items already logged. */
            cSegment = trim(substring(cSegment, index(cSegment, ttLogDynObj.Operation) + length(ttLogDynObj.Operation)))
            cSegment = collapseWhitespace(cSegment)
            .

        assign /* Continue logging items and shrinkin the string. */
            ttLogDynObj.ObjectType   = entry(1, cSegment, " ")
            ttLogDynObj.ObjectHandle = entry(2, cSegment, " ")
            ttLogDynObj.CodePoint    = trim(substring(cSegment, index(cSegment, "(") + 1, (index(cSegment,")") - index(cSegment, "(") - 1)))
            cSegment                 = trim(replace(cSegment, ttLogDynObj.CodePoint, ""))
            cSegment                 = trim(replace(cSegment, ttLogDynObj.ObjectType, ""))
            cSegment                 = trim(replace(cSegment, ttLogDynObj.ObjectHandle, ""))
            cSegment                 = trim(replace(cSegment, "( )", ""))
            cSegment                 = trim(replace(cSegment, "()", ""))
            .

        if cSegment begins "size:" then
            assign cSegment = replace(cSegment, "size:", "") + " bytes".

        assign ttLogDynObj.ExtraInfo = trim(cSegment).

        /* Replace generic object name with more specific object name. */
        if ttLogDynObj.ObjectType eq "Progress.Lang.Object" and ttLogDynObj.ExtraInfo gt "" then
            assign
                ttLogDynObj.ObjectType = ttLogDynObj.ExtraInfo
                ttLogDynObj.ExtraInfo  = ""
                .

        release ttLogDynObj.
    end. /* lParseDynObj */

    if lParseTrace and entry(2, cEntry, " ") eq "4GLTRACE" then do:
        create ttLogTrace. /* Create with basic info. */
        buffer-copy ttLogEntries to ttLogTrace no-error.

        assign /* Add operation information with start/stop flags. */
            cSegment             = trim(substring(cEntry, index(cEntry, "4GLTRACE") + 8))
            ttLogTrace.Operation = trim(entry(1, cSegment, " "))
            ttLogTrace.OpStart   = can-do("Func,Invoke,New,Run,Super", ttLogTrace.Operation)
            ttLogTrace.OpEnd     = can-do("End,Return", ttLogTrace.Operation)
            .

        assign /* Shrink the string by removing items already logged. */
            cSegment = trim(substring(cSegment, index(cSegment, ttLogTrace.Operation) + length(ttLogTrace.Operation)))
            cSegment = collapseWhitespace(replace(cSegment, "from ", ""))
            .

        /* Obtain the correct object name. */
        if entry(2, cSegment, " ") eq "in" then
            assign ttLogTrace.ObjectName = entry(3, cSegment, " ") + ":" + entry(1, cSegment, " ").
        else
            assign ttLogTrace.ObjectName = entry(1, cSegment, " ").

        assign /* Continue logging items and shrinkin the string. */
            ttLogTrace.CodePoint = trim(trim(substring(cSegment, r-index(cSegment, "[") + 1)), "]")
            cSegment             = trim(replace(cSegment, ttLogTrace.CodePoint, ""))
            cSegment             = trim(replace(cSegment, ttLogTrace.ObjectName, ""))
            cSegment             = trim(replace(cSegment, "[ ]", ""))
            cSegment             = trim(replace(cSegment, "[]", ""))
            ttLogTrace.ExtraInfo = trim(cSegment) when not cSegment matches "*in*"
            .

        if ttLogTrace.Operation eq "Return" then
            assign ttLogTrace.ObjectName = substitute("&1:&2", ttLogTrace.ExtraInfo, ttLogTrace.ObjectName).

        if ttLogTrace.ObjectName matches "*:*" then
            assign ttLogTrace.ObjectName = replace(ttLogTrace.ObjectName, "~"?~":", "").

        release ttLogDynObj.
    end. /* lParseTrace */

    release ttLogEntries.
end.
input close.

message "Done parsing, click OK to prepare output." view-as alert-box.

/* Filter out the start of any actions that have a matching end. */
for each ttLogDynObj
   where ttLogDynObj.OpStart
      by ttLogDynObj.LineNum:
    if can-do("Cached,Created,Creating", ttLogDynObj.Operation) then
        find first ttLogDynObj2
             where ttLogDynObj2.OpEnd
               and ttLogDynObj2.Operation begins "Del"
               and ttLogDynObj2.ObjectHandle eq ttLogDynObj.ObjectHandle
               and ttLogDynObj2.LineNum gt ttLogDynObj.LineNum no-error.

    if can-do("Allocated", ttLogDynObj.Operation) then
        find first ttLogDynObj2
             where ttLogDynObj2.OpEnd
               and ttLogDynObj2.Operation eq "Deallocated"
               and ttLogDynObj2.ObjectHandle eq ttLogDynObj.ObjectHandle
               and ttLogDynObj2.LineNum gt ttLogDynObj.LineNum no-error.

    if available(ttLogDynObj2) then do:
        delete ttLogDynObj.
        delete ttLogDynObj2.
    end.
end. /* ttLogDynObj */

/* Delete any unmatched end statements. */
for each ttLogDynObj
   where ttLogDynObj.OpEnd:
    delete ttLogDynObj.
end. /* ttLogTrace */

/* Filter out the start of any actions that have a matching end. */
for each ttLogTrace
   where ttLogTrace.OpStart
      by ttLogTrace.LineNum:
    find first ttLogTrace2
         where ttLogTrace2.OpEnd
           and ttLogTrace2.LineNum gt ttLogTrace.LineNum no-error.
    if available(ttLogTrace2) then do:
        assign ttLogTrace.ElapsedMS = (mtime(ttLogTrace2.Timestamp) - mtime(ttLogTrace.Timestamp)) / 1000.
        delete ttLogTrace2.
    end.
end. /* ttLogTrace */

/* Delete any unmatched end statements. */
for each ttLogTrace
   where ttLogTrace.OpEnd:
    delete ttLogTrace.
end. /* ttLogTrace */

temp-table ttLogDynObj:write-json("file", substitute("DynObjects-&1.json", replace(iso-date(now), ":", "-")), true).
output to DynObjects.txt.
for each ttLogDynObj by ttLogDynObj.LineNum:
    display ttLogDynObj.Operation ttLogDynObj.ObjectType ttLogDynObj.ObjectHandle ttLogDynObj.CodePoint ttLogDynObj.ExtraInfo with width 600.
end.
output close.

temp-table ttLogTrace:write-json("file", substitute("4GLTrace-&1.json", replace(iso-date(now), ":", "-")), true).
output to 4GLTrace.txt.
for each ttLogTrace by ttLogTrace.LineNum:
    display ttLogTrace.Operation ttLogTrace.ObjectName ttLogTrace.ElapsedMS ttLogTrace.CodePoint ttLogTrace.ExtraInfo with width 600.
end.
output close.

message "Done preparing output." view-as alert-box.
