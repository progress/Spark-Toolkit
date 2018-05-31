/*------------------------------------------------------------------------
    File        : Spark/shutdown
    Purpose     : Recommended to check for any dynamic objects left behind
    Description : Assigned as sessionShutdownProc in openedge.properties
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Apr 28 15:03:17 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

&GLOBAL-DEFINE MIN_LOG_LEVEL 3

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using Progress.Json.* from propath.
using Spark.Core.Manager.ICatalogManager from propath.
using Spark.Core.Manager.ISchemaManager from propath.
using Spark.Core.Manager.IStartupManager from propath.
using Spark.Core.Manager.ServiceLifeCycleEnum from propath.

{Spark/Core/Lib/LogMessage.i &IsClass=false &IsPublic=false}

/* ***************************  Main Block  *************************** */

logMessage("Session Shutdown", "SPARK-SHUT", {&MIN_LOG_LEVEL}).

if valid-object(Ccs.Common.Application:StartupManager) then do:
    if valid-object(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager))) then do on error undo, leave:
        cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager):stopProcedures().
        logMessage("Catalog Shutdown, Procedures stopped", "SPARK-SHUT", {&MIN_LOG_LEVEL}).

        catch err as Progress.Lang.Error:
            logError("Catalog Shutdown Error", err, "SPARK-SHUT", 0).
        end catch.
    end.

    if valid-object(Ccs.Common.Application:StartupManager:getManager(get-class(ISchemaManager))) then do on error undo, leave:
        cast(Ccs.Common.Application:StartupManager:getManager(get-class(ISchemaManager)), ISchemaManager):deleteObjects().
        logMessage("Schema Shutdown, Objects deleted", "SPARK-SHUT", {&MIN_LOG_LEVEL}).

        catch err as Progress.Lang.Error:
            logError("Schema Shutdown Error", err, "SPARK-SHUT", 0).
        end catch.
    end.

    if valid-object(Ccs.Common.Application:ServiceManager) then do on error undo, leave:
        Ccs.Common.Application:ServiceManager:stopServices(ServiceLifeCycleEnum:session) no-error.
        logMessage("Service Shutdown, Session Life Cycle stopped", "SPARK-SHUT", {&MIN_LOG_LEVEL}).

        catch err as Progress.Lang.Error:
            logError("Service Shutdown Error", err, "SPARK-SHUT", 0).
        end catch.
    end.

    if valid-object(Ccs.Common.Application:StartupManager) then do on error undo, leave:
        cast(Ccs.Common.Application:StartupManager, IStartupManager):stopManagers() no-error.
        logMessage("Manager Shutdown, Application Managers stopped", "SPARK-SHUT", {&MIN_LOG_LEVEL}).

        catch err as Progress.Lang.Error:
            logError("Manager Shutdown Error", err, "SPARK-SHUT", 0).
        end catch.
    end.

    /* Dispose of the remaining managers. */
    Ccs.Common.Application:ServiceManager:dispose() no-error.
    Ccs.Common.Application:SessionManager:dispose() no-error.
    Ccs.Common.Application:StartupManager:dispose() no-error.
    Ccs.Common.Application:ServiceManager = ?.
    Ccs.Common.Application:SessionManager = ?.
    Ccs.Common.Application:StartupManager = ?.
end. /* valid-object() */

define temp-table ttServerObjects no-undo
    field objectType     as character
    field objectFileName as character
    field objectHandle   as integer
    index idxObjFileType as primary objectType objectFileName
    .

if log-manager:logging-level ge {&MIN_LOG_LEVEL} then do:
    run logObjects. /* Export information about objects still in memory. */
    logMessage("Session Shutdown, Memory Dumped", "SPARK-SHUT", {&MIN_LOG_LEVEL}).
end.

catch err as Progress.Lang.Error:
    logError("Session Shutdown Error", err, "SPARK-SHUT", 0).
    logMessage(err:callstack, "SPARK-SHUT", 0).
end catch.

procedure logObjects private:
    define variable hTemp    as handle                      no-undo.
    define variable oTemp    as Progress.Lang.Object        no-undo.
    define variable iCount   as integer                     no-undo.
    define variable cFile    as character                   no-undo.
    define variable oRequest as Progress.Lang.OERequestInfo no-undo.

    empty temp-table ttServerObjects.

    hTemp = session:first-procedure.
    do while valid-handle(hTemp):
        create ttServerObjects.
        assign
            ttServerObjects.objectType     = "Procedure"
            ttServerObjects.objectFileName = hTemp:file-name
            ttServerObjects.objectHandle   = hTemp
            no-error.
        hTemp = hTemp:next-sibling.
    end.

    hTemp = session:first-buffer.
    do while valid-handle(hTemp):
        create ttServerObjects.
        assign
            ttServerObjects.objectType     = "Buffer"
            ttServerObjects.objectFileName = substitute("Name:&1, Table:&2, DataSet:&3", hTemp:name, hTemp:table, hTemp:dataset:name)
            ttServerObjects.objectHandle   = hTemp
            no-error.
        hTemp = hTemp:next-sibling.
    end.

    hTemp = session:first-data-source.
    do while valid-handle(hTemp):
        create ttServerObjects.
        assign
            ttServerObjects.objectType     = "Data Source"
            ttServerObjects.objectFileName = substitute("Name:&1, Query:&2", hTemp:name, hTemp:query:prepare-string)
            ttServerObjects.objectHandle   = hTemp
            no-error.
        hTemp = hTemp:next-sibling.
    end.

    hTemp = session:first-dataset.
    do while valid-handle(hTemp):
        create ttServerObjects.
        assign
            ttServerObjects.objectType     = "Dataset"
            ttServerObjects.objectFileName = substitute("Name:&1, Dynamic:&2", hTemp:name, hTemp:dynamic)
            ttServerObjects.objectHandle   = hTemp
            no-error.
        hTemp = hTemp:next-sibling.
    end.

    hTemp = session:first-query.
    do while valid-handle(hTemp):
        create ttServerObjects.
        assign
            ttServerObjects.objectType     = "Query"
            ttServerObjects.objectFileName = substitute("Name:&1, Dynamic:&2, Query:&3", hTemp:name, hTemp:dynamic, hTemp:prepare-string)
            ttServerObjects.objectHandle   = hTemp
            no-error.
        hTemp = hTemp:next-sibling.
    end.

    hTemp = session:first-socket.
    do while valid-object(oTemp):
        create ttServerObjects.
        assign
            ttServerObjects.objectType     = "Socket"
            ttServerObjects.objectFileName = substitute("Name:&1, Dynamic:&2", hTemp:name, hTemp:dynamic)
            ttServerObjects.objectHandle   = hTemp
            no-error.
        hTemp = hTemp:next-sibling.
    end.

    oTemp = session:first-object.
    do while valid-object(oTemp):
        create ttServerObjects.
        assign
            ttServerObjects.objectType   = "Object"
            ttServerObjects.objectHandle = hTemp
            no-error.
        assign
            ttServerObjects.objectFileName = substitute("&1, &2", oTemp:GetClass():TypeName, oTemp:ToString()) no-error.
        if error-status:error then
            ttServerObjects.objectFileName = substitute("&1, &2", oTemp:GetClass():TypeName, "XXXX") no-error.
        oTemp = oTemp:next-sibling.
    end.

    /* Create output file using current Agent PID and Session ID. */
    assign oRequest = cast(session:current-request-info, Progress.Lang.OERequestInfo).
    assign cFile = substitute("&1/MemDump_A&2_S&3.txt",
                              right-trim(replace(session:temp-directory, "~\", "~/"), "~/"),
                              oRequest:AgentId, oRequest:SessionId).
    delete object oRequest no-error.

    output to value(cFile).
    for each ttServerObjects no-lock:
        iCount = iCount + 1.
        export delimiter "," ttServerObjects.
    end.
    output close.

    logMessage(substitute("Memory dumped to &1. &2 objects still in memory", cFile, iCount), "SPARK-SHUT", 0).
end procedure.
