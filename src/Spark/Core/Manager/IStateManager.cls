using Spark.Core.Manager.StateLifeCycleEnum from propath.

/**
 * State Manager Interface
 * Responsible for reading and writing the session context data to and from a persistent store (i.e. a database)
 */
interface Spark.Core.Manager.IStateManager inherits Ccs.Common.IManager:

   method public longchar readContextFromStore( input pcClassID as character,
                                                input pcSessionContextID as character ).
   method public longchar readContextFromStoreAndLock( input pcClassID as character,
                                                       input pcSessionContextID as character ).

   method public void writeContextToStore( input pcData as longchar,
                                           input poLifeCycle as StateLifeCycleEnum,
                                           input pcClassID as character,
                                           input pcSessionContextID as character ).
   method public void writeContextToStore( input pcData as longchar,
                                           input ptExpire as datetime-tz,
                                           input pcClassID as character,
                                           input pcSessionContextID as character ).

   method public void updateLastUsed( input pcClassID as character,
                                      input pcSessionContextID as character ).

   method public void removeContextFromStore( input pcClassID as character,
                                              input pcSessionContextID as character ).

end interface.