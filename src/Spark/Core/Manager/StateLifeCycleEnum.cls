using Spark.Core.Manager.StateLifeCycleEnum from propath.

block-level on error undo, throw.

class Spark.Core.Manager.StateLifeCycleEnum inherits Spark.Core.Util.EnumMember final:

    define static public property application as StateLifeCycleEnum no-undo get. private set.
    define static public property session as StateLifeCycleEnum no-undo get. private set.
    define static public property default as StateLifeCycleEnum no-undo get. private set.

    constructor static StateLifeCycleEnum ( ):
        StateLifeCycleEnum:application = new StateLifeCycleEnum('Application').
        StateLifeCycleEnum:session = new StateLifeCycleEnum('Session').
        StateLifeCycleEnum:default = StateLifeCycleEnum:session.
    end constructor.

    constructor private StateLifeCycleEnum ( input pcName as character ):
        super(input pcName).
    end constructor.

    method public static StateLifeCycleEnum enumFromString ( input pcName as character ):
        define variable oStateLifeCycleEnum as StateLifeCycleEnum no-undo.

        case pcName:
            when StateLifeCycleEnum:application:name then
                oStateLifeCycleEnum = StateLifeCycleEnum:application.
            when StateLifeCycleEnum:session:name then
                oStateLifeCycleEnum = StateLifeCycleEnum:session.
            otherwise
                oStateLifeCycleEnum = StateLifeCycleEnum:default.
        end case.

        return oStateLifeCycleEnum.
    end method.

end class.