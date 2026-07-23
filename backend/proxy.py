#!/usr/bin/env python3
"""
Simple DeepSeek proxy for Android emulator.
Emulator calls 10.0.2.2:8765 -> this server -> api.deepseek.com
"""
import json
import urllib.request
import urllib.error
from http.server import HTTPServer, BaseHTTPRequestHandler

DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions"

class ProxyHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        
        auth_header = self.headers.get('Authorization', '')
        
        try:
            req = urllib.request.Request(
                DEEPSEEK_URL,
                data=body,
                headers={
                    'Content-Type': 'application/json',
                    'Authorization': auth_header,
                }
            )
            with urllib.request.urlopen(req, timeout=30) as resp:
                response_body = resp.read()
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(response_body)
                print(f"[OK] Forwarded request, response: {len(response_body)} bytes")
        except urllib.error.HTTPError as e:
            error_body = e.read()
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(error_body)
            print(f"[ERROR] HTTP {e.code}: {error_body[:200]}")
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())
            print(f"[ERROR] {e}")

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress default logging

if __name__ == '__main__':
    port = 8765
    server = HTTPServer(('0.0.0.0', port), ProxyHandler)
    print(f"DeepSeek proxy running on port {port}")
    print(f"Android emulator should call: http://10.0.2.2:{port}/v1/chat/completions")
    server.serve_forever()
