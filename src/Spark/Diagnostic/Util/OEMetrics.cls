/*------------------------------------------------------------------------
    File        : OEMetrics
    Purpose     : Gather and report OE metrics for the current PAS instance
    Description : Utilizes JMX or OEManager queries to get PAS metrics
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed Apr 25 13:58:59 EDT 2018
    Notes       : Provides front-end methods to enable/disable features for
                  tracking metrics in a PASOE environment. For ABLObjects
                  the report must be requested at an application boundary,
                  meaning a point at the end of a request where all normal
                  cleanup has been performed and before the session is made
                  available for the next request. Depends on a configuration
                  file at CATALINA_BASE/bin/metrics_config.json to run the
                  necessary features. The name of this file is set in the
                  related metrics_setenv.[bat|sh] files which must also be
                  placed in the CATALINA_BASE/bin directory.
  ----------------------------------------------------------------------*/

/**
 * Changes, Dated 5/15/19
 *
 * The latest output scheme will gather all individual metrics into a single
 * JSON object. If a remote collector is enabled this data can be sent to the
 * remote server as a single packet of data. If no remote collector is enabled,
 * or the remote server does not respond, or the process fails with an error,
 * then the data will be written out to its respective folders on disk per the
 * former scheme. The data can then be processed via manual processes on the
 * same collector instance.
 */

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Core.Assert from propath.
using OpenEdge.Logging.* from propath.
using OpenEdge.Net.HTTP.HttpClient from propath.
using OpenEdge.Net.HTTP.IHttpRequest from propath.
using OpenEdge.Net.HTTP.IHttpResponse from propath.
using OpenEdge.Net.HTTP.RequestBuilder from propath.
using Spark.Diagnostic.Util.RemoteMetrics from propath.

block-level on error undo, throw.

class Spark.Diagnostic.Util.OEMetrics inherits Spark.Diagnostic.Util.Logger use-widget-pool final:

    define private variable dLastReportOutput as datetime no-undo initial ?.

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

    define private property ApplicationName as character no-undo initial ""
        get():
            if (ApplicationName gt "") ne true then do:
                /* If a default name was provided by the config, use that. */
                if (this-object:oConfig:DefaultAppName gt "") eq true then do:
                    assign ApplicationName = this-object:oConfig:DefaultAppName.
                end. /* DefaultAppName */
                else do:
                    /**
                     * If no available ABL Application was previously set/found,
                     * then match the correct ABLApp based on the current AgentID.
                     * This provides support for multiple ABL Applications in the
                     * current PAS instance, and must rely on the unique AgentID
                     * to identify the correct one currently used for this request
                     * (since AgentID's are unique across the instance). This call
                     * should pass the list of discovered ABL Applications via the
                     * OEMetricsConfig class (discovered via openedge.properties).
                     */
                    assign ApplicationName = this-object:oRemoteMetrics
                                                        :GetApplication(this-object:oConfig:ABLAppList:GetNames(),
                                                                        this-object:GetAgentID()).
                end. /* Discovered Name */
            end. /* blank value */

            return ApplicationName.
        end get.
        set.

    define private property RequestCount as integer no-undo initial 0 get. set.

    define private property RequestStart as datetime-tz no-undo initial ? get. set.

    define private property MetricsOutput as JsonObject no-undo get. set.

    /**
     * MetricsOutput Structure:
     *
     * {
     *   AppName: "",
     *   Instance: "",
     *   SampleName: "",
     *   Data: {
     *     ABLObjects: {
     *       Filename: "",
     *       Agent: 0,
     *       Session: 0,
     *       Data: []
     *     },
     *     Sessions: {
     *       Filename: "",
     *       Agent: 0,
     *       Data: []
     *     },
     *     Requests: {
     *       Filename: "",
     *       Agent: 0,
     *       Data: []
     *     }
     *   }
     * }
     *
     */

    /* URI for remote metrics collector, relative to server/port. */
    define private property CollectorMetricsURI as character no-undo
        initial "web/pdo/monitor/intake/liveMetrics"
        get. set.

    /* URI for remote profile collector, relative to server/port. */
    define private property CollectorProfileURI as character no-undo
        initial "web/pdo/monitor/intake/liveProfile"
        get. set.

    /* URI for remote profile collector, relative to server/port. */
    define private property CollectorLogsURI as character no-undo
        initial "web/pdo/monitor/intake/liveLogs"
        get. set.

    define private property oMetricsLogger as ILogWriter no-undo
        get():
            /* Obtain the propper ILogWriter instance for this class. */
            if session:current-request-info:AgentId eq ? then
                /* When no AgentID is available, just use a single bucket. */
                return LoggerBuilder:GetLogger("AgentMetrics").
            else
                /* Otherwise use the standard logger for the OEMetrics class. */
                return this-object:oLogger.
        end get.
        private set.

    define private property oConfig as Spark.Diagnostic.Util.OEMetricsConfig no-undo
        get():
            if oConfig eq ? or not valid-object(oConfig) then
                assign oConfig = new Spark.Diagnostic.Util.OEMetricsConfig(oMetricsLogger).
            else if valid-object(oConfig) then
                oConfig:SetLogger(oMetricsLogger). /* Set the appropriate ILogWriter instance. */

            if not valid-object(oConfig) then
                oMetricsLogger:Error("Unable to create OEMetricsConfig instance.").

            return oConfig.
        end get.
        set.

    define private property oRemoteMetrics as RemoteMetrics no-undo
        get():
            if oRemoteMetrics eq ? or not valid-object(oRemoteMetrics) then
                assign oRemoteMetrics = new RemoteMetrics(oConfig:RemoteSource).
            return oRemoteMetrics.
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
        os-create-dir value(substitute("&1/metrics/Requests", this-object:TemporaryDir)).
        os-create-dir value(substitute("&1/metrics/SessionData", this-object:TemporaryDir)).

        /* Create initial JSON object for output, supplying basic application information. */
        assign this-object:MetricsOutput = new JsonObject().
        this-object:MetricsOutput:Add("AppName", ""). /* Default to blank value initially. */
        this-object:MetricsOutput:Add("Instance", oConfig:InstanceURI).
        this-object:MetricsOutput:Add("SampleName", "").
        this-object:MetricsOutput:Add("Data", new JsonObject()).
    end constructor.


    destructor OEMetrics ( ):
        delete object oConfig no-error.
        delete object oLogger no-error.
        delete object oMetricsLogger no-error.
        delete object oRemoteMetrics no-error.
        delete object Instance no-error.
    end destructor.


    /***** Private Methods *****/


    method private character GetRequestPath ( input piAgentID as integer ):
        define variable cBasePath as character no-undo.

        /* Assemble base path for output and create any needed directories. */
        assign cBasePath = substitute("&1/metrics/Requests/&2", this-object:TemporaryDir, piAgentID).
        os-create-dir value(cBasePath).

        if this-object:OutputTime ne ? then
            return substitute("&1/&2.&3_A&4.json",
                              cBasePath,
                              iso-date(date(this-object:OutputTime)),
                              mtime(this-object:OutputTime), piAgentID).
        else
            return substitute("&1/&2.&3_A&4.json",
                              cBasePath,
                              iso-date(today),
                              mtime(now), piAgentID).
    end method. /* GetRequestPath */


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
                              iso-date(today),
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
                              iso-date(today),
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
        define variable iAgentID     as int64         no-undo.

        assign oRequestInfo = this-object:GetRequestInfo().
        if valid-object(oRequestInfo) then
            assign iAgentID = oRequestInfo:AgentId.

        /* Fallback for getting current PID from OS. */
        if iAgentID eq ? then do on error undo, leave:
            define variable hProc as handle no-undo.

            /* Run the appropriate internal procedure for the OS. */
            run Spark/Diagnostic/Util/GetPID persistent set hProc.
            if opsys eq "win32" then
                run GetCurrentProcessId in hProc ( output iAgentID ).
            else
                run GetPID in hProc ( output iAgentID ).

            finally:
                delete object hProc no-error.
            end finally.
        end. /* Unknown PID Value */

        /* Don't return an unknown PID. */
        if iAgentID eq ? then assign iAgentID = 0.

        return integer(iAgentID).

        finally:
            delete object oRequestInfo no-error.
        end finally.
    end method. /* GetAgentID */


    method private integer GetSessionID ( ):
        define variable oRequestInfo as OERequestInfo no-undo.
        define variable iSessionID   as integer       no-undo.

        assign oRequestInfo = this-object:GetRequestInfo().
        if valid-object(oRequestInfo) then
            assign iSessionID = oRequestInfo:SessionId.

        /* Don't return an unknown PID. */
        if iSessionID eq ? then assign iSessionID = 0.

        return iSessionID.

        finally:
            delete object oRequestInfo no-error.
        end finally.
    end method. /* GetSessionID */


    method private character GetRequestID ( ):
        define variable oRequestInfo as OERequestInfo no-undo.
        define variable cRequestID   as character     no-undo.

        assign oRequestInfo = this-object:GetRequestInfo().
        if valid-object(oRequestInfo) then
            assign cRequestID = oRequestInfo:RequestId.

        /* Don't return an unknown value. */
        if (cRequestID gt "") ne true then assign cRequestID = "".

        return cRequestID.

        finally:
            delete object oRequestInfo no-error.
        end finally.
    end method. /* GetRequestID */


    method private void ResetOutput ( ):
        /* Clean up any old metrics if they exist in the output object. */
        if this-object:MetricsOutput:GetJsonObject("Data"):Has("ABLObjects") then this-object:MetricsOutput:GetJsonObject("Data"):Remove("ABLObjects").
        if this-object:MetricsOutput:GetJsonObject("Data"):Has("Sessions") then this-object:MetricsOutput:GetJsonObject("Data"):Remove("Sessions").
        if this-object:MetricsOutput:GetJsonObject("Data"):Has("Requests") then this-object:MetricsOutput:GetJsonObject("Data"):Remove("Requests").
    end method. /* ResetOutput */


    method private logical SendToCollector ( input pcType as character,
                                             input pcData as JsonObject ):
        /* Send full MetricsOutput to remote collector endpoint. */
        define variable oBody       as JsonObject    no-undo.
        define variable cRequestURI as character     no-undo.
        define variable oHttpReq    as IHttpRequest  no-undo.
        define variable oHttpResp   as IHttpResponse no-undo.

        /* Prepare the URL to the remote PAS Monitor instance endpoint for data intake. */
        case pcType:
            when "metrics" then
                assign cRequestURI = substitute("&1://&2:&3/&4",
                                                oConfig:CollectorScheme, oConfig:CollectorServer,
                                                oConfig:CollectorPort, this-object:CollectorMetricsURI).
            when "profile" then
                assign cRequestURI = substitute("&1://&2:&3/&4",
                                                oConfig:CollectorScheme, oConfig:CollectorServer,
                                                oConfig:CollectorPort, this-object:CollectorProfileURI).
            when "logs" then
                assign cRequestURI = substitute("&1://&2:&3/&4",
                                                oConfig:CollectorScheme, oConfig:CollectorServer,
                                                oConfig:CollectorPort, this-object:CollectorLogsURI).
        end case.

        /* Prepare to send the metrics data as JSON to the endpoint. */
        oMetricsLogger:Info(substitute("Sending &1 data to collector at &2", caps(pcType), cRequestURI)).
        oHttpReq = RequestBuilder:Put(cRequestURI, pcData)
                                 :ContentType("application/json")
                                 :Request.
        oHttpResp = HttpClient:Instance():Execute(oHttpReq).

        /* Check the status code from the remote collector. */
        if oHttpResp:StatusCode ne 200 then
            undo, throw new AppError(substitute("Collector response code was not HTTP/200: &1", string(oHttpResp:StatusCode)), 0).

        if valid-object(oHttpResp:Entity) and type-of(oHttpResp:Entity, JsonObject) then
            assign oBody = cast(oHttpResp:Entity, JsonObject).

        if valid-object(oBody) and oBody:Has("success") and oBody:GetType("success") eq JsonDataType:Boolean then do:
            if oBody:GetLogical("success") then do:
                if oBody:Has("processed") and oBody:GetType("processed") eq JsonDataType:String then
                    oMetricsLogger:Info(substitute("Collector processed &1 at &2", pcType, oBody:GetCharacter("processed"))).
            end. /* success */
            else
                undo, throw new AppError("Unsuccessful response from collector.", 0).
        end. /* oBody */

        return false. /* Return false to indicate no errors during sending/processing. */

        catch err as Progress.Lang.Error:
            oMetricsLogger:Error(substitute("Error while sending to collector: &1", err:GetMessage(1))).
            return true. /* Mark failure if any error occurs. */
        end catch.
        finally:
            delete object oBody no-error.
            delete object oHttpReq no-error.
            delete object oHttpResp no-error.
        end finally.
    end method. /* SendToCollector */


    method private void WriteSessionReports ( input piAgentID   as integer,
                                              input piSessionID as integer ):
        define variable oSubObj as JsonObject no-undo.
        define variable lError  as logical    no-undo initial false.

        /* Note when this output is being generated. */
        oMetricsLogger:Debug(substitute("Writing metrics for ABLApp '&1'; Agent '&2', Session '&3'.",
                                        this-object:ApplicationName, piAgentID, piSessionID)).

        /* Output the collected metrics to the remote collector. */
        if oConfig:CollectorType eq "remote" then do:
            /* Make sure the ABL Application name is up to date before sending. */
            if this-object:MetricsOutput:Has("AppName") then
                this-object:MetricsOutput:Set("AppName", this-object:ApplicationName).
            else
                this-object:MetricsOutput:Add("AppName", this-object:ApplicationName).

            /* Use a common method to transport data, since the endpoints should be similar. */
            assign lError = this-object:SendToCollector("metrics", this-object:MetricsOutput).

            /* Dump the full metrics output object to disk if logging at trace level. */
            if not lError and oMetricsLogger:LogLevel eq LogLevelEnum:Trace then
                this-object:MetricsOutput:WriteFile(substitute("&1/metrics/MetricsOutput_&2.&3_A&4_S&5.json",
                                                               this-object:TemporaryDir, iso-date(today),
                                                               mtime, piAgentID, piSessionID), true).
        end. /* remote */

        /**
         * Output each of the MetricsOutput to local files on disk, separated by predetermined filename.
         * Applies if collector type is "file" or an error occurred when sending data to the remote collector.
         */
        if oConfig:CollectorType eq "file" or lError then do:
            oMetricsLogger:Debug("Writing metrics to local files.").

            if this-object:MetricsOutput:GetJsonObject("Data"):Has("ABLObjects") then do:
                assign oSubObj = this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("ABLObjects").

                if oSubObj:Has("Data") and oSubObj:GetType("Data") eq JsonDataType:Array and
                   oSubObj:Has("Filename") and oSubObj:GetType("Filename") eq JsonDataType:String then
                    oSubObj:GetJsonArray("Data"):WriteFile(oSubObj:GetCharacter("Filename"), true).
                else
                    oMetricsLogger:Warn("ABLObjects missing Data or Filename.").
            end. /* ABLObjects */

            if this-object:MetricsOutput:GetJsonObject("Data"):Has("Sessions") then do:
                assign oSubObj = this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("Sessions").

                if oSubObj:Has("Data") and oSubObj:GetType("Data") eq JsonDataType:Array and
                   oSubObj:Has("Filename") and oSubObj:GetType("Filename") eq JsonDataType:String then
                    oSubObj:GetJsonArray("Data"):WriteFile(oSubObj:GetCharacter("Filename"), true).
                else
                    oMetricsLogger:Warn("Sessions missing Data or Filename.").
            end. /* Sessions */

            if this-object:MetricsOutput:GetJsonObject("Data"):Has("Requests") then do:
                assign oSubObj = this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("Requests").

                if oSubObj:Has("Data") and oSubObj:GetType("Data") eq JsonDataType:Array and
                   oSubObj:Has("Filename") and oSubObj:GetType("Filename") eq JsonDataType:String then
                    oSubObj:GetJsonArray("Data"):WriteFile(oSubObj:GetCharacter("Filename"), true).
                else
                    oMetricsLogger:Warn("Requests missing Data or Filename.").
            end. /* Requests */
        end. /* file */

        catch err as Progress.Lang.Error:
            oMetricsLogger:Error(substitute("Unable to output reports for Agent '&1', Session '&2': &3",
                                            piAgentID, piSessionID, err:GetMessage(1))).
            /* Just report error, don't throw any further. */
        end catch.
        finally:
            this-object:ResetOutput().
        end finally.
    end method. /* WriteSessionReports */


    /***** Public Methods *****/


    method public logical StartProfiler ( input pcTrackBy as character ):
        /* Start the profiler with any config-set filtering. */
        if (oConfig:ProfilerFilter gt "") eq true then
            return this-object:StartProfiler(pcTrackBy, oConfig:ProfilerFilter).
        else
            return this-object:StartProfiler(pcTrackBy, "*"). /* No filter. */
    end method. /* StartProfiler */


    method public logical StartProfiler ( input pcTrackBy as character,
                                          input pcFilter  as character ):
        /**
         * Method is meant to allow starting of the ABL profiler via either an
         * MSAS session startup or activate procedure, while the writing of the
         * report can be done within a session shutdown or deactivate procedure.
         * Note that the profiler can run either across an entire session or on
         * each request to a session, but not both.
         */

        /* Check if profiling is allowed, based on flags and scheduled time. */
        if not oConfig:IsProfilerEnabled("StartProfiler") then return false.
        if not oConfig:OnValidSchedule() then return false.

        /* Ignore start of profiler if not configured to track by stated type. */
        if pcTrackBy ne oConfig:ProfilerTrackBy then return false.

        define variable lFilterMatch as logical   no-undo initial false.
        define variable cBasePath    as character no-undo.
        define variable cOutPath     as character no-undo initial "".
        define variable cProcedure   as character no-undo.

        /* Get the current procedure, if available. */
        assign cProcedure = this-object:GetProcedureName().

        if (oConfig:PollingIgnoreList gt "") eq true then do:
            /* Do not proceed if current request procedure is on the ignore list. */
            if this-object:InMatchList(cProcedure, oConfig:PollingIgnoreList) then do:
                oMetricsLogger:Trace(substitute("[Profiler] Procedure Ignored: &1", cProcedure)).
                return false. /* Leave on first match of ignore list. */
            end. /* ignored */
        end. /* has ignore list */

        /* Create base path for output and create any needed directories. */
        assign cBasePath = substitute("&1/metrics/ProfilerData/&2",
                                      this-object:TemporaryDir, this-object:GetAgentID()).
        os-create-dir value(cBasePath).

        /* Always prepare to output if tracking by session. */
        if oConfig:ProfilerTrackBy eq "session" then do:
            /* Determine correct output location for this profiler log. */
            assign cOutPath = substitute("&1/&2.&3_A&4.prof",
                                         cBasePath, iso-date(today), mtime, this-object:GetAgentID()).
        end. /* Track By Session */
        else do:
            /* Filter should not be blank, so fill with wildcard at least. */
            if (pcFilter gt "") ne true then assign pcFilter = "*".

            /* Check if requested procedure matches in the filter whitelist. */
            if this-object:InMatchList(cProcedure, pcFilter) then do:
                /* Obtain the request information and set/increment special values. */
                assign this-object:RequestCount = this-object:RequestCount + 1.
                assign this-object:RequestStart = now.
                assign cOutPath = substitute("&1/&2.&3_R&4_A&5_S&6.prof",
                                             cBasePath, iso-date(today), mtime, this-object:RequestCount,
                                             this-object:GetAgentID(), this-object:GetSessionID()).
            end. /* matches */
        end. /* Track By Request */

        if (cOutPath gt "") eq true then do:
            assign /* Note: Order matters here, do not rearrange! */
                profiler:enabled      = true
                profiler:profiling    = true
                profiler:file-name    = cOutPath
                profiler:description  = "Profiler Output"
                /* As of OE 12.2 you cannot enable tracing without the -zproftmpf startup flag. */
                /*profiler:trace-filter = "":u*/
                /*profiler:tracing      = "":u*/
                profiler:coverage     = true
                profiler:statistics   = true
                .
            return true.
        end.

        return false. /* No filter matched for profiling. */

        catch err as Progress.Lang.Error:
            /* Should fail silently, while delivering errors to the standard local. */
            oMetricsLogger:Error(substitute("Error starting profiler: &1", err:GetMessage(1))).
            return false.
        end catch.
    end method. /* StartProfiler */


    method public logical WriteProfiler ( input pcTrackBy as character ):
        /* Start the profiler with any config-set filtering. */
        if oConfig:ProfilerThreshold gt 0 then
            return this-object:WriteProfiler(pcTrackBy, oConfig:ProfilerThreshold).
        else
            return this-object:WriteProfiler(pcTrackBy, 0). /* No threshold. */
    end method. /* StartProfiler */


    method public logical WriteProfiler ( input pcTrackBy       as character,
                                          input piExecThreshold as integer ):
        /**
         * Method is created as static to allow profiler output to be generated at
         * any time in the request lifecycle without dependency on a class instance.
         * Output beyond the profiler data itself should be performed via the new
         * LogWriter feature to place information/errors into a dedicated log file.
         * This allows for additional context about a request to be logged without
         * generating a standalone file, whether the profiler output has been made
         * available or not (eg. excution time may always be reported).
         */

        /* Ignore ending of profiler if not configured to track by stated type. */
        if pcTrackBy ne oConfig:ProfilerTrackBy then return false.

        if not oConfig:IsProfilerEnabled("WriteProfiler") then do:
            /* Even if profiling has been disabled, make sure we turn it off. */
            if profiler:enabled then
                assign
                    profiler:profiling = false
                    profiler:enabled   = false
                    .

            return false.
        end. /* not enabled */

        if profiler:enabled then do:
            /* Always turn off the profiler, if previously enabled. */
            assign
                profiler:profiling = false
                profiler:enabled   = false
                .

            /* Profiler data must be written to disk first. */
            if oConfig:ProfilerTrackBy eq "session" then do:
                oMetricsLogger:Debug(substitute("Write Profiler: A&1 | S&2",
                                                this-object:GetAgentID(),
                                                this-object:GetSessionID())).

                profiler:write-data(). /* Always write profiler data. */
            end. /* ProfilerTrackBy = Session */
            else do:
                /* Determine the time elapsed for this request. */
                define variable iExecTime as integer no-undo initial 0.
                if this-object:RequestStart ne ? and this-object:RequestStart lt now then
                    assign iExecTime = interval(now, this-object:RequestStart, "milliseconds" ).

                /* Only write the data out if execution time exceeds threshold. */
                if piExecThreshold eq ? or piExecThreshold lt 0 then assign piExecThreshold = 0.
                if iExecTime gt piExecThreshold then do:
                    /* Execution time threshold met, output the profiler data. */
                    oMetricsLogger:Debug(substitute("Write Profiler: &1 | &2ms | R&3 | A&4 | S&5",
                                                    this-object:GetProcedureName(), iExecTime, this-object:RequestCount,
                                                    this-object:GetAgentID(), this-object:GetSessionID())).

                    profiler:write-data(). /* Write profiler data when over threshold. */
                end. /* iExecTime gt piExecThreshold */
                else
                    oMetricsLogger:Trace(substitute("&1 | &2ms | -Threshold Not Met; No Profiler Output-",
                                                    this-object:GetProcedureName(), iExecTime)).
            end. /* ProfilerTrackBy = Request */

            /* Send profiler data to collector, if enabled. */
            if oConfig:CollectorType eq "remote" then do on error undo, throw:
                define variable lcProfile as longchar   no-undo.
                define variable oProfiler as JsonObject no-undo.

                /* Load the file into a longchar variable. */
                copy-lob from file profiler:file-name to lcProfile no-error.

                /* Prepare the JSON data for the collector. */
                assign oProfiler = new JsonObject().
                oProfiler:Add("AppName", this-object:ApplicationName).
                oProfiler:Add("Instance", oConfig:InstanceURI).
                oProfiler:Add("AgentPID", this-object:GetAgentID()).
                oProfiler:Add("ABLSessionID", this-object:GetSessionID()).
                oProfiler:Add("RequestID", this-object:GetRequestID()).
                oProfiler:Add("Data", lcProfile).

                /* Send the file and then delete if no error reported. */
                if not this-object:SendToCollector("profile", oProfiler) then
                    os-delete value(profiler:file-name) no-error.

                catch err as Progress.Lang.Error:
                    /* Just report any errors, but don't throw further (code should be allowed to exit cleanly). */
                    oMetricsLogger:Error(substitute("Error sending profile data to collector: &1", err:GetMessage(1))).
                end catch.
                finally:
                    assign lcProfile = ?.
                    delete object oProfiler no-error.
                end finally.
            end. /* remote */

            return true.
        end. /* profiler:enabled */
        else
            oMetricsLogger:Trace(substitute("&1 | &2ms | -Profiler Not Enabled-",
                                            this-object:GetProcedureName(), iExecTime)).

        return false. /* Profiler not enabled. */

        catch err as Progress.Lang.Error:
            /* Should fail silently, while delivering errors to the standard local. */
            oMetricsLogger:Error(substitute("Error writing profiler: &1", err:GetMessage(1))).
            return false.
        end catch.
    end method. /* WriteProfiler */


    method public void ProcessAccessLogs ():
        define variable lcLogData as longchar   no-undo.
        define variable oAccess   as JsonObject no-undo.
        define variable oLogs     as JsonArray  no-undo.
        define variable cLogDir   as character  no-undo.
        define variable cFileName as character  no-undo.
        define variable cFullName as character  no-undo.
        define variable cCodes    as character  no-undo.
        define variable cLogFiles as character  no-undo.
        define variable iX        as integer    no-undo.

        /* If not enabled for remote collection, leave. */
        if oConfig:CollectorType ne "remote" then return.

        /* Prepare the JSON data for the collector. */
        assign oAccess = new JsonObject().
        oAccess:Add("AppName", this-object:ApplicationName).
        oAccess:Add("Instance", oConfig:InstanceURI).

        /* Prevents multiple agent-sessions from sending the same log files. */
        define variable lIsSending as logical   no-undo initial false.
        define variable cSendFlag  as character no-undo.

        /* Avoid making the call to the agent if we have previously marked this agent as tracking objects. */
        assign cSendFlag = substitute("&1~/logs~/&2_log.sending", this-object:CatalinaBase, this-object:ApplicationName).
        file-info:file-name = cSendFlag.
        if file-info:full-pathname ne ? then
            assign lIsSending = true. /* Flag exists, assume tracking is enabled. */
        oMetricsLogger:Debug(substitute("Sending Logs for &1: &2", this-object:ApplicationName, lIsSending)).

        /* If not sending the log file, claim ownership of the task for the application and do it. */
        if not lIsSending then do:
            /* Set the semaphore to declare the log is being sent via this application. */
            output to value(cSendFlag).
            /* No output, just touch file. */
            output close.

            /* Look within the standard TC logs folder for access logs. */
            assign cLogDir = substitute("&1~/logs", this-object:CatalinaBase).
            oMetricsLogger:Trace(substitute("Checking log directory '&1'.", cLogDir)).
            input from os-dir(cLogDir) no-echo.
            repeat:
                import cFileName cFullName cCodes.

                if cFileName = "." or
                   cFileName = ".." then next.

                if cFileName matches "localhost_access_log*" or
                   cFileName matches "localhost-access*.log" then do:
                    assign cLogFiles = trim(substitute("&1,&2", cLogFiles, cFullName), ",").
                    oMetricsLogger:Trace(substitute("Found access log file '&1'.", cFileName)).
                end.
            end.
            input close.

            /* Add each access log into an array as longchar. */
            assign oLogs = new JsonArray().
            do iX = 1 to num-entries(cLogFiles, ","):
                assign
                    lcLogData = ?
                    cFileName = entry(iX, cLogFiles)
                    .
                copy-lob from file cFilename to lcLogData no-error.
                oLogs:Add(lcLogData).
            end. /* do iX */
            oAccess:Add("Data", oLogs).
            oMetricsLogger:Info(substitute("Located &1 access log file(s) for parsing.", oLogs:Length)).

            /* Send without regard for failure (since we have the file locally). */
            this-object:SendToCollector("logs", oAccess).
        end. /* not lIsSending */

        catch err as Progress.Lang.Error:
            /* Just report any errors, but don't throw further (code should be allowed to exit cleanly). */
            oMetricsLogger:Error(substitute("Error sending access log data to collector: &1", err:GetMessage(1))).
        end catch.
        finally:
            assign lcLogData = ?.
            delete object oAccess no-error.
            if lIsSending then
                os-delete value(cSendFlag) no-error.
        end finally.
    end method. /* ProcessAccessLogs */


    method public logical StartTrackingObjects ( ):
        /**
         * Send the request to obtain the report by JMX/OEM.
         */

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("StartTrackingObjects") then return false.
        if not oConfig:OnValidSchedule() then return false.

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

        /* Update username/password for OEM, if enabled. */
        oConfig:UpdateCredentialsOEM(oRemoteMetrics).

        define variable lIsTracking as logical   no-undo initial false.
        define variable cTrackFlag  as character no-undo.

        if (oConfig:PollingIgnoreList gt "") eq true then do:
            /* Do not proceed if current request procedure is on the ignore list. */
            if this-object:InMatchList(pcProcedure, oConfig:PollingIgnoreList) then do:
                oMetricsLogger:Trace(substitute("[Tracking] Procedure Ignored: &1", pcProcedure)).
                return false. /* Leave on first match of ignore list. */
            end. /* ignored */
        end. /* has ignore list */

        /* Avoid making the call to the agent if we have previously marked this agent as tracking objects. */
        assign cTrackFlag = oConfig:GetTrackingFlag(piAgentID).
        file-info:file-name = cTrackFlag.
        if file-info:full-pathname ne ? then
            assign lIsTracking = true. /* Flag exists, assume tracking is enabled. */
        oMetricsLogger:Debug(substitute("Tracking Agent #&1: &2", piAgentID, lIsTracking)).

        if not lIsTracking then do:
            /* Turn on tracking if not already enabled, and record the latest result. */
            assign lIsTracking = oRemoteMetrics:TrackABLObjects(this-object:ApplicationName, piAgentID, true).

            /* Remember whether objects are being tracked for this agent. */
            if lIsTracking then do:
                output to value(cTrackFlag).
                /* No output, just touch file. */
                output close.
            end. /* Tracking */

            /* Also begin tracking requests by making an initial call to this endpoint. */
            if oConfig:AreRequestsEnabled("StartTrackingObjects") then
                this-object:GetRequestMetrics(piAgentID).
        end. /* not lIsTracking */

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

        /* Update username/password for OEM, if enabled. */
        oConfig:UpdateCredentialsOEM(oRemoteMetrics).

        /* Remove the agent flag when tracking is stopped. */
        define variable cTrackFlag as character no-undo.
        assign cTrackFlag = oConfig:GetTrackingFlag(piAgentID).
        file-info:file-name = cTrackFlag.
        if file-info:full-pathname ne ? then
            os-delete value(file-info:full-pathname) no-error.

        /* Just immediately disable the object tracking for this agent. */
        return oRemoteMetrics:TrackABLObjects(this-object:ApplicationName, this-object:GetAgentID(), false).
    end method. /* StopTrackingObjects */


    method public logical GetABLObjects ( ):
        /**
         * Return the ABLObjects report from the current agent.
         */

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("GetABLObjects") then return false.
        if not oConfig:OnValidSchedule() then return false.

        /* Update username/password for OEM, if enabled. */
        oConfig:UpdateCredentialsOEM(oRemoteMetrics).

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
                oMetricsLogger:Trace(substitute("[Objects] Procedure Ignored: &1", cProcedure)).
                return false. /* Leave on first match of ignore list. */
            end. /* ignored */
        end. /* has ignore list */

        assign iAgentID = this-object:GetAgentID(). /* Obtain the current AgentID. */

        /* Request the current ABLObjects report for this agent. */
        if oRemoteMetrics:FilterABLObjectReport(input  this-object:ApplicationName,
                                                input  iAgentID,
                                                input  oConfig:ClassesExcluded,
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


    method public logical TrackAllAgents ( input pcAppName as character,
                                           input plEnable  as logical ):
        /**
         * Obtain a list of all available agents and make a request to each
         * to begin tracking ABLObjects. This can be time-consuming if there
         * are many agents configured per PAS instance.
         */

        /* Update username/password for OEM, if enabled. */
        oConfig:UpdateCredentialsOEM(oRemoteMetrics).

        define variable cAgents  as character no-undo.
        define variable iAgentID as integer   no-undo.
        define variable iCount   as integer   no-undo.
        define variable lSuccess as logical   no-undo initial false.

        /* Get the latest list of agents. */
        oRemoteMetrics:GetAgents(pcAppName).

        /* Make request to all agents of this ABLApp. */
        if RemoteMetrics:Applications:Has(pcAppName) then
            assign cAgents = RemoteMetrics:Applications:GetCharacter(pcAppName).
        do iCount = 1 to num-entries(cAgents):
            /* Set the tracking option for this agent. */
            assign iAgentID = integer(entry(iCount, cAgents)).
            if oRemoteMetrics:TrackABLObjects(pcAppName, iAgentID, plEnable) then
                assign lSuccess = true.
        end. /* do iCount */

        return lSuccess.
    end method. /* TrackAllAgents */


    method public logical GetAllABLObjectsReport ( input pcAppName as character ):
        /**
         * Obtain a list of all available agents and make a request to each
         * to return the current ABLObjectsReport. This can be time-consuming
         * if there are many agents configured per PAS instance.
         */

        define variable oObjReport as JsonObject no-undo.
        define variable cAgents    as character  no-undo.
        define variable cSessionID as character  no-undo extent.
        define variable iAgentID   as integer    no-undo.
        define variable iCount     as integer    no-undo.
        define variable lReturn    as logical    no-undo initial false.

        /* Check if object reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreObjectsEnabled("GetAllABLObjectsReport") then return false.
        if not oConfig:OnValidSchedule() then return false.

        /* Update username/password for OEM, if enabled. */
        oConfig:UpdateCredentialsOEM(oRemoteMetrics).

        /* Get the latest list of agents. */
        oRemoteMetrics:GetAgents(pcAppName).

        /* Make request to all agents of this ABLApp. */
        if RemoteMetrics:Applications:Has(pcAppName) then
            assign cAgents = RemoteMetrics:Applications:GetCharacter(pcAppName).
        do iCount = 1 to num-entries(cAgents):
            /* Extract the current agent for examination. */
            assign iAgentID = integer(entry(iCount, cAgents)).

            /* Request the ABL objects for this specific agent. */
            if oRemoteMetrics:FilterABLObjectReport(input  pcAppName,
                                                    input  iAgentID,
                                                    input  oConfig:ClassesExcluded,
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
        if not oConfig:AreObjectsEnabled("GetSessionABLObjects") then return false.
        if not oConfig:OnValidSchedule() then return false.

        /* Update username/password for OEM, if enabled. */
        oConfig:UpdateCredentialsOEM(oRemoteMetrics).

        assign cProcedure = this-object:GetProcedureName().
        if (oConfig:PollingIgnoreList gt "") eq true then do:
            /* Do not proceed if current request procedure is on the ignore list. */
            if this-object:InMatchList(cProcedure, oConfig:PollingIgnoreList) then do:
                oMetricsLogger:Trace(substitute("[Objects] Procedure Ignored: &1", cProcedure)).
                return false. /* Leave on first match of ignore list. */
            end. /* ignored */
        end. /* has ignore list */

        if piAgentID gt 0 and piSessionID gt 0 then do:
            /* Request the ABL objects for this specific agent and session. */
            if oRemoteMetrics:FilterSessionABLObjectReport(input  this-object:ApplicationName,
                                                           input  piAgentID,
                                                           input  piSessionID,
                                                           input  oConfig:ClassesExcluded,
                                                           output oObjReport) then do:
                /* Output the report to the common JSON structure for tracking. */
                this-object:MetricsOutput:GetJsonObject("Data"):Add("ABLObjects", new JsonObject()).
                this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("ABLObjects"):Add("Filename", this-object:GetObjectsPath(piAgentID, piSessionID)).
                this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("ABLObjects"):Add("AgentPID", piAgentID).
                this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("ABLObjects"):Add("ABLSessionID", piSessionID).
                this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("ABLObjects"):Add("Data", cast(oObjReport:Clone(), JsonArray)).
                assign lReturn = true.
            end.
        end. /* Has Agent/Session */

        return lReturn.

        finally:
            delete object oObjReport no-error.
        end finally.
    end method. /* GetSessionABLObjects */


    method public void GetRequestMetrics ( input piAgentID as integer ):
        /**
         * Send the request to obtain request metrics by JMX/OEM.
         */

        define variable oRequests as JsonArray no-undo.
        define variable iX        as integer   no-undo.
        define variable iCount    as integer   no-undo.

        /* Check if general reporting is allowed, based on flags and scheduled time. */
        if not oConfig:AreRequestsEnabled("GetRequestMetrics") then return.
        if not oConfig:OnValidSchedule() then return.

        /* Update username/password for OEM, if enabled. */
        oConfig:UpdateCredentialsOEM(oRemoteMetrics).

        /* Obtain the current list of sessions for this agent. */
        oRemoteMetrics:GetRequestMetrics(input this-object:ApplicationName, input piAgentID, output oRequests).

        do iX = 1 to oRequests:Length:
            /* If a request ended prior to the last report from this session, delete the object. */
            if oRequests:GetJsonObject(iX):GetDatetime("EndTime") le dLastReportOutput then
                assign iCount = iX.
        end. /* do iX */

        /* Remove the old requests. */
        if iCount gt 1 then
            oRequests:Remove(1, iCount).

        /* Output the report to the common JSON structure for tracking. */
        if valid-object(oRequests) and oRequests:Length gt 0 then do:
            this-object:MetricsOutput:GetJsonObject("Data"):Add("Requests", new JsonObject()).
            this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("Requests"):Add("Filename", this-object:GetRequestPath(piAgentID)).
            this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("Requests"):Add("AgentPID", piAgentID).
            this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("Requests"):Add("Data", cast(oRequests:Clone(), JsonArray)).
        end.

        finally:
            delete object oRequests no-error.
        end finally.
    end method. /* GetRequestMetrics */


    method public void GetSessionMetrics ( input piAgentID as integer ):
        /**
         * Send the request to obtain session metrics by JMX/OEM.
         */

        define variable oSessions as JsonArray no-undo.

        /* Check if session metrics are allowed, based on flags and scheduled time. */
        if not oConfig:IsMemoryEnabled("GetSessionMetrics") then return.
        if not oConfig:OnValidSchedule() then return.

        /* Update username/password for OEM, if enabled. */
        oConfig:UpdateCredentialsOEM(oRemoteMetrics).

        /* Obtain the current list of sessions for this agent. */
        oRemoteMetrics:GetSessions(input this-object:ApplicationName, input piAgentID, output oSessions).

        /* Output the report to the common JSON structure for tracking. */
        if valid-object(oSessions) and oSessions:Length gt 0 then do:
            this-object:MetricsOutput:GetJsonObject("Data"):Add("Sessions", new JsonObject()).
            this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("Sessions"):Add("Filename", this-object:GetSessionPath(piAgentID)).
            this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("Sessions"):Add("AgentPID", piAgentID).
            this-object:MetricsOutput:GetJsonObject("Data"):GetJsonObject("Sessions"):Add("Data", cast(oSessions:Clone(), JsonArray)).
        end.

        finally:
            delete object oSessions no-error.
        end finally.
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

        oMetricsLogger:Trace("PrepareSessionReports called; Checking schedule, agent, and session...").

        /* Check if general reporting is allowed, based on scheduled time. */
        if not oConfig:OnValidSchedule() then return.

        define variable dNextReportOutput as datetime no-undo initial ?.
        if oConfig:OutputInterval gt 0 then do:
            /* Check when reports were last output. */
            if dLastReportOutput eq ? then do:
                assign
                    dLastReportOutput = now /* Begin the next reporting interval as of right now. */
                    dNextReportOutput = add-interval(now, oConfig:OutputInterval, "milliseconds")
                    .
            end. /* No Previous Interval Recorded */
            else
                assign dNextReportOutput = add-interval(dLastReportOutput,
                                                        oConfig:OutputInterval,
                                                        "milliseconds").
        end. /* oConfig:OutputInterval gt 0 */
        else
            assign dNextReportOutput = now. /* Prepare reports immediately. */

        /* Request report output if current time is equal/greater than the next expected interval. */
        if now ge dNextReportOutput then do:
            oMetricsLogger:Debug(substitute("Requesting reports for Agent '&1', Session '&2'.",
                                            this-object:GetAgentID(), this-object:GetSessionID())).
            this-object:PrepareSessionReports(this-object:GetAgentID(), this-object:GetSessionID()).

            /* Update the timestamp to avoid this session requesting the report again. */
            assign dLastReportOutput = now.
        end. /* Do Output */
        else
            oMetricsLogger:Debug(substitute("Time Until Next Report Interval: &1s",
                                            interval(dNextReportOutput, now, "seconds"))).

        catch err as Progress.Lang.Error:
            oMetricsLogger:Error(substitute("Unable to check last report output for Agent '&1', Session '&2': &3",
                                            this-object:GetAgentID(), this-object:GetSessionID(), err:GetMessage(1))).
            undo, throw err.
        end catch.
        finally:
            /* Always reset the current ABL Application name before the next request. */
            assign this-object:ApplicationName = "".
        end finally.
    end method. /* PrepareSessionReports */


    method public void PrepareSessionReports ( input piAgentID   as integer,
                                               input piSessionID as integer ):
        if piAgentID le 0 or piAgentID eq ? then return.
        if piSessionID le 0 or piSessionID eq ? then return.

        /**
         * Send the request to obtain the report by JMX/OEM.
         */
        oMetricsLogger:Debug(substitute("Preparing reports for Agent '&1', Session '&2'",
                                        piAgentID, piSessionID)).

        /* Check if reporting is allowed, based scheduled time. */
        if not oConfig:OnValidSchedule() then return.

        /* Run the following reports for the given agent/session. */
        this-object:OutputTime = now. /* Synchronize output time. */
        oMetricsLogger:Info(substitute("Running reports for Agent '&1', Session '&2' at &3",
                                       piAgentID, piSessionID, this-object:OutputTime)).

        /* Clean up any old metrics if they exist in the output object. */
        this-object:ResetOutput().

        if oConfig:AreObjectsEnabled("PrepareSessionReports") then
            this-object:GetSessionABLObjects(piAgentID, piSessionID). /* ABLObjects Report */

        if oConfig:IsMemoryEnabled("PrepareSessionReports") then
            this-object:GetSessionMetrics(piAgentID). /* Session Metrics, eg. Memory */

        if oConfig:AreRequestsEnabled("PrepareSessionReports") then
            this-object:GetRequestMetrics(piAgentID). /* Last 1000 Requests (or since last interval) */

        this-object:OutputTime = ?. /* Reset output timestamp. */

        catch err as Progress.Lang.Error:
            oMetricsLogger:Error(substitute("Unable to prepare reports for Agent '&1', Session '&2': &3",
                                            piAgentID, piSessionID, err:GetMessage(1))).
            undo, throw err.
        end catch.
        finally:
            /* Always attempt to output any content gathered. */
            this-object:WriteSessionReports(piAgentID, piSessionID).
        end finally.
    end method. /* PrepareSessionReports */

end class.
