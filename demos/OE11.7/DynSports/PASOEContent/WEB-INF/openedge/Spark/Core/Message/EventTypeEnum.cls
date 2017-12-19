using Spark.Core.Message.EventTypeEnum from propath.
using Spark.Core.Util.EnumMember from propath.
using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

/**
 * Enumeration of Event Types
 */
class Spark.Core.Message.EventTypeEnum inherits EnumMember final:

    define static public property leave as EventTypeEnum no-undo get.
        private set.
    define static public property valueChanged as EventTypeEnum no-undo get.
        private set.
    define static public property keyUp as EventTypeEnum no-undo get.
        private set.
    define static public property rowChanged as EventTypeEnum no-undo get.
        private set.
    define static public property click as EventTypeEnum no-undo get.
        private set.
    define static public property beforeRowDelete as EventTypeEnum no-undo get.
        private set.
    define static public property afterRowDelete as EventTypeEnum no-undo get.
        private set.
    define static public property beforeRowSave as EventTypeEnum no-undo get.
        private set.
    define static public property afterRowSave as EventTypeEnum no-undo get.
        private set.
    define static public property forced as EventTypeEnum no-undo get.
        private set.

    constructor static EventTypeEnum():
        EventTypeEnum:leave = new EventTypeEnum('LEAVE').
        EventTypeEnum:valueChanged = new EventTypeEnum('VALUE_CHANGED').
        EventTypeEnum:keyUp = new EventTypeEnum('KEY_UP').
        EventTypeEnum:rowChanged = new EventTypeEnum('ROW_CHANGED').
        EventTypeEnum:click = new EventTypeEnum('CLICK').
        EventTypeEnum:beforeRowDelete = new EventTypeEnum('BEFORE_ROW_DELETE').
        EventTypeEnum:afterRowDelete = new EventTypeEnum('AFTER_ROW_DELETE').
        EventTypeEnum:beforeRowSave = new EventTypeEnum('BEFORE_ROW_SAVE').
        EventTypeEnum:afterRowSave = new EventTypeEnum('AFTER_ROW_SAVE').
        EventTypeEnum:forced = new EventTypeEnum('FORCED').
    end constructor.

    constructor private EventTypeEnum ( input pcName as character ):
        super (input pcName).
    end constructor.

    method public static EventTypeEnum enumFromString( input pcName as character ):

        define variable oEventTypeEnum as EventTypeEnum no-undo.

        case pcName:
            when EventTypeEnum:leave:name then
                oEventTypeEnum = EventTypeEnum:leave.
            when EventTypeEnum:valueChanged:name then
                oEventTypeEnum = EventTypeEnum:valueChanged.
            when EventTypeEnum:keyUp:name then
                oEventTypeEnum = EventTypeEnum:keyUp.
            when EventTypeEnum:rowChanged:name then
                oEventTypeEnum = EventTypeEnum:rowChanged.
            when EventTypeEnum:click:name then
                oEventTypeEnum = EventTypeEnum:click.
            when EventTypeEnum:beforeRowDelete:name then
                oEventTypeEnum = EventTypeEnum:beforeRowDelete.
            when EventTypeEnum:afterRowDelete:name then
                oEventTypeEnum = EventTypeEnum:afterRowDelete.
            when EventTypeEnum:beforeRowSave:name then
                oEventTypeEnum = EventTypeEnum:beforeRowSave.
            when EventTypeEnum:afterRowSave:name then
                oEventTypeEnum = EventTypeEnum:afterRowSave.
            when EventTypeEnum:forced:name then
                oEventTypeEnum = EventTypeEnum:forced.
            otherwise
            do:
                undo, throw new ApplicationError("Invalid Event Type").
            end.
        end case.

        return oEventTypeEnum.

    end method.

end class.