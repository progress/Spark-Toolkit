using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.IStateManager from propath.
using Spark.Core.Util.ApplicationError from propath.
using Spark.Core.Util.FormatTools from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Util.CryptoTools from propath.

block-level on error undo, throw.

&scoped-define contextIDProperty "ClientContext.ContextID"
&scoped-define sessionIDProperty "ClientContext.CPO.SessionID"
&scoped-define userIDProperty "ClientContext.UserID"
&scoped-define loginExpirationProperty "ClientContext.LoginExpiration"
&scoped-define userDomainProperty "ClientContext.UserDomain"
&scoped-define userExtraProperty "ClientContext.UserExtra"
&scoped-define extentDelimiter chr(28)

/**
 * The Client Context - holds all info about the user/client session
 * <p>This object provides easy access to the session Client-Principal and its attributes
 * as well as other application session properties</p>
 * <p>User Context data is basically any information that you want to persist between service requests.
 * Typically we will hold the traditional global shared variables like userid, branch, department, etc.</p>
 * <p>The user context data is retrieved from the State Manager and re-established in the ClientContext object and
 * then saved back to the State Manager at the end of the request.</p>
 * <p>So we need to ensure that we only store context data that is absolutely needed, not because it is easier.</p>
 *
 * To find the current user ID:
 * <code>cast(Ccs.Common.Application:SessionManager:CurrentClientContext, Spark.Core.Manager.IClientContext):userId</code>
 * <br>To find current user Domain:
 * <code>cast(Ccs.Common.Application:SessionManager:CurrentClientContext, Spark.Core.Manager.IClientContext):userDomain</code>
 * <br>To create and save a user context property:
 * <code>cast(Ccs.Common.Application:SessionManager:CurrentClientContext, Spark.Core.Manager.IClientContext):setUserProperty("myProp",cMyPropValue).</code>
 * <br>To retrieve a user context property:
 * <code>cast(Ccs.Common.Application:SessionManager:CurrentClientContext, Spark.Core.Manager.IClientContext):getUserPropertyAsChar("myProp")</code>
 * <br>To retrieve an extent (Array) user context property:
 * <code>cast(Ccs.Common.Application:SessionManager:CurrentClientContext, Spark.Core.Manager.IClientContext):getUserArrayPropertyAsChar("myExtProps")</code>
 * <br>To retrieve an array of user context properties:
 * <code>cast(Ccs.Common.Application:SessionManager:CurrentClientContext, Spark.Core.Manager.IClientContext):getUserPropertyArray(cExtPropNames)</code>
 */
class Spark.Core.Manager.ClientContext implements Spark.Core.Manager.IClientContext use-widget-pool:

    define protected property oStateManager as IStateManager no-undo
        get:
            if not valid-object(oStateManager) then
                assign oStateManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(IStateManager)), IStateManager).
            return oStateManager.
        end get.
        set.

    define protected temp-table ttUserSessionProp no-undo before-table biUserSessionProp
        field PropName  as character
        field PropValue as character
        field PropClob  as clob
        index ix1 as primary unique PropName.
    define dataset dsTtUserSessionProp for ttUserSessionProp.

    define temp-table dbUserSessionProp no-undo serialize-name "ttUserSessionProp" like ttUserSessionProp.
    define dataset dsDbUserSessionProp for dbUserSessionProp.

    /** The handle to the users Client Principal object */
    define public property clientPrincipal as handle no-undo get.
        protected set.

    /** A GUID representing the user context */
    define public property contextID as character no-undo get.
        protected set.

    /** The name of the users domain */
    define public property userDomain as character no-undo get.
        protected set.

    /** The users display name */
    define public property userID as character no-undo get.
        protected set.

    /** Extra Info */
    define public property userExtra as character no-undo get.
        protected set.

    /** The time stamp of when the client-principal object will expire. */
    define public property loginExpiration as datetime-tz initial ? no-undo get.
        protected set.

    /** Optional activity password */
    define public property activityPassword as character no-undo get.
        protected set.

    define public static property stateClassID as character init ? no-undo
        get():
            if stateClassID eq ? then
                assign
                    stateClassID = get-class(Spark.Core.Manager.ClientContext):TypeName.
            return stateClassID.
        end get.
        protected set.

    constructor public ClientContext ( ):

    end constructor.

    destructor public ClientContext ( ):

        delete object this-object:clientPrincipal no-error.

    end destructor.

    /**
     * Create a new user context from an existing Client Principal
     *
     * @param phClientPrincipal The handle to the existing Client Principal
     */
    method public void initializeContext ( input phClientPrincipal as handle ):

        define variable rCP as raw no-undo.

        /*
         * Take a deep copy of the CPO so that the caller can
         * safely delete it's copy of the CPO without this CPO being deleted
         */
        rCP = phClientPrincipal:export-principal().
        create client-principal clientPrincipal.
        clientPrincipal:import-principal(rCP).

        assign
            this-object:contextID       = phClientPrincipal:session-id
            this-object:userID          = phClientPrincipal:user-id
            this-object:userDomain      = phClientPrincipal:domain-name
            this-object:loginExpiration = phClientPrincipal:login-expiration-timestamp
            this-object:userExtra       = phClientPrincipal:client-workstation
            .

        cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager)
            :logMessage(substitute("Initializing Context for &1@&2", this-object:userID, this-object:userDomain), "SPARK-DB", 3).

        /* Under PASOE the session-id assigned to the CPO is NOT a GUID or based on a UUID
         * The session-id will be unique within the lifetime of the PASOE server (i.e. between startup and shutdown)
         * but not unique accross all time.  We need unique contextID so that we have a unique identifier
         * for this user session when the state manager looks up the session state in the database.
         *
         * session:current-request-info:ClientContextID - Assigned by PAS as the session-id and cannot be changed by ABL server (PASOE just re-assignes it to the session-id)
         * session:server-connection-context - According to the documentation this is only valid for session-managed sessions
         */
        if phClientPrincipal:seal-timestamp ne ? then
            assign
                this-object:contextID = substitute("&1.&2", phClientPrincipal:session-id, iso-date(phClientPrincipal:seal-timestamp)).

        assign
            this-object:contextID = replace(this-object:contextID, ":", ".").

        initializeContext().

    end method.

    /**
     * Create a user context from an existing contexID value
     * This constructor does NOT assign the clientPrincipal
     *
     * @param pcContexID The contextID
     */
    method public void initializeContext ( input pcContexID as character ):

        this-object:contextID = pcContexID.
        initializeContext().

    end method.

    method protected void initializeContext ( ):

        define variable cContext as longchar no-undo.

        cContext = oStateManager:readContextFromStore(stateClassID, this-object:contextID).
        if cContext ne ? and cContext ne "" then
        do:
            temp-table ttUserSessionProp:read-json("LONGCHAR", cContext, "EMPTY").
        end.

        setTrackingChangesOnUserProperties( ).

        /* If this is the first time then initialize the user properties */
        if valid-handle(this-object:clientPrincipal) and not can-find(first ttUserSessionProp) then
        do:
            initializeUserProperties().
            saveContext().
        end.

        if not valid-handle(this-object:clientPrincipal) and can-find(first ttUserSessionProp) then
        assign
            this-object:userID          = getUserProperty({&userIDProperty})
            this-object:userDomain      = getUserProperty({&userDomainProperty})
            this-object:userExtra       = getUserProperty({&userExtraProperty})
            .

        if can-find(first ttUserSessionProp) then
        assign
            this-object:loginExpiration = getUserPropertyAsDatetimeTz({&loginExpirationProperty})
            .

        /* If invalidateContext() was called from a logout then this-object:loginExpiration was expired and the CPO logged out.
         * But the CPO does not makes it's way back to PASOE spring security security token service so we check again during initialization.
         * The SessionManager will validate the CPO after this call is complete.
         */
        if valid-handle(this-object:clientPrincipal) and
           this-object:loginExpiration ne ? and
           this-object:loginExpiration le now and
           lookup(this-object:clientPrincipal:login-state,"LOGIN,SSO") ne 0 then
        this-object:clientPrincipal:logout().

    end method.

    /**
     * This method is called by the session manager after the Client Principal has been asserted
     * The purpose is to initialize any application User Properites e.g. Company, Branch etc.
     */
    method protected void initializeUserProperties ( ):

    end method.

    /**
     * This method is called to initialize a single property value if it has not previously been done
     * This can be used to lazily instantiate a user property once the session environment has been
     * initialized and only when the property is first required
     */
    method public void initializeUserProperty ( input pcProperty as character ):

    end method.

    /**
     *  Get the Signon Token that can be passed to the Spring Security Realm for authentication
     */
    method public character getSSOToken():

        return GenTools:encodeURL("OECP " + getSSORawToken(), "query").

    end.

    /**
     *  Get the Raw Signon Token
     */
    method public character getSSORawToken():

        define variable rCP as raw       no-undo.
        define variable cCP as character no-undo.

        assign
            rCP = clientPrincipal:export-principal()
            cCP = string(base64-encode(rCP))
            .

        return cCP.

    end.

    /**
     * Write the CPO info into the user properties before serialization of the ClientContext object
     */
    method protected void prepareForSerializeContext ( ):

        setUserProperty({&contextIDProperty},this-object:contextID).
        if valid-handle(this-object:clientPrincipal) then
            setUserProperty({&sessionIDProperty},this-object:clientPrincipal:session-id).
        setUserProperty({&userIDProperty},this-object:userID).
        setUserProperty({&loginExpirationProperty},this-object:loginExpiration).
        setUserProperty({&userDomainProperty},this-object:userDomain).
        setUserProperty({&userExtraProperty},this-object:userExtra).

    end method.

    /**
     * The serialized string returned from this method is used by the Constructor to recreate this object
     *
     * @return A Serialized string representing this ClientContext Object
     */
    method public longchar serializeContext ( ):

        define variable cResult as longchar no-undo.

        prepareForSerializeContext().

        temp-table ttUserSessionProp:write-json("LONGCHAR", cResult).

        return cResult.

    end method.

    /**
     * Save the curernt changes to the user properties back to the state manager by merging changes in the properties in this session
     * with any changes in from other concurrent sessions
     */
    method public void saveContext ( ):

        define variable cDbContext as longchar no-undo.
        define variable lChanges   as logical  no-undo.

        /* Write CP info back to User Properties */
        prepareForSerializeContext().

        CHECK-LOOP:
        for each biUserSessionProp while not lChanges:
            if buffer biUserSessionProp:row-state eq row-deleted or
                buffer biUserSessionProp:row-state eq row-created then
                lChanges = true.
            else if buffer biUserSessionProp:row-state eq row-modified then
                do:
                    find first ttUserSessionProp
                        where rowid(ttUserSessionProp) eq buffer biUserSessionProp:after-rowid.
                    if encode(ttUserSessionProp.PropValue) ne encode(biUserSessionProp.PropValue) then
                        lChanges = true.
                    if ttUserSessionProp.PropClob ne biUserSessionProp.PropClob then
                        lChanges = true.
                end.
            if lChanges then leave CHECK-LOOP.
        end.

        if lChanges then
        do transaction on error undo, throw:

            /*read current ClientContext values from DB*/
            cDbContext = oStateManager:readContextFromStoreAndLock(stateClassID,this-object:contextID).
            if cDbContext ne ? and cDbContext ne "" then do:
                temp-table dbUserSessionProp:read-json("LONGCHAR", cDbContext, "EMPTY").
            end.
            else
                empty temp-table dbUserSessionProp.

            /*compare and merge changes in current session ClientContext*/
            for each biUserSessionProp:
                if buffer biUserSessionProp:row-state eq row-deleted then
                do:
                    find first dbUserSessionProp
                        where dbUserSessionProp.PropName eq biUserSessionProp.PropName
                        no-error.
                    if available dbUserSessionProp then
                        delete dbUserSessionProp.
                end.
                else if buffer biUserSessionProp:row-state eq row-created
                        or buffer biUserSessionProp:row-state eq row-modified then
                    do:
                        find first ttUserSessionProp
                            where rowid(ttUserSessionProp) eq buffer biUserSessionProp:after-rowid.

                        find first dbUserSessionProp
                            where dbUserSessionProp.PropName eq ttUserSessionProp.PropName
                            no-error.
                        if not available dbUserSessionProp then
                        do:
                            create dbUserSessionProp.
                            assign
                                dbUserSessionProp.PropName = ttUserSessionProp.PropName.
                        end.
                        assign
                            dbUserSessionProp.PropValue = ttUserSessionProp.PropValue.
                        assign
                            dbUserSessionProp.PropClob = ttUserSessionProp.PropClob.
                    end.
            end.

            /* Save merged changes back to StateManager. */
            assign cDbContext = "".
            temp-table dbUserSessionProp:write-json("LONGCHAR", cDbContext).
            oStateManager:writeContextToStore(cDbContext,
                                              this-object:loginExpiration,
                                              stateClassID,
                                              this-object:contextID).

        end.
        else
            oStateManager:updateLastUsed(stateClassID, this-object:contextID).

        /*reset tracking changes on current ClientContext*/
        setTrackingChangesOnUserProperties( ).

    end method.

    method protected void setTrackingChangesOnUserProperties ( ):

        buffer biUserSessionProp:accept-changes ().
        temp-table ttUserSessionProp:tracking-changes = true.

    end method.

    /**
     * Get an array of User Properties
     *
     * @param pcProperties An array of properties to be returned
     * @return An Array of property values
     */
    method public character extent getUserPropertyArray ( input pcProperties as character extent ):

        define variable cPropValue as character no-undo extent.

        define variable iMax       as integer   no-undo.
        define variable iLoop      as integer   no-undo.

        iMax = extent(pcProperties).

        assign
            extent(cPropValue) = iMax.

        do iLoop = 1 to iMax:
            cPropValue[iLoop] = getUserProperty(pcProperties[iLoop]).
        end.

        return cPropValue.

    end method.

    /**
     * Get an array of User Property names
     *
     * @return An Array of property names
     */
    method public character extent getUserProperties ( ):

        define variable cPropNames as character no-undo extent.
        define variable iMax as integer no-undo.

        define buffer lbUserSessionProp for ttUserSessionProp.

        for each lbUserSessionProp:
            iMax = iMax + 1.
        end.

        assign
            extent(cPropNames)  = iMax
            iMax                 = 0.

        for each lbUserSessionProp:
            assign
                iMax               = iMax + 1
                cPropNames[iMax]  = lbUserSessionProp.PropName.
        end.

        return cPropNames.

    end method.

    /**
     * Get an array of all User Properties Names and Values
     *
     * @param pcPropNames An array of property names to be returned
     * @param pcPropValues An array of property values to be returned
     */
    method public void getUserPropertyArray ( output pcPropNames as character extent, output pcPropValues as character extent ):

        define variable iMax as integer no-undo.

        define buffer lbUserSessionProp for ttUserSessionProp.

        for each lbUserSessionProp:
            iMax = iMax + 1.
        end.

        assign
            extent(pcPropNames)  = iMax
            extent(pcPropValues) = iMax
            iMax                 = 0.

        for each lbUserSessionProp:
            assign
                iMax               = iMax + 1
                pcPropNames[iMax]  = lbUserSessionProp.PropName
                pcPropValues[iMax] = lbUserSessionProp.PropValue.
        end.

    end method.

    /**
     * Get a User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public character getUserProperty ( input pcProperty as character ):

        define variable cPropValue as character initial ? no-undo.
        define buffer lbUserSessionProp for ttUserSessionProp.

        find first lbUserSessionProp no-lock
             where lbUserSessionProp.PropName eq pcProperty no-error.
        if not available(lbUserSessionProp) then
        do:
            initializeUserProperty(pcProperty).
            find first lbUserSessionProp no-lock
                 where lbUserSessionProp.PropName eq pcProperty no-error.
            if not available lbUserSessionProp then
                undo, throw new ApplicationError("User Property [&1] has not been defined",pcProperty).
        end.

        if available lbUserSessionProp then
            assign cPropValue = lbUserSessionProp.PropValue.

        return cPropValue.

    end method.

    /**
     * Get a User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public longchar getUserPropertyAsLongchar ( input pcProperty as character ):

        define variable cPropValue as longchar initial ? no-undo.
        define buffer lbUserSessionProp for ttUserSessionProp.

        find first lbUserSessionProp no-lock
             where lbUserSessionProp.PropName eq pcProperty no-error.
        if not available(lbUserSessionProp) then
        do:
            initializeUserProperty(pcProperty).
            find first lbUserSessionProp no-lock
                 where lbUserSessionProp.PropName eq pcProperty no-error.
            if not available lbUserSessionProp then
                undo, throw new ApplicationError("User Property [&1] has not been defined",pcProperty).
        end.

        if available lbUserSessionProp then
            assign cPropValue = lbUserSessionProp.PropClob.

        return cPropValue.

    end method.

    /**
     * Get a User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public character getUserPropertyAsChar ( input pcProperty as character ):

        return getUserProperty(pcProperty).

    end method.

    /**
     * Get a User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public integer getUserPropertyAsInt ( input pcProperty as character ):

        return FormatTools:integerOf(getUserProperty(pcProperty)).

    end method.

    /**
     * Get a User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public int64 getUserPropertyAsInt64 ( input pcProperty as character ):

        return FormatTools:int64Of(getUserProperty(pcProperty)).

    end method.

    /**
     * Get a User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public decimal getUserPropertyAsDec ( input pcProperty as character ):

        return FormatTools:decimalOf(getUserProperty(pcProperty)).

    end method.

    /**
     * Get a User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public logical getUserPropertyAsLog ( input pcProperty as character ):

        return FormatTools:logicalOf(getUserProperty(pcProperty)).

    end method.

    /**
     * Get a User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public date getUserPropertyAsDate ( input pcProperty as character ):

        return FormatTools:dateOf(getUserProperty(pcProperty)).

    end method.

    /**
     * Get a User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public datetime getUserPropertyAsDatetime ( input pcProperty as character ):

        return FormatTools:datetimeOf(getUserProperty(pcProperty)).

    end method.

    /**
     * Get a User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public datetime-tz getUserPropertyAsDatetimeTz ( input pcProperty as character ):

        return FormatTools:datetime-tzOf(getUserProperty(pcProperty)).

    end method.

    /**
     * Get an Array User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public character extent getUserArrayPropertyAsChar ( input pcProperty as character ):

        define variable cPropValue as character extent no-undo.
        define variable iLoop      as integer   no-undo.
        define variable iExt       as integer   no-undo.
        define variable cTemp      as character no-undo.

        cTemp = getUserProperty(pcProperty).
        if cTemp ne "" then
        do:
            iExt = num-entries(cTemp,{&extentDelimiter}).
            extent(cPropValue) = iExt.
            do iLoop = 1 to iExt:
                assign
                    cPropValue[iLoop] = entry(iLoop,cTemp,{&extentDelimiter}).
            end.
        end.

        return cPropValue.

    end method.

    /**
     * Get an Array User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public decimal extent getUserArrayPropertyAsDec ( input pcProperty as character ):

        define variable dPropValue as decimal   extent no-undo.
        define variable iLoop      as integer   no-undo.
        define variable iExt       as integer   no-undo.
        define variable cTemp      as character no-undo.

        cTemp = getUserProperty(pcProperty).
        if cTemp ne "" then
        do:
            iExt = num-entries(cTemp,{&extentDelimiter}).
            extent(dPropValue) = iExt.
            do iLoop = 1 to iExt:
                assign
                    dPropValue[iLoop] = FormatTools:decimalOf(entry(iLoop,cTemp,{&extentDelimiter})).
            end.
        end.

        return dPropValue.

    end method.

    /**
     * Get an Array User Property value
     *
     * @param pcProperty The name of the property to return
     * @return The requested property value
     */
    method public integer extent getUserArrayPropertyAsInt ( input pcProperty as character ):

        define variable iPropValue as integer   extent no-undo.
        define variable iLoop      as integer   no-undo.
        define variable iExt       as integer   no-undo.
        define variable cTemp      as character no-undo.

        cTemp = getUserProperty(pcProperty).
        if cTemp ne "" then
        do:
            iExt = num-entries(cTemp,{&extentDelimiter}).
            extent(iPropValue) = iExt.
            do iLoop = 1 to iExt:
                assign
                    iPropValue[iLoop] = FormatTools:integerOf(entry(iLoop,cTemp,{&extentDelimiter})).
            end.
        end.

        return iPropValue.

    end method.

    /**
     * Returns if User Property exists
     *
     * @param pcProperty The name of the property to return
     * @return If the property exists
     */
    method public logical hasUserProperty ( input pcProperty as character ):

        define buffer lbUserSessionProp for ttUserSessionProp.

        find first lbUserSessionProp no-lock
             where lbUserSessionProp.PropName eq pcProperty no-error.
        if not available(lbUserSessionProp) then
        do:
            initializeUserProperty(pcProperty).
            find first lbUserSessionProp no-lock
                 where lbUserSessionProp.PropName eq pcProperty no-error.
        end.

        if available(lbUserSessionProp) then
            return true.

        return false.

    end method.

    /**
     * Create a new User Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param plcValue The value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input plcValue as longchar ):

        define buffer lbUserSessionProp for ttUserSessionProp.

        find first lbUserSessionProp exclusive-lock
             where lbUserSessionProp.PropName eq pcProperty no-error.
        if not available(lbUserSessionProp) then
        do:
            create lbUserSessionProp.
            assign lbUserSessionProp.PropName = pcProperty.
        end.

        copy-lob from plcValue to lbUserSessionProp.PropClob.

    end method.

    /**
     * Create a new User Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param pcValue The value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input pcValue as character ):

        define buffer lbUserSessionProp for ttUserSessionProp.

        find first lbUserSessionProp exclusive-lock
             where lbUserSessionProp.PropName eq pcProperty no-error.
        if not available(lbUserSessionProp) then
        do:
            create lbUserSessionProp.
            assign lbUserSessionProp.PropName = pcProperty.
        end.

        assign lbUserSessionProp.PropValue = pcValue.

    end method.

    /**
     * Create a new User Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param piValue The value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input piValue as integer ):

        setUserProperty(pcProperty,FormatTools:stringOf(piValue)).

    end method.

    /**
     * Create a new User Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param piValue The value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input piValue as int64 ):

        setUserProperty(pcProperty,FormatTools:stringOf(piValue)).

    end method.

    /**
     * Create a new User Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param pdValue The value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input pdValue as decimal ):

        setUserProperty(pcProperty,FormatTools:stringOf(pdValue)).

    end method.

    /**
     * Create a new User Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param plValue The value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input plValue as logical ):

        setUserProperty(pcProperty,FormatTools:stringOf(plValue)).

    end method.

    /**
     * Create a new User Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param ptValue The value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input ptValue as date ):

        setUserProperty(pcProperty,FormatTools:stringOf(ptValue)).

    end method.

    /**
     * Create a new User Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param ptValue The value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input ptValue as datetime ):

        setUserProperty(pcProperty,FormatTools:stringOf(ptValue)).

    end method.

    /**
     * Create a new User Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param ptValue The value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input pcValue as datetime-tz ):

        setUserProperty(pcProperty,FormatTools:stringOf(pcValue)).

    end method.

    /**
     * Create a new User Extent Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param pcValue The Extent value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input pcValue as character extent ):

        define variable iLoop as integer   no-undo.
        define variable iExt  as integer   no-undo.
        define variable cTemp as character no-undo.

        iExt = extent(pcValue).
        do iLoop = 1 to iExt:
            assign
                cTemp = cTemp +
                  (if iLoop = 1 then "" else {&extentDelimiter}) + pcValue[iLoop].
        end.

        setUserProperty(pcProperty, cTemp).

    end method.

    /**
     * Create a new User Extent Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param pdValue The Extent value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input pdValue as decimal extent ):

        define variable iLoop as integer   no-undo.
        define variable iExt  as integer   no-undo.
        define variable cTemp as character no-undo.

        iExt = extent(pdValue).
        do iLoop = 1 to iExt:
            assign
                cTemp = cTemp +
                  (if iLoop = 1 then "" else {&extentDelimiter}) + FormatTools:stringOf(pdValue[iLoop]).
        end.

        setUserProperty(pcProperty, cTemp).

    end method.

    /**
     * Create a new User Extent Property or update the value if it already exists
     *
     * @param pcProperty The name of the property to be saved
     * @param piValue The Extent value of the property to be saved
     */
    method public void setUserProperty ( input pcProperty as character, input piValue as integer extent ):

        define variable iLoop as integer   no-undo.
        define variable iExt  as integer   no-undo.
        define variable cTemp as character no-undo.

        iExt = extent(piValue).
        do iLoop = 1 to iExt:
            assign
                cTemp = cTemp +
                  (if iLoop = 1 then "" else {&extentDelimiter}) + FormatTools:stringOf(piValue[iLoop]).
        end.

        setUserProperty(pcProperty, cTemp).

    end method.

    /**
     * Remove/Delete the user property
     */
    method public void removeUserProperty ( input pcProperty as character ):

        define buffer lbUserSessionProp for ttUserSessionProp.

        find first lbUserSessionProp exclusive-lock
             where lbUserSessionProp.PropName eq pcProperty no-error.
        if available(lbUserSessionProp) then
            delete lbUserSessionProp.

    end method.

    /**
     * This method will invalidate the client principal object so that is can not be used again
     */
    method public void invalidateContext ( ):

        this-object:loginExpiration = now.

        if valid-handle(this-object:clientPrincipal) and
           lookup(this-object:clientPrincipal:login-state,"LOGIN,SSO") ne 0 then
            this-object:clientPrincipal:logout().

        saveContext().

    end method.

    method public void setActivityPassword ( input pcActivityPassword as character):

        activityPassword = CryptoTools:base64Decode(pcActivityPassword).

    end method.

end class.
