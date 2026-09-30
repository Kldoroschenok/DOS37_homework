import json
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer

HOST = "0.0.0.0"
PORT = 8080


class RequestHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Quiet default logging; keep only essential info if needed
        pass

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_text(self, text, status=200, content_type="text/plain; charset=utf-8"):
        body = text.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?")[0]  # ignore query string

        if path == "/health":
            self.send_json({"status": "ok", "endpoint": "health"})
        elif path == "/":
            self.send_text("Hello from minimal Python HTTP server\n", content_type="text/plain; charset=utf-8")
        elif path == "/time":
            now = datetime.now(timezone.utc).isoformat()
            self.send_json({"now_utc": now, "endpoint": "time"})
        else:
            self.send_json({"error": "not found", "path": path}, status=404)


def main():
    server = HTTPServer((HOST, PORT), RequestHandler)
    print(f"Server listening on http://{HOST}:{PORT}")
    print("Endpoints:")
    print("  GET /health — health check")
    print("  GET /       — welcome text")
    print("  GET /time   — current UTC time")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
