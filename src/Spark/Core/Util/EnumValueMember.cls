using Progress.Lang.Object.
using Spark.Core.Util.EnumValueMember.

block-level on error undo, throw.

/**
 * Abstract class for Enumerations' members.
 * Notes :  We could add a temp-table to manage the EnumMembers' values etc.
 * That's not done right now because there's no pressing need for it.
 * Value takes precedence over name, when both are specified.
 * @author pjudge 21/01/2010
 */
class Spark.Core.Util.EnumValueMember abstract:

    define public property value as integer no-undo get. private set.

    constructor public EnumValueMember(input piValue as integer):
        this-object:value = piValue.
    end constructor.

    method public logical equals(input piValue as integer):

        define variable lEquals as logical no-undo.

        lEquals = this-object:value eq piValue.

        return lEquals.

    end method.

    method public override logical equals(poEnumValueMember as Object):

        define variable lEquals as logical no-undo.

        lEquals = super:equals(poEnumValueMember).

        /* ABL deals with unknown values just fine */
        if not lEquals then
            lEquals = type-of(poEnumValueMember, EnumValueMember) and
                      this-object:toString() eq  cast(poEnumValueMember, EnumValueMember):toString().

        return lEquals.

    end method.

    method public override character toString():

        define variable cName as character no-undo.

        if this-object:value eq ? then
            cName = substitute('&1', this-object:value).
        else
            cName = substitute('&1_&2', this-object:GetClass():TypeName, this-object).

        return cName.

    end method.

end class.