/*------------------------------------------------------------------------
    File        : <Spark_EntityName>.cls
    Author(s)   : <Spark_GenAuthor>
    Created     : <Spark_GenDate>
    Notes       : Custom invoke-only BE instance.
  ----------------------------------------------------------------------*/
@program FILE(name="<Spark_EntityName>.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="<Spark_ResourceName>", URI="/<Spark_ResourceName>", schemaName="<Spark_DatasetName>", schemaFile="").

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.BusinessLogic.BusinessEntity from propath.

block-level on error undo, throw.

class <Spark_Namespace><Spark_EntityName> inherits <Spark_InheritedEntity>:
    /*------------------------------------------------------------------------------
            Purpose:
            Notes:
    ------------------------------------------------------------------------------*/

    {<Spark_SchemaFile>}

    @openapi.openedge.entity.primarykey (fields="ttName").
    define temp-table ttParam before-table bttParam
        field ttName as char
        field ttValue as char
        index IdxMain ttName.
    define dataset dsParam for ttParam.

    /*------------------------------------------------------------------------------
            Purpose:
            Notes:
    ------------------------------------------------------------------------------*/
    constructor public <Spark_EntityName>():
        super(dataset <Spark_DatasetName>:handle).
    end constructor.

    /*------------------------------------------------------------------------------
            Purpose:  Get Param Value from Table
            Notes:
    ------------------------------------------------------------------------------*/
    method private character getParamValue ( input dataset dsParam, input paramName as character ):
        find first ttParam no-lock
             where ttParam.ttName eq paramName no-error.
        if available(ttParam) then
            return ttParam.ttValue.
        else
            return "".
    end method.

    /*------------------------------------------------------------------------------
            Purpose:  Get Grid Data
            Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/GetGridData", alias="", mediaType="application/json").
    method public void GetGridData ( input dataset dsParam, output dataset <Spark_DatasetName>):
        /** Add your code to call Progress .p here. Use getParamValue method to get the parameters,
            pass then to your program, get temp-table back from your program and it will go to front end automatically **/

        /** Sample Code **/

        define variable ipSalesRep as character no-undo.
        define variable ipCustNum  as integer   no-undo.
        define variable ipItemNum  as integer   no-undo.

        ipSalesRep = getParamValue(input dataset dsParam, input "ipSalesRep") no-error.
        ipCustNum = integer(getParamValue(input dataset dsParam, input "ipCustNum")) no-error.
        ipItemNum = integer(getParamValue(input dataset dsParam, input "ipItemNum")) no-error.

        dataset <Spark_DatasetName>:empty-dataset().

        /** Run your program here **/
        run <Spark_CodePath>chUI2.p (input ipSalesRep, input ipCustNum, input ipItemNum, output table <Spark_TempTableName>).
    end method. /* GetGridData */

end class.
