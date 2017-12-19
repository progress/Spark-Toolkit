/**
 * Returns a list of all available PAS instances.
 * Usage: manageInstance.p <params>
 *  Parameter Default/Allowed
 *   Scheme   [http|https]
 *   Hostname [localhost]
 *   OEM Port [9090]
 *   UserId   [pasmgr]
 *   Password [s3cr3t]
 *   ABL App  [SportsPASOE]
 *   Action   [status]
 *
 * It is HIGHLY suggested to create a limited-access Operator account in OEM
 * that can only start/stop PAS instances. This prevents abuse and sharing
 * of the primary admin account. Also, use of HTTPS for OEM is recommended.
 */

using OpenEdge.Core.Assert.
using OpenEdge.Core.Assertion.AssertJson.
using OpenEdge.Core.AssertionFailedError.
using OpenEdge.Core.JsonDataTypeEnum.
using OpenEdge.Core.String.
using OpenEdge.Core.WidgetHandle.
using OpenEdge.Net.HTTP.Credentials.
using OpenEdge.Net.HTTP.HttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.RequestBuilder.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.Object.
using Progress.Json.ObjectModel.ObjectModelParser.
using Progress.Json.ObjectModel.JsonArray.

define variable oReq       as IHttpRequest  no-undo.
define variable oResp      as IHttpResponse no-undo.
define variable oEntity    as Object        no-undo.
define variable lcEntity   as longchar      no-undo.
define variable oCreds     as Credentials   no-undo.
define variable cHttpUrl   as character     no-undo.
define variable oJsonBody  as JsonObject    no-undo.
define variable oJsonResp  as JsonObject    no-undo.
define variable oInstances as JsonArray     no-undo.
define variable oInstance  as JsonObject    no-undo.
define variable lFound     as logical       no-undo initial false.
define variable iLoop      as integer       no-undo.
define variable iStatus    as integer       no-undo.
define variable cInstUrl   as character     no-undo.
define variable cScheme    as character     no-undo.
define variable cHost      as character     no-undo.
define variable cPort      as character     no-undo.
define variable cUserId    as character     no-undo.
define variable cPassword  as character     no-undo.
define variable cAppName   as character     no-undo.
define variable cAction    as character     no-undo.

assign
    cScheme   = "http"
    cHost     = "localhost"
    cPort     = "9090"
    cUserId   = "pasmgr"
    cPassword = "s3cr3t"
    cAppName  = "SportsPASOE"
    cAction   = "status"
    .

if num-entries(session:parameter) ge 7 then
    assign
        cScheme   = entry(1, session:parameter)
        cHost     = entry(2, session:parameter)
        cPort     = entry(3, session:parameter)
        cUserId   = entry(4, session:parameter)
        cPassword = entry(5, session:parameter)
        cAppName  = entry(6, session:parameter)
        cAction   = entry(7, session:parameter)
        .
else if session:parameter ne "" then /* original method */
    assign cPort = session:parameter.


assign oCreds = new Credentials("PASOE Manager Application", cUserId, cPassword).
assign cHttpUrl = substitute("&1://&2:&3/oem/containers/localhost/pas", cScheme, cHost, cPort).

message substitute("Looking for '&1' as '&2' at &3", cAppName, cUserId, cHttpUrl).

oReq = RequestBuilder
        :Get(cHttpUrl)
        :UsingBasicAuthentication(oCreds)
        :Request.
oResp = HttpClient:Instance():Execute(oReq).
oEntity = oResp:Entity.

if type-of(oEntity, JsonObject) then
do:
    oJsonResp = cast(oEntity, JsonObject).
    oJsonResp:Write(input-output lcEntity, true).
    oInstances = oJsonResp:GetJsonArray("instances").
    if oInstances:Length eq 0 then
        message "No instances available".
    else
    do iLoop = 1 to oInstances:Length:
        oInstance = oInstances:GetJsonObject(iLoop).
        if oInstance:GetCharacter("key") eq substitute("&1:resource.openedge.pas.&2", cHost, cAppName) then
        do:
            assign
                lFound  = true
                iStatus = oInstance:GetJsonObject("status"):GetInteger("status")
                .

            if can-do("status,info", cAction) then
            do:
                cInstUrl = substitute("&1://&2:&3&4", cScheme, cHost, cPort, oInstance:GetCharacter("url")).
                oReq = RequestBuilder
                        :Get(cInstUrl)
                        :UsingBasicAuthentication(oCreds)
                        :Request.
                oResp = HttpClient:Instance():Execute(oReq).
                oEntity = oResp:Entity.
                oJsonResp = cast(oEntity, JsonObject).
                oInstance = oJsonResp:GetJsonObject("instance").
                message oInstance:GetCharacter("key") "is" string(oInstance:GetLogical("running"), "started/stopped").
            end.

            if can-do("start,run", cAction) then
            do:
                if iStatus ne 5 then do:
                    message substitute("Starting instance &1", oInstance:GetCharacter("url")).
                    oJsonBody = new JsonObject().
                    oJsonBody:Add("running", true).
                    oReq = RequestBuilder
                            :Put(substitute("&1/&2", cHttpUrl, oInstance:GetCharacter("key")), oJsonBody)
                            :ContentType("application/json")
                            :UsingBasicAuthentication(oCreds)
                            :Request.
                    oResp = HttpClient:Instance():Execute(oReq).
                    oEntity = oResp:Entity.
                    if type-of(oEntity, JsonObject) then
                        message "Command completed, check status of server manually.".
                end.
                else
                    message "Server not fully stopped, please wait a moment and try again.".
            end. /* Start */

            if can-do("stop,kill", cAction) then
            do:
                message substitute("Stopping instance &1", oInstance:GetCharacter("url")).
                oJsonBody = new JsonObject().
                oJsonBody:Add("running", false).
                oReq = RequestBuilder
                        :Put(substitute("&1/&2", cHttpUrl, oInstance:GetCharacter("key")), oJsonBody)
                        :ContentType("application/json")
                        :UsingBasicAuthentication(oCreds)
                        :Request.
                oResp = HttpClient:Instance():Execute(oReq).
                oEntity = oResp:Entity.
                if type-of(oEntity, JsonObject) then
                    message "Command completed, check status of server manually.".
            end. /* Stop */
        end. /* Matches App Name */
    end. /* iLoop */

    if not lFound then
        message substitute("Unable to find PAS instance '&1'", cAppName).
end. /* Valid Entity */
else do:
    if valid-object(oResp) then
        message substitute("Error executing oemanager request. [&1]", oResp:ToString()).
    else
        message "Undefined response".
end.

/* Return value expected by PCT Ant task. */
return string(0).
