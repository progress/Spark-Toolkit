/*------------------------------------------------------------------------
    File        : OEMetrics
    Purpose     : Gather and report OE metrics for the current PAS instance
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed Apr 25 13:58:59 EDT 2018
    Notes       : Provides front-end methods to enable/disable features
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Core.Assert from propath.
using OpenEdge.Logging.* from propath.
using Spark.Diagnostic.Util.ABLObjectsReport from propath.

block-level on error undo, throw.

class Spark.Diagnostic.Util.OEMetrics inherits Spark.Diagnostic.Util.Logger use-widget-pool final:

    define private variable dLastReportOutput as datetime no-undo initial ?.

    define private variable hServer as handle no-undo.

    define private variable hAsync as handle no-undo.

    /*** Static Instance ***/

    define public static property Instance as Spark.Diagnostic.Util.OEMetrics no-undo
        get():
            if not valid-object(Instance) then
                assign Instance = new Spark.Diagnostic.Util.OEMetrics().
            return Instance.
        end get.
        private set.

    /*** Common Properties ***/

    /* Property to allow sychronization of timestamps on output generation. */
    define private property OutputTime as datetime no-undo initial ? get. set.

    define private property RequestCount as integer no-undo initial 0 get. set.

    define private property RequestStart as datetime-tz no-undo initial ? get. set.

    define private property oConfig as Spark.Diagnostic.Util.OEMetricsConfig no-undo
        get():
            if oConfig eq ? or not valid-object(oConfig) then
                assign oConfig = new Spark.Diagnostic.Util.OEMetricsConfig(oLogger).
            if not valid-object(oConfig) then
                oLogger:Error("Unable to create OEMetricsConfig instance.").
            return oConfig.
        end get.
        set.

    define private property oABLObjectsReport as ABLObjectsReport no-undo
        get():
            if oABLObjectsReport eq ? or not valid-object(oABLObjectsReport) then
                assign oABLObjectsReport = new ABLObjectsReport(oConfig:ObjectsSource).
            return oABLObjectsReport.
        end get.
        set.


    /***** Constructor/Destructor *****/


    constructor public OEMetrics ( ):
        super().

        /* Make sure we have a consistent path for temporary files. */
        os-create-dir value(substitute("&1", this-object:TemporaryDir)).
        os-create-dir value(substitute("&1/metrics", this-object:TemporaryDir)).

        /* Make sure any necessary subdirectories are created. */
        os-create-dir value(substitute("&1/metrics/ABLObjects", this-object:TemporaryDir)).
        os-create-dir value(substitute("&1/metrics/ProfilerData", this-object:TemporaryDir)).
        os-create-dir value(substitute("&1/metrics/SessionData", this-object:TemporaryDir)).

        create server hServer. /* For potential use with APSV requests. */
    end constructor.


    destructor OEMetrics ( ):
        if valid-handle(hServer) and hServer:connected() then do:
            delete object hAsync no-error.
            hServer:disconnect().
            delete object hServer no-error.
        end. /* hServer */

        delete object oConfig no-error.
        delete object oLogger no-error.
        delete object oABLObjectsReport no-error.
        delete object Instance no-error.
    end destructor.


    /***** Private Methods *****/


    method private character GetSessionPath ( input piAgentID as integer ):
        define variable cBasePath as character no-undo.

        /* Assemble base path for output and create any needed directories. */
        assign cBasePath = substitute("&1/metrics/SessionData/&2", this-object:TemporaryDir, piAgentID).
        os-create-dir value(cBasePath).

        if this-object:OutputTime ne ? then
            return substitute("&1/&2.&3_A&4.json",
                              cBasePath,
                              iso-date(date(this-object:OutputTime)),
                              mtime(this-object:OutputTime), piAgentID).
        else
            return substitute("&1/&2.&3_A&4.json",
                              cBasePath,
                              iso-date(now),
                              mtime(now), piAgentID).
    end method. /* GetSessionPath */


    method private character GetObjectsPath ( input piAgentID   as integer,
                                              input piSessionID as integer ):
        define variable cBasePath as character no-undo.

        /* Assemble base path for output and create any needed directories. */
        assign cBasePath = substitute("&1/metrics/ABLObjects/&2", this-object:TemporaryDir, piAgentID).
        os-create-dir value(cBasePath).

        if this-object:OutputTime ne ? then
            return substitute("&1/&2.&3_A&4_S&5.json",
                              cBasePath,
                              iso-date(date(this-object:OutputTime)),
                              mtime(this-object:OutputTime), piAgentID, piSessionID).
        else
            return substitute("&1/&2.&3_A&4_S&5.json",
                              cBasePath,
                              iso-date(now),
                              mtime(now), piAgentID, piSessionID).
    end method. /* GetObjectsPath */


    method private logical InMatchList ( input pcCompare as character,
                                         input pcMatches as character ):
        /* Check if value matches something in the list. */
        define variable ix as integer no-undo.
        do ix = 1 to num-entries(pcMatches):
            if pcCompare matches entry(ix, pcMatches) then
                return true.
        end. /* do ix */

        return false.
    end method. /* InMatchList */


    method private OERequestInfo GetRequestInfo ( ):
        return cast(session:current-request-info, OERequestInfo).
    end method. /* GetRequestInfo */


    method private character GetProcedureName ( ):
        define variable oRequestInfo as OERequestInfo no-undo.

        assign oRequestInfo = this-object:GetRequestInfo().
        if valid-object(oRequestInfo) then
            return oRequestInfo:ProcedureName.

        return "".

        finally:
            delete object oRequestInfo no-error.
        end finally.
    end method. /* GetProcedureName */


    method private integer GetAgentID ( ):
        define variable oRequestInfo as OERequestInfo no-undo.

        assign oRequestInfo = this-object:GetRequestInfo().
        if valid-object(oRequestInfo) then
            return oRequestInfo:AgentId.

        return ?.

        finally:
            delete object oRequestInfo no-error.
        end finally.
    end method. /* GetAgentID */


    method private integer GetSessionID ( ):
        define variable oRequestInfo as OERequestInfo no-undo.

        assign oRequestInfo = this-object:GetRequestInfo().
        if valid-object(oRequestInfo) then
            return oRequestInfo:SessionId.

        return ?.

        finally:
            delete object oRequestInfo no-error.
        end finally.
    end method. /* GetSessionID */


    method private logical GetConnection ( ):
        if not valid-handle(hServer) or not valid-object(oConfig) then return false.

        if oConfig:ObjectsUseAPSV and not hServer:connected() then do:
            define variable cServerConn as character no-undo initial "".

            assign cServerConn = substitute("-URL &1 -sessionModel Session-managed", oConfig:ObjectsApsvURI).

            hServer:connect(cServerConn).
        end. /* ObjectsUseAPSV */

        return hServer:connected().
    end method. /* GetConnection */


    /***** Public Methods *****/


    method public logical StartProfiler ( ):
        /* Start the profiler with any config-set filtering. */
        if (oConfig:ProfilerFilter gt "") eq true then
            return this-object:StartProfiler(oConfig:ProfilerFilter).
        else
            return this-object:StartProfiler("*"). /* No filter. */
    end method. /* StartProfiler */


    method public logical StartProfiler ( input pcFilter as character ):
        /**
         * Method is created as static to allow starting of a profiler session
         * without need for a class instance. This makes it useful for starting
         * within a session activate procedure, while the writing of the report
         * can be done within a deactivate procedure. Therefore, this method can
         * have no other dependencies or requirements of a class-instance method.
         */

        /* Check if profiling is allowed, based on flags and scheduled time. */
        if not oConfig:IsProfilerEnabled("StartProfiler") then return false.
        if not oConfig:OnValidSchedule() then return false.

        define variable lFilterMatch as logical   no-undo initial false.
        define variable cBasePath    as character no-undo.
        define variable cProcedure   as character no-undo.
        define variable cOutPath     as character no-undo.
        define variable ix           as integer   no-undo.

        assign cProcedure = this-object:GetProcedureName().
        if (oConfig:PollingIgnoreList gt "") eq true then do:
            /* Do not proceed if current request procedure is on the ignore list. */
            if this-object:InMatchList(cProcedure, oConfig:PollingIgnoreList) then do:
                oLogger:Trace(substitute("[Profiler] Procedure Ignored: &1", cProcedure)).
                return false. /* Leave on first match of ignore list. */
            end. /* ignored */
        end. /* has ignore list */

        /* Obtain the request information and set/increment special values. */
        assign this-object:RequestCount = this-object:RequestCount + 1.
        assign this-object:RequestStart = now.

        /* Filter should not be blank, so fill with wildcard at least. */
        if (pcFilter gt "") ne true then assign pcFilter = "*".

        /* Check if requested procedure matches in the filter whitelist. */
        if this-object:InMatchList(cProcedure, pcFilter) then do:
            /* Create base path for output and create any needed directories. */
            assign cBasePath = substitute("&1/metrics/ProfilerData/&2",
                                          this-object:TemporaryDir, this-object:GetAgentID()).
            os-create-dir value(cBasePath).

            /* Determine correct output location for this profiler log. */
            assign cOutPath = substitute("&1/&2.&3_R&4_A&5_S&6.prof",
                                         cBasePath, iso-date(today), mtime, this-object:RequestCount,
                                         this-object:GetAgentID(), this-object:GetSessionID()).

            assign /* Note: Order matters here, do not rearrange! */
                profiler:enabled      = true
                profiler:profiling    = true
                profiler:file-name    = cOutPath
                profiler:description  = "Profiler Output"
                profiler:trace-filter = "*":u
                profiler:tracing      = "":u
                profiler:coverage     = true
                profiler:statistics   = true
                .

            return true.
        end. /* matches */

        return false. /* No filter matched for profiling. */

        catch err as Progress.Lang.Error:
            /* Should fail silently, while delivering errors to the standard local. */
            oLogger:Error(substitute("Error starting profiler: &1", err:GetMessage(1))).
            return false.
        end catch.
    end method. /* StartProfiler */


    method public logical WriteProfiler ( ):
        /* Start the profiler with any config-set filtering. */
        if oConfig:ProfilerThreshold gt 0 then
            return this-object:WriteProfiler(oConfig:ProfilerThreshold).
        else
            return this-object:WriteProfiler(0). /* No threshold. */
    end method. /* StartProfiler */


    method public logical WriteProfiler ( input piExecThreshold as integer ):
        /**
         * Method is created as static to allow profiler output to be generated at
         * any time in the request lifecycle without dependency on a class instance.
         * Output beyond the profiler data itself should be performed via the new
         * LogWriter feature to place information/errors into a dedicated log file.
         * This allows for additional context about a request to be logged without
         * generating a standalone file, whether the profiler output has been made
         * available or not (eg. excution time may always be reported).
         */

        if not oConfig:IsProfilerEnabled("WriteProfiler") then do:
            /* Even if profiling has been disabled, make sure we turn it off. */
            if profiler:enabled then
                assign
                    profiler:profiling = false
                    profiler:enabled   = false
                    .

            return false.
        end. /* not enabled */

        /* Determine the time elapsed for this request. */
        define variable iExecTime as integer no-undo initial 0.
        if this-object:RequestStart ne ? and this-object:RequestStart lt now then
            assign iExecTime = interval(now, this-object:RequestStart, "milliseconds" ).

        if profiler:enabled then do:
            /* Turn off the profiler, if previously enabled. */
            assign
                profiler:profiling = false
                profiler:enabled   = false
                .

            /* Only write the data out if execution time exceeds threshold. */
            if piExecThreshold eq ? or piExecThreshold lt 0 then assign piExecThreshold = 0.
            if iExecTime gt piExecThreshold then do:
                /* Execution time threshold met, output the profiler data. */
                oLogger:Info(substitute("&1 | &2ms | R&3 | A&4 | S&5",
                                        this-object:GetProcedureName(), iExecTime, this-object:RequestCount,
                                        this-object:GetAgentID(), this-object:GetSessionID())).
                profiler:write-data().
            end. /* iExecTime gt piExecThreshold */
            else
                oLogger:Debug(substitute("&1 | &2ms | -Threshold Not Met; No Profiler Output-",
                                         this-object:GetProcedureName(), iExecTime)).

            return true.
        end. /* profiler:enabled */
        else
            oLogger:Trace(substitute("&1 | &2ms | -Profiler Not Enabled-",
                                     this-object:GetProcedureName(), iExecTime)).

        return false. /* Profiler not enabled. */

        catch err as Progress.Lang.Error:
            /* Should fail silently, while delivering errors to the standard local. */
            oLogger:Error(substitute("Error writing profiler: &1", err:GetMessage(1))).
            return false.
        end catch.
    end method. /* WriteProfiler */


    method public logical StartTrackingObjects ( ):
        /**
         * Send the request to obtain the report by either local (JMX/OEM)
         * or remote (apsv) means. If using remote, the same code will be
         * utilized though hopefully in an asynchronous way.
         */

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("StartTrackingObjects") then return false.
        if not oConfig:OnValidSchedule() then return false.

        if oConfig:ObjectsUseAPSV then
        do on error undo, throw:
            if this-object:GetConnection() then do:
                run "Spark/Diagnostic/Interface/StartTrackingObjects.p" on server hServer
                    asynchronous set hAsync (this-object:GetAgentID(), this-object:GetProcedureName()) no-error.
                if error-status:error then
                    oLogger:Error(substitute("Error creating async handle: &1", error-status:get-message(1))).

                return true.
            end. /* Has Connection */

            catch err as Progress.Lang.Error:
                oLogger:Error(substitute("Error in APSV request: &1", err:GetMessage(1))).
                return false.
            end catch.
        end. /* Use APSV */
        else /* When no parameters passed, use the current agent ID. */
            return this-object:StartTrackingObjects(this-object:GetAgentID(), this-object:GetProcedureName()).
    end method. /* StartTrackingObjects */


    method public logical StartTrackingObjects ( input piAgentID   as integer,
                                                 input pcProcedure as character ):
        /**
         * Request the current agent start tracking ABLObjects. This
         * should first check a local flag to determine if tracking
         * has already been started, as a request via OEJMX can be
         * expensive, and the data is impossible to share across
         * session memory.
         */

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("StartTrackingObjects") then return false.
        if not oConfig:OnValidSchedule() then return false.

        define variable lIsTracking as logical   no-undo initial false.
        define variable cTrackFlag  as character no-undo.

        if (oConfig:PollingIgnoreList gt "") eq true then do:
            /* Do not proceed if current request procedure is on the ignore list. */
            if this-object:InMatchList(pcProcedure, oConfig:PollingIgnoreList) then do:
                oLogger:Trace(substitute("[Tracking] Procedure Ignored: &1", pcProcedure)).
                return false. /* Leave on first match of ignore list. */
            end. /* ignored */
        end. /* has ignore list */

        /* Avoid making the call to the agent if we have previously marked this agent as tracking objects. */
        assign cTrackFlag = oConfig:GetTrackingFlag(piAgentID).
        file-info:file-name = cTrackFlag.
        if file-info:full-pathname ne ? then do:
            assign lIsTracking = true. /* Flag exists, assume tracking is enabled. */
            oLogger:Debug(substitute("Tracking Agent #&1: &2", piAgentID, lIsTracking)).
        end. /* file exists */

        if not lIsTracking then /* Turn on tracking if not already, and get latest result. */
            assign lIsTracking = oABLObjectsReport:TrackABLObjects(piAgentID, true).

        /* Remember whether objects are being tracked for this agent. */
        if lIsTracking then do:
            output to value(cTrackFlag).
            /* No output, just touch file. */
            output close.
        end. /* Tracking */

        return lIsTracking.
    end method. /* StartTrackingObjects */


    method public logical StopTrackingObjects ( ):
        /* Run the request using the current agent ID. */
        return this-object:StopTrackingObjects(this-object:GetAgentID()).
    end method. /* StopTrackingObjects */


    method public logical StopTrackingObjects ( input piAgentID as integer ):
        /**
         * Request the current agent stop tracking ABLObjects.
         */

        if not oConfig:AreObjectsEnabled("StopTrackingObjects") then return false.

        /* Remove the agent flag when tracking is stopped. */
        define variable cTrackFlag as character no-undo.
        assign cTrackFlag = oConfig:GetTrackingFlag(piAgentID).
        file-info:file-name = cTrackFlag.
        if file-info:full-pathname ne ? then
            os-delete value(file-info:full-pathname).

        /* Just immediately disable the object tracking for this agent. */
        return oABLObjectsReport:TrackABLObjects(this-object:GetAgentID(), false).
    end method. /* StopTrackingObjects */


    method public logical GetABLObjects ( ):
        /**
         * Return the ABLObjects report from the current agent.
         */

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("GetABLObjects") then return false.
        if not oConfig:OnValidSchedule() then return false.

        define variable iAgentID   as integer    no-undo.
        define variable iCount     as integer    no-undo.
        define variable cProcedure as character  no-undo.
        define variable cSessionID as character  no-undo extent.
        define variable lReturn    as logical    no-undo initial false.
        define variable oObjReport as JsonObject no-undo.

        assign cProcedure = this-object:GetProcedureName().
        if (oConfig:PollingIgnoreList gt "") eq true then do:
            /* Do not proceed if current request procedure is on the ignore list. */
            if this-object:InMatchList(cProcedure, oConfig:PollingIgnoreList) then do:
                oLogger:Trace(substitute("[Objects] Procedure Ignored: &1", cProcedure)).
                return false. /* Leave on first match of ignore list. */
            end. /* ignored */
        end. /* has ignore list */

        assign iAgentID = this-object:GetAgentID(). /* Obtain the current AgentID. */

        /* Request the current ABLObjects report for this agent. */
        if oABLObjectsReport:FilterABLObjectReport(input  iAgentID,
                                                   input  oConfig:ObjectsExcluded,
                                                   output oObjReport) then do:
            /* Output a file for each session in the report. */
            assign cSessionID = oObjReport:GetNames().
            do iCount = 1 to extent(cSessionID):
                /* Output the report to a known location on disk for review/archival. */
                assign lReturn = oObjReport:GetJsonArray(cSessionID[iCount])
                                           :WriteFile(this-object:GetObjectsPath(iAgentID,
                                                                                 integer(cSessionID[iCount])),
                                                                                 true).
            end. /* do iCount */
        end. /* ParseABLObjectReport */

        return lReturn.

        finally:
            delete object oObjReport no-error.
        end finally.
    end method. /* GetABLObjects */


    method public logical TrackAllAgents ( input plEnable as logical ):
        /**
         * Obtain a list of all available agents and make a request to each
         * to begin tracking ABLObjects. This can be time-consuming if there
         * are many agents configured per PAS instance.
         */

        define variable oAgent   as JsonObject no-undo.
        define variable cAgentID as character  no-undo.
        define variable iCount   as integer    no-undo.
        define variable lSuccess as logical    no-undo initial false.

        /* Get the agents if object is not present. */
        if not valid-object(ABLObjectsReport:AgentList) then oABLObjectsReport:GetAgents().

        /* Make request to all agents of this ABLApp. */
        do iCount = 1 to ABLObjectsReport:AgentList:Length:
            /* Set request with PAS instance name and specific Agent ID. */
            assign oAgent = ABLObjectsReport:AgentList:GetJsonObject(iCount).
            if valid-object(oAgent) and oAgent:Has("pid") then do:
                /* Set the tracking option for this agent. */
                assign cAgentID = oAgent:GetCharacter("pid").
                if oABLObjectsReport:TrackABLObjects(integer(cAgentID), plEnable) then
                    assign lSuccess = true.
            end. /* has agentId */
        end. /* do iCount */

        return lSuccess.
    end method. /* TrackAllAgents */


    method public logical GetAllABLObjectsReport ( ):
        /**
         * Obtain a list of all available agents and make a request to each
         * to return the current ABLObjectsReport. This can be time-consuming
         * if there are many agents configured per PAS instance.
         */

        define variable oObjReport as JsonObject no-undo.
        define variable oAgent     as JsonObject no-undo.
        define variable cAgentID   as character  no-undo.
        define variable cSessionID as character  no-undo extent.
        define variable iCount     as integer    no-undo.
        define variable lReturn    as logical    no-undo initial false.

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("GetAllABLObjectsReport") then return false.
        if not oConfig:OnValidSchedule() then return false.

        /* Get the agents if object is not present. */
        if not valid-object(ABLObjectsReport:AgentList) then oABLObjectsReport:GetAgents().

        /* Make request to all agents of this ABLApp. */
        do iCount = 1 to ABLObjectsReport:AgentList:Length:
            /* Set request with PAS instance name and specific Agent ID. */
            assign oAgent = ABLObjectsReport:AgentList:GetJsonObject(iCount).
            if oAgent:Has("pid") then
            do on error undo, throw:
                /* Extract the current agent for examination. */
                assign cAgentID = oAgent:GetCharacter("pid").

                /* Request the ABL objects for this specific agent. */
                if oABLObjectsReport:FilterABLObjectReport(input  integer(cAgentID),
                                                           input  oConfig:ObjectsExcluded,
                                                           output oObjReport) then do:
                    /* Output a file for each session in the report. */
                    assign cSessionID = oObjReport:GetNames().
                    do iCount = 1 to extent(cSessionID):
                        /* Output the report to a known location on disk for review/archival. */
                        assign lReturn = oObjReport:GetJsonArray(cSessionID[iCount])
                                                   :WriteFile(this-object:GetObjectsPath(integer(cAgentID),
                                                                                         integer(cSessionID[iCount])),
                                                                                         true).
                    end. /* do iCount */
                end. /* ParseABLObjectReport */
            end. /* has agentId */
        end. /* do iCount */

        return lReturn.

        finally:
            delete object oObjReport no-error.
        end finally.
    end method. /* GetAllABLObjectsReport */


    method public logical GetSessionABLObjects ( ):
        /* When no parameters passed, use the current agent/session ID's. */
        return this-object:GetSessionABLObjects(this-object:GetAgentID(), this-object:GetSessionID()).
    end method. /* GetSessionABLObjects */


    method public logical GetSessionABLObjects ( input piAgentID   as integer,
                                                 input piSessionID as integer ):
        /**
         * Return the available ABLObjectsReport for the
         * agent and session of the current request.
         */

        define variable oObjReport as JsonArray no-undo.
        define variable cProcedure as character no-undo.
        define variable lReturn    as logical   no-undo initial false.

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("GetAllABLObjectsReport") then return false.
        if not oConfig:OnValidSchedule() then return false.

        assign cProcedure = this-object:GetProcedureName().
        if (oConfig:PollingIgnoreList gt "") eq true then do:
            /* Do not proceed if current request procedure is on the ignore list. */
            if this-object:InMatchList(cProcedure, oConfig:PollingIgnoreList) then do:
                oLogger:Trace(substitute("[Objects] Procedure Ignored: &1", cProcedure)).
                return false. /* Leave on first match of ignore list. */
            end. /* ignored */
        end. /* has ignore list */

        if piAgentID gt 0 and piSessionID gt 0 then do:
            /* Request the ABL objects for this specific agent and session. */
            if oABLObjectsReport:FilterSessionABLObjectReport(input  piAgentID,
                                                              input  piSessionID,
                                                              input  oConfig:ObjectsExcluded,
                                                              output oObjReport) then
                /* Output the report to a known location on disk for review/archival. */
                assign lReturn = oObjReport:WriteFile(this-object:GetObjectsPath(piAgentID, piSessionID), true).
        end. /* Has Agent/Session */

        return lReturn.

        finally:
            delete object oObjReport no-error.
        end finally.
    end method. /* GetSessionABLObjects */


    method public void GetSessionMetrics ( input piAgentID as integer ):
        /**
         * Send the request to obtain session metrics by either local (JMX/OEM)
         * or remote (apsv) means. If using remote, the same code will be
         * utilized though hopefully in an asynchronous way.
         */

        define variable oSessions as JsonArray.

        /* Check special flag for session metrics (eg. memory). */
        if not oConfig:ObjectsTrackMem then return.

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("GetSessionMetrics") then return.
        if not oConfig:OnValidSchedule() then return.

        /* Obtain the current list of sessions for this agent. */
        oABLObjectsReport:GetSessions(input piAgentID, output oSessions).

        /* Output the report to a known location on disk for review/archival. */
        if valid-object(oSessions) and oSessions:Length gt 0 then
            oSessions:WriteFile(this-object:GetSessionPath(piAgentID), true).
    end method. /* GetSessionMetrics */


    method public void PrepareSessionReports ( ):
        /**
         * Determine if the timing is right to output an ABLObject report
         * for the current agent/session based on reporting interval. Since
         * this class is started as a static instance, it should be tied to
         * one and ONLY one session for any given agent. Therefore, we should
         * be able to just check a single value in this class instance to know
         * when we last output data, and whether it is time to do so again.
         */

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("PrepareSessionABLObjectReport") then return.
        if not oConfig:OnValidSchedule() then return.

        define variable dNextObjectOutput as datetime no-undo initial ?.
        if oConfig:ObjectsOutputInterval gt 0 then do:
            if dLastReportOutput eq ? then do:
                assign
                    dLastReportOutput = now /* Begin the next reporting interval as of right now. */
                    dNextObjectOutput = add-interval(now, oConfig:ObjectsOutputInterval, "milliseconds")
                    .
            end.
            else
                assign dNextObjectOutput = add-interval(dLastReportOutput,
                                                        oConfig:ObjectsOutputInterval,
                                                        "milliseconds").
        end. /* oConfig:ObjectsOutputInterval gt 0 */
        else
            assign dNextObjectOutput = now.

        /* Request report output if current time is equal/greater than the next expected interval. */
        if now ge dNextObjectOutput then do:
            /* Immediately update the timestamp to avoid this session requesting the report again. */
            assign dLastReportOutput = now.

            /* Run the report request via APSV call or locally. */
            if oConfig:ObjectsUseAPSV then
            do on error undo, throw:
                if this-object:GetConnection() then do:
                    run "Spark/Diagnostic/Interface/PrepareSessionReports.p" on server hServer
                        asynchronous set hAsync (this-object:GetAgentID(),
                                                 this-object:GetSessionID()) no-error.
                    if error-status:error then
                        oLogger:Error(substitute("Error creating async handle: &1",
                                                 error-status:get-message(1))).
                end. /* Has Connection */

                catch err as Progress.Lang.Error:
                    oLogger:Error(substitute("Error in APSV request: &1", err:GetMessage(1))).
                end catch.
            end. /* Use APSV */
            else
                this-object:PrepareSessionReports(this-object:GetAgentID(), this-object:GetSessionID()).
        end. /* Do Output */
        else
            oLogger:Debug(substitute("Time Until Next Report Interval: &1s",
                                     interval(dNextObjectOutput, now, "seconds"))).
    end method. /* PrepareSessionReports */


    method public void PrepareSessionReports ( input piAgentID   as integer,
                                               input piSessionID as integer ):
        /**
         * Send the request to obtain the report by either local (JMX/OEM)
         * or remote (apsv) means. If using remote, the same code will be
         * utilized though hopefully in an asynchronous way.
         */

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("PrepareSessionABLObjectReport") then return.
        if not oConfig:OnValidSchedule() then return.

        /* Run the following reports for the given agent/session. */
        this-object:OutputTime = now. /* Synchronize output time. */
        oLogger:Info(substitute("Running reports for Agent '&1', Session '&2' at &3",
                                piAgentID, piSessionID, this-object:OutputTime)).
        this-object:GetSessionABLObjects(piAgentID, piSessionID). /* ABLObjects */
        if oConfig:ObjectsTrackMem then
            this-object:GetSessionMetrics(piAgentID). /* Memory, etc. */
        this-object:OutputTime = ?. /* Reset timestamp. */
    end method. /* PrepareSessionReports */

end class.
