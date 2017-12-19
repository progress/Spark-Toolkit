/*------------------------------------------------------------------------
    File        : ResourceRouter
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Thu Apr 28 08:40:33 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Manager.IClientContext from propath.
using Spark.Core.Manager.IServiceManager from propath.
using Spark.Core.Manager.ICatalogManager from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.IMessageManager from propath.
using Spark.Core.Manager.IRouteManager from propath.
using Spark.Core.Manager.ISchemaManager from propath.
using Spark.Core.Manager.Manager from propath.
using Spark.Core.Message.IAbstractMessage from propath.
using Spark.Core.Message.IResponse from propath.
using Spark.Core.Service.IDynamicEntity from propath.
using Spark.Core.Service.IDynamicResource from propath.
using Spark.Core.Util.ApplicationError from propath.
using Spark.Core.Util.DynamicCaller from propath.
using Spark.Core.Util.GenTools from propath.
using Spark.Core.Util.MethodSignature from propath.

block-level on error undo, throw.
&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW

class Spark.Core.Manager.RouteManager inherits Spark.Core.Manager.Manager implements IRouteManager use-widget-pool:

    define protected property oCatalogManager as ICatalogManager no-undo
        get:
            if not valid-object(oCatalogManager) then
                assign oCatalogManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager).
            return oCatalogManager.
        end get.
        set.

    define protected property oClientContext as IClientContext no-undo
        get:
            if not valid-object(oClientContext) then
                assign oClientContext = cast(Ccs.Common.Application:SessionManager:CurrentClientContext, IClientContext).
            return oClientContext.
        end get.
        set.

    define protected property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.

    define protected property oMessageManager as IMessageManager no-undo
        get:
            if not valid-object(oMessageManager) then
                assign oMessageManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager).
            return oMessageManager.
        end get.
        set.

    define protected property oSchemaManager as ISchemaManager no-undo
        get:
            if not valid-object(oSchemaManager) then
                assign oSchemaManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ISchemaManager)), ISchemaManager).
            return oSchemaManager.
        end get.
        set.

    method public override void initialize ( ):
    end method.

    method public override void dispose ( ):
    end method.

    method private void prepareInputParams ( input poRequest   as IAbstractMessage,
                                             input poSignature as MethodSignature,
                                             input poDynCaller as DynamicCaller ):
        define variable cInputs    as character no-undo.
        define variable cParamName as character no-undo.
        define variable cParamList as character no-undo extent.
        define variable lFound     as logical   no-undo initial false.
        define variable iCount     as integer   no-undo.
        define variable iNumParams as integer   no-undo.
        define variable iParam     as integer   no-undo.
        define variable hParam     as handle    no-undo.

        if not valid-object(poRequest) or
           not valid-object(poSignature) or
           not valid-object(poDynCaller) then return.

        assign cInputs = poSignature:getInputParameters().

        if num-entries(cInputs) gt 0 then
        do iCount = 1 to num-entries(cInputs):
            assign
                cParamName = entry(iCount, cInputs)
                lFound     = false /* Reset for parameter. */
                hParam     = ?
                .

            assign cParamList = poRequest:getParams().
            assign iNumParams = extent(cParamList).
            do iParam = 1 to iNumParams:
                if cParamName eq cParamList[iParam] then
                    assign lFound = true.
            end. /* iParam */

            if not lFound then /* Exit if parameter is not in the JSON request object. */
                undo, throw new ApplicationError(substitute("Parameter '&1' not found", cParamName), -404).

            if poSignature:isDataset(cParamName) then do:
                oLoggingManager:logMessage(substitute("Obtaining dataset request parameter '&1'", cParamName), "ROUTE-DBG", 5).

                /* Input is explicitly a dataset, must convert and set as handle. */
                poDynCaller:getParameter( input  cParamName,
                                          output dataset-handle hParam by-reference ).

                if not valid-handle(hParam) then
                    undo, throw new ApplicationError(substitute("Invalid datatype for parameter '&1' (expected DataSet)", cParamName), -500).

                if log-manager:logging-level ge 7 then
                    hParam:write-xmlschema("file", substitute("prep_inparam_&1.xml", cParamName), true).

                /* Obtain parameter data from request. */
                poRequest:getParamAsHandle( input cParamName,
                                            input "empty",
                                            input hParam ).

                if log-manager:logging-level ge 7 then
                    hParam:write-json("file", substitute("prep_inparam_&1.json", cParamName), true).

                /* Set contents of parameter handle in dynamic caller. */
                poDynCaller:setParameter( input cParamName,
                                          input dataset-handle hParam ). /* DO NOT pass by-reference here! */

                delete object hParam no-error.
            end. /* isDataset (INPUT) */

            else if poSignature:isTempTable(cParamName) then do:
                oLoggingManager:logMessage(substitute("Obtaining temp-table request parameter '&1'", cParamName), "ROUTE-DBG", 5).

                /* Input is explicitly a temp-table, must convert and set as handle. */
                poDynCaller:getParameter( input  cParamName,
                                          output table-handle hParam by-reference ).

                if not valid-handle(hParam) then
                    undo, throw new ApplicationError(substitute("Invalid datatype for parameter '&1' (expected TempTable)", cParamName), -500).

                if log-manager:logging-level ge 7 then
                    hParam:write-xmlschema("file", substitute("prep_inparam_&1.xml", cParamName), true).

                /* Obtain parameter data from request. */
                poRequest:getParamAsHandle( input cParamName,
                                            input "empty",
                                            input hParam ).

                if log-manager:logging-level ge 7 then
                    hParam:write-json("file", substitute("prep_inparam_&1.json", cParamName), true).

                /* Set contents of parameter handle in dynamic caller. */
                poDynCaller:setParameter( input cParamName,
                                          input table-handle hParam ). /* DO NOT pass by-reference here! */

                delete object hParam no-error.
            end. /* isTempTable (INPUT) */

            else if poSignature:isJsonArray(cParamName) then do:
                oLoggingManager:logMessage(substitute("Obtaining array request parameter '&1'", cParamName), "ROUTE-DBG", 5).
                poDynCaller:setParameter( input cParamName,
                                          input poRequest:getParamAsJsonArray(cParamName) ).
            end. /* isJsonArray (INPUT) */

            else if poSignature:isJsonObject(cParamName) then do:
                oLoggingManager:logMessage(substitute("Obtaining object request parameter '&1'", cParamName), "ROUTE-DBG", 5).
                poDynCaller:setParameter( input cParamName,
                                          input poRequest:getParamAsJsonObject(cParamName) ).
            end. /* isJsonObject (INPUT) */

            /* Just pass input value as-is, and let the dynamic caller convert the datatype as needed. */
            else do:
                oLoggingManager:logMessage(substitute("Obtaining request parameter '&1'", cParamName), "ROUTE-DBG", 5).
                if not poDynCaller:setParameter(cParamName, poRequest:getParamAsJsonText(cParamName)) then
                    undo, throw new ApplicationError(substitute("Invalid datatype for parameter '&1'", cParamName), -500).
            end. /* All Other Types */
        end. /* Inputs */

    end method. /* prepareInputParams */


    method private void prepareOutputParams ( input poResponse   as IAbstractMessage,
                                              input poSignature  as MethodSignature,
                                              input poDynCaller  as DynamicCaller,
                                              input plUseTableBI as logical ):
        define variable cOutputs    as character            no-undo.
        define variable cParamName  as character            no-undo.
        define variable cParamValue as longchar             no-undo.
        define variable iCount      as integer              no-undo.
        define variable hParam      as handle               no-undo.
        define variable oParam      as Progress.Lang.Object no-undo.

        if not valid-object(poResponse) or
           not valid-object(poSignature) or
           not valid-object(poDynCaller) then return.

        assign cOutputs = poSignature:getOutputParameters().

        if num-entries(cOutputs) gt 0 then
        do iCount = 1 to num-entries(cOutputs):
            assign
                cParamName = entry(iCount, cOutputs)
                hParam     = ?
                .

            if poSignature:isDataset(cParamName) then do:
                oLoggingManager:logMessage(substitute("Outputting dataset parameter '&1'", cParamName), "ROUTE-DBG", 5).

                /* Output is explicitly a dataset. */
                poDynCaller:getParameter( input  cParamName,
                                          output dataset-handle hParam by-reference ).

                if log-manager:logging-level ge 7 then do:
                    hParam:write-xmlschema("file", substitute("prep_outparam_&1.xml", cParamName), true).
                    hParam:write-json("file", substitute("prep_outparam_&1.json", cParamName), true).
                end.

                poResponse:setParam(hParam:name, hParam, plUseTableBI).
                delete object hParam no-error.
            end. /* isDataset (OUTPUT) */

            else if poSignature:isTempTable(cParamName) then do:
                oLoggingManager:logMessage(substitute("Outputting temp-table parameter '&1'", cParamName), "ROUTE-DBG", 5).

                /* Output is explicitly a temp-table. */
                poDynCaller:getParameter( input  cParamName,
                                          output table-handle hParam by-reference ).

                if log-manager:logging-level ge 7 then do:
                    hParam:write-xmlschema("file", substitute("prep_outparam_&1.xml", cParamName), true).
                    hParam:write-json("file", substitute("prep_outparam_&1.json", cParamName), true).
                end.

                poResponse:setParam(hParam:name, hParam).
                delete object hParam no-error.
            end. /* isTempTable (OUTPUT) */

            else if poSignature:isObject(cParamName) then do:
                /* Output is either an actual JSON object or array. */
                poDynCaller:getParameter(cParamName, output oParam).
                if valid-object(oParam) then do:
                    case oParam:GetClass():TypeName:
                        when "Progress.Json.ObjectModel.JsonArray" then do:
                            oLoggingManager:logMessage(substitute("Outputting array parameter '&1'", cParamName), "ROUTE-DBG", 5).
                            poResponse:setParam(cParamName, cast(oParam, JsonArray)).
                        end.
                        when "Progress.Json.ObjectModel.JsonObject" then do:
                            oLoggingManager:logMessage(substitute("Outputting object parameter '&1'", cParamName), "ROUTE-DBG", 5).
                            poResponse:setParam(cParamName, cast(oParam, JsonObject)).
                        end.
                    end case.
                    delete object oParam no-error.
                end. /* oParam */
            end. /* isObject (OUTPUT) */

            else do:
                /* Convert according to supported JSON datatypes. */
                poDynCaller:getParameter(cParamName, output cParamValue).
                case poSignature:getParameterType(cParamName):
                    when "decimal" then do:
                        oLoggingManager:logMessage(substitute("Outputting decimal parameter '&1'", cParamName), "ROUTE-DBG", 5).
                        poResponse:setParam(cParamName, decimal(cParamValue)).
                    end. /* decimal */
                    when "integer" then do:
                        oLoggingManager:logMessage(substitute("Outputting integer parameter '&1'", cParamName), "ROUTE-DBG", 5).
                        poResponse:setParam(cParamName, integer(cParamValue)).
                    end. /* integer */
                    when "logical" then do:
                        oLoggingManager:logMessage(substitute("Outputting logical parameter '&1'", cParamName), "ROUTE-DBG", 5).
                        poResponse:setParam(cParamName, logical(cParamValue)).
                    end. /* logical */
                    otherwise do:
                        oLoggingManager:logMessage(substitute("Outputting string parameter '&1'", cParamName), "ROUTE-DBG", 5).
                        poResponse:setParam(cParamName, cParamValue).
                    end. /* character, date, etc. */
                end case.
            end. /* Primitive (OUTPUT) */
        end. /* Outputs */
    end method. /* prepareInputParams */


    method private void invokeMethod ( input poSignature  as MethodSignature,
                                       input pcEntityName as character,
                                       input lUseTableBI  as logical ):
        define variable oRequest      as IAbstractMessage     no-undo.
        define variable oResponse     as IAbstractMessage     no-undo.
        define variable oDynCaller    as DynamicCaller        no-undo.
        define variable oServiceClass as Progress.Lang.Class  no-undo.
        define variable oServiceImpl  as Progress.Lang.Object no-undo.
        define variable oEntity       as IDynamicEntity       no-undo.
        define variable oResource     as IDynamicResource     no-undo.
        define variable hDataset      as handle               no-undo.
        define variable lWrapOutput   as logical              no-undo.

        assign
            oRequest  = oMessageManager:RequestMessage
            oResponse = oMessageManager:ResponseMessage
            .

        /* Get the service class to be run (the Dynamic* classes are services). */
        oLoggingManager:logMessage(substitute("Obtaining service for '&1'", poSignature:getClassPath()), "ROUTE-DBG", 5).
        assign oServiceClass = Progress.Lang.Class:GetClass(poSignature:getClassPath()) no-error.
        if not valid-object(oServiceClass) then
            undo, throw new ApplicationError("Unknown Service Class [&1]", poSignature:getClassPath()).
        assign oServiceImpl = Ccs.Common.Application:ServiceManager:getService(oServiceClass) no-error.
        if not valid-object(oServiceImpl) then
            undo, throw new ApplicationError("Unknown Service Implementation [&1]", poSignature:getClassPath()).

        /* Confirm that specified class is of type IDynamic* and create instance. */
        if oServiceClass:IsA(get-class(IDynamicEntity)) then do:
            oLoggingManager:logMessage(substitute("Invoking method '&1' in '&2' with entity '&3'",
                                                  poSignature:getMethodName(), poSignature:getClassPath(), pcEntityName), "ROUTE-DBG", 5).

            /* Class is of type IDynamicEntity which contains CRUD+Submit methods. */
            oEntity = cast(oServiceImpl, IDynamicEntity) no-error.

            /* Run the appropriate method, as based on the interface definition. */
            if valid-object(oEntity) then do:
                if (pcEntityName gt "") eq true then do:
                    /* Obtain dataset handle as should have been set by class constructor. */
                    oSchemaManager:getDataset(pcEntityName, dataset-handle hDataset by-reference).
                    if not valid-handle(hDataset) then
                        undo, throw new ApplicationError("Unable to obtain entity dataset schema.", -500).
                end. /* pcEntity */

                /* NOTE: Due to a bug with the serialize-name attribute, we may obtain incorrect schema
                 * within a dataset created dynamically. Therefore we must directly populate the public
                 * handle to the dataset as defined within the entity class. Applies to CUD operations.
                 */

                case poSignature:getMethodName():
                    when "readData" then do:
                        define variable iNumRecs as int64 no-undo.
                        oEntity:readData( input  string(oRequest:serializeMessage()),
                                          output iNumRecs,
                                          output dataset-handle hDataset by-reference ).
                        oLoggingManager:logMessage(substitute("Outputting parameter 'numRecs'"), "ROUTE-DBG", 5).
                        oResponse:setParam("numRecs", iNumRecs).
                        oLoggingManager:logMessage(substitute("Outputting entity '&1'", pcEntityName), "ROUTE-DBG", 5).
                        oResponse:setParam(pcEntityName, hDataset, lUseTableBI).
                    end. /* readData */

                    when "createData" then do:
                        oLoggingManager:logMessage(substitute("Obtaining entity '&1'", pcEntityName), "ROUTE-DBG", 5).
                        oRequest:getParamAsHandle(pcEntityName, "empty", hDataset).
                        oEntity:createData(input-output dataset-handle hDataset).
                        oLoggingManager:logMessage(substitute("Outputting entity '&1'", pcEntityName), "ROUTE-DBG", 5).
                        oResponse:setParam(pcEntityName, hDataset, lUseTableBI).
                    end. /* createData */

                    when "updateData" then do:
                        oLoggingManager:logMessage(substitute("Obtaining entity '&1'", pcEntityName), "ROUTE-DBG", 5).
                        oRequest:getParamAsHandle(pcEntityName, "empty", hDataset).
                        oEntity:updateData(input-output dataset-handle hDataset).
                        oLoggingManager:logMessage(substitute("Outputting entity '&1'", pcEntityName), "ROUTE-DBG", 5).
                        oResponse:setParam(pcEntityName, hDataset, lUseTableBI).
                    end. /* updateData */

                    when "deleteData" then do:
                        oLoggingManager:logMessage(substitute("Obtaining entity '&1'", pcEntityName), "ROUTE-DBG", 5).
                        oRequest:getParamAsHandle(pcEntityName, "empty", hDataset).
                        oEntity:deleteData(input-output dataset-handle hDataset).
                        oLoggingManager:logMessage(substitute("Outputting entity '&1'", pcEntityName), "ROUTE-DBG", 5).
                        oResponse:setParam(pcEntityName, hDataset, lUseTableBI).
                    end. /* deleteData */

                    when "submitData" then do:
                        oLoggingManager:logMessage(substitute("Obtaining entity '&1'", pcEntityName), "ROUTE-DBG", 5).
                        oRequest:getParamAsHandle(pcEntityName, "empty", hDataset).
                        oEntity:submitData(input-output dataset-handle hDataset).
                        oLoggingManager:logMessage(substitute("Outputting entity '&1'", pcEntityName), "ROUTE-DBG", 5).
                        oResponse:setParam(pcEntityName, hDataset, lUseTableBI).
                    end. /* submitData */

                    otherwise do {&THROW}: /* Invoke */
                        /* Prepare the dynamic caller object. */
                        oSchemaManager:initMethodSignature(poSignature).
                        assign oDynCaller = new DynamicCaller(poSignature, oServiceClass).

                        /* If invoke operation contains only a single top-level object "request"
                         * then the response object must be output within a "response" as well.
                         */
                        if oCatalogManager:UseRequestObj or (oRequest:getParamCount() eq 1 and oRequest:hasParam("request")) then do:
                            assign lWrapOutput = true.
                            oRequest:promoteObject("request").
                        end.

                        /* Get input params, invoke, and set outputs. */
                        prepareInputParams(oRequest, poSignature, oDynCaller).
                        oDynCaller:executeMethod(oEntity).
                        prepareOutputParams(oResponse, poSignature, oDynCaller, lUseTableBI).

                        /* Places current output within another object, if indicated by flag. */
                        if lWrapOutput then
                            oResponse:demoteObject("response").

                        if error-status:error then
                            undo, throw new ApplicationError(GenTools:getAblError(), error-status:get-number(1)).

                        finally:
                            delete object oDynCaller no-error.
                        end finally.
                    end. /* otherwise */
                end case.
            end. /* valid-object */
        end. /* IDynamicEntity */
        else if oServiceClass:IsA(get-class(IDynamicResource)) then do:
            oLoggingManager:logMessage(substitute("Invoking method '&1' in resource '&2'",
                                                                        poSignature:getMethodName(), poSignature:getClassPath()), "ROUTE-DBG", 5).

            /* Class is of type IDynamicResource which has no CRUD+Submit methods. */
            oResource = cast(oServiceImpl, IDynamicResource) no-error.

            /* Run the appropriate method, as based on the interface definition. */
            if valid-object(oResource) then do {&throw}:
                /* Prepare the dynamic caller object. */
                oSchemaManager:initMethodSignature(poSignature).
                oDynCaller = new DynamicCaller(poSignature, oServiceClass).

                /* If invoke operation contains only a single top-level object "request"
                 * then the response object must be output within a "response" as well.
                 */
                if oCatalogManager:UseRequestObj or (oRequest:getParamCount() eq 1 and oRequest:hasParam("request")) then do:
                    assign lWrapOutput = true.
                    oRequest:promoteObject("request").
                end.

                /* Get input params, invoke, and set outputs. */
                prepareInputParams(oRequest, poSignature, oDynCaller).
                oDynCaller:executeMethod(oResource).
                prepareOutputParams(oResponse, poSignature, oDynCaller, lUseTableBI).

                /* Places current output within another object, if indicated by flag. */
                if lWrapOutput then
                    oResponse:demoteObject("response").

                if error-status:error then
                    undo, throw new ApplicationError(GenTools:getAblError(), error-status:get-number(1)).

                finally:
                    delete object oDynCaller no-error.
                end finally.
            end. /* valid-object */
        end. /* IDynamicResource */

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Error while invoking method", err, "SPARK-ERR", 0).
            undo, throw err.
        end catch.
        finally:
            delete object oServiceClass no-error.
            delete object oServiceImpl  no-error.
            delete object oEntity   no-error.
            delete object oResource no-error.
            delete object hDataset  no-error.
        end finally.
    end method. /* invokeMethod */


    method private void invokeProcedure ( input poSignature  as MethodSignature,
                                          input phProcHandle as handle ):
        define variable oRequest    as IAbstractMessage no-undo.
        define variable oResponse   as IAbstractMessage no-undo.
        define variable oDynCaller  as DynamicCaller    no-undo.
        define variable lWrapOutput as logical          no-undo.

        assign
            oRequest  = oMessageManager:RequestMessage
            oResponse = oMessageManager:ResponseMessage
            .

        oLoggingManager:logMessage(substitute("Invoking procedure '&1'", poSignature:getMethodName()), "ROUTE-DBG", 5).

        /* Prepare the dynamic caller object. */
        oSchemaManager:initMethodSignature(poSignature).
        oDynCaller = new DynamicCaller(poSignature, phProcHandle).

        /* If invoke operation contains only a single top-level object "request"
         * then the response object must be output within a "response" as well.
         */
        if oCatalogManager:UseRequestObj or (oRequest:getParamCount() eq 1 and oRequest:hasParam("request")) then do:
            assign lWrapOutput = true.
            oRequest:promoteObject("request").
        end.

        /* Get input params, invoke, and set outputs. */
        prepareInputParams(oRequest, poSignature, oDynCaller).
        oDynCaller:executeMethod().
        prepareOutputParams(oResponse, poSignature, oDynCaller, false).

        /* Places current output within another object, if indicated by flag. */
        if lWrapOutput then
            oResponse:demoteObject("response").

        if error-status:error then
            undo, throw new ApplicationError(GenTools:getAblError(), error-status:get-number(1)).

        catch err as Progress.Lang.Error:
            oLoggingManager:logError("Error while invoking procedure", err, "SPARK-ERR", 0).
            undo, throw err.
        end catch.
        finally:
            delete object oDynCaller no-error.
        end finally.
    end method. /* invokeProcedure */


    method public void invokeServiceFunction ( input pcService  as character,
                                               input pcResource as character,
                                               input pcMethod   as character ):
        define variable oService            as Progress.Lang.Class no-undo.
        define variable oValidationResponse as IResponse           no-undo.
        define variable oRequest            as IAbstractMessage    no-undo.
        define variable oResponse           as IAbstractMessage    no-undo.

        oRequest = oMessageManager:RequestMessage.
        oResponse = oMessageManager:ResponseMessage.

        if pcResource eq "static" or pcResource eq "presenter" then
        do:
            /* If we get here then the ContextID must be valid. */
            oValidationResponse = cast(oResponse, IResponse).
            oValidationResponse:validContextID = true.

            /* Get the service class to be run. */
            oService = Progress.Lang.Class:GetClass(pcService) no-error.
            if not valid-object(oService) then
                undo, throw new ApplicationError("Unknown Service [&1]", pcService).

            preProcessInvokeServiceFunction(pcService, pcResource, pcMethod).

            /* Perform direct call on service/method as requested. */
            cast(Ccs.Common.Application:ServiceManager, IServiceManager):callServiceFunction(oService, pcMethod).

            postProcessInvokeServiceFunction(pcService, pcResource, pcMethod).
        end.
        else if pcMethod eq "getCatalog" then do:
            if pcResource eq "all" or (pcService eq "" and pcResource eq "") then do:
                oLoggingManager:logMessage(substitute("Invoking catalog service (all resources)"), "ROUTE-DBG", 5).
                oResponse:setParam("catalog", oCatalogManager:getCatalog("", "")).
            end.
            else do:
                oLoggingManager:logMessage(substitute("Invoking catalog service for '&1' via '&2'", pcResource, pcService), "ROUTE-DBG", 5).
                oResponse:setParam("catalog", oCatalogManager:getCatalog(pcService, pcResource)).
            end.

            oResponse:promoteObject("catalog").
        end.
        else
        do:
            oLoggingManager:logMessage(substitute("Requesting dynamic service '&1' in '&2' via '&3'", pcMethod, pcResource, pcService), "ROUTE-DBG", 5).

            /* Perform dynamic invocation of procedure in module. */
            define variable oSignature  as Progress.Lang.Object no-undo.
            define variable cClassPath  as character            no-undo.
            define variable cEntityName as character            no-undo.
            define variable lUseTableBI as logical              no-undo.
            define variable hProc       as handle               no-undo.

            /* Obtain the signature and any additional data about the resource to be invoked. */
            assign oSignature = oCatalogManager:getResourceMetadata( input  pcService,
                                                                     input  pcResource,
                                                                     input  pcMethod,
                                                                     output hProc,
                                                                     output cEntityName,
                                                                     output lUseTableBI ).

            /* Perform any pre-processing prior to service execution. */
            preProcessInvokeServiceFunction(pcService, pcResource, pcMethod).

            /* Invoke as either a procedure or a class method. */
            if valid-handle(hProc) then
                invokeProcedure(cast(oSignature, MethodSignature), hProc).
            else
                invokeMethod(cast(oSignature, MethodSignature), cEntityName, lUseTableBI).

            /* Perform any post-processing prior to service execution. */
            postProcessInvokeServiceFunction(pcService, pcResource, pcMethod).

            delete object oSignature no-error.
        end.
    end method. /* invokeServiceFunction */



    method protected integer checkApiVersion ( input pfApiVersion as decimal ):
        define variable iApiVersion as integer no-undo.
        assign iApiVersion = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager):ApiVersion.
        if iApiVersion ne ? and iApiVersion gt 0 and
           pfApiVersion ne ? and pfApiVersion gt 0 then
        do:
            /* Output an info message when the client requests an earlier API version. */
            if pfApiVersion lt iApiVersion then
                oLoggingManager:logMessage(substitute("Client requested an API of version &1, current is &2",
                                                      pfApiVersion,
                                                      iApiVersion),
                                                      "SPARK-INFO", 3).

            /* Stop the user from accessing a later API version than currently supported. */
            if pfApiVersion gt iApiVersion then
                undo, throw new AppError(substitute("Client requested a higher API version (&1) than what is currently supported (&2).",
                                                    pfApiVersion, iApiVersion), -409).
        end. /* API Version */

        return iApiVersion. /* Return the current API version. */
    end method. /* checkApiVersion */


    method protected void checkApiLimits ( input phCPO as handle ):
        /* Sample usage, reporting the rate limit, requests remaining, and retry delay. */
        /* Based on similar API's used by major websites, returning a standard header.  */

        /*oMessageManager:setResponseHeader("X-RateLimit-Limit", "180").             */
        /*oMessageManager:setResponseHeader("X-RateLimit-Remaining", "0").           */
        /*oMessageManager:setResponseHeader("Retry-After", "5").                     */
        /*undo, throw new AppError(substitute("API limit has been exceeded."), -429).*/
    end method. /* checkApiLimits */


    method protected void preProcessInvokeServiceFunction ( input pcService  as character,
                                                            input pcResource as character,
                                                            input pcMethod   as character ):

        /* For POS type applications - set the users password/keypin to authorize the service function call. */
        oClientContext:setActivityPassword(oMessageManager:RequestMessage:messageKeyPin).


        /* Allow or reject the request based on the API versions specified. */
        checkApiVersion(Spark.Core.Interface.ServiceInterface:ApiVersion).

        /* Allow or reject the request based on the API limits specified. */
        checkApiLimits(oClientContext:clientPrincipal).

    end method.


    method protected void postProcessInvokeServiceFunction ( input pcService  as character,
                                                             input pcResource as character,
                                                             input pcMethod   as character ):

    end method.

end class.
