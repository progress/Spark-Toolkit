/*------------------------------------------------------------------------
    File        : Reflection
    Purpose     : Product a common JSON format for class reflection in ABL
    Syntax      : Reflection.getClassSignature(<class.package>[, true|false])
    Description : Generates a JSON object with a single property containing
                  class attributes, properties, variables, and methods. Can
                  optionally omit the outer object and class name property.
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Jun 16 15:54:44 EDT 2015
    Notes       : Reflection will only be performed on OE 11.6 and later.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.

block-level on error undo, throw.

&GLOBAL-DEFINE SKIP_NAMES "addIdField,addError,addWarning,getData,getDataset,getResultCount,initialize,dispose,postFetch,postRowFill,preCommit,postCommit,validateData"

class Spark.Core.Util.Reflection final:

    method private static JsonObject getConstructors ( input poClassRef as Progress.Lang.Class ):
        define variable oConstructs as JsonObject no-undo.
        assign oConstructs = new JsonObject().

        define variable oConstsExt  as Progress.Reflect.Constructor no-undo extent.
        define variable oConstsInt  as Progress.Reflect.Constructor no-undo.
        define variable oElementSig as JsonObject                   no-undo.
        define variable oParamArr   as JsonArray                    no-undo.
        define variable oParamSig   as JsonObject                   no-undo.
        define variable oParamExt   as Progress.Reflect.Parameter   no-undo extent.
        define variable oParamInt   as Progress.Reflect.Parameter   no-undo.
        define variable cDataType   as character                    no-undo.
        define variable iCount      as integer                      no-undo.
        define variable iParam      as integer                      no-undo.

        assign oConstsExt  = poClassRef:GetConstructors().
        do iCount = 1 to extent(oConstsExt):
            assign
                oConstsInt  = oConstsExt[iCount]
                oElementSig = new Progress.Json.ObjectModel.JsonObject()
                oParamArr   = new Progress.Json.ObjectModel.JsonArray()
                .

            extent(oParamExt) = ?. /* Reset from previous params. */
            assign oParamExt = oConstsInt:GetParameters().
            do iParam = 1 to extent(oParamExt):
                assign oParamInt = oParamExt[iParam].

                if oParamInt:DataType:toString() eq "object" then
                    assign cDataType = oParamInt:DataTypeName.
                else
                    assign cDataType = lc(oParamInt:DataType:toString()).

                assign oParamSig = new Progress.Json.ObjectModel.JsonObject().
                oParamSig:Add("mode", oParamInt:Mode:toString()).
                oParamSig:Add("type", cDataType).
                oParamSig:Add("name", oParamInt:Name).
                if oParamInt:Extent gt 0 then
                    oParamSig:Add("extent", oParamInt:Extent).

                oParamArr:Add(oParamSig).
            end. /* oParamExt */

            oElementSig:Add("mode", oConstsInt:AccessMode:toString()).
            oElementSig:Add("params", oParamArr).
            oConstructs:Add(oConstsInt:Name, oElementSig).
        end. /* oConstsExt */

        return oConstructs.

        catch err as Progress.Lang.Error:
            message "Constructors:" err:GetMessage(1).
            return oConstructs.
        end catch.
    end method. /* getConstructors */


    method private static JsonObject getProperties ( input poClassRef as Progress.Lang.Class ):
        define variable oProperties as JsonObject no-undo.
        assign oProperties = new JsonObject().

        define variable oPropsExt   as Progress.Reflect.Property no-undo extent.
        define variable oPropsInt   as Progress.Reflect.Property no-undo.
        define variable oElementSig as JsonObject                no-undo.
        define variable cDataType   as character                 no-undo.
        define variable iCount      as integer                   no-undo.

        assign oPropsExt = poClassRef:GetProperties().
        do iCount = 1 to extent(oPropsExt):
            assign
                oPropsInt   = oPropsExt[iCount]
                oElementSig = new Progress.Json.ObjectModel.JsonObject()
                .

            if can-do({&SKIP_NAMES}, oPropsInt:name) or
               oPropsInt:DeclaringClass:TypeName eq "Progress.Lang.Object" then next.

            if oPropsInt:DataType:toString() eq "object" then
                assign cDataType = oPropsInt:DataTypeName.
            else
                assign cDataType = lc(oPropsInt:DataType:toString()).

            oElementSig:Add("origin", oPropsInt:OriginatingClass:TypeName).
            oElementSig:Add("defined", oPropsInt:DeclaringClass:TypeName).
            oElementSig:Add("mode", oPropsInt:AccessMode:toString()).
            oElementSig:Add("override", oPropsInt:IsOverride).
            oElementSig:Add("static", oPropsInt:IsStatic).
            oElementSig:Add("readable", oPropsInt:CanRead).
            oElementSig:Add("writable", oPropsInt:CanWrite).
            oElementSig:Add("type", cDataType).
            if oPropsInt:Extent gt 0 then
                oElementSig:Add("extent", oPropsInt:Extent).

            oProperties:Add(oPropsInt:Name, oElementSig).
        end. /* oPropsExt */

        return oProperties.

        catch err as Progress.Lang.Error:
            message "Properties:" err:GetMessage(1).
            return oProperties.
        end catch.
    end method. /* getProperties */


    method private static JsonObject getVariables ( input poClassRef as Progress.Lang.Class ):
        define variable oVariables as JsonObject no-undo.
        assign oVariables = new JsonObject().

        define variable oVarsExt    as Progress.Reflect.Variable no-undo extent.
        define variable oVarsInt    as Progress.Reflect.Variable no-undo.
        define variable oElementSig as JsonObject                no-undo.
        define variable cDataType   as character                 no-undo.
        define variable iCount      as integer                   no-undo.

        assign oVarsExt = poClassRef:GetVariables().
        do iCount = 1 to extent(oVarsExt):
            assign
                oVarsInt    = oVarsExt[iCount]
                oElementSig = new Progress.Json.ObjectModel.JsonObject()
                .

            if can-do({&SKIP_NAMES}, oVarsInt:name) or
               oVarsInt:DeclaringClass:TypeName eq "Progress.Lang.Object" then next.

            if oVarsInt:DataType:toString() eq "object" then
                assign cDataType = oVarsInt:DataTypeName.
            else
                assign cDataType = lc(oVarsInt:DataType:toString()).

            oElementSig:Add("origin", oVarsInt:OriginatingClass:TypeName).
            oElementSig:Add("defined", oVarsInt:DeclaringClass:TypeName).
            oElementSig:Add("mode", oVarsInt:AccessMode:toString()).
            oElementSig:Add("static", oVarsInt:IsStatic).
            oElementSig:Add("type", cDataType).
            if oVarsInt:Extent gt 0 then
                oElementSig:Add("extent", oVarsInt:Extent).
            oVariables:Add(oVarsInt:Name, oElementSig).
        end. /* oVarsExt */

        return oVariables.

        catch err as Progress.Lang.Error:
            message "Variables:" err:GetMessage(1).
            return oVariables.
        end catch.
    end method. /* getVariables */


    method private static JsonObject getMethods ( input poClassRef as Progress.Lang.Class ):
        define variable oMethods as JsonObject no-undo.
        assign oMethods = new JsonObject().

        define variable oMethodExt  as Progress.Reflect.Method    no-undo extent.
        define variable oMethodInt  as Progress.Reflect.Method    no-undo.
        define variable oElementSig as JsonObject                 no-undo.
        define variable oParamArr   as JsonArray                  no-undo.
        define variable oParamSig   as JsonObject                 no-undo.
        define variable oParamExt   as Progress.Reflect.Parameter no-undo extent.
        define variable oParamInt   as Progress.Reflect.Parameter no-undo.
        define variable cDataType   as character                  no-undo.
        define variable cReturnType as character                  no-undo.
        define variable iCount      as integer                    no-undo.
        define variable iParam      as integer                    no-undo.

        assign oMethodExt = poClassRef:GetMethods().
        methodblk:
        do iCount = 1 to extent(oMethodExt):
            assign oMethodInt = oMethodExt[iCount].

            if can-do({&SKIP_NAMES}, oMethodInt:name) or
               oMethodInt:DeclaringClass:TypeName eq "Progress.Lang.Object" then next.

            if oMethodInt:ReturnType:toString() eq "object" then
                assign cReturnType = oMethodInt:ReturnTypeName.
            else
                assign cReturnType = lc(oMethodInt:ReturnType:toString()).

            if oMethods:Has(oMethodInt:name) then do:
                /**
                 * This signature-detection logic can only add a single method by a given name,
                 * therefore overloaded methods are not currently supported. The reason being
                 * that for externally-exposed (public) methods, the dynamic method invocation
                 * logic must match against a single method signature (partly for performance).
                 */
                if log-manager:logging-level ge 2 then
                    message substitute("Public method '&1:&2' already exists.", oMethodInt:DeclaringClass:TypeName, oMethodInt:name).
                next methodblk.
            end. /* Has Method */

            assign
                oElementSig = new Progress.Json.ObjectModel.JsonObject()
                oParamArr   = new Progress.Json.ObjectModel.JsonArray()
                .

            extent(oParamExt) = ?. /* Reset from previous params. */
            assign oParamExt = oMethodInt:GetParameters().
            do iParam = 1 to extent(oParamExt):
                assign oParamInt = oParamExt[iParam].

                if oParamInt:DataType:toString() eq "object" then
                    assign cDataType = oParamInt:DataTypeName.
                else
                    assign cDataType = lc(oParamInt:DataType:toString()).

                assign oParamSig = new Progress.Json.ObjectModel.JsonObject().
                oParamSig:Add("mode", oParamInt:Mode:toString()).
                oParamSig:Add("name", oParamInt:Name).
                oParamSig:Add("type", cDataType).
                if oParamInt:Extent gt 0 then
                    oParamSig:Add("extent", oParamInt:Extent).

                oParamArr:Add(oParamSig).
            end. /* oParamExt */

            /* Add current method with params. */
            oElementSig:Add("return", cReturnType).
            oElementSig:Add("params", oParamArr).
            if oMethodInt:ReturnExtent gt 0 then
                oElementSig:Add("extent", oMethodInt:ReturnExtent).
            oMethods:Add(oMethodInt:name, oElementSig).
        end. /* oMethodExt */

        return oMethods.

        catch err as Progress.Lang.Error:
            message "Methods:" err:GetMessage(1).
            return oMethods.
        end catch.
    end method. /* getMethods */


    method public static JsonObject getClassSignature ( input pcClassName as character ):
        return getClassSignature(pcClassName, false).
    end method. /* getClassSignature */


    method public static JsonObject getClassSignature ( input pcClassName as character,
                                                        input plOmitName  as logical ):
        define variable oClassSig as JsonObject no-undo.
        assign oClassSig = new Progress.Json.ObjectModel.JsonObject().

        /* Obtain reference to a class by full package name. */
        define variable oClassRef as Progress.Lang.Class no-undo.
        assign oClassRef = Progress.Lang.Class:GetClass(pcClassName) no-error.
        if error-status:error then do:
            /* Really should not happen, but just in case... */
            message "SigError:" error-status:get-message(1).
            return new Progress.Json.ObjectModel.JsonObject().
        end.

        /* Add properties to new class signature JSON object. */
        if valid-object(oClassRef) then do:
            if oClassRef:SuperClass ne ? then
                oClassSig:Add("super", oClassRef:SuperClass:TypeName).
            oClassSig:Add("abstract", oClassRef:IsAbstract()).
            oClassSig:Add("final", oClassRef:IsFinal()).
            oClassSig:Add("interface", oClassRef:IsInterface()).
            oClassSig:Add("statics", oClassRef:HasStatics()).
            oClassSig:Add("constructors", getConstructors(oClassRef)).
            oClassSig:Add("properties", getProperties(oClassRef)).
            oClassSig:Add("variables", getVariables(oClassRef)).
            oClassSig:Add("methods", getMethods(oClassRef)).
        end. /* valid-object */

        /* If omitting name from object, return now. */
        if plOmitName then return oClassSig.

        /* Add signature of class as property of object. */
        define variable oSignature as JsonObject no-undo.
        oSignature = new Progress.Json.ObjectModel.JsonObject().
        oSignature:Add(pcClassName, oClassSig).

        return oSignature.

        catch err as Progress.Lang.Error:
            message "Signature:" err:GetMessage(1).
            return oSignature.
        end catch.
    end method. /* getClassSignature */

end class.