using Ccs.ServiceManager.ILifecycleScope from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.ServiceLifeCycleEnum from propath.
using Spark.Core.Util.ApplicationError from propath.
using Spark.Core.Util.OSTools from propath.

block-level on error undo, throw.

/**
 * Connection Manager
 * Starts up and manager all connections to other servers.  e.g. other Progress appservers or extenal web services.
 */
class Spark.Core.Manager.ConnectionManager inherits Spark.Core.Manager.Manager implements Spark.Core.Manager.IConnectionManager use-widget-pool:

    define protected property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.

    define protected temp-table ttServer no-undo
        field ServerName         as character
        field ServerHandle       as handle
        field ServerContext      as character
        field ProcedureHandle    as handle
        field ConnectionParam    as character
        field ConnectionUser     as character
        field ConnectionPassword as character
        field ConnectionInfo     as character
        field ServerType         as character
        field LifeCycleScope     as character
        index ix1 as primary unique ServerName
        index ix2                   LifeCycleScope ServerName.

    define protected temp-table ttConnection no-undo serialize-name "Connection"
        field ConnectName  as character serialize-name "Name"
        field ConnectType  as character serialize-name "Type"
        field ConnectParam as character serialize-name "Param"
        field LifeCycle    as character serialize-name "LifeCycle"
        index ix1 as primary unique ConnectName.

    define protected dataset dsConnection serialize-name "Config"
        for ttConnection.

    constructor public ConnectionManager (  ):
        super().
    end constructor.

    method override public void initialize(  ):
        loadConfig().
    end method.

    method override public void dispose ( ):
    end method. /* dispose */

    method protected void loadConfig():

        define variable cCfgFileName     as character no-undo.
        define variable cFullCfgFileName as character no-undo.

        assign cCfgFileName = "connection.json".
        file-info:file-name = OSTools:sparkConf + cCfgFileName.
        assign cFullCfgFileName = file-info:full-pathname.

        if cFullCfgFileName ne ? then
            dataset dsConnection:read-json("file", cFullCfgFileName, "empty").
        else
            undo, throw new ApplicationError(substitute("Connection config file [&1] not found in [&2]", cCfgFileName, OSTools:sparkConf), 0).

        find first ttConnection
             where ttConnection.ConnectName eq "Session" no-error.
        if not available(ttConnection) then
            create ttConnection.

        /* Make sure these are set correctly. */
        assign
            ttConnection.ConnectName  = "Session"
            ttConnection.ConnectParam = "session:handle"
            ttConnection.ConnectType  = "AppServer"
            ttConnection.LifeCycle    = "Session"
            .

    end method.

    /**
     * Return the Connection Configuration data
     *
     * @param pcConnectName The Connection Name
     * @param pcConnectType The Connection Type
     * @param pcConnectParam The Connection Parameters
     * @return TRUE if the Connection Configuration is found else FALSE
     */
    method public logical getConnectionParam(input pcConnectName as character, output pcConnectType as character, output poLifeCycle as ILifecycleScope, output pcConnectParam as character):

        find first ttConnection no-lock
             where ttConnection.ConnectName eq pcConnectName no-error.
        if available(ttConnection) then
        do:
            assign
                pcConnectType  = ttConnection.ConnectType
                poLifeCycle    = ServiceLifeCycleEnum:enumFromString(ttConnection.LifeCycle)
                pcConnectParam = ttConnection.ConnectParam
                .
            return true.
        end.

        return false.

    end method.

    /**
     * Will return the handle to the requested server.
     * If the server is not connected then this function will create the server and connect it using the parameters supplied in the Config.xml
     *
     * @param pcConnectName The Name of the Server to connect to as defined in the Config.xml
     * @return The Handle to the server
     */
    method public handle getServer( input pcConnectName as character ):

        define buffer lbServer for ttServer.

        define variable cConnectParam         as character       no-undo.
        define variable cConnectType          as character       no-undo.
        define variable oServiceLifeCycleEnum as ILifecycleScope no-undo.

        find first lbServer no-lock
             where lbServer.ServerName eq pcConnectName no-error.
        if not available(lbServer) then
        do:
            if getConnectionParam(pcConnectName, output cConnectType, output oServiceLifeCycleEnum, output cConnectParam ) then
            do:
                create lbServer.
                assign
                    lbServer.ServerName      = pcConnectName
                    lbServer.ServerType      = cConnectType
                    lbServer.LifeCycleScope  = ServiceLifeCycleEnum:stringFromEnum(oServiceLifeCycleEnum)
                    lbServer.ConnectionParam = cConnectParam
                    .
            end.
        end.
        find first lbServer no-lock
             where lbServer.ServerName eq pcConnectName no-error.
        if not available(lbServer) then
            undo, throw new ApplicationError("Connection [&1] not defined",pcConnectName).

        if lbServer.LifeCycleScope eq ServiceLifeCycleEnum:stringFromEnum(ServiceLifeCycleEnum:none) then
        do:
            delete lbServer.
            undo, throw new ApplicationError("Connection LifeCyle of NONE for connection [&1] is not allowed", pcConnectName).
        end.

        case lbServer.ServerType:
            when "AppServer" then do:
                if not valid-handle(lbServer.ServerHandle) or
                   not lbServer.ServerHandle:connected() then
                do:
                    if not lbServer.ConnectionParam eq "session:handle" then
                        delete object lbServer.ServerHandle no-error.

                    if lbServer.ConnectionParam eq "session:handle" then
                        lbServer.ServerHandle = session:handle.
                    else
                    do:
                        create server lbServer.ServerHandle.
                        if lbServer.ConnectionUser gt "" or
                           lbServer.ConnectionPassword gt "" or
                           lbServer.ConnectionInfo gt "" then
                            /* Additional parameters are needed for the connection. */
                            lbServer.ServerHandle:connect(lbServer.ConnectionParam,
                                                          lbServer.ConnectionUser,
                                                          lbServer.ConnectionPassword,
                                                          lbServer.ConnectionInfo).
                        else
                            /* Otherwise simply make the connection with the params. */
                            lbServer.ServerHandle:connect(lbServer.ConnectionParam).
                        assign lbServer.ProcedureHandle = ?. /* Reset proc handle. */
                        if valid-handle(lbServer.ServerHandle) and valid-object(lbServer.ServerHandle:request-info) then
                            lbServer.ServerContext = lbServer.ServerHandle:request-info:ClientContextId. /* SessionID */

                        oLoggingManager:logMessage(substitute("AS Connection Made [&1]: &2 (ID: &3)", pcConnectName, lbServer.ConnectionParam, lbServer.ServerContext), "CONN-MGR", 3).
                    end.
                end.
            end.

            when "WebService" then do:
                if not valid-handle(lbServer.ServerHandle) or
                   not lbServer.ServerHandle:connected() then
                do:
                    delete object lbServer.ServerHandle no-error.
                    create server lbServer.ServerHandle.
                    lbServer.ServerHandle:connect(lbServer.ConnectionParam).

                    oLoggingManager:logMessage(substitute("Web Connection Made [&1]: &2", pcConnectName, lbServer.ConnectionParam), "CONN-MGR", 3).
                end.
            end.

            otherwise
                undo, throw new ApplicationError("Connection Type [&1] not implemented for connection [&2]", lbServer.ServerType, pcConnectName).

        end case.

        return lbServer.ServerHandle.

    end method.

    /**
     * Stops all servers running in a life cycle scope.
     *
     * @param poLifeCycle The Life Cycle scope to stop
     */
    method public void stopLifeCycle ( input poLifeCycle as ILifecycleScope ):

        define buffer lbServer for ttServer.

        for each lbServer no-lock
           where lbServer.LifeCycleScope eq ServiceLifeCycleEnum:stringFromEnum(poLifeCycle):
            stopServer(lbServer.ServerName).
        end.

    end method.

    /**
     * Stops a running server.
     *
     * @param pcServerName Server Name of server to stop
     */
    method public void stopServer ( input pcServerName as character ):

        define buffer lbServer for ttServer.

        do transaction:
            find first lbServer exclusive-lock
                 where lbServer.ServerName eq pcServerName no-error.
            if available(lbServer) then
            do:
                if not lbServer.ServerHandle eq session:handle then
                do:
                    if valid-handle(lbServer.ProcedureHandle) then
                        delete procedure lbServer.ProcedureHandle no-error.
                    lbServer.ServerHandle:disconnect() no-error.
                    delete object lbServer.ServerHandle no-error.
                    delete lbServer.
                end.
            end.
        end.

    end method.

    /**
     * Stops and reconnects to a server.
     *
     * @param pcServerName Server Name of server to reconnect
     */
    method public handle reconnectServer( input pcServerName as character ):

        stopServer(pcServerName).
        return getServer(pcServerName).

    end method.

    /**
     * Determines if server context has expired.
     *
     * @param pcServerName Server Name of server to check
     */
    method public logical validContext( input pcServerName as character ):

        define buffer lbServer for ttServer.

        do transaction:
            find first lbServer exclusive-lock
                 where lbServer.ServerName eq pcServerName no-error.
            if available(lbServer) then
            do:
                if not lbServer.ServerHandle eq session:handle then
                do:
                    /* If server handle has a valid response-info object, compare to existing context. */
                    if valid-object(lbServer.ServerHandle:response-info) then
                        return (lbServer.ServerHandle:response-info:ClientContextId ne ? and
                                lbServer.ServerContext eq lbServer.ServerHandle:response-info:ClientContextId).
                end.
            end.
        end.

        return true.

    end method.

    /**
     * Get a singleton procedure handle on a given server.
     *
     * @param pcServerName Server Name of server to set
     * @param phProcedure Handle for procedure on server
     */
    method public handle getProcHandle( input pcServerName as character,
                                        input pcProcName   as character ):

        define buffer lbServer for ttServer.

        do transaction:
            find first lbServer exclusive-lock
                 where lbServer.ServerName eq pcServerName no-error.
            if available(lbServer) then
            do:
                if lbServer.ServerHandle ne session:handle then
                do:
                    /* If server handle has a valid response-info object, compare to existing context. */
                    if valid-handle(lbServer.ServerHandle) and lbServer.ServerHandle:connected() then
                    do:
                        if not valid-handle(lbServer.ProcedureHandle) then do:
                            if (pcProcName gt "") eq true then do:
                                run value(pcProcName) on server lbServer.ServerHandle singleton set lbServer.ProcedureHandle no-error.
                                if error-status:error then
                                    oLoggingManager:logMessage(substitute("Error creating procedure handle: &1", error-status:get-message(1)), "CONN-MGR", 1).
                                oLoggingManager:logMessage(substitute("Procedure Handle Created: &1 (ID: &2)", pcProcName, lbServer.ServerContext), "CONN-MGR", 3).
                            end.
                            else
                                assign lbServer.ProcedureHandle = ?.
                        end. /* not valid-handle */

                        return lbServer.ProcedureHandle.
                    end. /* connected */
                    else
                        oLoggingManager:logMessage("Server handle is invalid or not connected.", "CONN-MGR", 3).
                end.
                else
                    oLoggingManager:logMessage("Server handle is the session handle.", "CONN-MGR", 3).
            end.
            else
                oLoggingManager:logMessage("Unable to locate server handle record.", "CONN-MGR", 3).
        end.

        return ?.

    end method.

end class.
