using Progress.Lang.* from propath.
using Spark.Core.Manager.ClientContext from propath.

block-level on error undo, throw.

&GLOBAL-DEFINE WEB_PROFILE_TABLE WebProfile

class Sports.Spark.Core.Manager.ClientContext inherits ClientContext:

    method override protected void initializeUserProperties ( ):
        for first {&WEB_PROFILE_TABLE} no-lock
            where {&WEB_PROFILE_TABLE}.Username eq this-object:userID:
            this-object:setUserProperty("FullName", substitute("&1 &2", {&WEB_PROFILE_TABLE}.FirstName, {&WEB_PROFILE_TABLE}.LastName)).
            this-object:setUserProperty("UserNum", {&WEB_PROFILE_TABLE}.UserNum).

            if {&WEB_PROFILE_TABLE}.Email gt "" then
                this-object:setUserProperty("EmailAddr", {&WEB_PROFILE_TABLE}.Email).
            else
                this-object:setUserProperty("EmailAddr", "N/A").
        end. /* for first */
    end method. /* initializeUserProperties */

end class.