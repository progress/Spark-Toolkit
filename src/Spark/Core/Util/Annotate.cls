/*------------------------------------------------------------------------
    File        : Annotate
    Purpose     : Provide annotation methods for the catalog manager
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Feb 27 16:07:15 EST 2015
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.
using OpenEdge.Net.HTTP.MethodEnum from propath.
using Spark.Core.Manager.ICatalogManager from propath.
using Spark.Core.Util.FieldInfo from propath.
using Spark.Core.Util.OperationEnum from propath.

block-level on error undo, throw.

class Spark.Core.Util.Annotate:

    method public static void addProperty ( input pcClassPath     as character,
                                            input pcOperationType as character,
                                            input pcPropertyName  as character,
                                            input pcPropertyType  as character,
                                            input pcPropertyValue as character ):
        addProperty( "",
                     pcClassPath,
                     pcOperationType,
                     pcPropertyName,
                     pcPropertyType,
                     pcPropertyValue ).
    end method. /* addProperty */


    method public static void addProperty ( input pcServiceURI    as character,
                                            input pcClassPath     as character,
                                            input pcOperationType as character,
                                            input pcPropertyName  as character,
                                            input pcPropertyType  as character,
                                            input pcPropertyValue as character ):
        cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager)
             :addProperty( pcServiceURI,
                           pcClassPath,
                           pcOperationType,
                           pcPropertyName,
                           pcPropertyType,
                           pcPropertyValue ).
    end method. /* addProperty */


    method public static void describeEntity ( input pcResourceName as character,
                                               input pcEntityName   as character ):
        describeEntity( pcResourceName,
                        pcEntityName,
                        "",
                        "" ).
    end method. /* describeEntity */


    method public static void describeEntity ( input pcResourceName as character,
                                               input pcEntityName   as character,
                                               input pcPrimaryKeys  as character ):
        describeEntity( pcResourceName,
                        pcEntityName,
                        pcPrimaryKeys,
                        "" ).
    end method. /* describeEntity */


    method public static void describeEntity ( input pcResourceName as character,
                                               input pcEntityName   as character,
                                               input pcPrimaryKeys  as character,
                                               input pcForeignKeys  as character ):
        cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager)
             :describeEntity( "",
                              pcResourceName,
                              pcEntityName,
                              pcPrimaryKeys,
                              pcForeignKeys ).
    end method. /* describeEntity */


    method public static void describeFields ( input pcEntityName as character,
                                               input pcTableName  as character,
                                               input plcFieldData as longchar ):
        define variable oParser    as ObjectModelParser no-undo.
        define variable oFieldData as JsonObject        no-undo.

        if (plcFieldData gt "") eq true then do:
            assign oParser = new ObjectModelParser(). /* Prepare to parse user-supplied data, which may be incorrect. */
            assign oFieldData = cast(oParser:Parse(Spark.Core.Util.FormatTools:convertToUTF8(plcFieldData)), JsonObject).
            describeFields( pcEntityName,
                            pcTableName,
                            oFieldData ).

            delete object oParser no-error.
            delete object oFieldData no-error.
        end. /* plcFieldData */

        catch err as Progress.Lang.Error:
            message substitute("Error parsing field properties: &1", err:GetMessage(1)).
        end catch.
    end method. /* describeFields */


    method public static void describeFields ( input pcEntityName as character,
                                               input pcTableName  as character,
                                               input poFieldData  as JsonObject ):
        if (pcEntityName gt "") eq true and (pcTableName gt "") eq true and valid-object(poFieldData) then
            cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager)
                 :describeFields( pcEntityName,
                                  pcTableName,
                                  poFieldData ).
    end method. /* describeFields */


    method public static void describeFields ( input poFieldProps as FieldInfo ):
        cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager)
             :describeFields( poFieldProps:DatasetName,
                              poFieldProps:TempTableName,
                              poFieldProps ).
    end method. /* describeFields */


    method public static void describeCreate ( input pcServiceURI      as character,
                                               input pcResourceName    as character,
                                               input pcMethodName      as character ):
        describeResource( pcServiceURI,
                          pcResourceName,
                          pcMethodName,
                          OperationEnum:create:toString(),
                          OperationEnum:create:toString(),
                          MethodEnum:post:toString() ).
    end method. /* describeCreate */


    method public static void describeRead ( input pcServiceURI      as character,
                                             input pcResourceName    as character,
                                             input pcMethodName      as character ):
        describeResource( pcServiceURI,
                          pcResourceName,
                          pcMethodName,
                          OperationEnum:read:toString(),
                          OperationEnum:read:toString(),
                          MethodEnum:get:toString() ).
    end method. /* describeRead */


    method public static void describeUpdate ( input pcServiceURI      as character,
                                               input pcResourceName    as character,
                                               input pcMethodName      as character ):
        describeResource( pcServiceURI,
                          pcResourceName,
                          pcMethodName,
                          OperationEnum:update:toString(),
                          OperationEnum:update:toString(),
                          MethodEnum:put:toString() ).
    end method. /* describeCreate */


    method public static void describeDelete ( input pcServiceURI      as character,
                                               input pcResourceName    as character,
                                               input pcMethodName      as character ):
        describeResource( pcServiceURI,
                          pcResourceName,
                          pcMethodName,
                          OperationEnum:delete:toString(),
                          OperationEnum:delete:toString(),
                          MethodEnum:delete:toString() ).
    end method. /* describeDelete */


    method public static void describeSubmit ( input pcServiceURI      as character,
                                               input pcResourceName    as character,
                                               input pcMethodName      as character ):
        describeResource( pcServiceURI,
                          pcResourceName,
                          pcMethodName,
                          OperationEnum:submit:toString(),
                          OperationEnum:submit:toString(),
                          MethodEnum:put:toString() ).
    end method. /* describeSubmit */


    method public static void describeInvoke ( input pcServiceURI      as character,
                                               input pcResourceName    as character,
                                               input pcMethodName      as character,
                                               input pcMethodAlternate as character,
                                               input pcHttpMethod      as character ):
        describeResource( pcServiceURI,
                          pcResourceName,
                          pcMethodName,
                          pcMethodAlternate,
                          OperationEnum:invoke:toString(),
                          pcHttpMethod ).
    end method. /* describeInvoke */


    method public static void describeResource ( input pcServiceURI      as character,
                                                 input pcResourceName    as character,
                                                 input pcMethodName      as character,
                                                 input pcMethodAlternate as character,
                                                 input pcOperationType   as character,
                                                 input pcOperationVerb   as character ):
        cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager)
             :describeResource( pcServiceURI,
                                pcResourceName,
                                pcMethodName,
                                pcMethodAlternate,
                                pcOperationType,
                                pcOperationVerb ).
    end method. /* describeResource */

end class.