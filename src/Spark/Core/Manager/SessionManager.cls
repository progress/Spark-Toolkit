/*------------------------------------------------------------------------
    File        : SessionManager
    Purpose     : Primary manager for framework startup
    Description : Session Startup Manager
    Author(s)   : rosmith
    Created     : Nov 02 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.DataAdmin.* from propath.
using OpenEdge.DataAdmin.Error.* from propath.
using OpenEdge.DataAdmin.Lang.Collections.* from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Util.OSTools from propath.
using Spark.Core.Manager.IClientContext from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.IServiceManager from propath.
using Spark.Core.Manager.SessionAttributeEnum from propath.

block-level on error undo, throw.

class Spark.Core.Manager.SessionManager inherits Spark.Core.Manager.Manager implements Spark.Core.Manager.ISessionManager use-widget-pool:

    define private temp-table ttConfig no-undo serialize-name "SessionParam"
        field LoginExpirationTimeOut as integer   init 0
        field ResetClientPrincipal   as character
        .

    define private temp-table ttDomains no-undo serialize-name "Domains"
        field domain            as character serialize-name "domain"
        field accessCode        as character serialize-name "accessCode"
        field domainDescription as character serialize-name "description"
        index idxDomain         as primary unique domain.

    define private temp-table ttDatabase no-undo
        field DatabaseNum     as integer
        field LogicalName     as character
        field ValidDomains    as integer
        field DomainAuthority as logical
        field UseAppRegistry  as logical
        index pkName          as primary unique DatabaseNum
        .

    define private dataset dsConfig serialize-name "Config"
        for ttConfig, ttDomains.

    /** The current users context object */
    define public property CurrentClientContext as Ccs.Common.IClientContext no-undo get.
        private set.

    /** Low-level CPO used to replace the authenticated user after request completes. */
    define private   variable hResetClientPrincipal   as handle no-undo.
    define private   variable iLoginExpirationTimeOut as integer no-undo.
    define protected variable lDomainsLoaded          as logical no-undo.

    constructor public SessionManager ( ):
        super().
    end constructor.

    method override public void initialize ( ):
        loadConfig().
    end method.

    method override public void dispose ( ):
        delete object hResetClientPrincipal no-error.
    end method.

    method protected void loadConfig():

        define variable cCfgFileName     as character no-undo.
        define variable cFullCfgFileName as character no-undo.
        define variable mCP              as memptr    no-undo.
        define variable rCP              as raw       no-undo.
        define variable iSize            as integer   no-undo.
        define variable lValid           as logical   no-undo initial false.

        cCfgFileName = "session.json".
        file-info:file-name = OSTools:sparkConf + cCfgFileName.
        cFullCfgFileName = file-info:full-pathname.

        if cFullCfgFileName ne ? then
            dataset dsConfig:read-json ("FILE", cFullCfgFileName, "EMPTY").
        else
            undo, throw new AppError(substitute("Session config file [&1] not found in [&2]", cCfgFileName, OSTools:sparkConf), 0).

        find first ttConfig no-lock no-error.
        if available(ttConfig) then do:
            assign
                iLoginExpirationTimeOut = ttConfig.LoginExpirationTimeOut
                .

            if (ttConfig.ResetClientPrincipal gt "") eq true then do:
                /* Look for the CPO in the SPARK_CONF or CATALINA_BASE/conf directory. */
                file-info:file-name = ttConfig.ResetClientPrincipal.
                if file-info:full-pathname eq ? then
                    file-info:file-name = OSTools:sparkConf + ttConfig.ResetClientPrincipal.
                if file-info:full-pathname eq ? then
                    undo, throw new AppError(substitute("The Reset Client Principal [&1] can not be found", ttConfig.ResetClientPrincipal), 0).

                copy-lob from file file-info:full-pathname to mCP no-convert.
                iSize = get-size(mCP).
                put-bytes(rCP, 1) = get-bytes(mCP, 1, iSize).
                set-size(mCP) = 0.
                create client-principal hResetClientPrincipal.
                hResetClientPrincipal:import-principal(rCP).

                for each ttDatabase no-lock:
                    /* Note: this will return true if no DB's connected. */
                    assign lValid = set-db-client(hResetClientPrincipal, ttDatabase.LogicalName) no-error.
                    if not lValid then
                        undo, throw new AppError(substitute("Invalid Reset Client-Principal on &1; Reason(s): &2", ttDatabase.LogicalName, GenTools:getAblError()), 0).
                end. /* for each ttDatabase */
            end. /* ttConfig.ResetClientPrincipal */
        end. /* available(ttConfig) */

        finally:
            set-size(mCP) = 0.
        end finally.

    end method.

    /**
     * Ends a user's session (not a log out, but the opposite of establishRequestEnvironment).
     */
    method public void endRequestEnvironment ( ):

        if valid-object(this-object:CurrentClientContext) then
            this-object:CurrentClientContext:saveContext().

        this-object:resetSession().

    end method.

    /**
     * Reset the state of the current session to it's initial 'empty' state.
     */
    method private void resetSession ( ):

        define variable lValid as logical no-undo initial false.

        if valid-object(this-object:CurrentClientContext) then
            delete object this-object:CurrentClientContext no-error.

        assign
            this-object:CurrentClientContext = ?.

        this-object:registerDomains().

        if num-dbs eq 0 then do:
            assign lValid = security-policy:set-client(hResetClientPrincipal) no-error.
            if not lValid then
                undo, throw new AppError(substitute("Invalid Reset Client-Principal; Reason(s): &1", GenTools:getAblError()), 0).
        end.
        else
            for each ttDatabase no-lock:
                assign lValid = set-db-client(hResetClientPrincipal, ttDatabase.LogicalName) no-error.
                if not lValid then
                    undo, throw new AppError(substitute("Invalid Reset Client-Principal on &1; Reason(s): &2", ttDatabase.LogicalName, GenTools:getAblError()), 0).
            end. /* for each ttDatabase */

    end method.

    /**
     * Checks that all available databases are connected
     */
    method public logical databasesConnected ( ):

        define variable iDB        as integer no-undo.
        define variable lConnected as logical no-undo.

        do iDB = 1 to num-dbs:
            lConnected = connected(ldbname(iDB)) no-error.
            if not lConnected then
            do:
                cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager)
                    :logMessage(substitute("Database &1 has been disconnected", ldbname(iDB)), "SPARK-DB", 0).
                return false.
            end.
        end.
        return true.

    end method.

    /**
     * Validates that the Client Principal passed in is valid and establishes a new Spark session
     */
    method public void establishRequestEnvironment ( input phClientPrincipal as handle ):

        define variable oClientContextImpl as Progress.Lang.Class no-undo.

        if not valid-handle(phClientPrincipal) then
            undo, throw new AppError("Invalid Client Principal Handle", 0).

        oClientContextImpl = cast(Ccs.Common.Application:ServiceManager, IServiceManager)
                                 :getServiceImplementation(get-class(IClientContext)).
        if valid-object(oClientContextImpl) then
            this-object:CurrentClientContext = cast(oClientContextImpl:New(), IClientContext).

        if not valid-object(this-object:CurrentClientContext) then
            undo, throw new AppError("Invalid Client Context Object", 0).

        this-object:CurrentClientContext:initializeContext(phClientPrincipal).

        this-object:assertUserCredentials(CurrentClientContext:clientPrincipal).

        this-object:resetSessionAttributes().

    end method.

    method public void establishRequestEnvironment( input pcSessionID as character ):

        undo, throw new AppError("Establish method not supported", 0).

    end method.

    /**
     * Validates that the Client Principal on the session handle is valid and establishes a new Spark session
     */
    method public void establishRequestEnvironment ( ):

        define variable oPrincipal as OpenEdge.Security.Principal no-undo.

        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).
        this-object:establishRequestEnvironment(oPrincipal:Token).

        finally:
            delete object oPrincipal no-error.
        end.

    end method.

    /**
     * This method will authenticate the user credentials and seal the CPO if it's a new user login.
     * If this is re-establishing a user session or the CPO has been created externally (e.g. by PASOE Spring authentication)
     * then this method will check that the user CPO is a valid object
     * that has not expired etc. and will assert the user against all connected databases
     *
     * @param phClientPrincipal The users Client Principal Object
     */
    method protected void assertUserCredentials ( input phClientPrincipal as handle):

        define variable lValid as logical no-undo initial false.
        define variable hCP    as handle  no-undo.

        this-object:registerDomains().

        if num-dbs eq 0 then
        do:
            if phClientPrincipal:login-state eq "LOGIN" or phClientPrincipal:login-state eq "SSO" then
                assign lValid = security-policy:set-client(phClientPrincipal) no-error.
            else
                undo, throw new AppError("Invalid User Token supplied.", -400). /* CPO must be sealed! */
        end.
        else
            for each ttDatabase no-lock:
                assign lValid = set-db-client(phClientPrincipal, ttDatabase.LogicalName) no-error.

                /**
                 * If needed, provide output when user is asserted against the database.
                 * Also reports if database is Domain Authority or Not applicable,
                 * and if database uses the App Registry or has Domains Present.
                 */
/*                assign hCP = get-db-client(ttDatabase.LogicalName).                                                */
/*                cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager)*/
/*                    :logMessage(substitute("User &1 asserted against Database &2 [&3, &4]",                        */
/*                                           hCP:qualified-user-id,                                                  */
/*                                           ttDatabase.LogicalName,                                                 */
/*                                           string(ttDatabase.DomainAuthority, "DA/NA"),                            */
/*                                           string(ttDatabase.UseAppRegistry, "AR/DP")), "SPARK-DB", 3).            */
            end. /* for each ttDatabase */

        if not lValid then do:
            if error-status:error then
                undo, throw new AppError(error-status:get-message(1), -500).
            else if phClientPrincipal:login-state eq "FAILED" then
                undo, throw new AppError("The username or password you entered is incorrect.", -401).
            else if phClientPrincipal:login-state eq "EXPIRED" then
                undo, throw new AppError("This session has expired. Please login again.", -403).
            else if phClientPrincipal:login-state eq "LOGOUT" then
                undo, throw new AppError("This session has been logged out. Please login again.", -403).
            else
                undo, throw new AppError(substitute("Invalid User Token supplied [&1]", GenTools:getAblError()), -400).
        end. /* not lValid */

    end method.

    /**
     * Obtain options in use for available databases
     */
    method protected void getDatabaseOptions ( ):

        define variable oService as DataAdminService no-undo.
        define variable oDomain  as IDomain          no-undo.
        define variable oOption  as IDatabaseOption  no-undo.
        define variable iNumDB   as integer          no-undo.

        /* If no entries in local registry, attempt to load option info. */
        if not can-find(first ttDatabase no-lock) then
        do iNumDB = 1 to num-dbs:
            assign oService = new DataAdminService(ldbname(iNumDB)) no-error.
            if valid-object(oService) then do:
                assign oOption = oService:GetDatabaseOption("_pvm.useAppRegistry") no-error.
                if valid-object(oOption) then do:
                    /* Create an info record for this database. */
                    create ttDatabase.
                    assign
                        ttDatabase.DatabaseNum     = iNumDB
                        ttDatabase.LogicalName     = ldbname(iNumDB)
                        ttDatabase.ValidDomains    = 0
                        ttDatabase.DomainAuthority = false
                        ttDatabase.UseAppRegistry  = logical(oOption:OptionValue)
                        .

                    /* Determine if database contains the necessary domains. */
                    for each ttDomains no-lock:
                        assign oDomain = oService:GetDomain(ttDomains.domain) no-error.
                        if valid-object(oDomain) then
                            assign ttDatabase.ValidDomains = ttDatabase.ValidDomains + 1.
                        delete object oDomain no-error.
                    end. /* for each ttDomain */
                end. /* valid-object(oOption) */
                delete object oOption no-error.
            end. /* valid-object(oService) */
            delete object oService no-error.

            /* If still no entry, create a record with default options. */
            if not can-find(first ttDatabase no-lock) then do:
                create ttDatabase.
                assign
                    ttDatabase.DatabaseNum     = iNumDB
                    ttDatabase.LogicalName     = ldbname(iNumDB)
                    ttDatabase.ValidDomains    = 0
                    ttDatabase.DomainAuthority = false
                    ttDatabase.UseAppRegistry  = false
                    .
            end. /* not can-find */
        end. /* not can-find, iNumDB */

        /* Based on highest valid domain count, set authority database. */
        for last ttDatabase exclusive-lock
           where not ttDatabase.UseAppRegistry
             and ttDatabase.ValidDomains gt 0
              by ttDatabase.ValidDomains
              by ttDatabase.DatabaseNum:
            assign ttDatabase.DomainAuthority = true.
        end. /* for last ttDatabase */

    end method.

    /**
     * Load the security domains from the connected databases
     */
    method protected void registerDomains ( ):

        define variable iNumDB as integer no-undo.

        if not this-object:databasesConnected() then
        do:
            lDomainsLoaded = false. /* Reset flag. */
            /* Cannot assert credentials if any databases are not available. */
            undo, throw new AppError("One or more databases disconnected!", -503).
        end.

        if num-dbs gt 0 then
            this-object:getDatabaseOptions(). /* Load options for all connected databases. */

        if lDomainsLoaded then return.

        if num-dbs eq 0 then do:
            /* No databases available so register domains direclty, 1-by-1. */
            for each ttDomains no-lock:
                assign lDomainsLoaded = security-policy:register-domain(ttDomains.domain, ttDomains.accessCode, ttDomains.domainDescription) no-error.
                if not lDomainsLoaded then /* Denote when failed to register a specific domain record. */
                    undo, throw new AppError(substitute("Unable to register domain &1 [&2]",
                                                        ttDomains.domain, GenTools:getAblError()), -500).
            end. /* for each ttDomains */

            if not lDomainsLoaded then
                undo, throw new AppError("No domain details provided in session.json to register", -500).
            security-policy:lock-registration(). /* Lock the application registry. */
        end. /* no databases */
        else do:
            /* DB's have to be connected before any domains can be loaded. */
            find first ttDatabase no-lock
                 where ttDatabase.DomainAuthority no-error.

            /* Only load domains from the database that is set as the authority. */
            if available(ttDatabase) then do:
                assign lDomainsLoaded = security-policy:load-domains(ttDatabase.DatabaseNum) no-error.
                if not lDomainsLoaded then /* Denote when failed to register from a specific database. */
                    undo, throw new AppError(substitute("Unable to register domain for database &1 [&2]",
                                                        ttDatabase.LogicalName, GenTools:getAblError()), -500).
            end. /* available(ttDatabase) */
            else
                undo, throw new AppError("Unable to register domains, no authority database available.", -500).
        end. /* databases present */

    end method.

    /**
     * Log a user in
     *
     * @param pcUserID The User ID
     * @param pcDomain The user domain
     * @param pcPassword The user password
     * @return A raw Client Principal object
     */
    method public raw userLogin ( input pcUserID as character, input pcDomain as character, input pcPassword as character, input pcExtra as character ):

        define variable hCPO             as handle      no-undo.
        define variable tLoginExpiration as datetime-tz no-undo.

        if pcUserID eq ? or pcUserID eq '' then
            undo, throw new AppError(substitute('User ID cannot be unknown or empty'), 0).
        if pcDomain eq ? then
            undo, throw new AppError(substitute('User Domain cannot be unknown'), 0).

        if iLoginExpirationTimeOut ne 0 then
            tLoginExpiration = add-interval(now, iLoginExpirationTimeOut,'seconds').

        create client-principal hCPO.
        pcPassword = decryptPassword(pcPassword).
        hCPO:initialize(pcUserID + '@' + pcDomain, ?, tLoginExpiration, pcPassword ).
        hCPO:client-workstation = pcExtra.
        this-object:setClientPrincipalAttributes(hCPO).

        /* This new client principal is initialized with the users credentials
           and will be authenticated and validated in the establishRequestEnvironment called below. */

        this-object:establishRequestEnvironment(hCPO).

        return hCPO:export-principal ().

        finally:
            delete object hCPO no-error.
        end finally.
    end method.

    /**
     * An overide point to allow for a password to be passed as an encrypted value and be decrypted here
     */
    method protected character decryptPassword ( input pcPassword as character ):
        return pcPassword.
    end method.

    /**
     * Used to assign any attributes and user properties to the client principal before it is sealed.
     */
    method protected void setClientPrincipalAttributes (input phClientPrincipal as handle ):

        phClientPrincipal:roles = "PSCUser,PSCDebug,EndUser".
        phClientPrincipal:set-property("ATTR_ENABLED", "true").
        phClientPrincipal:set-property("ATTR_LOCKED", "false").
        phClientPrincipal:set-property("ATTR_EXPIRED", "false").

    end method.

    /**
     * Invalidate a UserContext object
     */
    method public void invalidateContext ( ):

        define variable oPrincipal as OpenEdge.Security.Principal no-undo.
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).
        this-object:invalidateContext(oPrincipal:Token).
        delete object oPrincipal no-error.

    end method.

    /**
     * Invalidate a UserContext object
     *
     * @param pcContextId The ContextID to invalidate
     */
    method public void invalidateContext ( input pcContextId as character ):

        define variable oClientContextImpl as Progress.Lang.Class no-undo.
        define variable oClientContext     as IClientContext      no-undo.

        oClientContextImpl = cast(Ccs.Common.Application:ServiceManager, IServiceManager)
                                 :getServiceImplementation(get-class(IClientContext)).
        if valid-object(oClientContextImpl) then
            oClientContext = cast(oClientContextImpl:New(), IClientContext).

        if valid-object(oClientContext) then
        do:
            oClientContext:initializeContext(pcContextId).
            if oClientContext:GetClass():IsA(get-class(Spark.Core.Manager.IClientContext)) then
                cast(oClientContext, Spark.Core.Manager.IClientContext):invalidateContext().
        end.

    end method.

    /**
     * Invalidate a UserContext object
     *
     * @param phClientPrincipal The session CPO to invalidate
     */
    method public void invalidateContext ( input phClientPrincipal as handle ):

        define variable oClientContextImpl as Progress.Lang.Class no-undo.
        define variable oClientContext     as IClientContext      no-undo.

        oClientContextImpl = cast(Ccs.Common.Application:ServiceManager, IServiceManager)
                                 :getServiceImplementation(get-class(IClientContext)).
        if valid-object(oClientContextImpl) then
            oClientContext = cast(oClientContextImpl:New(), IClientContext).

        if valid-object(oClientContext) then
        do:
            oClientContext:initializeContext(phClientPrincipal).
            if oClientContext:GetClass():IsA(get-class(Spark.Core.Manager.IClientContext)) then
                cast(oClientContext, Spark.Core.Manager.IClientContext):invalidateContext().
        end.

    end method.

    /**
     * Set the runtime session attributes
     * Attributes: date-format, timezone, numeric-separator, numeric-decimal-point
     */
    method public void setSessionAttribute ( input oAttribute as SessionAttributeEnum, input pcValue as character ):

        define variable cSep as character no-undo.
        define variable cDec as character no-undo.

        if this-object:CurrentClientContext:GetClass():IsA(get-class(Spark.Core.Manager.IClientContext)) then
        case oAttribute:
            when SessionAttributeEnum:dateFormat then
                do:
                    session:date-format = pcValue.
                    if valid-object(this-object:CurrentClientContext) then
                        cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):setUserProperty(SessionAttributeEnum:dateFormat:ToString(), session:date-format).
                end.
            when SessionAttributeEnum:timezoneOffset then
                do:
                    session:timezone = timezone(pcValue).
                    if valid-object(this-object:CurrentClientContext) then
                        cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):setUserProperty(SessionAttributeEnum:timezoneOffset:ToString(),string(session:timezone,"+HH:MM")).
                end.
            when SessionAttributeEnum:numericDecimalPoint then
                do:
                    cSep = session:numeric-separator.
                    cDec = pcValue.
                    session:set-numeric-format (cSep,cDec).
                    if valid-object(this-object:CurrentClientContext) then
                        cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):setUserProperty(SessionAttributeEnum:numericDecimalPoint:ToString(),session:numeric-decimal-point).
                end.
            when SessionAttributeEnum:numericSeparator then
                do:
                    cSep = pcValue.
                    cDec = session:numeric-decimal-point.
                    session:set-numeric-format (cSep,cDec).
                    if valid-object(this-object:CurrentClientContext) then
                        cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):setUserProperty(SessionAttributeEnum:numericSeparator:ToString(),session:numeric-separator).
                end.
            otherwise
                do:
                    undo, throw new AppError(substitute('Session attribute [&1] not catered for', oAttribute:ToString()), 0).
                end.
        end case.

    end method.

    /**
     * Reset the runtime session attributes from the user context
     * Attributes: date-format, timezone, numeric-separator, set-numeric-format, numeric-decimal-point
     */
    method protected void resetSessionAttributes ( ):

        define variable cValue as character no-undo.
        define variable cSep   as character no-undo.
        define variable cDec   as character no-undo.

        if valid-object(this-object:CurrentClientContext)
           and this-object:CurrentClientContext:GetClass():IsA(get-class(Spark.Core.Manager.IClientContext)) then
        do:
            if cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):hasUserProperty(SessionAttributeEnum:dateFormat:ToString()) then
                cValue = cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):getUserProperty(SessionAttributeEnum:dateFormat:ToString()).
            else
                cValue = ?.
            if cValue ne ? then
                session:date-format = cValue.
            else
                cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):setUserProperty(SessionAttributeEnum:dateFormat:ToString(),session:date-format).

            if cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):hasUserProperty(SessionAttributeEnum:timezoneOffset:ToString()) then
                cValue = cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):getUserProperty(SessionAttributeEnum:timezoneOffset:ToString()).
            else
                cValue = ?.
            if cValue ne ? then
                session:timezone = timezone(cValue).
            else
                cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):setUserProperty(SessionAttributeEnum:timezoneOffset:ToString(),string(timezone,"+HH:MM")).

            assign
                cSep = ?
                cDec = ?.
            if cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):hasUserProperty(SessionAttributeEnum:numericSeparator:ToString()) then
                cSep = cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):getUserProperty(SessionAttributeEnum:numericSeparator:ToString()).
            if cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):hasUserProperty(SessionAttributeEnum:numericDecimalPoint:ToString()) then
                cDec = cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):getUserProperty(SessionAttributeEnum:numericDecimalPoint:ToString()).
            if cSep ne ? and cDec ne ? then
                session:set-numeric-format(cSep, cDec).
            else do:
                cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):setUserProperty(SessionAttributeEnum:numericSeparator:ToString(),session:numeric-separator).
                cast(this-object:CurrentClientContext, Spark.Core.Manager.IClientContext):setUserProperty(SessionAttributeEnum:numericDecimalPoint:ToString(),session:numeric-decimal-point).
            end.
        end.

    end method.

    /**
     * If the curent user has a valid CPO then this will return a new sealed CPO with the same properties but with a new expiration date
     * This token can be used by other systems such as a task scheduler perform a task on behalf of the user
     */
    method public character getUserSSOToken ( input ptExpiration as datetime-tz ):

        define variable hCPO as handle    no-undo.
        define variable cCP  as character no-undo.

        if valid-object(this-object:CurrentClientContext) then
        do:
            if this-object:CurrentClientContext:clientPrincipal:login-state eq "LOGIN" or
               this-object:CurrentClientContext:clientPrincipal:login-state eq "SSO" then
            do:
                create client-principal hCPO.
                hCPO:initialize(this-object:CurrentClientContext:clientPrincipal:qualified-user-id, ?, ptExpiration ).
                hCPO:client-workstation = this-object:CurrentClientContext:clientPrincipal:client-workstation.
                this-object:setClientPrincipalAttributes(hCPO).
                hCPO:seal(getDomainAccessCode(this-object:CurrentClientContext:clientPrincipal:domain-name)).

                assign
                    cCP  = string(base64-encode(hCPO:export-principal()))
                    hCPO = ?
                    .
            end.
            else
                undo, throw new AppError('Current User Context Object is not in a login state', 0).
        end.
        else
            undo, throw new AppError('Invalid User Context Object', 0).

        return cCP.

        finally:
            delete object hCPO no-error.
        end finally.
    end method.

    /**
     * If the passed in token is a valid CPO then this will return a new sealed CPO with the same properties but with a new expiration date
     * This token can be used by other systems such as a task scheduler perform a task on behalf of the user
     */
    method public character getUserSSOToken ( input pcRawToken as character, input ptExpiration as datetime-tz ):

        define variable hCPOIn  as handle    no-undo.
        define variable hCPOOut as handle    no-undo.
        define variable rCP     as raw       no-undo.
        define variable cCP     as character no-undo.

        create client-principal hCPOIn.
        rCP = base64-decode(pcRawToken).
        hCPOIn:import-principal(rCP).

        if valid-handle(hCPOIn) then
        do:
            if hCPOIn:login-state eq "LOGIN" or
               hCPOIn:login-state eq "SSO" then
            do:
                if not hCPOIn:validate-seal(getDomainAccessCode(hCPOIn:domain-name)) then
                    undo, throw new AppError("Token failed seal check", 0).

                if hCPOIn:login-expiration-timestamp ne ? and
                   hCPOIn:login-expiration-timestamp le now then
                    undo, throw new AppError("Token expired", 0).

                create client-principal hCPOOut.
                hCPOOut:initialize(hCPOIn:qualified-user-id, ?, ptExpiration ).
                hCPOOut:client-workstation = hCPOIn:client-workstation.
                this-object:setClientPrincipalAttributes(hCPOOut).
                hCPOOut:seal(getDomainAccessCode(hCPOIn:domain-name)).

                assign cCP = string(base64-encode(hCPOOut:export-principal())).
            end.
            else
                undo, throw new AppError(substitute("Token state [&1] is invalid", hCPOIn:login-state), 0).
        end.
        else
            undo, throw new AppError("Invalid token", 0).

        return cCP.

        finally:
            hCPOIn = ?.
            hCPOOut = ?.
            delete object hCPOIn no-error.
            delete object hCPOOut no-error.
        end finally.
    end method.

    method protected character getDomainAccessCode ( input pcDomainName as character ):

        find first ttDomains where ttDomains.domain eq pcDomainName no-error.
        if available ttDomains then
            return ttDomains.accessCode.
        else
            undo, throw new AppError(substitute("The session.json configuration does not contain an access code for domain [&1]", pcDomainName), 0).

    end method.

end class.
