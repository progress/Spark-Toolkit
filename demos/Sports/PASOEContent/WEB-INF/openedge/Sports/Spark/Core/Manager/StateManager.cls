using Spark.Core.Manager.IClientContext from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.StateLifeCycleEnum from propath.
using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

&GLOBAL-DEFINE USE_BP_SESSION_MGMT TRUE
&GLOBAL-DEFINE USE_WEB_DATA_STORE  TRUE
&GLOBAL-DEFINE WEB_SESSION_TABLE   WebSession
&GLOBAL-DEFINE WEB_DATASTORE_TABLE WebDataStore

/**
 * Session State Manager
 * Manages reading and writing the session context data from a persistent store
 */
class Sports.Spark.Core.Manager.StateManager inherits Spark.Core.Manager.StateManager:

    define protected property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.

    constructor public StateManager ( ):
        super().
    end constructor.

    method private void checkSession ( input pcSessionContextID as character ):
    &IF {&USE_BP_SESSION_MGMT} &THEN
        define buffer tbSession for {&WEB_SESSION_TABLE}.

        if pcSessionContextID begins "0." then return.

        repeat transaction:
            find first tbSession exclusive-lock
                 where tbSession.WebSessionID eq pcSessionContextID no-error no-wait.
            if locked tbSession then next.

            if not available tbSession then do:
                create tbSession.
                assign
                    tbSession.WebSessionID  = pcSessionContextID
                    tbSession.SessionActive = true
                    tbSession.StartDate     = today
                    tbSession.StartTime     = time
                    .
            end.

            assign
                tbSession.LastDate = today
                tbSession.LastTime = time
                .
            leave.
        end. /* repeat */
    &ENDIF

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Error while checking context", err, "SPARK-ERR", 0).
            return.
        end catch.
    end method. /* checkSession */

    /**
     * Reads the context data from the database store
     *
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     * @return The context data
     */
    method public override longchar readContextFromStore ( input pcClassID          as character,
                                                           input pcSessionContextID as character ):
        define variable cContext as longchar no-undo.

        checkSession( input pcSessionContextID ).
        if pcSessionContextID begins "0." then return "".

    &IF ({&USE_BP_SESSION_MGMT} and {&USE_WEB_DATA_STORE}) &THEN
        define buffer tbSessionState for {&WEB_DATASTORE_TABLE}.

        /**
         * If the record is read at the same time another session is updating the value in the CLOB field then a runtime error will occur when the
         * CLOB data is copied to the LONGCHAR. This error occurs when a reader reads a row that contains a lob no-lock. There is a race condition
         * between when the no-lock reader reads a row and then goes to fetch the lob via the locator in the record. It is possible for for another
         * transaction to have deleted the lob between the time the no-lock reader read the row and fetches the lob. If the lob has been deleted
         * (which can occur as a result of deleting the row or the lob can be deleted as the result of updating the lob, then an error is returned
         * (error up to 11.5 and in future fix/version, a zero length LOB will be returned instead of an error).
         *
         * So we read the state record with a share lock to ensure that any other writes have completed before reading the CLOB value.
        */
        repeat:
            find first tbSessionState share-lock
                 where tbSessionState.WebSessionID eq pcSessionContextID
                   and tbSessionState.ObjectName eq pcClassID no-error no-wait.
            if locked tbSessionState then next.

            if available tbSessionState then
                assign cContext = tbSessionState.ObjectData.

            leave.
        end. /* repeat */
    &ENDIF

        return cContext.

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Error while reading context", err, "SPARK-ERR", 0).
            return "". /* Just leave without issue. */
        end catch.
    end method. /* readContextFromStore */

    /**
     * Reads the context data from the database store and locks the db record
     *
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     * @return The context data
     */
    method public override longchar readContextFromStoreAndLock ( input pcClassID          as character,
                                                                  input pcSessionContextID as character ):
        return this-object:readContextFromStore(pcClassID, pcSessionContextID).
    end method. /* readContextFromStoreAndLock */

    /**
     * Store the context data in the database
     *
     * @param pcData The data to be stored
     * @param poLifeCycle The life cycle enumeration used to determine the expiry date for the data that can be used to clean up the data
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     */
    method public override void writeContextToStore ( input pcData             as longchar,
                                                      input poLifeCycle        as StateLifeCycleEnum,
                                                      input pcClassID          as character,
                                                      input pcSessionContextID as character ):
        checkSession ( input pcSessionContextID ).
        if pcSessionContextID begins "0." then return.

    &IF ({&USE_BP_SESSION_MGMT} and {&USE_WEB_DATA_STORE}) &THEN
        define buffer tbSessionState for {&WEB_DATASTORE_TABLE}.

        repeat transaction:
            find first tbSessionState exclusive-lock
                 where tbSessionState.WebSessionID eq pcSessionContextID
                   and tbSessionState.ObjectName eq pcClassID no-wait no-error.
            if locked tbSessionState then next.

            if not available tbSessionState then do:
                create tbSessionState.
                assign
                    tbSessionState.WebSessionID = pcSessionContextID
                    tbSessionState.ObjectName   = pcClassID
                    tbSessionState.add_dt       = today
                    tbSessionState.add_time     = time
                    tbSessionState.add_userid   = cast(Ccs.Common.Application:SessionManager:CurrentClientContext, IClientContext):userID
                    .
            end.

            assign
                tbSessionState.ObjectData = pcData
                tbSessionState.chg_dt     = today
                tbSessionState.chg_time   = time
                tbSessionState.chg_userid = cast(Ccs.Common.Application:SessionManager:CurrentClientContext, IClientContext):userID
                .

            leave.
        end. /* repeat */
    &ENDIF

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Error while writing context", err, "SPARK-ERR", 0).
            return.
        end catch.
    end method. /* writeContextToStore */

    /**
     * Store the context data in the database
     *
     * @param pcData The data to be stored
     * @param ptExpire The expiry date for the data that can be used to clean up the data
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     */
    method public override void writeContextToStore ( input pcData             as longchar,
                                                      input ptExpire           as datetime-tz,
                                                      input pcClassID          as character,
                                                      input pcSessionContextID as character ):
        this-object:writeContextToStore ( input pcData,
                                          input StateLifeCycleEnum:default,
                                          input pcClassID,
                                          input pcSessionContextID ).
    end method. /* writeContextToStore */

    /**
     * Update the state data record with the current datetime stamp
     *
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     */
    method public override void updateLastUsed ( input pcClassID          as character,
                                                 input pcSessionContextID as character ):
        checkSession ( input pcSessionContextID ).
        if pcSessionContextID begins "0." then return.

    &IF ({&USE_BP_SESSION_MGMT} and {&USE_WEB_DATA_STORE}) &THEN
        define buffer tbSessionState for {&WEB_DATASTORE_TABLE}.

        repeat transaction:
            find first tbSessionState exclusive-lock
                 where tbSessionState.WebSessionID eq pcSessionContextID
                   and tbSessionState.ObjectName eq pcClassID no-error no-wait.
            if locked tbSessionState then next.

            if not available tbSessionState then do:
                create tbSessionState.
                assign
                    tbSessionState.WebSessionID = pcSessionContextID
                    tbSessionState.ObjectName   = pcClassID
                    tbSessionState.add_dt       = today
                    tbSessionState.add_time     = time
                    tbSessionState.add_userid   = cast(Ccs.Common.Application:SessionManager:CurrentClientContext, IClientContext):userID
                    .
            end.

            assign
                tbSessionState.chg_dt     = today
                tbSessionState.chg_time   = time
                tbSessionState.chg_userid = cast(Ccs.Common.Application:SessionManager:CurrentClientContext, IClientContext):userID
                .

            leave.
        end. /* repeat */
    &ENDIF

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Error while updating context", err, "SPARK-ERR", 0).
            return.
        end catch.
    end method. /* updateLastUsed */

    /**
     * Remove the context data from the database
     *
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     */
    method public override void removeContextFromStore ( input pcClassID          as character,
                                                         input pcSessionContextID as character ):
        if pcSessionContextID begins "0." then return.

    &IF ({&USE_BP_SESSION_MGMT} and {&USE_WEB_DATA_STORE}) &THEN
        define buffer tbSessionState for {&WEB_DATASTORE_TABLE}.

        repeat transaction:
            find first tbSessionState exclusive-lock
                 where tbSessionState.WebSessionID eq pcSessionContextID
                   and tbSessionState.ObjectName eq pcClassID no-wait no-error.
            if locked tbSessionState then next.

            if available tbSessionState then
                delete tbSessionState.

            leave.
        end. /* repeat */
    &ENDIF

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Error while removing context", err, "SPARK-ERR", 0).
            return.
        end catch.
    end method. /* removeContextFromStore */

end class.