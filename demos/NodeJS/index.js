/**
 * Provide service at a default port.
 */
var listen_port = 1337;

/**
 * Callback for HTTP requests
 * @param request
 * @param response
 * @returns void
 */
function onHttpRequest(request, response) {
    var parsedUrl = url.parse(request.url);
    var pathName = parsedUrl.pathname || "";
    var pathArray = pathName.split("/"); // Convert to array.
    var pathVal = (pathArray.length > 1) ? pathArray[1] : "";

    switch(request.method){
        case "GET":
            doGet(pathVal, request, response);
            break;
        case "POST":
            doPost(pathVal, request, response);
            break;
        default:
            // Unsupported HTTP method.
            response.writeHeader(405, "Method Not Allowed", {"Content-Type": "text/plain"});
            response.end();
    }
}

/**
 * Callback for GET requests
 * @param pathVal
 * @param request
 * @param response
 * @returns void
 */
function doGet(pathVal, request, response){
    var filename = null;

    switch(pathVal){
        case "test":
        case "test.html":
            // Serve the test HTML file on GET.
            filename = "/test.html";
            break;
        case "sample":
            var input = fs.createReadStream('5x5.json'); // Read sample data from file.
            response.writeHeader(200, "OK", {"Content-Type": "application/json", "Content-Encoding": "gzip"});
            input.pipe(zlib.createGzip()).pipe(response); // Output file data as gzip-compressed.
            break;
        default:
            // File not found for serving.
            response.writeHeader(404, "Not Found", {"Content-Type": "text/plain"});
            response.end();
    }

    if (filename) {
        fs.readFile(__dirname + filename, "utf8", function(error, content) {
            response.writeHeader(200, "OK", {"Content-Type": "text/html"});
            response.end(content);
        });
    }
}

/**
 * Callback for POST requests
 * @param pathVal
 * @param request
 * @param response
 * @returns void
 */
function doPost(pathVal, request, response){
    var sessionID = pathVal; // In this case the path value is a sessionID.
    var postData = ""; // Store the body data on POST.
    var count = 1;

    request.on("data", function(chunk){
        postData += chunk;
        if (postData.length > 1e6) {
            postData = ""; // Abort if data appears to be a [malicious] flood.
            response.writeHeader(413, {"Content-Type": "text/plain"}).end();
            request.connection.destroy();
        }
        count++;
    }); // on data

    request.on("end", function(){
        var responseBody = {response: "Broadcast Sent: " + sessionID};
        if (postData != "") {
            var jsonObj = null;
            try {
                jsonObj = JSON.parse(postData);
            } catch(parseErr) {
                responseBody = {response: "JSON Error: " + parseErr.message};
            }
            
            // Broadcast to all clients on socket server, based on sessionID.
            if (jsonObj) {
                sio.to(sessionID).emit("broadcast-data", jsonObj);
            }
        } // postData

        // End the response with a message.
        var responseJSON = JSON.stringify(responseBody);
        var responseHeaders = {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Content-Length": Buffer.byteLength(responseJSON)
        };
        response.writeHeader(200, "OK", responseHeaders);
        response.write(responseJSON);
        response.end();
    }); // on end
}

/**
 * Callback for socket connections
 * @param socket
 * @returns void
 */
function onSocketConnect(socket){
    /**
     * Handle requests to listen for broadcast consoles
     */
    socket.on("listen", function(sessionID, callback) {
        // If the sessionID looks legit, subscribe.
        if (sessionID && sessionID !== "") {
            socket.sessionID = sessionID; // Save sessionID on socket.
            socket.join(sessionID); // Join a "room" for sessionID.

            // Callback to the listener with a successful flag.
            callback(true);
        } else {
            // If the sessionID is not available, reject the request to listen.
            callback(false);
        }
    }); // on listen
}


/* ***** Server Startup ***** */

/**
 * Create an HTTP server to handle regular web requests.
 */
var http = require("http"); // HTTP server
var url = require("url"); // URL parser
var fs = require("fs"); // FileSystem
var zlib = require("zlib"); // Compression
var httpServer = http.createServer(onHttpRequest).listen(listen_port);
httpServer.on("connection", function(socket){
    socket.setTimeout(2000); // Allow a long enough window for getting data.
});

/**
 * Handle socket.io connections.
 */
var sio = require("socket.io")(httpServer);
sio.on("connection", onSocketConnect);
