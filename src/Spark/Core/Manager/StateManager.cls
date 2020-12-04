using Spark.Core.Manager.StateLifeCycleEnum from propath.

block-level on error undo, throw.

/**
 * Session State Manager
 * Responsible for reading and writing the session context data to and from a persistent store (i.e. a database)
 */
class Spark.Core.Manager.StateManager inherits Spark.Core.Manager.Manager implements Spark.Core.Manager.IStateManager:

    constructor public StateManager (  ):
        super ().
    end constructor.

    method override public void initialize ( ):

    end method.

    method override public void dispose ( ):

    end method.

    /**
     * Reads the context data from the database store
     *
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     * @return The context data
     */
    method public longchar readContextFromStore ( input pcClassID as character, input pcSessionContextID as character ):

        define variable cContext as longchar no-undo.

        file-info:file-name = session:temp-directory + pcClassID + "." + pcSessionContextID.
        if file-info:full-pathname ne ? then
        do:
            /* Move this to a secure store - better still into the database. */
            input from value(file-info:full-pathname).
            import cContext.
            input close.
        end.

        return cContext.

    end method.

    /**
     * Reads the context data from the database store and locks the db record
     *
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     * @return The context data
     */
    method public longchar readContextFromStoreAndLock ( input pcClassID as character, input pcSessionContextID as character ):

        define variable cContext as longchar no-undo.

        file-info:file-name = session:temp-directory + pcClassID + "." + pcSessionContextID.
        if file-info:full-pathname ne ? then
        do:
            /* Move this to a secure store - better still into the database. */
            input from value(file-info:full-pathname).
            import cContext.
            input close.
        end.

        return cContext.

    end method.

    /**
     * Store the context data in the database
     *
     * @param pcData The data to be stored
     * @param poLifeCycle The life cycle enumeration used to determine the expiry date for the data that can be used to clean up the data
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     */
    method public void writeContextToStore ( input pcData             as longchar,
                                             input poLifeCycle        as StateLifeCycleEnum,
                                             input pcClassID          as character,
                                             input pcSessionContextID as character ):

        /* This should go in the DB. */
        output to value(session:temp-directory + pcClassID + "." + pcSessionContextID).
        export pcData.
        output close.

    end method.

    /**
     * Store the context data in the database
     *
     * @param pcData The data to be stored
     * @param ptExpire The expiry date for the data that can be used to clean up the data
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     */
    method public void writeContextToStore ( input pcData             as longchar,
                                             input ptExpire           as datetime-tz,
                                             input pcClassID          as character,
                                             input pcSessionContextID as character ):

        /* This should go in the DB. */
        output to value(session:temp-directory + pcClassID + "." + pcSessionContextID).
        export pcData.
        output close.

    end method.

    /**
     * Update the state data record with the current datetime stamp
     *
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     */
    method public void updateLastUsed ( input pcClassID as character, input pcSessionContextID as character ):

    end.

    /**
     * Remove the context data from the database
     *
     * @param pcClassID A Unique ID to save the context data under
     * @param pcSessionContextID The unique Session Context ID used to store the context data under
     */
    method public void removeContextFromStore ( pcClassID as character, input pcSessionContextID as character ):

        os-delete value(session:temp-directory + pcClassID + "." + pcSessionContextID) no-error.

    end method.

    method public logical cleanOldContextData ( input piDays as integer ):

        /**
         * This will turn on the context file cleanup feature, which does use
         * system resources and has file I/O associated with it. Execute this
         * only if you have no other options for removing the context files
         * automatically from your filesystem.
         */

        /* Prepare to search the working directory. */
        file-info:file-name = session:temp-directory.

        DIRBLOCK:
        do on error undo DIRBLOCK, leave DIRBLOCK
           on stop  undo DIRBLOCK, leave DIRBLOCK:
            define variable cFileName as character no-undo.
            define variable cFilePath as character no-undo.
            define variable cFileType as character no-undo.

            if file-info:full-pathname eq ? then leave DIRBLOCK.
            input from os-dir(file-info:full-pathname).
            repeat:
                import cFileName cFilePath cFileType no-error.
                if error-status:error then leave DIRBLOCK.
                if cFileType eq "F" and cFileName matches get-class(Spark.Core.Manager.ClientContext):TypeName + ".*" then do:
                    /* Delete session context files more than X days old. */
                    file-info:file-name = cFilePath.
                    if file-info:file-mod-date lt (today - absolute(piDays)) then
                        os-delete value(file-info:full-pathname).
                end.
            end.
        end.

        catch err as Progress.Lang.Error:
            message err:GetMessage(1).
        end catch.

    end method.

end class.
