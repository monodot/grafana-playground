"""Backend that the EchoBackend business service calls.

Replies with the request it received, as JSON, so you can see exactly what OSB
sent: method, path, headers and body. Python standard library only, so there is
nothing to install and no image to build.
"""

import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8080


class EchoHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _echo(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length).decode("utf-8", "replace") if length else ""

        # Send X-Delay with a number of seconds to make this backend slow. OSB
        # forwards request headers, so you can set it on the call to the proxy
        # service. Useful for seeing latency in traces, and for holding a
        # request open long enough to take a thread dump.
        try:
            delay = float(self.headers.get("X-Delay") or 0)
        except ValueError:
            delay = 0
        if delay > 0:
            time.sleep(min(delay, 60))

        reply = json.dumps(
            {
                "method": self.command,
                "path": self.path,
                "headers": dict(self.headers),
                "body": body,
            },
            indent=2,
        ).encode()

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(reply)))
        self.end_headers()
        self.wfile.write(reply)

    do_GET = _echo
    do_POST = _echo
    do_PUT = _echo
    do_DELETE = _echo

    def log_message(self, fmt, *args):
        # One line per request, so `podman logs echo` shows the calls from OSB.
        print("%s - %s" % (self.address_string(), fmt % args), flush=True)


if __name__ == "__main__":
    print("echo backend listening on %d" % PORT, flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), EchoHandler).serve_forever()