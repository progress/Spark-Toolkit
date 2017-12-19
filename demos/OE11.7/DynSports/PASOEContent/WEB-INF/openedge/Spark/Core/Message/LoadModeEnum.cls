using Spark.Core.Message.LoadModeEnum from propath.
using Spark.Core.Util.EnumMember from propath.

block-level on error undo, throw.

/**
 * Enumeration of Load Modes
 */
class Spark.Core.Message.LoadModeEnum inherits EnumMember final:

    define static public property default as LoadModeEnum no-undo get.
        private set.
    define static public property edit    as LoadModeEnum no-undo get.
        private set.
    define static public property add     as LoadModeEnum no-undo get.
        private set.
    define static public property copy    as LoadModeEnum no-undo get.
        private set.
    define static public property view    as LoadModeEnum no-undo get.
        private set.

    constructor static LoadModeEnum():
        LoadModeEnum:edit = new LoadModeEnum('EDIT').
        LoadModeEnum:add = new LoadModeEnum('ADD').
        LoadModeEnum:copy = new LoadModeEnum('COPY').
        LoadModeEnum:view = new LoadModeEnum('VIEW').
        LoadModeEnum:default = LoadModeEnum:edit.
    end constructor.

    constructor private LoadModeEnum ( input pcName as character ):
        super (input pcName).
    end constructor.

    method public static LoadModeEnum enumFromString( input pcName as character ):

        define variable oLoadModeEnum as LoadModeEnum no-undo.

        case pcName:
            when LoadModeEnum:edit:name then
                oLoadModeEnum = LoadModeEnum:edit.
            when LoadModeEnum:add:name then
                oLoadModeEnum = LoadModeEnum:add.
            when LoadModeEnum:copy:name then
                oLoadModeEnum = LoadModeEnum:copy.
            when LoadModeEnum:view:name then
                oLoadModeEnum = LoadModeEnum:view.
            otherwise
                oLoadModeEnum = LoadModeEnum:edit.
        end case.

        return oLoadModeEnum.

    end method.

end class.