import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/sensor_data.dart';
import 'leak_detection_service.dart';

class Esp32Service {
  // Mock ESP32 server address.
  static const String esp32Url = 'http://127.0.0.1:5000/data';

  static Future<SensorData?> getSensorData() async {
    try {
      // Add a timestamp so the browser does not reuse
      // an old cached response.
      final String url = '$esp32Url?t=${DateTime.now().millisecondsSinceEpoch}';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final SensorData rawData = SensorData(
          yfFlowRate: (data['yfFlowRate'] ?? 0).toDouble(),
          zjFlowRate: (data['zjFlowRate'] ?? 0).toDouble(),
          vibration1: (data['vibration1'] ?? 0).toDouble(),
          vibration2: (data['vibration2'] ?? 0).toDouble(),
          leakDetected: false,
          leakZone: null,
        );

        return LeakDetectionService.analyze(rawData);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}