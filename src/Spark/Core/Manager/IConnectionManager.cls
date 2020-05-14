/**
 * Connection Manager Intereface
 */
interface Spark.Core.Manager.IConnectionManager inherits Ccs.Common.IManager:

    method public handle getServer( input pcConnectName as character ).

    method public void stopLifeCycle( input poLifeCycle as Ccs.ServiceManager.ILifecycleScope ).

    method public void stopServer( input pcServerName as character ).

    method public handle reconnectServer( input pcServerName as character ).

    method public logical validContext( input pcServerName as character ).

    method public logical getConnectionParam( input pcConnectName as character,
                                              output pcConnectType as character,
                                              output poLifeCycle as Ccs.ServiceManager.ILifecycleScope,
                                              output pcConnectParam as character).

    method public handle getProcHandle( input pcServerName as character, input pcProcName as character ).

end interface.