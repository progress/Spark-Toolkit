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


    /***** Public Methods *****/



    method public character GetMetricsPath ( input piAgentID as integer ):
        define variable cBasePath as character no-undo.

        /* Assemble base path for output and create any needed directories. */
        assign cBasePath = substitute("&1/metrics/SessionData/&2", this-object:TemporaryDir, piAgentID).
        os-create-dir value(cBasePath) no-error.

        return substitute("&1/&2.&3_A&4.json",
                          cBasePath,
                          replace(iso-date(today), "-", ""),
                          mtime, piAgentID).
    end method. /* GetMetricsPath */


    method public character GetReportPath ( input piAgentID   as integer,
                                            input piSessionID as integer ):
        define variable cBasePath as character no-undo.

        /* Assemble base path for output and create any needed directories. */
        assign cBasePath = substitute("&1/metrics/ABLObjectsReport/&2", this-object:TemporaryDir, piAgentID).
        os-create-dir value(cBasePath) no-error.

        return substitute("&1/&2.&3_A&4_S&5.json",
                          cBasePath,
                          replace(iso-date(today), "-", ""),
                          mtime, piAgentID, piSessionID).
    end method. /* GetReportPath */

end class.