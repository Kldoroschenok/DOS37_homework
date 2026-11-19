import logging
from http.server import BaseHTTPRequestHandler, HTTPServer

logger = logging.getLogger("RequestLogger")
logger.setLevel(logging.DEBUG)
file_handler = logging.FileHandler("logs/payment.log")
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

SERVICE = "plant-shop"
PART = "payment"
SERVICE_TAG = f"{SERVICE}:{PART}"

class RequestHandler(BaseHTTPRequestHandler):
    def log_request_info(self, level, method, body=None):
        client_ip = self.client_address[0]
        msg = f"[{SERVICE_TAG}] {method} request for path: {self.path} from IP: {client_ip}"
        if body:
            msg += f" with body: {body}"
        # Логирование с нужным уровнем severity
        if level == "info":
            logger.info(msg)
        elif level == "warning":
            logger.warning(msg)
        elif level == "error":
            logger.error(msg)
        elif level == "critical":
            logger.critical(msg)
        else:
            logger.debug(msg)

    def do_GET(self):
        self.log_request_info("info", "GET")
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b"GET request logged")

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_body = self.rfile.read(content_length).decode('utf-8') if content_length > 0 else ''
        self.log_request_info("info", "POST", post_body)
        self.send_response(201)  # Created
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b"POST request logged and resource created")

    def do_PUT(self):
        content_length = int(self.headers.get('Content-Length', 0))
        put_body = self.rfile.read(content_length).decode('utf-8') if content_length > 0 else ''
        self.log_request_info("warning", "PUT", put_body)
        self.send_response(200)  # OK, resource updated
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b"PUT request logged and resource updated")

    def do_DELETE(self):
        self.log_request_info("error", "DELETE")
        self.send_response(405)  # Method Not Allowed
        self.send_header('Allow', 'GET, POST, PUT')
        self.end_headers()

def run(server_class=HTTPServer, handler_class=RequestHandler, port=8080):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f'Server running on port {port}...')
    httpd.serve_forever()

if __name__ == "__main__":
    run()
