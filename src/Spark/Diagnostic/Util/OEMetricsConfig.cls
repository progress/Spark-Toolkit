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

    /* Tracks the last time the config file was loaded from the file system. */
    define private variable dConfigLastLoaded as datetime no-undo initial ?.

    /*** Private Properties ***/

    define private property oLogger as ILogWriter no-undo get. set.

    define private property MetricsConfigPath as character no-undo initial ""
        get():
            if MetricsConfigPath eq "" then do:
                /* Determine the location of the config file for this feature. */
                define variable cConfigName as character no-undo.
                assign cConfigName = trim(os-getenv("METRICS_CONFIG")).
                oLogger:Trace(substitute("Metrics Config Name: &1", cConfigName)).

                /* First, check the CATALINA_BASE/conf/ location. */
                file-info:filename = substitute("&1/conf/&2", this-object:CatalinaBase, cConfigName).
                if file-info:full-pathname eq ? then do:
                    /* Next, check the CATALINA_BASE/bin/ location. */
                    file-info:filename = substitute("&1/bin/&2", this-object:CatalinaBase, cConfigName).
                    if file-info:full-pathname eq ? then do:
                        /* Last, check the SESSION-TEMP location. */
                        file-info:filename = substitute("&1/&2", this-object:TemporaryDir, cConfigName).
                    end. /* not found in /bin/ */                        
                end. /* not found in /conf/ */

                /* If one of the above paths is still present, use that. */
                if file-info:full-pathname ne ? then
                    assign MetricsConfigPath = file-info:full-pathname.
                else
                    assign MetricsConfigPath = "". /* Keep blank if not found. */

                /* Provide context as to where we are getting our config options. */
                oLogger:Info(substitute("Metrics Config Path: &1", MetricsConfigPath)).
            end. /* MetricsConfigPath eq "" */

            return MetricsConfigPath.
        end get.
        set.

    /*** Public Properties ***/

    define public property PollingIgnoreList as character no-undo initial "" get. private set.

    define public property PollingStartTime as datetime no-undo initial ? get. private set.

    define public property PollingStopTime as datetime no-undo initial ? get. private set.

    define public property ProfilerEnabled as logical no-undo initial false get. private set.

    define public property ProfilerFilter as character no-undo initial "" get. private set.

    define public property ProfilerThreshold as integer no-undo initial 0 get. private set.

    define public property ObjectsApsvURI as character no-undo initial "" get. private set.

    define public property ObjectsEnabled as logical no-undo initial false get. private set.

    define public property ObjectsExcluded as character no-undo initial "" get. private set.

    define public property ObjectsOutputInterval as integer no-undo initial 0 get. private set.

    define public property ObjectsSource as character no-undo initial "oejmx" get. private set.

    define public property ObjectsTrackMem as logical no-undo initial false get. private set.

    define public property ObjectsUseAPSV as logical no-undo initial false get. private set.


    /***** Constructor/Destructor *****/


    constructor public OEMetricsConfig ( input poLogger as ILogWriter ):
        super().

        assign oLogger = poLogger. /* Use the logger from the calling class. */
        this-object:RefreshConfig(). /* Obtain initial configuration options. */
    end constructor.


    /***** Private Methods *****/


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
                                oLogger:Debug(substitute("Using polling schedule: &1 to &2",
                                                         this-object:PollingStartTime,
                                                         this-object:PollingStopTime)).

                            delete object oSubObj no-error.
                        end. /* has sub-object */
                    end. /* general */

                    when "objects" then do:
                        if oConfig:Has("objects") and oConfig:GetType("objects") eq JsonDataType:Object then do:
                            assign oSubObj = oConfig:GetJsonObject("objects").

                            if oSubObj:Has("apsvURI") and oSubObj:GetType("apsvURI") eq JsonDataType:String then
                                assign this-object:ObjectsApsvURI = oSubObj:GetCharacter("apsvURI").

                            if oSubObj:Has("enabled") and oSubObj:GetType("enabled") eq JsonDataType:Boolean then
                                assign this-object:ObjectsEnabled = oSubObj:GetLogical("enabled").

                            if oSubObj:Has("exclude") and oSubObj:GetType("exclude") eq JsonDataType:String then
                                assign this-object:ObjectsExcluded = oSubObj:GetCharacter("exclude").

                            if oSubObj:Has("outputInterval") and oSubObj:GetType("outputInterval") eq JsonDataType:Number then
                                assign this-object:ObjectsOutputInterval = oSubObj:GetInteger("outputInterval").

                            if oSubObj:Has("source") and oSubObj:GetType("source") eq JsonDataType:String then
                                assign this-object:ObjectsSource = oSubObj:GetCharacter("source").

                            if oSubObj:Has("useAPSV") and oSubObj:GetType("useAPSV") eq JsonDataType:Boolean then
                                assign this-object:ObjectsUseAPSV = oSubObj:GetLogical("useAPSV").

                            if oSubObj:Has("trackMemory") and oSubObj:GetType("trackMemory") eq JsonDataType:Boolean then
                                assign this-object:ObjectsTrackMem = oSubObj:GetLogical("trackMemory").

                            /* Cannot use APSV if no URI has been provided. */
                            if (this-object:ObjectsApsvURI gt "") ne true then
                                assign this-object:ObjectsUseAPSV = false.

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

                            delete object oSubObj no-error.
                        end. /* has sub-object */
                    end. /* profiler */
                end case. /* cNames */
            end. /* do ix */
        end. /* valid object */

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("Error parsing config file: &1", err:GetMessage(1))).
            undo, throw err.                
        end catch.
        finally:
            delete object oParser no-error.
            delete object oConfig no-error.
        end finally.
    end method. /* ParseConfig */


    /***** Public Methods *****/


    method public void RefreshConfig ( ):
        /* Cannot proceed if the configuration file is not present. */
        if (this-object:MetricsConfigPath gt "") ne true then return.

        /* Load the config file path as previously discovered. */
        file-info:file-name = this-object:MetricsConfigPath.
        if file-info:full-pathname ne ? then do:
            define variable dLastDate as datetime no-undo.

            /* Get the current date/time . */
            assign dLastDate = datetime(file-info:file-mod-date, file-info:file-mod-time * 1000).

            if dLastDate ne dConfigLastLoaded then do:
                oLogger:Debug("Updating configuration options from file.").

                /* Mark down the current modified date/time for this file. */
                assign dConfigLastLoaded = dLastDate.

                /* Load and parse the current config file. */
                this-object:ParseConfig().
            end. /* File Changed */
        end. /* File Exists */
    end method. /* CheckConfig */


    method public character GetTrackingFlag ( input piAgentID as integer ):
        os-create-dir value(substitute("&1/metrics/TrackingAgents", this-object:TemporaryDir)).

        return substitute("&1/metrics/TrackingAgents/&2", this-object:TemporaryDir, piAgentID).
    end method. /* GetTrackingFlag */


    method public logical AreObjectsEnabled ( input pcMethodName as character ):
        this-object:RefreshConfig(). /* Update configuration options. */

        if not this-object:ObjectsEnabled then do:
            oLogger:Debug(substitute("Objects disabled, leaving &1", pcMethodName)).
            return false.
        end. /* not enabled */

        return true.
    end method. /* AreObjectsEnabled */


    method public logical IsProfilerEnabled ( input pcMethodName as character ):
        this-object:RefreshConfig(). /* Update configuration options. */

        if not this-object:ProfilerEnabled then do:
            oLogger:Debug(substitute("Profiler disabled, leaving &1", pcMethodName)).
            return false.
        end. /* not enabled */

        return true.
    end method. /* IsProfilerEnabled */


    method public logical OnValidSchedule ():
        if this-object:PollingStartTime ne ? and this-object:PollingStopTime ne ? then do:
            /* Do not allow polling outside of scheduled start/stop times. */
            if now lt this-object:PollingStartTime then return false. /* Before Start */
            if now gt this-object:PollingStopTime then return false. /* After Stop */
        end. /* has polling schedule */

        return true.
    end method. /* CheckSchedule */
end class.