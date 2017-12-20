/*------------------------------------------------------------------------
    File        : profile.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed Jun 07 08:47:45 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

&global-define test_username dev@spark
&global-define allowed_roles PSCUser,EndUser
&global-define domain_passkey oech1::23222e35397562

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.

block-level on error undo, throw.

define variable oTest as tests.ParameterTests no-undo.
define variable cPath as character            no-undo.
define variable hCPO  as handle               no-undo.

assign cPath = replace(session:temp-directory, "~\", "~/").
os-create-dir value(cPath + "tests/listing/").

assign
    profiler:enabled      = true
    profiler:file-name    = cPath + "tests/profiler.out"
    profiler:description  = "Parameter Tests"
    profiler:listings     = true
    profiler:directory    = cPath + "tests/listing/"
    profiler:trace-filter = "*"
    profiler:tracing      = ""
    profiler:statistics   = true
    profiler:coverage     = true
    profiler:profiling    = true
    .

/* ***************************  Main Block  *************************** */

/* Setup for the PMFO stack. */
run Spark/startup.p (input "").

/* Create a known user for security. */
create client-principal hCPO.
hCPO:initialize("{&test_username}").
hCPO:roles = "{&allowed_roles}".
hCPO:set-property("ATTR_ENABLED", "true").
hCPO:set-property("ATTR_LOCKED", "false").
hCPO:set-property("ATTR_EXPIRED", "false").
hCPO:seal("{&domain_passkey}").

/* Run tasks that need profiling. */
run profileFacade.

/* Teardown for the PMFO stack. */
run Spark/shutdown.p.

finally:
    if profiler:enabled then do:
        assign
            profiler:profiling = false
            profiler:enabled   = false
            .
        profiler:write-data().
    end.
    delete object hCPO no-error.
    delete object oTest no-error.
end finally.

/** Samples for Profiling **/

procedure profileFacade private:
    define variable oFacade        as Spark.Core.DirectFacade no-undo.
    define variable oRequest       as JsonObject              no-undo.
    define variable oResponse      as JsonObject              no-undo.
    define variable lResult        as logical                 no-undo.
    define variable fElapsedTime   as decimal                 no-undo.
    define variable iResponseCode  as integer                 no-undo.
    define variable lcJsonRequest  as longchar                no-undo.
    define variable lcJsonHeaders  as longchar                no-undo.
    define variable lcJsonResponse as longchar                no-undo.

    assign oRequest = new JsonObject().
    oRequest:Add("inString", "Hello World").
    oRequest:Add("inDecimal", 3.1415).
    oRequest:Add("inInteger", 12345).
    oRequest:Add("inDate", today).
    oRequest:Add("inDTime", datetime(today)).
    oRequest:Add("inDTimeTZ", datetime-tz(now)).
    lcJsonRequest = oRequest:GetJsonText().

    assign oFacade = new Spark.Core.DirectFacade().
    assign lResult = oFacade:runService ( input  hCPO,
                                          input  "params",
                                          input  "primitives",
                                          input  "PUT",
                                          input  "/web/pdo/tests",
                                          input  lcJsonRequest,
                                          output fElapsedTime,
                                          output iResponseCode,
                                          output lcJsonHeaders,
                                          output lcJsonResponse ).
end procedure. /* profileFacade */
