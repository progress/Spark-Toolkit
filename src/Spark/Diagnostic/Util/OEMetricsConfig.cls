/*------------------------------------------------------------------------
    File        : OEMetricsConfig
    Purpose     : Provide a central object for metrics configuration options
    Description :
    Author(s)   : Dustin Grau
    Created     : Mon May 07 17:01:59 EDT 2018
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Logging.* from propath.

block-level on error undo, throw.

class Spark.Diagnostic.Util.OEMetricsConfig inherits Spark.Diagnostic.Util.OSPath use-widget-pool final:

    /* Tracks the last time the metrics config file was loaded from the file system. */
    define private variable dConfigLastLoaded as datetime no-undo initial ?.

    /* Tracks the last time the CB props file was loaded from the file system. */
    define private variable dCBPropsLastLoaded as datetime no-undo initial ?.

    /* Tracks the last time the OE props file was loaded from the file system. */
    define private variable dOEPropsLastLoaded as datetime no-undo initial ?.

    /*** Private Properties ***/

    define private property oLogger as ILogWriter no-undo get. set.

    define private property OEManagerUser as character no-undo initial "" get. set.

    define private property OEManagerPass as character no-undo initial "" get. set.

    define private property MetricsConfigFile as character no-undo initial "metrics_config.json"
        get. set.

    define private property MetricsConfigPath as character no-undo initial ""
        get():
            if MetricsConfigPath eq "" then do:
                /**
                 * Determine the location of the config file for this feature. By default
                 * the file should be called "metrics_config.json" and exist in either the
                 * conf/ or bin/ or SESSION-TEMP folders. If the name of the config file
                 * is custom, then it should be provided as a METRICS_CONFIG environment
                 * variable.
                 */
                if (trim(os-getenv("METRICS_CONFIG")) gt "") eq true then
                    this-object:MetricsConfigFile = trim(os-getenv("METRICS_CONFIG")).
                oLogger:Trace(substitute("CFG: Metrics Config Name: &1", this-object:MetricsConfigFile)).

                /* First, check the CATALINA_BASE/conf/ location. */
                file-info:filename = substitute("&1/conf/&2", this-object:CatalinaBase, this-object:MetricsConfigFile).
                if file-info:full-pathname eq ? then do:
                    /* Next, check the CATALINA_BASE/bin/ location. */
                    file-info:filename = substitute("&1/bin/&2", this-object:CatalinaBase, this-object:MetricsConfigFile).
                    if file-info:full-pathname eq ? then do:
                        /* Last, check the SESSION-TEMP location. */
                        file-info:filename = substitute("&1/&2", this-object:TemporaryDir, this-object:MetricsConfigFile).
                    end. /* not found in /bin/ */
                end. /* not found in /conf/ */

                /* If one of the above paths is still present, use that. */
                if file-info:full-pathname ne ? then
                    assign MetricsConfigPath = file-info:full-pathname.
                else
                    assign MetricsConfigPath = "". /* Keep blank if not found. */

                /* Provide context as to where we are getting our config options. */
                oLogger:Info(substitute("CFG: Metrics Config Path: &1", MetricsConfigPath)).
            end. /* MetricsConfigPath eq "" */

            return MetricsConfigPath.
        end get.
        set.

    /*** Public Properties ***/

    /* Tracks the list of ABL Applications and WebApps for this instance. */
    define public property ABLAppList as JsonObject no-undo get. private set.

    define public property DefaultAppName as character no-undo initial "" get. private set.

    define public property PollingIgnoreList as character no-undo initial "" get. private set.

    define public property PollingStartTime as datetime no-undo initial ? get. private set.

    define public property PollingStopTime as datetime no-undo initial ? get. private set.

    define public property ProfilerEnabled as logical no-undo initial false get. private set.

    define public property ProfilerFilter as character no-undo initial "" get. private set.

    define public property ProfilerThreshold as integer no-undo initial 0 get. private set.

    define public property ProfilerTrackBy as character no-undo initial "request" get. private set.

    define public property ClassesExcluded as character no-undo initial "" get. private set.

    define public property OutputInterval as integer no-undo initial 0 get. private set.

    define public property RemoteSource as character no-undo initial "oejmx" get. private set.

    define public property TrackMemory as logical no-undo initial false get. private set.

    define public property TrackObjects as logical no-undo initial false get. private set.

    define public property TrackRequests as logical no-undo initial false get. private set.

    define public property CollectorType as character no-undo initial "file" get. private set.

    define public property CollectorScheme as character no-undo initial "http" get. private set.

    define public property CollectorServer as character no-undo initial "localhost" get. private set.

    define public property CollectorPort as integer no-undo initial ? get. private set.

    define public property InstanceURI as character no-undo initial "" get. private set.


    /***** Constructor/Destructor *****/


    constructor public OEMetricsConfig ( input poLogger as ILogWriter ):
        super().

        assign oLogger = poLogger. /* Use the logger from the calling class. */
        assign ABLAppList = new JsonObject(). /* Create initial object. */
        this-object:RefreshConfig(). /* Obtain initial configuration options. */
    end constructor.


    /***** Private Methods *****/


    method private void Discovery ( ):
        define variable cLine        as character  no-undo.
        define variable cAppName     as character  no-undo.
        define variable cAppNames    as character  no-undo.
        define variable cWebApp      as character  no-undo.
        define variable cTransport   as character  no-undo.
        define variable cIPAddress   as character  no-undo.
        define variable lcConfigTemp as longchar   no-undo.
        define variable iLines       as integer    no-undo.
        define variable iLine        as integer    no-undo.
        define variable iX           as integer    no-undo.
        define variable iHttpPort    as integer    no-undo.
        define variable iHttpsPort   as integer    no-undo.
        define variable lFound       as logical    no-undo.
        define variable dLastDate    as datetime   no-undo.
        define variable oWebAppList  as JsonArray  no-undo.

        /* Examine the catalina.properties for info about the available ports. */
        file-info:file-name = substitute("&1/conf/catalina.properties", this-object:CatalinaBase).
        if file-info:full-pathname ne ? then do:
            /* Get the current date/time that the file was last modified. */
            assign dLastDate = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000).

            if dLastDate ne dCBPropsLastLoaded then do:
                /* Mark down the current modified date/time for this file. */
                assign dCBPropsLastLoaded = dLastDate.

                /* Read the file into a longchar value (avoids keeping the file open). */
                copy-lob from file file-info:full-pathname to lcConfigTemp no-error.

                assign iLines = num-entries(lcConfigTemp, "~n").
                if iLines ge 1 then cfgblk:
                do iLine = 1 to iLines:
                    assign cLine = trim(entry(iLine, lcConfigTemp, "~n")).

                    case true:
                        when cLine begins "psc.as.http.port=" then
                            assign iHttpPort = integer(trim(entry(2, cLine, "="))).
                        when cLine begins "psc.as.https.port=" then
                            assign iHttpsPort = integer(trim(entry(2, cLine, "="))).
                    end case.
                end. /* do iLines */

                /* Use a distinct INSTANCE_URI environment variable, if supplied. */
                if (trim(os-getenv("INSTANCE_URI")) gt "") eq true then
                    assign this-object:InstanceURI = trim(os-getenv("INSTANCE_URI")).
                else do:
                    assign cIPAddress = trim(os-getenv("PUBLIC_IP")).
                    if (cIPAddress gt "") ne true then
                        assign cIPAddress = "127.0.0.1". /* Defaul to loopback address. */

                    /* Look to the same server at either the HTTP or HTTPS port for OEManager. */
                    if iHttpPort gt 0 then
                        this-object:InstanceURI = substitute("http://&1:&2", cIPAddress, iHttpPort).
                    else if iHttpsPort gt 0 then
                        this-object:InstanceURI = substitute("https://&1:&2", cIPAddress, iHttpsPort).
                end. /* Assembled URL */

                assign lcConfigTemp = ?. /* Reset the variable. */
                oLogger:Trace(substitute("CFG: Completed discovery of catalina.properties [Instance: &1]", this-object:InstanceURI)).
            end. /* file updated */
        end. /* catalina.properties */

        /* Examine the openedge.properties for ABL Application and WebApp information. */
        file-info:file-name = substitute("&1/conf/openedge.properties", this-object:CatalinaBase).
        if file-info:full-pathname ne ? then do:
            /* Get the current date/time that the file was last modified. */
            assign dLastDate = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000).

            if dLastDate ne dOEPropsLastLoaded then do:
                assign this-object:DefaultAppName = "". /* Clear the default ABL Application name. */

                /* Mark down the current modified date/time for this file. */
                assign dOEPropsLastLoaded = dLastDate.

                /* Read the file into a longchar value (avoids keeping the file open). */
                copy-lob from file file-info:full-pathname to lcConfigTemp no-error.

                /* Read each line of the properties file, looking for transports. */
                assign iLines = num-entries(lcConfigTemp, "~n").
                if iLines ge 1 then cfgblk:
                do iLine = 1 to iLines:
                    assign cLine = trim(entry(iLine, lcConfigTemp, "~n")).

                    if cLine matches "[*.*.APSV]" or
                       cLine matches "[*.*.REST]" or
                       cLine matches "[*.*.SOAP]" or
                       cLine matches "[*.*.WEB]" then do:
                        assign cLine = replace(cLine, "[", "").
                        assign cLine = replace(cLine, "]", "").

                        assign
                            cAppName   = entry(1, cLine, ".")
                            cWebApp    = entry(2, cLine, ".")
                            cTransport = entry(3, cLine, ".")
                            lFound     = false
                            .

                        if ABLAppList:Has(cAppName) then
                            /* If an ABLApp exists it should have an array of WebApps. */
                            assign oWebAppList = ABLAppList:GetJsonArray(cAppName).
                        else
                            /* If no ABLApp then create new list of WebApp names. */
                            assign oWebAppList = new JsonArray().

                        /* WebApp names across the PAS instance must be unique. */
                        do iX = 1 to oWebAppList:Length:
                            if oWebAppList:GetCharacter(iX) eq cWebApp then
                                assign lFound = true.
                        end.

                        /* Add to list if not found. */
                        if not lFound then
                            oWebAppList:Add(cWebApp).

                        /* Either update or add the list of WebApps. */
                        if ABLAppList:Has(cAppName) then
                            ABLAppList:Set(cAppname, oWebAppList).
                        else do:
                            ABLAppList:Add(cAppname, oWebAppList).
                            cAppNames = substitute("&1,&2", cAppNames, cAppName).
                        end.
                    end. /* transport */
                end. /* do iLines */

                assign lcConfigTemp = ?. /* Reset the variable. */
                oLogger:Trace(substitute("CFG: Completed discovery of openedge.properties [ABL Apps: &1]", trim(cAppNames, ","))).
            end. /* file updated */
        end. /* openedge.properties */

        /* Check if only a single ABL Application exists. */
        define variable cNames as character no-undo extent.
        assign cNames = ABLAppList:GetNames().
        if extent(cNames) eq 1 and this-object:DefaultAppName ne cNames[1] then do:
            assign this-object:DefaultAppName = cNames[1]. /* Use the only name as the default application. */
            oLogger:Trace(substitute("CFG: Using default ABL Application: &1", this-object:DefaultAppName)).
        end.
    end method. /* Discovery */


    method private void ParseConfig ( ):
        /* Cannot proceed if the configuration file is not present. */
        if (this-object:MetricsConfigPath gt "") ne true then return.

        define variable oParser as ObjectModelParser no-undo.
        define variable oConfig as JsonObject        no-undo.
        define variable oSubObj as JsonObject        no-undo.
        define variable cNames  as character extent  no-undo.
        define variable ix      as integer           no-undo.

        /* Parse the config file as a JSON object. */
        assign oParser = new ObjectModelParser().
        assign oConfig = cast(oParser:ParseFile(MetricsConfigPath), JsonObject).

        /* Parse the contents of the JSON object. */
        if valid-object(oConfig) then do:
            assign cNames = oConfig:GetNames().

            /* Set properties based on config options. */
            do ix = 1 to extent(cNames):
                case cNames[ix]:
                    when "general" then do:
                        if oConfig:Has("general") and oConfig:GetType("general") eq JsonDataType:Object then do:
                            assign oSubObj = oConfig:GetJsonObject("general").

                            /* Use a default ABL Application name if specified either by config for ENV variable. */
                            if oSubObj:Has("limitAppName") and oSubObj:GetType("limitAppName") eq JsonDataType:String then
                                assign this-object:DefaultAppName = oSubObj:GetCharacter("limitAppName").
                            else if (trim(os-getenv("ABLAPP_NAME")) gt "") eq true then
                                assign this-object:DefaultAppName = trim(os-getenv("ABLAPP_NAME")).

                            if oSubObj:Has("pollIgnore") and oSubObj:GetType("pollIgnore") eq JsonDataType:String then
                                assign this-object:PollingIgnoreList = oSubObj:GetCharacter("pollIgnore").

                            if oSubObj:Has("pollStart") and oSubObj:GetType("pollStart") eq JsonDataType:String then
                                assign this-object:PollingStartTime = oSubObj:GetDatetime("pollStart").
                            else
                                assign this-object:PollingStartTime = ?.

                            if oSubObj:Has("pollStop") and oSubObj:GetType("pollStop") eq JsonDataType:String then
                                assign this-object:PollingStopTime = oSubObj:GetDatetime("pollStop").
                            else
                                assign this-object:PollingStopTime = ?.

                            if this-object:PollingStartTime ne ? and this-object:PollingStopTime ne ? then
                                oLogger:Debug(substitute("CFG: Using polling schedule: &1 to &2",
                                                         this-object:PollingStartTime,
                                                         this-object:PollingStopTime)).

                            delete object oSubObj no-error.
                        end. /* has sub-object */
                    end. /* general */

                    when "remote" then do:
                        if oConfig:Has("remote") and oConfig:GetType("remote") eq JsonDataType:Object then do:
                            assign oSubObj = oConfig:GetJsonObject("remote").

                            if oSubObj:Has("exclude") and oSubObj:GetType("exclude") eq JsonDataType:String then
                                assign this-object:ClassesExcluded = oSubObj:GetCharacter("exclude").

                            if oSubObj:Has("oemUser") and oSubObj:GetType("oemUser") eq JsonDataType:String then
                                assign this-object:OEManagerUser = oSubObj:GetCharacter("oemUser").

                            if oSubObj:Has("oemPass") and oSubObj:GetType("oemPass") eq JsonDataType:String then
                                assign this-object:OEManagerPass = oSubObj:GetCharacter("oemPass").

                            if oSubObj:Has("outputInterval") and oSubObj:GetType("outputInterval") eq JsonDataType:Number then
                                assign this-object:OutputInterval = oSubObj:GetInteger("outputInterval").

                            if oSubObj:Has("source") and oSubObj:GetType("source") eq JsonDataType:String then
                                assign this-object:RemoteSource = oSubObj:GetCharacter("source").

                            if oSubObj:Has("trackMemory") and oSubObj:GetType("trackMemory") eq JsonDataType:Boolean then
                                assign this-object:TrackMemory = oSubObj:GetLogical("trackMemory").

                            if oSubObj:Has("trackObjects") and oSubObj:GetType("trackObjects") eq JsonDataType:Boolean then
                                assign this-object:TrackObjects = oSubObj:GetLogical("trackObjects").

                            if oSubObj:Has("trackRequests") and oSubObj:GetType("trackRequests") eq JsonDataType:Boolean then
                                assign this-object:TrackRequests = oSubObj:GetLogical("trackRequests").

                            delete object oSubObj no-error.
                        end. /* has sub-object */
                    end. /* objects */

                    when "profiler" then do:
                        if oConfig:Has("profiler") and oConfig:GetType("profiler") eq JsonDataType:Object then do:
                            assign oSubObj = oConfig:GetJsonObject("profiler").

                            if oSubObj:Has("enabled") and oSubObj:GetType("enabled") eq JsonDataType:Boolean then
                                assign this-object:ProfilerEnabled = oSubObj:GetLogical("enabled").

                            if oSubObj:Has("filter") and oSubObj:GetType("filter") eq JsonDataType:String then
                                assign this-object:ProfilerFilter = oSubObj:GetCharacter("filter").

                            if oSubObj:Has("threshold") and oSubObj:GetType("threshold") eq JsonDataType:Number then
                                assign this-object:ProfilerThreshold = oSubObj:GetInteger("threshold").

                            if oSubObj:Has("trackBy") and oSubObj:GetType("trackBy") eq JsonDataType:String then
                                assign this-object:ProfilerTrackBy = oSubObj:GetCharacter("trackBy").

                            delete object oSubObj no-error.
                        end. /* has sub-object */
                    end. /* profiler */

                    when "collector" then do:
                        if oConfig:Has("collector") and oConfig:GetType("collector") eq JsonDataType:Object then do:
                            assign oSubObj = oConfig:GetJsonObject("collector").

                            /* If the collector is enabled, set type to "remote" otherwise use local files. */
                            if oSubObj:Has("enabled") and oSubObj:GetType("enabled") eq JsonDataType:Boolean then
                                assign this-object:CollectorType = trim(string(oSubObj:GetLogical("enabled"), "remote/file")).
                            else
                                assign this-object:CollectorType = "file".

                            if oSubObj:Has("scheme") and oSubObj:GetType("scheme") eq JsonDataType:String then
                                assign this-object:CollectorScheme = oSubObj:GetCharacter("scheme").
                            else
                                assign this-object:CollectorScheme = "http".

                            if oSubObj:Has("server") and oSubObj:GetType("server") eq JsonDataType:String then
                                assign this-object:CollectorServer = oSubObj:GetCharacter("server").
                            else
                                assign this-object:CollectorServer = "localhost".

                            if oSubObj:Has("port") and oSubObj:GetType("port") eq JsonDataType:Number then
                                assign this-object:CollectorPort = oSubObj:GetInteger("port").
                            else
                                assign this-object:CollectorPort = ?.

                            delete object oSubObj no-error.
                        end. /* has sub-object */
                    end. /* general */
                end case. /* cNames */
            end. /* do ix */
        end. /* valid object */

        oLogger:Trace(substitute("CFG: Completed parsing of &1", this-object:MetricsConfigPath)).

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("CFG: Error parsing config file: &1", err:GetMessage(1))).
            undo, throw err.
        end catch.
        finally:
            delete object oParser no-error.
            delete object oConfig no-error.
        end finally.
    end method. /* ParseConfig */


    /***** Public Methods *****/


    method public void SetLogger ( input poLogger as ILogWriter ):
        assign oLogger = poLogger.
    end method. /* SetLogger */


    method public void RefreshConfig ( ):
        /* Cannot proceed if the configuration file is not present. */
        if (this-object:MetricsConfigPath gt "") ne true then return.

        this-object:Discovery(). /* Perform local discovery of server info. */

        /* Load the metrics config file path as previously discovered. */
        file-info:file-name = this-object:MetricsConfigPath.
        if file-info:full-pathname ne ? then do:
            define variable dLastDate as datetime no-undo.

            /* Get the current date/time this file was modified. */
            assign dLastDate = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000).

            if dLastDate ne dConfigLastLoaded then do:
                oLogger:Debug(substitute("CFG: Updating metrics options from configuration file (&1).", this-object:MetricsConfigFile)).

                /* Mark down the current modified date/time for this file. */
                assign dConfigLastLoaded = dLastDate.

                /* Load and parse the current config file. */
                this-object:ParseConfig().
            end. /* File Changed */
        end. /* File Exists */
    end method. /* CheckConfig */


    method public void UpdateCredentialsOEM ( input poRemoteMetrics as Spark.Diagnostic.Util.RemoteMetrics ):
        if can-do("oem,oemanager", this-object:RemoteSource) then do:
            if (this-object:InstanceURI gt "") eq true then
                assign poRemoteMetrics:InstanceURI = this-object:InstanceURI.
            if (this-object:OEManagerUser gt "") eq true then
                assign poRemoteMetrics:ManagerUsername = this-object:OEManagerUser.
            if (this-object:OEManagerPass gt "") eq true then
                assign poRemoteMetrics:ManagerPassword = this-object:OEManagerPass.
        end. /* Using OEM */
    end method. /* UpdateCredentialsOEM */


    method public character GetTrackingFlag ( input piAgentID as integer ):
        os-create-dir value(substitute("&1/metrics/TrackingAgents", this-object:TemporaryDir)).

        return substitute("&1/metrics/TrackingAgents/&2", this-object:TemporaryDir, piAgentID).
    end method. /* GetTrackingFlag */


    method public logical AreObjectsEnabled ( input pcMethodName as character ):
        this-object:RefreshConfig(). /* Update configuration options. */

        if not this-object:TrackObjects then do:
            oLogger:Debug(substitute("CFG: Objects disabled, leaving &1", pcMethodName)).
            return false.
        end. /* not enabled */

        return true.
    end method. /* AreObjectsEnabled */


    method public logical IsMemoryEnabled ( input pcMethodName as character ):
        this-object:RefreshConfig(). /* Update configuration options. */

        if not this-object:TrackMemory then do:
            oLogger:Debug(substitute("CFG: Sessions disabled, leaving &1", pcMethodName)).
            return false.
        end. /* not enabled */

        return true.
    end method. /* IsMemoryEnabled */


    method public logical AreRequestsEnabled ( input pcMethodName as character ):
        this-object:RefreshConfig(). /* Update configuration options. */

        if not this-object:TrackRequests then do:
            oLogger:Debug(substitute("CFG: Requests disabled, leaving &1", pcMethodName)).
            return false.
        end. /* not enabled */

        return true.
    end method. /* AreRequestsEnabled */


    method public logical IsProfilerEnabled ( input pcMethodName as character ):
        this-object:RefreshConfig(). /* Update configuration options. */

        if not this-object:ProfilerEnabled then do:
            oLogger:Trace(substitute("CFG: Profiler disabled, leaving &1", pcMethodName)).
            return false.
        end. /* not enabled */

        return true.
    end method. /* IsProfilerEnabled */


    method public logical OnValidSchedule ():
        define variable lValid as logical  no-undo initial true.
        define variable tNow   as datetime no-undo.

        /* Determine if polling is controled by start/stop datetime values. */
        assign tNow = now.
        if this-object:PollingStartTime ne ? and this-object:PollingStopTime ne ? then do:
            /* Do not allow polling outside of scheduled start/stop times. */
            if tNow lt this-object:PollingStartTime then assign lValid = false. /* Before Start */
            if tNow gt this-object:PollingStopTime then assign lValid = false. /* After Stop */
        end. /* has polling schedule */

        if not lValid then /* Remark when current time is outside of the expected schedule. */
            oLogger:Trace(substitute("CFG: Configured schedule prevents tracking metrics at this time (&1).", tNow)).

        return lValid. /* Assumes polling is active if no specific timestamps present. */
    end method. /* CheckSchedule */

end class.