 /*------------------------------------------------------------------------
    File        : MethodSignature
    Purpose     : Provide easy access to method parameters.
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Dec 12 10:14:53 EST 2014
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.

block-level on error undo, throw.
&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW

class Spark.Core.Util.MethodSignature use-widget-pool final:

   define private temp-table MethodParameter no-undo
      field paramNum      as integer
      field paramName     as character
      field paramType     as character
      field isInputParam  as logical
      field isOutputParam as logical
      field paramSchema   as CLOB
      index idxPrimary    is primary unique paramNum
      index idxParamName  paramName.


   define private variable classPath     as character no-undo.
   define private variable methodName    as character no-undo.
   define private variable numParameters as integer   no-undo.
   define private variable paramArray    as JsonArray no-undo.


   constructor public MethodSignature ( input pcMethodName      as character,
                                        input pcMethodSignature as character ):
      methodName = pcMethodName.
      parseMethodSignature(pcMethodSignature).
   end constructor.


   constructor public MethodSignature ( input pcMethodName as character,
                                        input phProcHandle as handle ):
      methodName = pcMethodName.
      parseMethodSignature(phProcHandle:get-signature(methodName)).
   end constructor.


   constructor public MethodSignature ( input pcMethodName   as character,
                                        input poMethodParams as JsonArray ):
      methodName = pcMethodName.
      paramArray = poMethodParams.
      parseMethodSignature(poMethodParams).
   end constructor.


   constructor public MethodSignature ( input pcClassPath    as character,
                                        input pcMethodName   as character,
                                        input poMethodParams as JsonArray ):
      classPath  = pcClassPath.
      methodName = pcMethodName.
      paramArray = poMethodParams.
      parseMethodSignature(poMethodParams).
   end constructor.


   destructor public MethodSignature ( ):
      empty temp-table MethodParameter.
   end destructor.


   method private void parseMethodSignature ( input methodSignature as character ):
      define variable paramSignature as character no-undo.
      define variable paramMode      as character no-undo.
      define variable paramName      as character no-undo.
      define variable paramType      as character no-undo.
      define variable tmpString      as character no-undo.
      define variable iCount         as integer   no-undo.

      assign numParameters = 0.

      do iCount = 3 to num-entries(methodSignature) {&THROW}:
         paramSignature = entry(iCount,methodSignature).

         if num-entries(paramSignature, " ") eq 3 then do {&THROW}:
            assign
                numParameters  = numParameters + 1
                paramMode      = replace(entry(1, paramSignature, " "), "-", "")
                paramName      = entry(2, paramSignature, " ")
                paramType      = entry(3, paramSignature, " ")
                .

            case paramName:
               when "table" or
               when "table-handle" then
                  assign paramName = paramType
                         paramType = "table-handle".
               when "dataset" or
               when "dataset-handle" then
                  assign paramName = paramType
                         paramType = "dataset-handle".
            end case.

            create MethodParameter.
            assign MethodParameter.paramNum      = iCount - 2
                   MethodParameter.paramName     = paramName
                   MethodParameter.paramType     = paramType
                   MethodParameter.isInputParam  = paramMode begins "input"
                   MethodParameter.isOutputparam = left-trim(paramMode, "input") eq "output"
                   .
         end.
      end.
   end method.


   method private void parseMethodSignature ( input methodSignature as JsonArray ):
      define variable paramSignature as JsonObject no-undo.
      define variable paramMode      as character  no-undo.
      define variable paramName      as character  no-undo.
      define variable paramType      as character  no-undo.
      define variable tmpString      as character  no-undo.
      define variable iCount         as integer    no-undo.

      assign numParameters = methodSignature:Length.

      do iCount = 1 to methodSignature:Length {&THROW}:
         paramSignature = methodSignature:GetJsonObject(iCount).

        assign
            paramMode = paramSignature:GetCharacter("mode")
            paramName = paramSignature:GetCharacter("name")
            paramType = paramSignature:GetCharacter("type")
            .

        case paramType:
           when "table" or
           when "tablehandle" then
              assign paramType = "table-handle".
           when "dataset" or
           when "datasethandle" then
              assign paramType = "dataset-handle".
           when "datetimetz" then
              assign paramType = "datetime-tz".
        end case.

        create MethodParameter.
        assign MethodParameter.paramNum      = iCount
               MethodParameter.paramName     = paramName
               MethodParameter.paramType     = paramType
               MethodParameter.isInputParam  = paramMode begins "input"
               MethodParameter.isOutputparam = left-trim(paramMode,"input") eq "output"
               .
      end.

      finally:
          delete object paramSignature no-error.
      end finally.
   end method.


   method public character getClassPath ( ):
      return classPath.
   end method.


   method public character getMethodName ( ):
      return methodName.
   end method.


   method public integer getParameterCount ( ):
      return numParameters.
   end method.


   method public logical hasParameters ( ):
      return numParameters gt 0.
   end method.


   method public logical hasParameter ( input paramName as character ):
      return can-find(first MethodParameter where MethodParameter.paramName eq paramName).
   end method.


   method public character getParameters ( ):
      define variable paramList as character no-undo.

      for each MethodParameter {&THROW}:
         paramList = substitute("&1,&2", paramList, MethodParameter.paramName).
      end.

      return trim(paramList,",").
   end method.


   method public character getInputParameters ( ):
      define variable paramList as character no-undo.

      for each MethodParameter where isInputParam {&THROW}:
         paramList = substitute("&1,&2", paramList, MethodParameter.paramName).
      end.

      return trim(paramList,",").
   end method.


   method public character getOutputParameters ( ):
      define variable paramList as character no-undo.

      for each MethodParameter where isOutputParam {&THROW}:
         paramList = substitute("&1,&2", paramList, MethodParameter.paramName).
      end.

      return trim(paramList,",").
   end method.


   method public integer getParameterNum ( input paramName as character ):
      for first MethodParameter where MethodParameter.paramName eq paramName {&THROW}:
         return MethodParameter.paramNum.
      end.
   end method.


   method public character getParameterName ( input paramNum as integer ):
      for first MethodParameter where MethodParameter.paramNum eq paramNum {&THROW}:
         return MethodParameter.paramName.
      end.
   end method.


   method public character getParameterMode ( input paramNum as integer ):
      for first MethodParameter where MethodParameter.paramNum eq paramNum {&THROW}:
         case true:
            when MethodParameter.isInputParam and MethodParameter.isOutputParam then
               return "input-output".
            when MethodParameter.isInputParam then
               return "input".
            when MethodParameter.isOutputParam then
               return "output".
         end case.
      end.

      return "".
   end method.


   method public character getParameterMode ( input paramName as character ):
      for first MethodParameter where MethodParameter.paramName eq paramName {&THROW}:
         case true:
            when MethodParameter.isInputParam and MethodParameter.isOutputParam then
               return "input-output".
            when MethodParameter.isInputParam then
               return "input".
            when MethodParameter.isOutputParam then
               return "output".
         end case.
      end.

      return "".
   end method.


   method public JsonObject getParameterObject ( input piIndex as integer ):
       return paramArray:GetJsonObject(piIndex).
   end method.


   method public character getParameterType ( input paramNum as integer ):
      for first MethodParameter where MethodParameter.paramNum eq paramNum {&THROW}:
         return MethodParameter.paramType.
      end.
   end method.


   method public character getParameterType ( input paramName as character ):
      for first MethodParameter where MethodParameter.paramName eq paramName {&THROW}:
         return MethodParameter.paramType.
      end.
   end method.


   method public longchar getParameterSchema ( input paramNum as integer ):
      define variable paramSchema as longchar no-undo.

      for first MethodParameter where MethodParameter.paramNum eq paramNum {&THROW}:
         paramSchema = MethodParameter.paramSchema.
      end.

      return paramSchema.
   end method.


   method public longchar getParameterSchema ( input paramName as character ):
      define variable paramSchema as longchar no-undo.

      for first MethodParameter where MethodParameter.paramName eq paramName {&THROW}:
         paramSchema = MethodParameter.paramSchema.
      end.

      return paramSchema.
   end method.


   method public void setParameterSchema ( input paramNum    as integer,
                                           input paramSchema as longchar ):
      for first MethodParameter where MethodParameter.paramNum eq paramNum {&THROW}:
         MethodParameter.paramSchema = paramSchema.
      end.
   end method.


   method public void setParameterSchema ( input paramName   as character,
                                           input paramSchema as longchar ):
      for first MethodParameter where MethodParameter.paramName eq paramName {&THROW}:
         MethodParameter.paramSchema = paramSchema.
      end.
   end method.


   method public character getDatasets ( ):
      define variable datasetList as character no-undo.

      for each MethodParameter where MethodParameter.paramType begins "dataset" {&THROW}:
         datasetList = substitute("&1,&2", datasetList, MethodParameter.paramName).
      end.

      return trim(datasetList,",").
   end method.


   method public character getTempTables ( ):
      define variable tableList as character no-undo.

      for each MethodParameter where MethodParameter.paramType begins "table" {&THROW}:
         tableList = substitute("&1,&2", tableList, MethodParameter.paramName).
      end.

      return trim(tableList, ",").
   end method.


   method public logical isInputParameter ( input paramNum as integer ):
      return can-find(first MethodParameter
                      where MethodParameter.paramNum eq paramNum
                        and MethodParameter.isInputParam eq true).
   end method.


   method public logical isInputParameter ( input paramName as character ):
      return can-find(first MethodParameter
                      where MethodParameter.paramName eq paramName
                        and MethodParameter.isInputParam eq true).
   end method.


   method public logical isOutputParameter ( input paramNum as integer):
      return can-find(first MethodParameter
                      where MethodParameter.paramNum eq paramNum
                        and MethodParameter.isOutputParam eq true).
   end method.


   method public logical isOutputParameter ( input paramName as character ):
      return can-find(first MethodParameter
                      where MethodParameter.paramName eq paramName
                        and MethodParameter.isOutputParam eq true).
   end method.


   method public logical isTempTable ( input paramNum as integer ):
      return can-find(first MethodParameter
                      where MethodParameter.paramNum eq paramNum
                        and MethodParameter.paramType begins "table").
   end method.


   method public logical isTempTable ( input paramName as character ):
      return can-find(first MethodParameter
                      where MethodParameter.paramName eq paramName
                        and MethodParameter.paramType begins "table").
   end method.


   method public logical isDataset ( input paramNum as integer ):
      return can-find(first MethodParameter
                      where MethodParameter.paramNum eq paramNum
                        and MethodParameter.paramType begins "dataset").
   end method.


   method public logical isDataset ( input paramName as character ):
      return can-find(first MethodParameter
                      where MethodParameter.paramName eq paramName
                        and MethodParameter.paramType begins "dataset").
   end method.


   method public logical isObject ( input paramNum as integer ):
      return can-find(first MethodParameter
                      where MethodParameter.paramNum eq paramNum
                        and (MethodParameter.paramType eq "Progress.Lang.Object" or
                             MethodParameter.paramType eq "Progress.Json.ObjectModel.JsonArray" or
                             MethodParameter.paramType eq "Progress.Json.ObjectModel.JsonObject")).
   end method.


   method public logical isObject ( input paramName as character ):
      return can-find(first MethodParameter
                      where MethodParameter.paramName eq paramName
                        and (MethodParameter.paramType eq "Progress.Lang.Object" or
                             MethodParameter.paramType eq "Progress.Json.ObjectModel.JsonArray" or
                             MethodParameter.paramType eq "Progress.Json.ObjectModel.JsonObject")).
   end method.


   method public logical isJsonArray ( input paramNum as integer ):
      return can-find(first MethodParameter
                      where MethodParameter.paramNum eq paramNum
                        and MethodParameter.paramType eq "Progress.Json.ObjectModel.JsonArray").
   end method.


   method public logical isJsonArray ( input paramName as character ):
      return can-find(first MethodParameter
                      where MethodParameter.paramName eq paramName
                        and MethodParameter.paramType eq "Progress.Json.ObjectModel.JsonArray").
   end method.


   method public logical isJsonObject ( input paramNum as integer ):
      return can-find(first MethodParameter
                      where MethodParameter.paramNum eq paramNum
                        and MethodParameter.paramType eq "Progress.Json.ObjectModel.JsonObject").
   end method.


   method public logical isJsonObject ( input paramName as character ):
      return can-find(first MethodParameter
                      where MethodParameter.paramName eq paramName
                        and MethodParameter.paramType eq "Progress.Json.ObjectModel.JsonObject").
   end method.

end class.
