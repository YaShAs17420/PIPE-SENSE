class Esp32Config {
  // --------------------------------------------------
  // CURRENTLY: Mock ESP32 server running on this PC
  // --------------------------------------------------
  static const String baseUrl = 'http://127.0.0.1:5000';

  // --------------------------------------------------
  // TOMORROW: Real ESP32
  // Example:
  //
  // static const String baseUrl = 'http://192.168.4.1';
  //
  // --------------------------------------------------

  static const String dataEndpoint = '/data';

  static String get dataUrl => '$baseUrl$dataEndpoint';
}