/**
 * Deletes (trims) all running agents from PASOE instance.
 * Usage: trimAgents.p <params>
 *  Parameter Default/Allowed
 *   Scheme   [http|https]
 *   Hostname [localhost]
 *   PAS Port [8820]
 *   UserId   [tomcat]
 *   Password [tomcat]
 *   ABL App  [SportsPASOE]
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

define variable oReq      as IHttpRequest  no-undo.
define variable oResp     as IHttpResponse no-undo.
define variable oEntity   as Object        no-undo.
define variable lcEntity  as longchar      no-undo.
define variable oCreds    as Credentials   no-undo.
define variable cHttpUrl  as character     no-undo.
define variable oJsonResp as JsonObject    no-undo.
define variable oAgents   as JsonArray     no-undo.
define variable oAgent    as JsonObject    no-undo.
define variable iLoop     as integer       no-undo.
define variable cScheme   as character     no-undo.
define variable cHost     as character     no-undo.
define variable cPort     as character     no-undo.
define variable cUserId   as character     no-undo.
define variable cPassword as character     no-undo.
define variable cAblApp   as character     no-undo.

assign
    cScheme   = "http"
    cHost     = "localhost"
    cPort     = "8820"
    cUserId   = "tomcat"
    cPassword = "tomcat"
    cAblApp   = "SportsPASOE"
    .

if num-entries(session:parameter) ge 6 then
    assign
        cScheme   = entry(1, session:parameter)
        cHost     = entry(2, session:parameter)
        cPort     = entry(3, session:parameter)
        cUserId   = entry(4, session:parameter)
        cPassword = entry(5, session:parameter)
        cAblApp   = entry(6, session:parameter)
        .
else if session:parameter ne "" then /* original method */
    assign cPort = session:parameter.

assign oCreds = new Credentials("PASOE Manager Application", cUserId, cPassword).
assign cHttpUrl = substitute("&1://&2:&3/oemanager/applications/&4/agents", cScheme, cHost, cPort, cAblApp).

message substitute("Looking for agents at &1", cHttpUrl).

oReq = RequestBuilder
        :Get(cHttpUrl)
        :ContentType("application/vnd.progress+json")
        :UsingBasicAuthentication(oCreds)
        :Request.
oResp = HttpClient:Instance():Execute(oReq).
oEntity = oResp:Entity.

if type-of(oEntity, JsonObject) then
do:
    oJsonResp = cast(oEntity, JsonObject).
    oJsonResp:Write(input-output lcEntity, true).
    oAgents = oJsonResp:GetJsonObject("result"):GetJsonArray("agents").
    if oAgents:Length eq 0 then
        message "No agents running".
    else
    do iLoop = 1 to oAgents:Length:
        oAgent = oAgents:GetJsonObject(iLoop).
        message substitute("Trimming agent &1", oAgent:GetCharacter("agentId")).
        oReq = RequestBuilder
            :Delete(substitute("&1/&2", cHttpUrl, oAgent:GetCharacter("agentId")))
            :ContentType("application/vnd.progress+json")
            :UsingBasicAuthentication(oCreds)
            :Request.
        oResp = HttpClient:Instance():Execute(oReq).
        oEntity = oResp:Entity.
        if type-of(oEntity, JsonObject) then
        do:
            lcEntity = "".
            cast(oEntity, JsonObject):Write(input-output lcEntity, true).
            message string(lcEntity).
        end.
    end. /* iLoop */
end. /* Valid Entity */
else do:
    if valid-object(oResp) then
        message substitute("Error executing oemanager request. [&1]", oResp:ToString()).
    else
        message "Undefined response".
end.

/* Return value expected by PCT Ant task. */
return string(0).

