using Progress.IO.* from propath.
using Progress.Lang.* from propath.
using Spark.Core.Util.LongcharInputStream from propath.
using Spark.Core.Util.LongcharOutputStream from propath.

block-level on error undo, throw.

/**
 * In 11.6, you can now serialize objects to binary or JSON via the Progress.IO.BinarySerializer
 * and Progress.IO.JsonSerializer classes; Progress.IO.InputStream and Progress.IO.OutputStream,
 * provide the default functionality for input and output streams (respectively) and 2 subclasses,
 * Progress.IO.FileInputStream and Progress.IO.FileOutputStream, facilitate reading objects from
 * and writing objects to a file. As with passing objects between client and AppServer, the class
 * of any object serialized to binary or JSON must be defined as SERIALIZABLE. By default, binary
 * serialization includes all data members, properties, temp-tables, and ProDataSets, regardless
 * of whether they are public, protected, or private. However, only data members and properties
 * defined as public participate in JSON serialization by default. Protected and private class
 * members must be themselves defined as SERIALIZABLE in the DEFINE VARIABLE, DEFINE PROPERTY,
 * DEFINE TEMP-TABLE, and DEFINE DATASET statements. Upon deserialization the members for the
 * serialized class must match exactly when deserialized and cast to the original class.
 */

/**
 * A static class with serialization helper methods
 */
class Spark.Core.Util.Serialize:

    method public static logical serializeClassToBinary ( input  poClassObj as Progress.Lang.Object,
                                                          output pcLongData as longchar ):
        define variable oOutStream  as LongcharOutputStream no-undo.
        define variable oSerializer as BinarySerializer     no-undo.

        /* Output global class data as serialized JSON data. */
        assign oOutStream = new LongcharOutputStream() no-error.
        if valid-object(oOutStream) then do:
            oSerializer = new BinarySerializer().
            oSerializer:Serialize(poClassObj, oOutStream) no-error.
            copy-lob from oOutStream:StreamData to pcLongData no-error.
            oOutStream:Close().
        end. /* oOutStream */
        else
            return false.

        return true.

        catch err as Progress.Lang.Error:
            message substitute("Binary Serialize Error: &1", error-status:get-message(1)).
            if valid-object(oOutStream) then oOutStream:Close().
            return false.
        end catch.
        finally:
            delete object oSerializer no-error.
            delete object oOutStream  no-error.
        end finally.
    end method. /* serializeClassToBinary */


    method public static logical serializeClassToBinary ( input poClassObj as Progress.Lang.Object,
                                                          input pcFilePath as character ):
        define variable oOutStream  as FileOutputStream no-undo.
        define variable oSerializer as BinarySerializer no-undo.

        /* Output global class data as serialized JSON data. */
        assign oOutStream = new FileOutputStream(pcFilePath) no-error.
        if valid-object(oOutStream) then do:
            oSerializer = new BinarySerializer().
            oSerializer:Serialize(poClassObj, oOutStream) no-error.
            oOutStream:Close().
        end. /* oOutStream */
        else
            return false.

        return true.

        catch err as Progress.Lang.Error:
            message substitute("Binary Serialize Error: &1", error-status:get-message(1)).
            if valid-object(oOutStream) then oOutStream:Close().
            return false.
        end catch.
        finally:
            delete object oSerializer no-error.
            delete object oOutStream  no-error.
        end finally.
    end method. /* serializeClassToBinary */


    method public static logical serializeClassToJson ( input poClassObj as Progress.Lang.Object,
                                                        input pcFilePath as character ):
        define variable oOutStream  as FileOutputStream no-undo.
        define variable oSerializer as JsonSerializer   no-undo.

        /* Output global class data as serialized JSON data. */
        assign oOutStream = new FileOutputStream(pcFilePath) no-error.
        if valid-object(oOutStream) then do:
            oSerializer = new JsonSerializer(true).
            oSerializer:Serialize(poClassObj, oOutStream) no-error.
            oOutStream:Close().
        end. /* oOutStream */
        else
            return false.

        return true.

        catch err as Progress.Lang.Error:
            message substitute("JSON Serialize Error: &1", error-status:get-message(1)).
            if valid-object(oOutStream) then oOutStream:Close().
            return false.
        end catch.
        finally:
            delete object oSerializer no-error.
            delete object oOutStream  no-error.
        end finally.
    end method. /* serializeClassToJson */


    method public static logical serializeClassToJson ( input  poClassObj as Progress.Lang.Object,
                                                        output pcLongData as longchar ):
        define variable oOutStream  as LongcharOutputStream no-undo.
        define variable oSerializer as JsonSerializer       no-undo.

        /* Output global class data as serialized JSON data. */
        assign oOutStream = new LongcharOutputStream() no-error.
        if valid-object(oOutStream) then do:
            oSerializer = new JsonSerializer(true).
            oSerializer:Serialize(poClassObj, oOutStream) no-error.
            copy-lob from oOutStream:StreamData to pcLongData no-error.
            oOutStream:Close().
        end. /* oOutStream */
        else
            return false.

        return true.

        catch err as Progress.Lang.Error:
            message substitute("JSON Serialize Error: &1", error-status:get-message(1)).
            if valid-object(oOutStream) then oOutStream:Close().
            return false.
        end catch.
        finally:
            delete object oSerializer no-error.
            delete object oOutStream  no-error.
        end finally.
    end method. /* serializeClassToJson */


    method public static Progress.Lang.Object deserializeClassFromBinary ( input pcLongData as longchar ):
        define variable oInStream   as LongcharInputStream  no-undo.
        define variable oSerializer as BinarySerializer     no-undo.
        define variable oClassObj   as Progress.Lang.Object no-undo.

        if (pcLongData gt "") ne true then return ?.

        assign oInStream = new LongcharInputStream() no-error.
        if valid-object(oInStream) then do:
            oSerializer = new BinarySerializer().
            copy-lob from pcLongData to oInStream:StreamData no-error.
            assign oClassObj = oSerializer:Deserialize(oInStream) no-error.
            oInStream:Close().
        end. /* oInStream */
        else
            undo, throw new AppError("Existing class data not available.", 0).

        return oClassObj.

        catch err as Progress.Lang.Error:
            message substitute("Binary Deserialize Error: &1", error-status:get-message(1)).
            if valid-object(oInStream) then oInStream:Close().
            return ?.
        end catch.
        finally:
            delete object oSerializer no-error.
            delete object oInStream   no-error.
        end finally.
    end method. /* deserializeClassFromBinary */


    method public static Progress.Lang.Object deserializeClassFromBinary ( input pcFilePath as character ):
        define variable oInStream   as FileInputStream      no-undo.
        define variable oSerializer as BinarySerializer     no-undo.
        define variable oClassObj   as Progress.Lang.Object no-undo.

        assign oInStream = new FileInputStream(pcFilePath) no-error.
        if valid-object(oInStream) then do:
            oSerializer = new BinarySerializer().
            assign oClassObj = oSerializer:Deserialize(oInStream) no-error.
            oInStream:Close().
        end. /* oInStream */
        else
            undo, throw new AppError("Existing class data not available.", 0).

        return oClassObj.

        catch err as Progress.Lang.Error:
            message substitute("Binary Deserialize Error: &1", error-status:get-message(1)).
            if valid-object(oInStream) then oInStream:Close().
            return ?.
        end catch.
        finally:
            delete object oSerializer no-error.
            delete object oInStream   no-error.
        end finally.
    end method. /* deserializeClassFromBinary */


    method public static Progress.Lang.Object deserializeClassFromJson ( input pcLongData as longchar ):
        define variable oInStream   as LongcharInputStream  no-undo.
        define variable oSerializer as JsonSerializer       no-undo.
        define variable oClassObj   as Progress.Lang.Object no-undo.

        assign oInStream = new LongcharInputStream() no-error.
        if valid-object(oInStream) then do:
            oSerializer = new JsonSerializer(true).
            copy-lob from pcLongData to oInStream:StreamData no-error.
            assign oClassObj = oSerializer:Deserialize(oInStream) no-error.
            oInStream:Close().
        end. /* oInStream */
        else
            undo, throw new AppError("Existing class data not available.", 0).

        return oClassObj.

        catch err as Progress.Lang.Error:
            message substitute("JSON Deserialize Error: &1", error-status:get-message(1)).
            if valid-object(oInStream) then oInStream:Close().
            return ?.
        end catch.
        finally:
            delete object oSerializer no-error.
            delete object oInStream   no-error.
        end finally.
    end method. /* deserializeClassFromJson */


    method public static Progress.Lang.Object deserializeClassFromJson ( input pcFilePath as character ):
        define variable oInStream   as FileInputStream      no-undo.
        define variable oSerializer as JsonSerializer       no-undo.
        define variable oClassObj   as Progress.Lang.Object no-undo.

        assign oInStream = new FileInputStream(pcFilePath) no-error.
        if valid-object(oInStream) then do:
            oSerializer = new JsonSerializer(true).
            assign oClassObj = oSerializer:Deserialize(oInStream) no-error.
            oInStream:Close().
        end. /* oInStream */
        else
            undo, throw new AppError("Existing class data not available.", 0).

        return oClassObj.

        catch err as Progress.Lang.Error:
            message substitute("JSON Deserialize Error: &1", error-status:get-message(1)).
            if valid-object(oInStream) then oInStream:Close().
            return ?.
        end catch.
        finally:
            delete object oSerializer no-error.
            delete object oInStream   no-error.
        end finally.
    end method. /* deserializeClassFromJson */

end class.