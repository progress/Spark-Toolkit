/*------------------------------------------------------------------------
    File        : shutdown.p
    Purpose     : Recommended to check for anydynamic objects left behind
    Description : Assigned as sessionShutdownProc in openedge.properties
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Apr 28 15:03:17 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

&GLOBAL-DEFINE MIN_LOG_LEVEL 3

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using Progress.Json.* from propath.

&GLOBAL-DEFINE WEB_SESSION_TABLE   WebSession
&GLOBAL-DEFINE WEB_DATASTORE_TABLE WebDataStore

procedure logMessage private:
    define input parameter pcMessage   as character no-undo.
    define input parameter pcSubSystem as character no-undo.

    if valid-handle(log-manager) and log-manager:logfile-name ne ? then
        log-manager:write-message (pcMessage, caps(pcSubSystem)).
    else
        message substitute("&1~n&2", pcSubSystem, pcMessage).
end procedure. /* logMessage */

/* ***************************  Main Block  *************************** */

/**
 * Important Note!
 * Since we still do not have any control over sessions and when they expire,
 * all of this is a BEST GUESS! We have to assume that sessions created prior
 * to today are subject to cleanup rules whenever a session is shut down.
 * This should take care of first deleting the master session record that we
 * are aware of (not what Tomcat holds in its own memory), and then delete
 * any related context data that no longer relates to a master session record.
 */

define buffer tbSession for {&WEB_SESSION_TABLE}.
for each tbSession exclusive-lock
   where tbSession.StartDate lt today
     and tbSession.LastDate lt today
     and tbSession.LastTime lt (time - 7200):
    /* Delete any sessions where both started and last touched prior to today.  */
    /* Extra check on time should account for sessions started before midnight. */
    run logMessage (substitute("Deleting Old Session: &1", tbSession.WebSessionID), "SHUTDOWN").
    delete tbSession.
end. /* for each */

define buffer tbSessionState for {&WEB_DATASTORE_TABLE}.
for each tbSessionState exclusive-lock
   where not can-find(first tbSession no-lock
                      where tbSession.WebSessionID eq tbSessionState.WebSessionID):
    /* Cleanup all orphaned datastore records (those with no session record). */
    run logMessage (substitute("Deleting Old Context: &1", tbSessionState.WebSessionID), "SHUTDOWN").
    delete tbSessionState.
end. /* for each */

/**
 * Run the default shutdown procedure.
 * -Logs any objects still in memory.
 * -Stops all lifecycles, managers.
 */
run Spark/shutdown.p.

catch err as Progress.Lang.Error:
    run logMessage (substitute("Error: &1", err:GetMessage(1)), "SHUTDOWN").
end catch.

