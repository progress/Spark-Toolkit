/*------------------------------------------------------------------------
    File        : IServiceManager
    Purpose     : Implement a customized CCS Startup Manager
    Description : Startup Manager (Interface)
    Author(s)   : progress
    Created     : Tue Mar 03 13:55:33 EST 2015
    Notes       : An instance is to be created and set in the ServiceManager
                  property of Ccs.Common.Application and accessed from there.
  ----------------------------------------------------------------------*/

using Spark.Core.Message.IAbstractMessage.

interface Spark.Core.Manager.IServiceManager inherits Ccs.Common.IServiceManager:

    method public void callServiceFunction( input poServiceClass as Progress.Lang.Class,
                                            input pcFunction     as character,
                                            input poRequest      as IAbstractMessage,
                                            input poResponse     as IAbstractMessage ).

    method public void callServiceFunction( input poServiceClass as Progress.Lang.Class,
                                            input pcFunction     as character ).

    method public Progress.Lang.Class getServiceImplementation( input poService as Progress.Lang.Class ).

end interface.
