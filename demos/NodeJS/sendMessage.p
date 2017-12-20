/*------------------------------------------------------------------------
    File        : sendMessage.p
    Purpose     : Sample code for sending a message to Node.js via HTTP.
    Description : POST's a JSON object to a server on port 1337.
    Created     : Mon Dec 14 13:40:57 EST 2015
  ----------------------------------------------------------------------*/

&GLOBAL-DEFINE SESSION_ID "61CAA69BCC844F9751837789DB36D2DD"

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using OpenEdge.Net.HTTP.ClientBuilder.
using OpenEdge.Net.HTTP.IHttpClient.
using OpenEdge.Net.HTTP.IHttpRequest.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Net.HTTP.RequestBuilder.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.

/* ********************  Preprocessor Definitions  ******************** */
define variable messageArray as JsonArray     no-undo.
define variable jsonRequest  as JsonObject    no-undo.
define variable jsonResponse as JsonObject    no-undo.
define variable messageObj   as JsonObject    no-undo.
define variable oReq         as IHttpRequest  no-undo.
define variable oResp        as IHttpResponse no-undo.
define variable oClient      as IHttpClient   no-undo.

/* ***************************  Main Block  *************************** */
assign
    messageObj   = new JsonObject()
    messageArray = new JsonArray()
    jsonRequest  = new JsonObject()
    .

/* Build a common JSON data packet for this contact. */
messageObj:Add(input "messageType", input "info").
messageObj:Add(input "messageText", input "This is a test from OpenEdge.").
messageArray:Add(messageObj).
jsonRequest:Add(input "messages", input messageArray).

/* Construct the message to send via POST. */
assign oReq = RequestBuilder:Post(substitute("http://localhost:1337/&1", {&SESSION_ID}), jsonRequest):Request.

/* Send to server. */
assign oClient = ClientBuilder:Build():Client.
assign oResp = oClient:execute(oReq).

/* Parse the response. */
assign jsonResponse = cast(oResp:Entity, JsonObject).
message oResp:statusCode view-as alert-box.