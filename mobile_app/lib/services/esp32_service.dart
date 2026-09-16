import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_data.dart';
import 'esp32_config.dart';
import 'leak_detection_service.dart';

class Esp32Service {
  static Future<SensorData?> getSensorData() async {
    try {
      // Cache-busting timestamp prevents the browser from
      // returning an old response.
      final String url =
          '${Esp32Config.dataUrl}?t=${DateTime.now().millisecondsSinceEpoch}';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) {
        return null;
      }

      final dynamic data = jsonDecode(response.body);

      final SensorData rawData = SensorData(
        yfFlowRate: (data['yfFlowRate'] ?? 0).toDouble(),
        zjFlowRate: (data['zjFlowRate'] ?? 0).toDouble(),
        vibration1: (data['vibration1'] ?? 0).toDouble(),
        vibration2: (data['vibration2'] ?? 0).toDouble(),
        leakDetected: false,
        leakZone: null,
      );

      // Flutter remains responsible for the final
      // leak detection and approximate zone decision.
      return LeakDetectionService.analyze(rawData);
    } catch (_) {
      return null;
    }
  }
}