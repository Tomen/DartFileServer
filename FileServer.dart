// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library time_server;

import "dart:io";
import "dart:utf";

const HOST = "127.0.0.1";
const PORT = 8081;

const LOG_REQUESTS = true;

void main() {
  HttpServer server = new HttpServer();

  server.addRequestHandler((HttpRequest request) => true, requestReceivedHandler);

  server.listen(HOST, PORT);

  print("Serving the current time on http://${HOST}:${PORT}.");
}

void requestReceivedHandler(HttpRequest request, HttpResponse response) {
  if (LOG_REQUESTS) {
    print("Request: ${request.method} ${request.uri}");
  }
  
  var path = request.uri.substring(1, request.uri.length); //strip the slash
  
  var dir;
  if(path.length != 0)
  {
    dir = new Directory(path);
  }
  else
  {
    dir = new Directory.current();
  }
  
  List<String> subDirectories = new List<String>();
  List<String> files = new List<String>();
  
  DirectoryLister lister = dir.list(recursive:false); // Returns immediately.
  lister.onError = (e) => respondFile(path, response);
  lister.onFile = (String name) => subDirectories.add(name);
  lister.onDir = (String name) => files.add(name);
  lister.onDone = (bool completed){
    if(!completed)
    {
      return;
    }
    
    String htmlResponse = '<h1>Directory Listing</h1><br/><h2>Subdirectories</h2><br/>';
    for(String subDirectory in subDirectories)
    {
      htmlResponse.concat('<a href="${subDirectory}">${subDirectory}</a><br/>');
    }
    htmlResponse.concat('<h2>Files</h2><br/>');
    for(String file in files)
    {
      htmlResponse.concat('<a href="${file}">${file}</a><br/>');
    }
    List<int> encodedHtmlResponse = encodeUtf8(htmlResponse);
    response.headers.set(HttpHeaders.CONTENT_TYPE, "text/html; charset=UTF-8");
    response.contentLength = encodedHtmlResponse.length;
    response.outputStream.write(encodedHtmlResponse);
    response.outputStream.close();
  };
}

void respondFile(String path, HttpResponse response)
{
  var file = new File(path);
  Future readFile = file.readAsBytes();
  readFile.handleException((e) {
    print(e);
    send404(response);
    return true;
  });
  readFile.then((bytes){
    response.headers.set(HttpHeaders.CONTENT_TYPE, "text/html; charset=UTF-8");
    response.contentLength = bytes.length;
    response.outputStream.write(bytes);
    response.outputStream.close();
    return;
  });
}

void send404(HttpResponse response) {
  String htmlResponse = create404Response();
  List<int> encodedHtmlResponse = encodeUtf8(htmlResponse);

  response.headers.set(HttpHeaders.CONTENT_TYPE, "text/html; charset=UTF-8");
  response.contentLength = encodedHtmlResponse.length;
  response.statusCode = HttpStatus.NOT_FOUND;
  response.outputStream.write(encodedHtmlResponse);
  response.outputStream.close();
}

String create404Response() {
  return
'''
<html>
  <style>
    body { background-color: teal; }
    p { background-color: white; border-radius: 8px; border:solid 1px #555; text-align: center; padding: 0.5em;
        font-family: "Lucida Grande", Tahoma; font-size: 18px; color: #555; }
  </style>
  <body>
    <br/><br/>
    <p>you just got so 404'd</p>
  </body>
</html>
''';
}
