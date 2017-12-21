using Progress.Lang.Object from propath.
using Spark.Core.Util.EnumMember from propath.

block-level on error undo, throw.

/**
 * Abstract class for Enumerations' members.
 * Notes :  We could add a temp-table to manage the EnumMembers' values etc.
 * That's not done right now because there's no pressing need for it.
 * Value takes precedence over name, when both are specified.
 * @author pjudge 21/01/2010
 */
class Spark.Core.Util.EnumMember abstract:

    define public property name as character no-undo get. private set.
    define public property value as integer no-undo get. private set.

    constructor public EnumMember(input piValue as integer, input pcName as character):
        assign this-object:name = pcName
               this-object:value = piValue.
    end constructor.

    constructor public EnumMember(input piValue as integer):
        this-object(piValue, ?).
    end constructor.

    constructor public EnumMember(input pcName as character):
        this-object(?, pcName).
    end constructor.

    method public logical equals(input pcName as character):

        define variable lEquals as logical no-undo.

        lEquals = this-object:name eq pcName.

        return lEquals.

    end method.

    method public logical equals(input piValue as integer):

        define variable lEquals as logical no-undo.

        lEquals = this-object:value eq piValue.

        return lEquals.

    end method.

    method public override logical equals(poEnumMember as Object):

        define variable lEquals as logical no-undo.

        lEquals = super:equals(poEnumMember).

        /* ABL deals with unknown values just fine */
        if not lEquals then
            lEquals = type-of(poEnumMember, EnumMember) and
                      this-object:toString() eq  cast(poEnumMember, EnumMember):toString().

        return lEquals.

    end method.

    method public override character toString():

        define variable cName as character no-undo.

        if this-object:name ne ? then
            cName = substitute('&1', this-object:name).
        else
        if this-object:value eq ? then
            cName = substitute('&1_Value_&2', this-object:GetClass():TypeName, this-object:value).
        else
            cName = substitute('&1_&2', this-object:GetClass():TypeName, this-object).

        return cName.

    end method.

end class.