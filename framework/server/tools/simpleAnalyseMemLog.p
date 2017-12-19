define variable cFile   as character no-undo.
define variable cLine   as character no-undo.
define variable iSeq    as integer   no-undo.
define variable cAgent  as character no-undo.
define variable cType   as character no-undo.
define variable cHandle as character no-undo.

/*add this to the openedge.properties file for the agent
agentLogEntryTypes=DynObjects.*:3
*/
define temp-table ttMem
    field seq        as int
    field agent      as character
    field type       as char
    field reference  as char
    field memSize    as int
    field srcCode    as char
    index ix1 as primary seq
    index ix2 agent reference.

cFile = "/tmp/appserver.log". /*this is a copy of the appserver log file*/

input from value(cFile).
repeat:
    import unformatted cLine.
    iSeq = iSeq + 1.
    if not entry(6, cLine, " ") eq "DYNOBJECTS" then next.
    cAgent = entry(2, cline, " ").
    cLine = trim(substring(cLine, index(cLine,"DYNOBJECTS") + 11)).
    if cline matches "*Handle:0*" then next.

    if cline begins "Allocated" then
    do:
        cline = trim(substring(cLine, index(cLine, entry(1, cLine, " ")) + length(entry(1, cLine, " ")) + 1)).
        create ttMem.
        assign
            ttMem.seq       = iSeq
            ttMem.agent     = cAgent
            ttMem.type      = entry(1, cLine, " ")
            ttMem.reference = entry(2, cLine, " ")
            ttMem.memSize   = int(entry(4, cLine, " "))
            ttMem.srcCode   = substring(cLine, index(cLine, "(") + 1, index(cLine, ")") - index(cLine, "(") - 1).

    end.
    else if cline begins "Deallocated" then
    do:
        cline = trim(substring(cLine, index(cLine, entry(1, cLine, " ")) + length(entry(1, cLine, " ")) + 1)).
        find first ttMem
             where ttMem.agent eq cAgent
               and ttMem.reference eq entry(2, cLine, " ")
               no-error.
        if available ttMem then
        do:
            assign ttMem.memSize = ttMem.memSize - int(entry(4, cLine, " ")).
            if ttMem.memSize eq 0 then delete ttMem.
        end.
    end.
    else if cline begins "Created" then
    do:
        cLine = trim(substring(cLine, index(cLine, entry(1, cLine, " ")) + length(entry(1, cLine, " ")) + 1)).
        cType = entry(1,cline," ").
        cLine = trim(substring(cLine, index(cLine, entry(1, cLine, " ")) + length(entry(1, cLine, " ")) + 1)).
        cHandle = entry(1, cLine, " ").

        create ttMem.
        assign
            ttMem.seq       = iSeq
            ttMem.agent     = cAgent
            ttMem.type      = cType
            ttMem.reference = cHandle
            ttMem.srcCode   = substring(cLine, index(cLine, "(") + 1, index(cLine, ")") - index(cLine, "(") - 1).

    end.
    else if cline begins "Deleted" then
    do:
        cLine = trim(substring(cLine, index(cLine, entry(1, cLine, " ")) + length(entry(1, cLine, " ")) + 1)).
        cType = entry(1, cLine, " ").
        cLine = trim(substring(cLine, index(cLine, entry(1, cLine, " ")) + length(entry(1, cLine, " ")) + 1)).
        cHandle = entry(1, cLine, " ").

        find first ttMem
             where ttMem.agent eq cAgent
               and ttMem.type eq cType
               and ttMem.reference eq cHandle
               no-error.
        if available ttMem then
            delete ttMem.
    end.
end.
input close.

output to /tmp/mem.csv.
for each ttMem:
    export delimiter "," ttMem.
end.
output close.

