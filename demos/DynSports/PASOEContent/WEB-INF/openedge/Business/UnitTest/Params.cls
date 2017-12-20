/*------------------------------------------------------------------------
    File        : Params
    Purpose     : Test harness for confirming all datatypes as params
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Thu Mar 23 08:56:07 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Manager.ISchemaManager from propath.
using Spark.Core.Message.ErrorTypeEnum from propath.

block-level on error undo, throw.

class Business.UnitTest.Params inherits Spark.Core.Service.DynamicResource:

    define public override property serviceURI as character
        initial "/web/pdo/tests" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "params" no-undo get.
        protected set.

    define protected property oSchemaManager as ISchemaManager no-undo
        get:
            if not valid-object(oSchemaManager) then
                assign oSchemaManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ISchemaManager)), ISchemaManager).
            return oSchemaManager.
        end get.
        set.

    define temp-table ttInParam no-undo
        field cString  as character
        field fDecimal as decimal
        field iInteger as integer
        field dDate    as date
        field dDTime   as datetime
        field dDTimeTZ as datetime-tz
        .
    define dataset dsInParam for ttInParam.

    define temp-table ttOutParam no-undo
        field cString  as character
        field fDecimal as decimal
        field iInteger as integer
        field dDate    as date
        field dDTime   as datetime
        field dDTimeTZ as datetime-tz
        .
    define dataset dsOutParam for ttOutParam.

    method public override void initialize ( ):
        define variable hDataset as handle no-undo.

        /* Describe schema for any temp-tables to be exposed. */
        oSchemaManager:registerTempTable(input temp-table ttInParam:handle).
        oSchemaManager:registerTempTable(input temp-table ttOutParam:handle).

        /* Describe schema for any datasets to be exposed. */
        assign hDataset = dataset dsInParam:handle.
        oSchemaManager:registerDataset(input hDataset).
        assign hDataset = dataset dsOutParam:handle.
        oSchemaManager:registerDataset(input hDataset).

        /* Describe any properties about invoke methods to be exposed. */
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "testPrimitives", "primitives", "put").
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "testTable", "table", "put").
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "testDataset", "dataset", "put").
    end method. /* initialize */

    method public void testPrimitives ( input  inString   as character,
                                        input  inDecimal  as decimal,
                                        input  inInteger  as integer,
                                        input  inDate     as date,
                                        input  inDTime    as datetime,
                                        input  inDTimeTZ  as datetime-tz,
                                        output outString  as character,
                                        output outDecimal as decimal,
                                        output outInteger as integer,
                                        output outDate    as date,
                                        output outDTime   as datetime,
                                        output outDTimeTZ as datetime-tz ):
        /* Simply echo any input parameters back via their output counterpart. */
        assign
            outString  = inString
            outDecimal = inDecimal
            outInteger = inInteger
            outDate    = inDate
            outDTime   = inDTime
            outDTimeTZ = inDTimeTZ
            .
    end method. /* testPrimitives */

    method public void testTable ( input  table ttInParam,
                                   output table ttOutParam ):
        empty temp-table ttOutParam.

        if can-find(first ttInParam) then
            for each ttInParam:
                create ttOutParam.
                message "Record:" ttInParam.cString ":" ttInParam.fDecimal ":" ttInParam.iInteger ":" ttInParam.dDate ":" ttInParam.dDTime ":" ttInParam.dDTimeTZ.
                buffer-copy ttInParam to ttOutParam no-error.
            end.
        else do:
            this-object:oResponse:addError("Field", ErrorTypeEnum:warning, "No records available from input temp-table.").
            create ttOutParam.
            assign
                ttOutParam.cString  = "OutString"
                ttOutParam.fDecimal = 3.14
                ttOutParam.iInteger = 123
                ttOutParam.dDate    = today
                ttOutParam.dDTime   = now
                ttOutParam.dDTimeTZ = now
                .
        end.
    end method. /* testTable */

    method public void testDataset ( input  dataset dsInParam,
                                     output dataset dsOutParam ):
        empty temp-table ttOutParam.

        if can-find(first ttInParam) then
            for each ttInParam:
                create ttOutParam.
                message "Record:" ttInParam.cString ":" ttInParam.fDecimal ":" ttInParam.iInteger ":" ttInParam.dDate ":" ttInParam.dDTime ":" ttInParam.dDTimeTZ.
                buffer-copy ttInParam to ttOutParam no-error.
            end.
        else do:
            this-object:oResponse:addError("Field", ErrorTypeEnum:warning, "No records available from input dataset.").
            create ttOutParam.
            assign
                ttOutParam.cString  = "OutString"
                ttOutParam.fDecimal = 3.14
                ttOutParam.iInteger = 123
                ttOutParam.dDate    = today
                ttOutParam.dDTime   = now
                ttOutParam.dDTimeTZ = now
                .
        end.
    end method. /* testDataset */

end class.