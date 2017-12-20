/*------------------------------------------------------------------------
    File        : Globals
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Aug 02 15:00:34 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Manager.IStateManager from propath.
using Spark.Core.Manager.StateLifeCycleEnum from propath.

block-level on error undo, throw.

class Common.Globals serializable:

    /* Static Members */

    define public static property Instance as Common.Globals no-undo
        get():
            if not valid-object(Instance) then do on error undo, throw:
                /* Attempt to restore globals from serialized data. */
                define variable cFilename as character            no-undo.
                define variable oClassObj as Progress.Lang.Object no-undo.

                /* Obtain the serialized class data using the proper context ID. */
                define variable lcData as longchar no-undo.
                assign lcData = cast(Ccs.Common.Application:StartupManager:getManager(get-class(IStateManager)), IStateManager)
                                    :readContextFromStore("Common.Globals", Ccs.Common.Application:SessionManager:CurrentClientContext:contextID).

                /* Restore the class object by deserialization from longchar data. */
                assign oClassObj = Spark.Core.Util.Serialize:deserializeClassFromJson(lcData).
                if valid-object(oClassObj) then do:
                    Instance = cast(oClassObj, Common.Globals) no-error.
                    if error-status:error then
                        undo, throw new AppError("Unable to cast to globals object.", 0).
                end.
                else
                    undo, throw new AppError("Existing globals data not available.", 0).

                catch err as Progress.Lang.Error:
                    if log-manager:logging-level ge 3 then
                        message substitute("&1 Creating new object with default properties.", err:GetMessage(1)).

                    /* Error occurred during deserialization, or no data was available. */
                    Instance = new Common.Globals().

                    assign /* Set with initial data for this test, including constant and variable values. */
                        Instance:cID    = Ccs.Common.Application:SessionManager:CurrentClientContext:contextID
                        Instance:dTime  = now
                        Instance:iMTime = mtime
                        .

                    Instance:addRecord().
                end catch.
                finally:
                    assign lcData = "".
                end finally.
            end.
            return Instance.
        end get.
        private set.


    /* Instance Members */

    define public variable cID    as character   no-undo.
    define public variable dTime  as datetime-tz no-undo.
    define public variable iMTime as integer     no-undo.

    define private serializable temp-table ttCustomer like Customer.
    define private serializable dataset dsCustomer for ttCustomer.


    constructor Globals ( ):
        /* Instance constructor, run when new instance is created. */
    end constructor.


    method public void addRecord ( ):
        empty temp-table ttCustomer.

        for first Customer no-lock:
            create ttCustomer.
            buffer-copy Customer to ttCustomer no-error.
            release ttCustomer.
        end.
    end method.


    method public logical hasRecord ( ):
        return can-find(first ttCustomer).
    end method.

end class.