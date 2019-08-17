#!/usr/bin/env python

# Credits: https://pythonbasics.org/webserver/

from http.server import BaseHTTPRequestHandler, HTTPServer

hostName = "0.0.0.0"
serverPort = 8080
staticFile = "/var/www/index.html"


class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()

        with open(staticFile, 'r') as content_file:
                content = content_file.read()
        self.wfile.write(bytes(content, "utf-8"))

if __name__ == "__main__":
    httpd = HTTPServer((hostName, serverPort), SimpleHTTPRequestHandler)
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass

    httpd.server_close()
    print("Server stopped.")
