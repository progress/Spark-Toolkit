/*------------------------------------------------------------------------
    File        : OSPath
    Purpose     : Helper properties for creating standard OS paths
    Description :
    Author(s)   : Dustin Grau
    Created     : Mon May 07 17:25:15 EDT 2018
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Spark.Diagnostic.Util.OSPath abstract:

    /* Set automatically as part of the PAS instance startup process. */
    define protected property CatalinaBase as character no-undo initial ""
        get():
            if CatalinaBase eq "" then do:
                file-info:filename = trim(os-getenv("CATALINA_BASE")).
                assign CatalinaBase = right-trim(replace(file-info:full-pathname, "~\", "~/"), "~/").
            end.
            return CatalinaBase.
        end get.
        set.

    /* Used as a standard location for creating temporary files. */
    define protected property TemporaryDir as character no-undo initial ""
        get():
            if TemporaryDir eq "" then
                assign TemporaryDir = right-trim(replace(session:temp-directory, "~\", "~/"), "~/").
            return TemporaryDir.
        end get.
        set.

end class.