/*------------------------------------------------------------------------
    File        : PMFOUnit
    Purpose     : Provide basic methods to run ABLUnit against PMFO.
    Syntax      : 
    Description : 
    Author(s)   : dugrau@progress.com
    Created     : Tue May 30 11:47:54 EDT 2017
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.

block-level on error undo, throw.

class tests.PMFOUnit abstract: 

    define protected variable NumDatabases as integer no-undo.

    method protected void StartPMFO ( ):
        define variable oParser    as ObjectModelParser no-undo.
        define variable oConfig    as JsonObject        no-undo.
        define variable oDatabases as JsonObject        no-undo.
        define variable cDB        as character extent  no-undo.
        define variable ix         as integer           no-undo.

        this-object:NumDatabases = 0.
        if search("tests/config.json") ne ? then do:
            assign oParser = new Progress.Json.ObjectModel.ObjectModelParser().
            assign oConfig = cast(oParser:ParseFile(search("tests/config.json")), JsonObject) no-error.
            delete object oParser no-error.
        end. /* config.json */

        if valid-object(oConfig) and oConfig:Has("Databases") and
           oConfig:GetType("Databases") eq JsonDataType:object then do:
            /* Assign databases to be used via the config object. */
            assign oDatabases = oConfig:GetJsonObject("Databases") no-error.
        end.

        if valid-object(oDatabases) then do:
            /* Connect to standard databases, similar to -pf option in agentStartupParam. */
            assign cDB = oDatabases:GetNames().
            this-object:NumDatabases = extent(cDB).
            do ix = 1 to NumDatabases:
                connect value(cDB[ix]) value(oDatabases:GetCharacter(cDB[ix])) no-error.
            end. /* do ix */
        end. /* valid-object(oDatabases) */

        if this-object:NumDatabases eq 0 then
            OpenEdge.Core.Assert:RaiseError("No databases configured for testing.").

        /* Run standard "sessionStartupProc". */
        define variable cStartup as character no-undo. /* sessionStartupProcParam */
        run Spark/startup.p (input cStartup).

        catch err as Progress.Lang.Error:
    		OpenEdge.Core.Assert:RaiseError(err:GetMessage(1)).
        end catch.
        finally:
            delete object oConfig no-error.
            delete object oDatabases no-error.
        end finally.
    end method. /* StartPMFO */

    method protected void StopPMFO ( ):
        /* Run standard "sessionShutdownProc". */
        run Spark/shutdown.p.
        
        catch err as Progress.Lang.Error:
            OpenEdge.Core.Assert:RaiseError(err:GetMessage(1)).
        end catch.
    end method. /* StopPMFO */

    method protected logical HasManagerInterface ( ):
        define variable oManager as Progress.Lang.Class no-undo.

        assign oManager = Progress.Lang.Class:GetClass("Ccs.Common.IManager") no-error.

        return valid-object(oManager).
    end method. /* HasManagerInterface */

    method protected Progress.Lang.Object GetManager ( input pcClassInterface as character ):
        define variable oInterface as Progress.Lang.Class  no-undo.
        define variable oManager   as Progress.Lang.Object no-undo.

        assign oInterface = Progress.Lang.Class:GetClass(pcClassInterface) no-error.
        if valid-object(oInterface) then do:
            assign oManager = Ccs.Common.Application:StartupManager:getManager(oInterface) no-error.
        end.
        else
            OpenEdge.Core.Assert:RaiseError(substitute("Class interface unavailable: &1", pcClassInterface)).

        return oManager.
    end method. /* GetManager */

end class.