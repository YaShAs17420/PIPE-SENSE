import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/sensor_data.dart';

class Esp32Service {
  // We will replace this with the actual ESP32 address later.
  static const String esp32Url = 'http://192.168.4.1/data';

  static Future<SensorData?> getSensorData() async {
    try {
      final response = await http
          .get(Uri.parse(esp32Url))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return SensorData(
          pressure: (data['pressure'] ?? 0).toDouble(),
          flowRate: (data['flowRate'] ?? 0).toDouble(),
          vibration: data['vibration'] ?? 'Normal',
          leakDetected: data['leakDetected'] ?? false,
          leakLocation: data['leakLocation'] != null
              ? (data['leakLocation']).toDouble()
              : null,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}