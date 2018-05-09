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
using Spark.Diagnostic.Util.OEMetricsConfig from propath.
using Spark.Diagnostic.Util.OEMetrics from propath.

block-level on error undo, throw.

class Spark.Diagnostic.Util.OEMetrics inherits Spark.Diagnostic.Util.Logger use-widget-pool final: 

    define private variable dMetricsStarted as datetime no-undo initial ?.

    define private variable dLastObjectOutput as datetime no-undo initial ?.

    /*** Static Instance ***/

    define public static property Instance as Spark.Diagnostic.Util.OEMetrics no-undo
        get():
            if not valid-object(Instance) then
                assign Instance = new Spark.Diagnostic.Util.OEMetrics().
            return Instance.
        end get.
        private set.

    /*** Common Properties ***/

    define private property RequestCount as integer no-undo initial 0 get. set.

    define private property RequestStart as datetime-tz no-undo initial ? get. set.

    define private property oConfig as OEMetricsConfig no-undo get. set.

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
        os-create-dir value(substitute("&1/metrics/ABLObjectsReport", this-object:TemporaryDir)).
        os-create-dir value(substitute("&1/metrics/ProfilerData", this-object:TemporaryDir)).

        assign dMetricsStarted = now. /* Note when class was created. */
        assign oConfig = new OEMetricsConfig(oLogger). /* Configuration options. */
    end constructor.


    destructor OEMetrics ( ):
        delete object oConfig no-error.
        delete object oLogger no-error.
        delete object oABLObjectsReport no-error.
        delete object Instance no-error.
    end destructor.


    /***** Private Methods *****/


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

        define variable lFilterMatch as logical   no-undo initial false.
        define variable cBasePath    as character no-undo.
        define variable cProcedure   as character no-undo.
        define variable cOutPath     as character no-undo.
        define variable ix           as integer   no-undo.

        oConfig:RefreshConfig(). /* Update configuration options. */

        /* Check if profiling is allowed, based on flags and scheduled time. */
        if not oConfig:IsProfilerEnabled("StartProfiler") then return false.
        if not oConfig:OnValidSchedule() then return false.

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
            assign cBasePath = substitute("&1/metrics/ProfilerData/&2", this-object:TemporaryDir, this-object:GetAgentID()).
            os-create-dir value(cBasePath) no-error.

            /* Determine correct output location for this profiler log. */
            assign cOutPath = substitute("&1/&2.&3_R&4_A&5_S&6.prof",
                                         cBasePath, replace(iso-date(today), "-", ""), mtime, this-object:RequestCount,
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
                oLogger:Info(substitute("&1 | &2ms | &3",
                                        this-object:GetProcedureName(), iExecTime, profiler:file-name)).
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
         * Request the current agent start tracking ABLObjects. This
         * should first check a local flag to determine if tracking
         * has already been started, as a request via OEJMX can be
         * expensive, and the data is impossible to share across
         * session memory.
         */

        define variable iAgentID    as integer   no-undo.
        define variable cProcedure  as character no-undo.
        define variable cTrackFlag  as character no-undo.
        define variable lIsTracking as logical   no-undo initial false.
        define variable dFileCreate as datetime  no-undo.

        oConfig:RefreshConfig(). /* Update configuration options. */

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("StartTrackingObjects") then return false.
        if not oConfig:OnValidSchedule() then return false.

        assign cProcedure = this-object:GetProcedureName().
        if (oConfig:PollingIgnoreList gt "") eq true then do:
            /* Do not proceed if current request procedure is on the ignore list. */
            if this-object:InMatchList(cProcedure, oConfig:PollingIgnoreList) then do:
                oLogger:Trace(substitute("[Tracking] Procedure Ignored: &1", cProcedure)).
                return false. /* Leave on first match of ignore list. */
            end. /* ignored */
        end. /* has ignore list */

        assign iAgentID = this-object:GetAgentID(). /* Obtain the current AgentID. */

        /* Avoid making the call to the agent if we have previously marked this agent as tracking objects. */
        assign cTrackFlag = oConfig:GetTrackingFlag(iAgentID).
        file-info:file-name = cTrackFlag.
        if file-info:full-pathname ne ? then do:
            /* Make sure flag was created AFTER the agent started this class instance. */
            assign dFileCreate = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000).
            if dFileCreate lt dMetricsStarted then
                os-delete value(file-info:full-pathname). /* Remove the tracking flag. */
            else
                assign lIsTracking = true. /* Flag exists, assume tracking is enabled. */
        end. /* file exists */

        if not lIsTracking then /* Turn on tracking if not already, and get latest result. */
            assign lIsTracking = oABLObjectsReport:TrackABLObjects(string(iAgentID), true).

        /* Remember whether objects are being tracked for this agent. */
        if lIsTracking then do:
            output to value(cTrackFlag).
            /* No output, just touch file. */
            output close.
        end. /* Tracking */

        return lIsTracking.
    end method. /* StartTrackingObjects */


    method public logical StopTrackingObjects ( ):
        /**
         * Request the current agent stop tracking ABLObjects.
         */

        if not oConfig:AreObjectsEnabled("StopTrackingObjects") then return false.

        /* Just immediately disable the object tracking for this agent. */
        return oABLObjectsReport:TrackABLObjects(string(this-object:GetAgentID()), false).
    end method. /* StopTrackingObjects */
    

    method public logical GetABLObjectsReport ( ):
        /**
         * Return the ABLObjects report from the current agent.
         */

        define variable iAgentID   as integer    no-undo.
        define variable iCount     as integer    no-undo.
        define variable cProcedure as character  no-undo.
        define variable cSessionID as character  no-undo extent.
        define variable lReturn    as logical    no-undo initial false.
        define variable oObjReport as JsonObject no-undo.

        oConfig:RefreshConfig(). /* Update configuration options. */

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("GetABLObjectsReport") then return false.
        if not oConfig:OnValidSchedule() then return false.

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
        if oABLObjectsReport:ParseABLObjectReport(input  iAgentID,
                                                  input  oConfig:ObjectsExcluded,
                                                  output oObjReport) then do:
            /* Output a file for each session in the report. */
            assign cSessionID = oObjReport:GetNames().
            do iCount = 1 to extent(cSessionID):
                /* Output the report to a known location on disk for review/archival. */
                assign lReturn = oObjReport:GetJsonArray(cSessionID[iCount])
                                           :WriteFile(this-object:GetReportPath(iAgentID, integer(cSessionID[iCount])), true).
            end. /* do iCount */
        end. /* ParseABLObjectReport */

        return lReturn.

        finally:
            delete object oObjReport no-error.
        end finally.
    end method. /* GetABLObjectsReport */


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
                if oABLObjectsReport:TrackABLObjects(cAgentID, plEnable) then
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

        oConfig:RefreshConfig(). /* Update configuration options. */

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
                if oABLObjectsReport:ParseABLObjectReport(input  cAgentID,
                                                          input  oConfig:ObjectsExcluded,
                                                          output oObjReport) then do:
                    /* Output a file for each session in the report. */
                    assign cSessionID = oObjReport:GetNames().
                    do iCount = 1 to extent(cSessionID):
                        /* Output the report to a known location on disk for review/archival. */
                        assign lReturn = oObjReport:GetJsonArray(cSessionID[iCount])
                                                   :WriteFile(this-object:GetReportPath(integer(cAgentID), integer(cSessionID[iCount])), true).
                    end. /* do iCount */
                end. /* ParseABLObjectReport */
            end. /* has agentId */
        end. /* do iCount */

        return lReturn.

        finally:
            delete object oObjReport no-error.
        end finally.
    end method. /* GetAllABLObjectsReport */


    method public logical GetSessionABLObjectsReport ( ):
        /**
         * Return the available ABLObjectsReport for the
         * agent and session of the current request.
         */

        define variable oObjReport as JsonArray no-undo.
        define variable iAgentID   as integer   no-undo.
        define variable iSessionID as integer   no-undo.
        define variable cProcedure as character no-undo.
        define variable lReturn    as logical   no-undo initial false.

        oConfig:RefreshConfig(). /* Update configuration options. */

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

        assign /* Get values from current request. */
            iAgentID   = this-object:GetAgentID()
            iSessionID = this-object:GetSessionID()
            .

        if iAgentID gt 0 and iSessionID gt 0 then do:
            /* Request the ABL objects for this specific agent and session. */
            if oABLObjectsReport:ParseSessionABLObjectReport(input  iAgentID,
                                                             input  iSessionID,
                                                             input  oConfig:ObjectsExcluded,
                                                             output oObjReport) then
                /* Output the report to a known location on disk for review/archival. */
                assign lReturn = oObjReport:WriteFile(this-object:GetReportPath(iAgentID, iSessionID), true).
        end. /* Has Agent/Session */

        return lReturn.

        finally:
            delete object oObjReport no-error.
        end finally.
    end method. /* GetSessionABLObjectsReport */


    method public void PrepareABLObjectReport ( ):
        /**
         * Determine if the timing is right to output an ABLObject report
         * for the current agent/session based on reporting interval. Since
         * this class is started as a static instance, it should be tied to
         * one and ONLY one session for any given agent. Therefore, we should
         * be able to just check a single value in this class instance to know
         * when we last output data, and whether it is time to do so again.
         */

        define variable dNextObjectOutput as datetime no-undo initial ?.
        if dLastObjectOutput eq ? then do:
            assign
                dLastObjectOutput = now /* Begin the next interval as of right now. */
                dNextObjectOutput = add-interval(now, oConfig:ObjectsOutputInterval, "milliseconds")
                .
        end.
        else
            assign dNextObjectOutput = add-interval(dLastObjectOutput, oConfig:ObjectsOutputInterval, "milliseconds").

        /* Request report output if current time is equal/greater than the next expected interval. */
        if now ge dNextObjectOutput then do:
            /* Run the report request and update the timestamp. */
            this-object:GetSessionABLObjectsReport().
            assign dLastObjectOutput = now.
        end. /* Do Output */
        else
            oLogger:Debug(substitute("Time Until Next ABLObjects Report: &1ms",
                                     interval(dNextObjectOutput, now, "milliseconds"))).
    end method. /* PrepareABLObjectReport */

end class.
