/*------------------------------------------------------------------------
    File        : LongcharInputStream
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed Aug 03 13:43:47 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Progress.IO.InputStream.

block-level on error undo, throw.

class Spark.Core.Util.LongcharInputStream inherits InputStream:

    define public property StreamData as longchar no-undo get. set.

    method override public int64 Read ( input pmTarget as memptr,
                                        input piOffset as int64,
                                        input piLength as int64 ):
        if StreamData gt "" then do:
            /* If data present and appears as JSON, just copy back. */
            if StreamData begins "~{" then
                copy-lob from StreamData to pmTarget.
            else /* Otherwise assume to be base64-encoded. */
                assign pmTarget = base64-decode(StreamData).
        end.

        if log-manager:logging-level ge 5 then do:
            copy-lob from StreamData to file "stream_input_original.log" no-error.
            copy-lob from pmTarget to file "stream_input_decoded.log" no-error.
        end.

        return get-size(pmTarget).
    end method.

    method override public int64 Read ( input  pcDelimiter as character,
                                        output plcTarget   as longchar ):
        return 0. /* Method is not implemented at this time. */
    end method.

    method override public int64 Read ( input  pcDelimiter as character,
                                        output pcTarget    as character ):
       return 0. /* Method is not implemented at this time. */
    end method.

end class.