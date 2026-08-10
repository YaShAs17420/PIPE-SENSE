from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import random

# Change this to test different conditions:
# "normal"
# "leak"
# "location"

TEST_MODE = "location"


class MockESP32Handler(BaseHTTPRequestHandler):

    def do_GET(self):

        if self.path == "/data":

            if TEST_MODE == "normal":

                data = {
                    "pressure": round(random.uniform(2.3, 3.0), 2),
                    "flowRate": round(random.uniform(0.8, 1.5), 2),
                    "vibration": "Normal",
                    "leakDetected": False,
                    "leakLocation": None
                }

            elif TEST_MODE == "leak":

                data = {
                    "pressure": round(random.uniform(1.2, 1.9), 2),
                    "flowRate": round(random.uniform(2.0, 2.8), 2),
                    "vibration": "High",
                    "leakDetected": True,
                    "leakLocation": None
                }

            elif TEST_MODE == "location":

                data = {
                    "pressure": round(random.uniform(1.2, 1.9), 2),
                    "flowRate": round(random.uniform(2.0, 2.8), 2),
                    "vibration": "High",
                    "leakDetected": True,
                    "leakLocation": round(random.uniform(5.0, 20.0), 2)
                }

            else:

                data = {
                    "pressure": 2.5,
                    "flowRate": 1.2,
                    "vibration": "Normal",
                    "leakDetected": False,
                    "leakLocation": None
                }

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()

            self.wfile.write(json.dumps(data).encode())

            print("Sensor data:", data)

        else:

            self.send_response(404)
            self.end_headers()


server = HTTPServer(("127.0.0.1", 5000), MockESP32Handler)

print("Mock ESP32 server running...")
print("Open: http://127.0.0.1:5000/data")
print("Current test mode:", TEST_MODE)

server.serve_forever()