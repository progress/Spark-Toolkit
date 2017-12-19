using Progress.Lang.Object.
using Spark.Core.Util.EnumNameMember.

block-level on error undo, throw.

/**
 * Abstract class for Enumerations' members.
 * Notes :  We could add a temp-table to manage the EnumNameMembers' values etc.
 * That's not done right now because there's no pressing need for it.
 * Value takes precedence over name, when both are specified.
 * @author pjudge 21/01/2010
 */
class Spark.Core.Util.EnumNameMember abstract:

    define public property name as character no-undo get. private set.

    constructor public EnumNameMember(input pcName as character):
        this-object:name = pcName.
    end constructor.

    method public logical equals(input pcName as character):

        define variable lEquals as logical no-undo.

        lEquals = this-object:name eq pcName.

        return lEquals.

    end method.

    method public override logical equals(poEnumNameMember as Object):

        define variable lEquals as logical no-undo.

        lEquals = super:equals(poEnumNameMember).

        /* ABL deals with unknown values just fine */
        if not lEquals then
            lEquals = type-of(poEnumNameMember, EnumNameMember) and
                      this-object:toString() eq  cast(poEnumNameMember, EnumNameMember):toString().

        return lEquals.

    end method.

    method public override character toString():

        define variable cName as character no-undo.

        if this-object:name ne ? then
            cName = substitute('&1', this-object:name).
        else
            cName = substitute('&1_&2', this-object:GetClass():TypeName, this-object).

        return cName.

    end method.

end class.