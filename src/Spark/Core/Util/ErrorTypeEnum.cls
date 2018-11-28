using Spark.Core.Util.EnumMember from propath.
using Spark.Core.Util.ErrorTypeEnum from propath.

block-level on error undo, throw.

/**
 * Enumeration of Error Types
 */
class Spark.Core.Util.ErrorTypeEnum inherits EnumMember final:

    define static public property default     as ErrorTypeEnum no-undo get.
        private set.
    define static public property error       as ErrorTypeEnum no-undo get.
        private set.
    define static public property fatal       as ErrorTypeEnum no-undo get.
        private set.
    define static public property trace       as ErrorTypeEnum no-undo get.
        private set.
    define static public property warning     as ErrorTypeEnum no-undo get.
        private set.
    define static public property information as ErrorTypeEnum no-undo get.
        private set.
    define static public property success     as ErrorTypeEnum no-undo get.
        private set.
    define static public property validation  as ErrorTypeEnum no-undo get.
        private set.

    constructor static ErrorTypeEnum():
        ErrorTypeEnum:error = new ErrorTypeEnum('ERROR').
        ErrorTypeEnum:fatal = new ErrorTypeEnum('FATAL').
        ErrorTypeEnum:trace = new ErrorTypeEnum('TRACE').
        ErrorTypeEnum:warning = new ErrorTypeEnum('WARNING').
        ErrorTypeEnum:information = new ErrorTypeEnum('INFORMATION').
        ErrorTypeEnum:success = new ErrorTypeEnum('SUCCESS').
        ErrorTypeEnum:validation = new ErrorTypeEnum('VALIDATION').

        ErrorTypeEnum:default = ErrorTypeEnum:error.
    end constructor.

    constructor private ErrorTypeEnum ( input pcName as character ):
        super (input pcName).
    end constructor.


    method public static ErrorTypeEnum enumFromString( input pcName as character ):

        define variable oErrorTypeEnum as ErrorTypeEnum no-undo.

        case pcName:
            when ErrorTypeEnum:error:name then
                oErrorTypeEnum = ErrorTypeEnum:error.
            when ErrorTypeEnum:fatal:name then
                oErrorTypeEnum = ErrorTypeEnum:fatal.
            when ErrorTypeEnum:trace:name then
                oErrorTypeEnum = ErrorTypeEnum:trace.
            when ErrorTypeEnum:warning:name then
                oErrorTypeEnum = ErrorTypeEnum:warning.
            when ErrorTypeEnum:information:name then
                oErrorTypeEnum = ErrorTypeEnum:information.
            when ErrorTypeEnum:success:name then
                oErrorTypeEnum = ErrorTypeEnum:success.
            when ErrorTypeEnum:validation:name then
                oErrorTypeEnum = ErrorTypeEnum:validation.
            otherwise
                oErrorTypeEnum = ErrorTypeEnum:error.
        end case.

        return oErrorTypeEnum.

    end method.

end class.