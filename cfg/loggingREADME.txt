To enable the dynamic logging options, you will need the logging.json config file
present in your PAS config directory, available to the Spark toolkit. By default
this should be a "spark" subdirectory, but as a last resort the primary "conf"
folder will be checked. When the file is present, it will be evaluated within the
LoggingManager (when necessary) as provided with the project code here. Modifying
the logging.json file is simple, as it contains only 2 options at present, with
the same defaults as would be found in any new PAS configuration:

    {
        "loggingLevel": 2,
        "logEntryTypes": "ASPlumbing,DB.Connects"
    }

These options correspond to the related properties in the log-manager object, and
accept the same values and datatypes. For example, if you wish to increase the
logging level then you would provide an integer value between 0 and 5 (typically).
Similarly, to change the log entry types, add a new comma-delimited character value
such as "DynObjects.*" to alter which items are logged. On each session request,
the config file will be located, and if present will be parsed. Only when the
current value in the file differs from that in the log-manager object will the
option be changed. You will be able to see messages in your log file that indicate
when one of these options is changed, similar to the lines below:

    ACTIVATE  Changing user-defined logging level from '<before>' to '<after>'.
    ACTIVATE  Changing user-defined log entry types from '<before>' to '<after>'.
