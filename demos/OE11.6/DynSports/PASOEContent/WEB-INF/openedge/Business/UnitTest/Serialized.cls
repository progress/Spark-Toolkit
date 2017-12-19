/*------------------------------------------------------------------------
    File        : Serialized
    Purpose     : Test harness for serialize-name issue
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Thu Mar 23 08:56:07 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Manager.ISchemaManager from propath.
using Spark.Core.Message.ErrorTypeEnum from propath.

block-level on error undo, throw.

class Business.UnitTest.Serialized inherits Spark.Core.Service.DynamicResource:

    define public override property serviceURI as character
        initial "/web/pdo/tests" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "serialize" no-undo get.
        protected set.

    define protected property oSchemaManager as ISchemaManager no-undo
        get:
            if not valid-object(oSchemaManager) then
                assign oSchemaManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ISchemaManager)), ISchemaManager).
            return oSchemaManager.
        end get.
        set.

    define temp-table ttSerTest no-undo serialize-name "test"
        field EmployeeID as integer
        field Number     as integer serialize-name "EmpNum"
        field Username   as character
        field Firstname  as character
        field Lastname   as character
        index EmployeeID is primary unique EmployeeID ascending
        index Username   is unique Username ascending
        index Lastname   is unique Lastname ascending
        index Number     Number ascending
        .
    define dataset dsSerialize serialize-name "serialized" for ttSerTest.

    method public override void initialize ( ):
        define variable hDataset as handle no-undo.

        /* Describe schema for any datasets to be exposed. */
        assign hDataset = dataset dsSerialize:handle.
        oSchemaManager:registerDataset(input hDataset).

        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "testOutput", "output", "get").
    end method. /* initialize */

    method public void testOutput ( output dataset for dsSerialize ):
        create ttSerTest.
        assign
            ttSerTest.EmployeeID = 1
            ttSerTest.Number     = 1
            ttSerTest.Username   = "Test"
            .
    end method. /* testOutput */

end class.