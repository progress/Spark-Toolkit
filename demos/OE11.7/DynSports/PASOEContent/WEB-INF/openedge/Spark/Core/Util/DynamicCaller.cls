/*------------------------------------------------------------------------
   File        : DynamicCaller
   Purpose     : Provide dynamic invocation for procedures.
   Syntax      :
   Description :
   Author(s)   : Dustin Grau (dugrau@progress.com)
   Created     : Fri Dec 12 10:14:53 EST 2014
   Notes       :
 ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Manager.ISchemaManager from propath.
using Spark.Core.Util.FormatTools from propath.
using Spark.Core.Util.MethodSignature from propath.
using Spark.Core.Util.GenTools from propath.

block-level on error undo, throw.
&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW

class Spark.Core.Util.DynamicCaller use-widget-pool final:

    define private variable methodSignature as MethodSignature     no-undo.
    define private variable implementation  as Progress.Lang.Class no-undo.
    define private variable paramList       as ParameterList       no-undo.
    define private variable parameterCount  as integer             no-undo.
    define private variable procedureHandle as handle              no-undo.
    define private variable callHandle      as handle              no-undo.
    define private variable valueTable      as handle              no-undo.


    define private property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.


    define protected property oSchemaManager as ISchemaManager no-undo
        get:
            if not valid-object(oSchemaManager) then
                assign oSchemaManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ISchemaManager)), ISchemaManager).
            return oSchemaManager.
        end get.
        set.


    define private property valueBuffer as handle no-undo
        get:
            return valueTable:default-buffer-handle.
        end get.


    define private temp-table ParamObject no-undo
        field paramName   as character
        field paramHandle as handle
        index idxPrimary is primary unique paramName.


    constructor public DynamicCaller ( input poMethodSignature as MethodSignature,
                                       input poImplementation  as Progress.Lang.Class ):
        define variable iCount    as integer   no-undo.
        define variable paramName as character no-undo.
        define variable paramType as character no-undo.

        create temp-table valueTable.

        if valid-object(poMethodSignature) then do {&THROW}:
            assign methodSignature = poMethodSignature.
            assign paramList = new Progress.Lang.ParameterList(poMethodSignature:getParameterCount()).
            assign parameterCount = paramList:NumParameters.
        end.

        if valid-object(poImplementation) then
            implementation = poImplementation.

        if poMethodSignature:hasParameters() then do {&THROW}:
            do iCount = 1 to parameterCount {&THROW}:
                assign
                    paramName = poMethodSignature:getParameterName(iCount)
                    paramType = poMethodSignature:getParameterType(iCount).

                if poMethodSignature:isTempTable(iCount) or
                    poMethodSignature:isDataset(iCount) then
                    paramType = "handle".

                if poMethodSignature:isObject(iCount) then
                    paramType = "Progress.Lang.Object".

                if paramType eq "longchar" then
                    paramType = "clob".

                valueTable:add-new-field(paramName, paramType) no-error.
                if error-status:error then
                    message "Error while adding parameter field:" GenTools:getLastAblError().
            end.

            valueTable:temp-table-prepare("valueTable") no-error.
            if valueTable:prepared then
                valueBuffer:buffer-create().
        end.
    end constructor.


    constructor public DynamicCaller ( input poMethodSignature as MethodSignature,
                                       input phProcedureHandle as handle ):
        define variable iCount    as integer   no-undo.
        define variable paramName as character no-undo.
        define variable paramType as character no-undo.

        assign
            methodSignature = poMethodSignature
            procedureHandle = phProcedureHandle.

        create call callHandle.
        create temp-table valueTable.

        assign
            callHandle:call-name = poMethodSignature:getMethodName()
            callHandle:call-type = procedure-call-type.

        if valid-handle(procedureHandle) then
            callHandle:in-handle = procedureHandle no-error.

        if poMethodSignature:hasParameters() then do {&THROW}:
            callHandle:num-parameters = poMethodSignature:getParameterCount().
            parameterCount = callHandle:num-parameters.

            do iCount = 1 to parameterCount {&THROW}:
                assign
                    paramName = poMethodSignature:getParameterName(iCount)
                    paramType = poMethodSignature:getParameterType(iCount).

                if poMethodSignature:isTempTable(iCount) or
                    poMethodSignature:isDataset(iCount) then
                    paramType = "handle".

                if paramType eq "longchar" then
                    paramType = "clob".

                valueTable:add-new-field(paramName, paramType) no-error.
                if error-status:error then
                    message "Error while adding parameter field:" GenTools:getLastAblError().
            end.

            valueTable:temp-table-prepare("valueTable") no-error.
            if valueTable:prepared then
                valueBuffer:buffer-create().
        end.
    end constructor.


    destructor public DynamicCaller ( ):
        define variable iCount     as integer no-undo.
        define variable valueField as handle  no-undo.

        if valueTable:prepared then do {&THROW}:
            do iCount = 1 to valueBuffer:num-fields {&THROW}:
                valueField = valueBuffer:buffer-field(iCount).
                if valueField:data-type eq "handle" then
                    delete object valueField:buffer-value no-error.
            end. /* iCount */
        end. /* prepared */

        for each ParamObject {&THROW}:
            delete object ParamObject.paramHandle no-error.
            delete ParamObject.
        end. /* for each */

        delete object methodSignature no-error.
        delete object implementation  no-error.
        delete object valueBuffer     no-error.
        delete object callHandle      no-error.
        delete object valueTable      no-error.
        delete object paramList       no-error.
        /* Note: Do not delete procedureHandle! */
    end destructor.


    method public logical getParameterHandle ( input  paramName   as character,
                                               output paramHandle as handle ):
        if not valid-object(methodSignature) or not methodSignature:hasParameters() then
            return false.

        paramHandle = valueBuffer:buffer-field(paramName) no-error.

        return valid-handle(paramHandle).
    end method.


    method public logical isInitialized ( ):
        if valid-object(methodSignature) then
            return not methodSignature:hasParameters() or valueTable:prepared.
        else
            return false.
    end method.


    method public logical parameterExists ( input paramName as character,
                                            input paramType as character ):
        define variable valueField  as handle  no-undo.
        return getParameterHandle(paramName, output valueField) and valueField:data-type eq paramType.
    end method.


    method public void executeMethod ( ):
        executeMethod(?).
    end method.


    method public void executeMethod ( input poInstance as Progress.Lang.Object ):
        define variable iCount      as integer   no-undo.
        define variable paramHandle as handle    no-undo.
        define variable paramName   as character no-undo.
        define variable paramLong   as longchar  no-undo extent.

        CallBlock:
        do on error undo, throw
            on stop undo, retry:
            if retry then
                undo, throw new AppError("A STOP condition occurred", 0).
            else if not isInitialized() then
                undo, throw new AppError("Not initialized", 0).

            if parameterCount gt 0 then
                extent(paramLong) = parameterCount.

            /**
             * This is done as it is, since you can't pass tables -by-reference
             */
            oSchemaManager:initSchema().

            if parameterCount gt 0 then
            do iCount = 1 to parameterCount {&THROW}:
                assign paramHandle = ?.

                paramName = methodSignature:getParameterName(iCount).
                oLoggingManager:logMessage(substitute("Preparing &1 parameter #&2: &3 &4 as &5",
                                                      trim(string(valid-handle(procedureHandle), "procedure/method")),
                                                      iCount,
                                                      methodSignature:getParameterMode(iCount),
                                                      paramName,
                                                      methodSignature:getParameterType(iCount)), "DYN-CALL", 5).

                if methodSignature:isDataset(iCount) then do {&THROW}:
                    /* Create the dataset within the ParamObject table if it does not yet exist. */
                    oLoggingManager:logMessage(substitute("Obtaining dataset parameter '&1'", paramName), "DYN-CALL", 5).
                    getParameter(paramName, output dataset-handle paramHandle by-reference).

                    for first ParamObject
                        where ParamObject.paramName eq paramName {&THROW}:
                        /* Point the parameter to the record handle so that output can be extracted later. */
                        if valid-handle(procedureHandle) then
                            callHandle:set-parameter( iCount,
                                                      methodSignature:getParameterType(iCount),
                                                      methodSignature:getParameterMode(iCount),
                                                      ParamObject.paramHandle ).
                        else
                            paramList:SetParameter( iCount,
                                                    methodSignature:getParameterType(iCount),
                                                    methodSignature:getParameterMode(iCount),
                                                    ParamObject.paramHandle ).
                    end. /* for first ParamObject */

                    catch err as Progress.Lang.Error:
                        undo, throw new AppError("Dataset: " + err:GetMessage(1), 0).
                    end catch.
                end. /* dataset */

                else if methodSignature:isTempTable(iCount) then do {&THROW}:
                    /* Create the temp-table within the ParamObject table if it does not yet exist. */
                    oLoggingManager:logMessage(substitute("Obtaining temp-table parameter '&1'", paramName), "DYN-CALL", 5).
                    getParameter(paramName, output table-handle paramHandle by-reference).

                    for first ParamObject
                        where ParamObject.paramName eq paramName {&THROW}:
                        /* Point the parameter to the record handle so that output can be extracted later. */
                        if valid-handle(procedureHandle) then
                            callHandle:set-parameter( iCount,
                                                      methodSignature:getParameterType(iCount),
                                                      methodSignature:getParameterMode(iCount),
                                                      ParamObject.paramHandle ).
                        else
                            paramList:SetParameter( iCount,
                                                    methodSignature:getParameterType(iCount),
                                                    methodSignature:getParameterMode(iCount),
                                                    ParamObject.paramHandle ).
                    end. /* for first ParamObject */

                    catch err as Progress.Lang.Error:
                        undo, throw new AppError("Temp-Table: " + err:GetMessage(1), 0).
                    end catch.
                end. /* temp-table */

                else do {&THROW}:
                    if valueBuffer:buffer-field(iCount):data-type eq "clob" then do {&THROW}:
                        /* Can't pass a clob value/field, must convert to a longchar first. */
                        assign paramLong[iCount] = valueBuffer:buffer-field(iCount):buffer-value.
                        /* Point the parameter to the variable so that output can be extracted later. */
                        if valid-handle(procedureHandle) then
                            callHandle:set-parameter( iCount,
                                                      methodSignature:getParameterType(iCount),
                                                      methodSignature:getParameterMode(iCount),
                                                      paramLong[iCount] ).
                        else
                            paramList:SetParameter( iCount,
                                                    methodSignature:getParameterType(iCount),
                                                    methodSignature:getParameterMode(iCount),
                                                    paramLong[iCount] ).

                        catch err as Progress.Lang.Error:
                            undo, throw new AppError("CLOB: " + err:GetMessage(1), 0).
                        end catch.
                    end. /* clob */
                    else do {&THROW}:
                        if valid-handle(procedureHandle) then
                            callHandle:set-parameter( iCount,
                                                      methodSignature:getParameterType(iCount),
                                                      methodSignature:getParameterMode(iCount),
                                                      valueBuffer:buffer-field(iCount):buffer-value ).
                        else
                            paramList:SetParameter( iCount,
                                                    methodSignature:getParameterType(iCount),
                                                    methodSignature:getParameterMode(iCount),
                                                    valueBuffer:buffer-field(iCount):buffer-value ).

                        catch err as Progress.Lang.Error:
                            undo, throw new AppError("Primitive: " + err:GetMessage(1), 0).
                        end catch.
                    end. /* object, character, date*, decimal, integer, logical, etc. */
                end. /* else */

                /* Note: Do not delete paramHandle! */
            end. /* iCount */

            if valid-handle(callHandle) then
                callHandle:invoke() no-error.
            else if valid-object(poInstance) then
                implementation:Invoke(poInstance, methodSignature:getMethodName(), paramList) no-error.
            if error-status:error then
                undo, throw new AppError(error-status:get-message(1), error-status:get-number(1)).

            /* Copy back any special output values into the valueBuffer. */
            if parameterCount gt 0 then
            do iCount = 1 to parameterCount {&THROW}:
                if valueBuffer:buffer-field(iCount):data-type eq "clob" then
                    valueBuffer:buffer-field(iCount):buffer-value = paramLong[iCount].
            end.
        end. /* CallBlock */
    end method.


    method public logical getParameter ( input  paramName as character,
                                         output dataset-handle paramValue ):
        define variable paramSchema as longchar no-undo.
        define variable retValue    as logical  no-undo.

        if not parameterExists(paramName, "handle") or
           not methodSignature:isDataset(paramName) then
            return false.

        find first ParamObject
             where ParamObject.paramName eq paramName no-error.

        if not available(ParamObject) then do {&THROW}:
            create ParamObject.
            assign ParamObject.paramName = paramName.
        end.

        if not valid-handle(ParamObject.paramHandle) then
        do {&THROW}:
            create dataset ParamObject.paramHandle.
            paramSchema = methodSignature:getParameterSchema(paramName).
            retValue = oSchemaManager:getDataset(paramSchema, output dataset-handle ParamObject.paramHandle by-reference) no-error.
            if not retValue or error-status:error then do:
                message substitute("Error while getting parameter: &1", error-status:get-message(1)).
                delete object ParamObject.paramHandle no-error.
            end.
        end.

        paramValue = ParamObject.paramHandle.

        return valid-handle(paramValue).

        finally:
            delete object paramValue no-error.
        end finally.
    end method.


    method public logical getParameter ( input  paramName as character,
                                         output table-handle paramValue ):
        define variable paramSchema as longchar no-undo.
        define variable retValue    as logical  no-undo.

        if not parameterExists(paramName, "handle") or
           not methodSignature:isTempTable(paramName) then
            return false.

        find first ParamObject
             where ParamObject.paramName eq paramName no-error.

        if not available(ParamObject) then do {&THROW}:
            create ParamObject.
            assign ParamObject.paramName = paramName.
        end.

        if not valid-handle(ParamObject.paramHandle) then do {&THROW}:
            create temp-table ParamObject.paramHandle.
            paramSchema = methodSignature:getParameterSchema(paramName).
            retValue = ParamObject.paramHandle:read-xmlschema("longchar", paramSchema, ?) no-error.
            Spark.Core.Manager.SchemaManager:fixSerializedNames(input table-handle ParamObject.paramHandle by-reference).
            if not retValue or error-status:error then do:
                message substitute("Error while getting parameter: &1", error-status:get-message(1)).
                delete object ParamObject.paramHandle no-error.
            end.
        end.

        paramValue = ParamObject.paramHandle.

        return valid-handle(paramValue).

        finally:
            delete object paramValue no-error.
        end finally.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as longchar ):
        define variable paramHandle as handle no-undo.

        if not getParameterHandle(paramName, output paramHandle) then
            return false.

        case paramHandle:data-type:
            when "date" or
            when "datetime" or
            when "datetime-tz" then
                paramValue = iso-date(paramHandle:buffer-value) no-error.
            when "int64" then
                paramValue = trim(string(int64(paramHandle:buffer-value))) no-error.
            when "integer" then
                paramValue = trim(string(integer(paramHandle:buffer-value))) no-error.
            when "raw" then
                paramValue = base64-encode(paramHandle::buffer-value) no-error.
            when "logical" then do {&THROW}:
                if paramHandle:buffer-value eq ? then
                    paramValue = ?. /* Null */
                else
                    paramValue = trim(string(paramHandle:buffer-value eq true, "true/false")) no-error.
            end.
            when "decimal" then do {&THROW}:
                paramValue = string(paramHandle:buffer-value).
                if paramHandle:buffer-value gt 0 and paramHandle:buffer-value lt 1 then
                    paramValue = "0" + paramValue.
                if paramHandle:buffer-value lt 0 and paramHandle:buffer-value gt -1 then
                    paramValue = "-0" + substring(paramValue, 2).
            end.
            when "clob" then do {&THROW}:
                paramValue = paramHandle:buffer-value no-error.
                paramValue = replace(paramValue, "\/", "/").
            end.
            when "progress.lang.object" then do {&THROW}:
                define variable oValue as Progress.Lang.Object no-undo.
                assign oValue = paramHandle:buffer-value NO-ERROR.
                if valid-object(oValue) then
                    case oValue:GetClass():TypeName:
                        when "Progress.Json.ObjectModel.JsonArray" then
                            paramValue = cast(paramHandle:buffer-value, JsonArray):getJsonText() no-error.
                        when "Progress.Json.ObjectModel.JsonObject" then
                            paramValue = cast(paramHandle:buffer-value, JsonObject):getJsonText() no-error.
                    end case.
            end.
            otherwise do {&THROW}:
                paramValue = paramHandle:buffer-value no-error.
                paramValue = replace(paramValue, "\/", "/").
            end.
        end case.

        return not error-status:error.

        catch err as Error:
            undo, throw new AppError(substitute("Parameter Error: &1", err:GetMessage(1)), err:GetMessageNum(1)).
        end catch.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as Progress.Lang.Object ):
        if not parameterExists(paramName, "progress.lang.object") then
            return false.

        paramValue = valueBuffer:buffer-field(paramName):buffer-value no-error.

        return not error-status:error.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as date ):
        if not parameterExists(paramName, "date") then
            return false.

        paramValue = valueBuffer:buffer-field(paramName):buffer-value no-error.

        return not error-status:error.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as datetime ):
        if not parameterExists(paramName, "datetime") then
            return false.

        paramValue = valueBuffer:buffer-field(paramName):buffer-value no-error.

        return not error-status:error.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as datetime-tz ):
        if not parameterExists(paramName, "datetime-tz") then
            return false.

        paramValue = valueBuffer:buffer-field(paramName):buffer-value no-error.

        return not error-status:error.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as decimal ):
        if not parameterExists(paramName, "decimal") then
            return false.

        paramValue = valueBuffer:buffer-field(paramName):buffer-value no-error.

        return not error-status:error.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as int64 ):
        if not parameterExists(paramName, "int64") then
            return false.

        paramValue = valueBuffer:buffer-field(paramName):buffer-value no-error.

        return not error-status:error.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as integer ):
        if not parameterExists(paramName, "integer") then
            return false.

        paramValue = valueBuffer:buffer-field(paramName):buffer-value no-error.

        return not error-status:error.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as logical ):
        if not parameterExists(paramName, "logical") then
            return false.

        paramValue = valueBuffer:buffer-field(paramName):buffer-value no-error.

        return not error-status:error.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as raw ):
        if not parameterExists(paramName, "raw") then
            return false.

        paramValue = valueBuffer:buffer-field(paramName):buffer-value no-error.

        return not error-status:error.
    end method.


    method public logical getParameter ( input  paramName  as character,
                                         output paramValue as rowid ):
        if not parameterExists(paramName, "rowid") then
            return false.

        paramValue = valueBuffer:buffer-field(paramName):buffer-value no-error.

        return not error-status:error.
    end method.


    method public JsonArray getJsonArrayParam ( input paramName as character ):
        if not parameterExists(paramName, "progress.lang.object") then
            return new JsonArray().

        return cast(valueBuffer:buffer-field(paramName):buffer-value, JsonArray).
    end method.


    method public JsonObject getJsonObjectParam ( input paramName as character ):
        if not parameterExists(paramName, "progress.lang.object") then
            return new JsonObject().

        return cast(valueBuffer:buffer-field(paramName):buffer-value, JsonObject).
    end method.


    method public logical setParameter ( input paramName as character,
                                         input dataset-handle paramValue ):
        if not parameterExists(paramName, "handle") or
           not methodSignature:isDataset(paramName) then
            return false.

        find first ParamObject
             where ParamObject.paramName eq paramName no-error.

        if not available(ParamObject) then do {&THROW}:
            create ParamObject.
            assign ParamObject.paramName = paramName.
        end.

        ParamObject.paramHandle = paramValue.

        if valid-handle(ParamObject.paramHandle) and log-manager:logging-level ge 7 then do:
            ParamObject.paramHandle:write-xmlschema("file", substitute("setparam_&1.xml", paramName), true).
            ParamObject.paramHandle:write-json("file", substitute("setparam_&1.json", paramName), true).
        end.

        return valid-handle(ParamObject.paramHandle).
    end method.


    method public logical setParameter ( input paramName as character,
                                         input table-handle paramValue ):
        if not parameterExists(paramName, "handle") or
           not methodSignature:isTempTable(paramName) then
            return false.

        find first ParamObject
             where ParamObject.paramName eq paramName no-error.

        if not available(ParamObject) then
        do {&THROW}:
            create ParamObject.
            assign
                ParamObject.paramName = paramName.
        end.

        ParamObject.paramHandle = paramValue.

        if not error-status:error and log-manager:logging-level ge 7 then do:
            ParamObject.paramHandle:write-xmlschema("file", substitute("setparam_&1.xml", paramName), true).
            ParamObject.paramHandle:write-json("file", substitute("setparam_&1.json", paramName), true).
        end.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as longchar ):
        define variable paramHandle as handle no-undo.

        if not getParameterHandle(paramName, output paramHandle) then
            return false.

        case paramHandle:data-type:
            when "character" then
                paramHandle:buffer-value = paramValue no-error.
            when "clob" then
                paramHandle:buffer-value = paramValue no-error.
            when "date" then
                paramHandle:buffer-value = FormatTools:iso2Date(string(paramValue)) no-error.
            when "datetime" then
                paramHandle:buffer-value = FormatTools:iso2DateTime(string(paramValue)) no-error.
            when "datetime-tz" then
                paramHandle:buffer-value = FormatTools:iso2DateTZ(string(paramValue)) no-error.
            when "decimal" then
                paramHandle:buffer-value = decimal(string(paramValue)) no-error.
            when "int64" then
                paramHandle:buffer-value = int64(string(paramValue)) no-error.
            when "integer" then
                paramHandle:buffer-value = integer(string(paramValue)) no-error.
            when "logical" then
                paramHandle:buffer-value = logical(string(paramValue)) no-error.
            when "raw" then
                paramHandle:buffer-value = base64-decode(paramValue) no-error.
            when "rowid" then
                paramHandle:buffer-value = to-rowid(string(paramValue)) no-error.
            otherwise
                return false.
        end case.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as date ):
        if not parameterExists(paramName, "date") then
            return false.

        valueBuffer:buffer-field(paramName):buffer-value = paramValue no-error.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as datetime ):
        if not parameterExists(paramName, "datetime") then
            return false.

        valueBuffer:buffer-field(paramName):buffer-value = paramValue no-error.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as datetime-tz ):
        if not parameterExists(paramName, "datetime-tz") then
            return false.

        valueBuffer:buffer-field(paramName):buffer-value = paramValue no-error.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as decimal ):
        if not parameterExists(paramName, "decimal") then
            return false.

        valueBuffer:buffer-field(paramName):buffer-value = paramValue no-error.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as int64 ):
        if not parameterExists(paramName, "int64") then
            return false.

        valueBuffer:buffer-field(paramName):buffer-value = paramValue no-error.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as integer ):
        if not parameterExists(paramName, "integer") then
            return false.

        valueBuffer:buffer-field(paramName):buffer-value = paramValue no-error.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as logical ):
        if not parameterExists(paramName, "logical") then
            return false.

        valueBuffer:buffer-field(paramName):buffer-value = paramValue no-error.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as raw ):
        if not parameterExists(paramName, "raw") then
            return false.

        valueBuffer:buffer-field(paramName):buffer-value = paramValue no-error.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as rowid ):
        if not parameterExists(paramName, "rowid") then
            return false.

        valueBuffer:buffer-field(paramName):buffer-value = paramValue no-error.

        return not error-status:error.
    end method.


    method public logical setParameter ( input paramName  as character,
                                         input paramValue as Progress.Lang.Object ):
        if not parameterExists(paramName, "progress.lang.object") then
            return false.

        valueBuffer:buffer-field(paramName):buffer-value = paramValue no-error.

        return not error-status:error.
    end method.

end class.