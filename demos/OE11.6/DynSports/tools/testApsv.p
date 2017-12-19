/*------------------------------------------------------------------------
    File        : testApsv.p
    Purpose     : Test remote APSV connections via special facade on AS.
    Description :
    Author(s)   : dugrau
    Created     : Wed Mar 02 15:38:52 EST 2016
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

using Progress.Lang.*.
using Progress.Json.ObjectModel.*.

block-level on error undo, throw.

/* ***************************  Main Block  *************************** */

define variable hServer  as handle    no-undo.
define variable hFacade  as handle    no-undo.
define variable cConnect as character no-undo.
define variable lReturn  as logical   no-undo.

create server hServer.

/*assign cConnect = substitute("http://&1:&2@&3:&4/apsv", "apsvuser", "secret", "localhost", "8830").*/
assign cConnect = substitute("http://&1:&2/DynSports/apsv", "localhost", "8820").
/*assign cConnect = substitute("http://&1:&2/DynSports/apsv", "54.173.59.64", "8820").*/

assign lReturn = hServer:connect(substitute("-URL &1 -sessionModel Session-free", cConnect)) no-error.
if error-status:error then
    message error-status:get-message(1) view-as alert-box.

if not lReturn then
    message "Failed to connect to AppServer." view-as alert-box.

if hServer:connected() then do:
    define variable pcResourceName as character         no-undo.
    define variable pcMethodName   as character         no-undo.
    define variable pcHttpMethod   as character         no-undo.
    define variable pcServiceObj   as character         no-undo.
    define variable pcJsonRequest  as longchar          no-undo.
    define variable fElapsedTime   as decimal           no-undo.
    define variable iResponseCode  as integer           no-undo.
    define variable cHeadResponse  as longchar          no-undo.
    define variable cJsonResponse  as longchar          no-undo.
    define variable hCPO           as handle            no-undo.
    define variable oParser        as ObjectModelParser no-undo.

    message "Connected to AppServer!" view-as alert-box.

/*    if valid-object(session:current-request-info) then                                             */
/*        hServer:request-info:SetClientPrincipal(session:current-request-info:GetClientPrincipal()).*/

    create client-principal hCPO.
    hCPO:initialize("dev", "0").
    hCPO:domain-name = "spark".
    hCPO:seal("spark01").
    hServer:request-info:SetClientPrincipal(hCPO).

    do stop-after 20 on stop undo, leave:
        run Spark/Core/ApsvFacade.p on server hServer single-run set hFacade no-error.
        if error-status:error then
            message "Error, Return-Value:" return-value view-as alert-box.

        if valid-handle(hFacade) then
            run runService in hFacade ( input  "all",
                                        input  "getCatalog",
                                        input  "get",
                                        input  "",
                                        input  "",
                                        output fElapsedTime,
                                        output iResponseCode,
                                        output cHeadResponse,
                                        output cJsonResponse ).

        assign oParser = new ObjectModelParser().
        cast(oParser:parse(cJsonResponse), JsonObject):WriteFile("output1.json", true).
        message "Length:" length(cJsonResponse, "raw") view-as alert-box.
    end. /* do */

    delete object hCPO no-error.

    create client-principal hCPO.
    hCPO:initialize("dev2", "0").
    hCPO:domain-name = "spark".
    hCPO:seal("spark01").
    hServer:request-info:SetClientPrincipal(hCPO).

    do stop-after 20 on stop undo, leave:
        run Spark/Core/ApsvFacade.p on server hServer single-run set hFacade no-error.
        if error-status:error then
            message return-value view-as alert-box.

        if valid-handle(hFacade) then
            run runService in hFacade ( input  "customer",
                                        input  "read",
                                        input  "get",
                                        input  "/web/pdo/ordering",
                                        input  "",
                                        output fElapsedTime,
                                        output iResponseCode,
                                        output cHeadResponse,
                                        output cJsonResponse ).

        assign oParser = new ObjectModelParser().
        cast(oParser:parse(cJsonResponse), JsonObject):WriteFile("output2.json", true).
        message "Length:" length(cJsonResponse, "raw") view-as alert-box.
    end. /* do */
end. /* connected */

finally:
    delete object hFacade no-error.
    hServer:disconnect().
    delete object hServer no-error.
end.
