import base64
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.request import Request, urlopen

HOST = "0.0.0.0"
PORT = 8000
MODEL = "gemini-2.5-flash"


def call_gemini(payload):
    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        raise RuntimeError("GEMINI_API_KEY belum diset")
    request = Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={key}",
        data=json.dumps({
            "contents": [{"parts": [
                {"text": payload["prompt"]},
                {"inline_data": {
                    "mime_type": payload["mimeType"],
                    "data": payload["imageBase64"],
                }},
            ]}],
            "generationConfig": {
                "responseMimeType": "application/json",
                "temperature": 0.1,
            },
        }).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(request, timeout=90) as response:
        result = json.loads(response.read().decode())
    return result["candidates"][0]["content"]["parts"][0]["text"]


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/analyze":
            self.send_error(404)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length).decode())
            text = call_gemini(payload)
            body = json.dumps({"text": text}).encode()
            self.send_response(200)
        except Exception as error:
            body = json.dumps({"error": str(error)}).encode()
            self.send_response(500)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        print(format % args)


if __name__ == "__main__":
    print(f"ScaleUp AI server listening on http://127.0.0.1:{PORT}")
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
