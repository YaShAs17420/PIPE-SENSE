class Esp32Config {
  // Current ESP32 IP address on the Windows Mobile Hotspot
  static const String esp32Ip = '192.168.137.78';

  // ESP32 HTTP server
  static const String baseUrl = 'http://$esp32Ip';

  // Sensor data endpoint
  static const String dataEndpoint = '/data';

  static String get dataUrl => '$baseUrl$dataEndpoint';
}