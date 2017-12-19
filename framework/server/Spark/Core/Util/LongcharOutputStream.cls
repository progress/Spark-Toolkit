/*------------------------------------------------------------------------
    File        : LongcharOutputStream
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed Aug 03 13:35:44 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.IO.OutputStream.

block-level on error undo, throw.

class Spark.Core.Util.LongcharOutputStream inherits OutputStream:

    define public property StreamData as longchar no-undo get.
        private set.

    method override public int64 Write ( input pmSource as memptr,
                                         input piOffset as int64,
                                         input piLength as int64 ):
        define variable mTemp   as memptr  no-undo.
        define variable iLength as integer no-undo.

        assign iLength = get-size(pmSource).

        /* Check for invalid length/offset. Note: 1-based counting in ABL. */
        if iLength eq 0 or piOffset lt 1 or piLength le 0 or
           (piOffset ge iLength) or (piOffset + piLength - 1) gt iLength then return 0.

        /* if it's the whole memptr, just dump it. */
        if piLength eq iLength and piOffset eq 1 then do:
            /* First attempt to store the data in a longchar. */
            copy-lob from pmSource to StreamData no-convert no-error.
            if error-status:error then do:
                /* If error occurs, we should store as base64-encoded data. */
                assign StreamData = base64-encode(pmSource) no-error.
            end.
        end.
        else do:
            /* Exract the expected length of data from the input data. */
            assign mTemp = get-bytes(pmSource, piOffset, piLength).

            /* First attempt to store the data in a longchar. */
            copy-lob from mTemp to StreamData no-convert no-error.
            if error-status:error then do:
                /* If error occurs, we should store as base64-encoded data. */
                assign StreamData = base64-encode(mTemp) no-error.
            end.
        end.

        if log-manager:logging-level ge 5 then do:
            if get-size(mTemp) gt 0 then
                copy-lob from mTemp to file "stream_output_original.log" no-error.
            else
                copy-lob from pmSource to file "stream_output_original.log" no-error.
            copy-lob from StreamData to file "stream_output_encoded.log" no-error.
        end.

        if error-status:error then
            message error-status:get-message(1).

        return length(StreamData, "raw").

        finally:
            set-size(mTemp) = 0.
        end finally.
    end method.

    method override public int64 Write ( input plcSource as longchar ):
        return 0. /* Method is not implemented at this time. */
    end method.

    method override public int64 Write ( input pcSource as character ):
        return 0. /* Method is not implemented at this time. */
    end method.

end class.