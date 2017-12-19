/*------------------------------------------------------------------------
    File        : Sports.Spark.Core.Security.SportsRealm
    Purpose     : Provide Tomcat access to application auth data
    Description : Customized OERealm authentication
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Feb 2 15:59:53 EST 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

{Common/config.i}

class Sports.Spark.Core.Security.SportsRealm inherits Spark.Core.Security.OEUserRealm final:


    /**************************** Public Helper Methods ******************************/


    method protected override logical checkPasswordHash ( input piUserID   as integer,
                                                          input pcPassword as character,
                                                          input pcHashPass as character ):
        if piUserID eq 0 then return true. /* Anonymous */

        if length(pcHashPass) eq 6 then
            /* If hashed password is exactly 6 characters, must be TFA token. */
            return (pcPassword eq pcHashPass).
        else
            /* Use a common method to check that the password hash matches. */
            return Spark.Core.Security.Password:checkPassword(pcPassword, pcHashPass).
    end method. /* checkPasswordHash */


    method protected override character getPassword ( input piUserID as integer ):
        define variable oToken as Spark.Core.Security.TOTP no-undo.
        define variable cToken as character            no-undo.

        define buffer bProfile for {&WEB_PROFILE_TABLE}.

        find first bProfile no-lock
             where bProfile.UserNum eq piUserID no-error.
        if available(bProfile) then do:
            if bProfile.UseTFA then do:
                if bProfile.TFAMethod eq "Device" then do:
                    /* Use standard 30-second step interval for code rotation. */
                    assign oToken = new Spark.Core.Security.TOTP(bProfile.TFASecret).
                    return oToken:Token.
                end.
                else do:
                    /* Use extended 90-second step interval for Email/SMS. */
                    assign oToken = new Spark.Core.Security.TOTP(bProfile.TFASecret, 90, 6).
                    return oToken:Token.
                end.
            end. /* UseTFA */
            else
                return bProfile.password.
        end.

        return ?.

        finally:
            delete object oToken no-error.
        end finally.
    end method. /* getPassword */


    method protected override void postAuthenticate ( input piUserID as integer,
                                                      input lRetVal  as logical ):
        if piUserID eq 0 then return. /* Anonymous */

        define buffer bProfile for {&WEB_PROFILE_TABLE}.
        define buffer bAudit   for {&WEB_USERAUDIT_TABLE}.

        find first bProfile exclusive-lock
             where bProfile.UserNum eq piUserID no-error.

        if available(bProfile) then
            assign /* Update some information about this account. */
                bProfile.FirstLogin = today when bProfile.FirstLogin eq ?
                bProfile.LastLogin  = today
                bProfile.LoginCount = bProfile.LoginCount + 1
                bProfile.TFAToken   = "" /* Clear any previous token! */
                .

        /* Sample code to log info about an authentication attempt. */
        create bAudit.
        assign
            bAudit.AuditLogID    = next-value({&WEB_AUDIT_ID_SEQ})
            bAudit.LogDate       = today
            bAudit.LogTime       = time
            bAudit.LogType       = "Authentication"
            bAudit.LogDesc       = string(lRetVal, "Success/Failure")
            bAudit.UserName      = if available(bProfile) then bProfile.Username else string(piUserID)
            bAudit.WebSessionID  = session:current-request-info:ClientContextId
            .

        release bAudit no-error.
        release bProfile no-error.
    end method. /* postAuthenticate */


    method public override integer getUserID ( input pcUsername   as character,
                                               input pcDomainName as character ):
        /* This is a special ID for an anonymous account, and is not a normal practice!
         * However, due to a limitation with the JSDO and the fact that this application
         * allows both secured and unsecured access, we must provide this use case here
         * so that a user who has not yet authenticated gets appropriate access to the
         * server endpoints. This special UserID will trigger all remaining OERealm
         * options to return a passing value, and a distinct ROLE for access.
         */
        if pcUsername eq "anonymous" then return 0.

        define buffer bProfile for {&WEB_PROFILE_TABLE}.

        assign pcDomainName = "". /* Override for now, as we're not using domains. */
        find first bProfile no-lock
             where bProfile.Username eq pcUsername
               and bProfile.DomainName eq pcDomainName no-error.
        if available(bProfile) then
            return bProfile.UserNum.

        return -1. /* Use negative value if no record. */
    end method. /* getUserID */


    method public override logical isActive ( input piUserID as integer ):
        if piUserID eq 0 then return true. /* Anonymous */

        define buffer bProfile for {&WEB_PROFILE_TABLE}.

        find first bProfile no-lock
             where bProfile.UserNum eq piUserID no-error.
        if available(bProfile) then
            return bProfile.IsActive.

        return false. /* Assume inactive if no record. */
    end method.



    method public override logical isExpired ( input piUserID as integer ):
        if piUserID eq 0 then return false. /* Anonymous */

        define buffer bProfile for {&WEB_PROFILE_TABLE}.

        find first bProfile no-lock
             where bProfile.UserNum eq piUserID no-error.
        if available(bProfile) then
            return (bProfile.PasswordExpires le today).

        return true. /* Assume expired if no record. */
    end method.


    method public override logical isLocked ( input piUserID as integer ):
        if piUserID eq 0 then return false. /* Anonymous */

        define buffer bProfile for {&WEB_PROFILE_TABLE}.

        find first bProfile no-lock
             where bProfile.UserNum eq piUserID no-error.
        if available(bProfile) then
            return bProfile.IsLocked.

        return true. /* Assume locked if no record. */
    end method.


    method public override character getUserRoles ( input piUserID as integer ):
        /* This is the critical part that is ONLY for Anonymous access. */
        if piUserID eq 0 then return "ANONYMOUS".

        define variable cRoles as character no-undo initial "".

        define buffer bProfile     for {&WEB_PROFILE_TABLE}.
        define buffer bRoleProfile for {&WEB_ROLEUSER_TABLE}.

        find first bProfile no-lock
             where bProfile.UserNum eq piUserID no-error.
        if available(bProfile) then
            if (bProfile.SecurityRole gt "") eq true then
                assign cRoles = trim(substitute("&1,&2", cRoles, bProfile.SecurityRole), ",").
            for each bRoleProfile no-lock
               where bRoleProfile.Username eq bProfile.Username:
                assign cRoles = trim(substitute("&1,&2", cRoles, bRoleProfile.RoleID), ",").
            end.

        return trim(substitute("&1,&2", cRoles, "PSCUser"), ",").
    end method. /* getUserRoles */

end class.