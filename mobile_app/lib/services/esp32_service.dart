import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_data.dart';
import 'esp32_config.dart';
import 'leak_detection_service.dart';

class Esp32Service {
  static Future<SensorData?> getSensorData() async {
    try {
      final String url =
          '${Esp32Config.dataUrl}?t=${DateTime.now().millisecondsSinceEpoch}';

      print('PIPE-SENSE: Connecting to ESP32...');
      print('PIPE-SENSE: $url');

      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(
            const Duration(seconds: 3),
          );

      print(
        'PIPE-SENSE: ESP32 response status = ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        print(
          'PIPE-SENSE: ESP32 returned status ${response.statusCode}',
        );

        return null;
      }

      print(
        'PIPE-SENSE: ESP32 response = ${response.body}',
      );

      final dynamic data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        print('PIPE-SENSE: Invalid JSON format received.');

        return null;
      }

      // ------------------------------------------------------
      // READ SENSOR VALUES FROM ESP32
      // ------------------------------------------------------

      final double yfFlowRate =
          _toDouble(data['yfFlowRate']);

      final double zjFlowRate =
          _toDouble(data['zjFlowRate']);

      final double vibration1 =
          _toDouble(data['vibration1']);

      final double vibration2 =
          _toDouble(data['vibration2']);

      // ------------------------------------------------------
      // CREATE RAW SENSOR DATA
      // ------------------------------------------------------

      final SensorData rawData = SensorData(
        yfFlowRate: yfFlowRate,
        zjFlowRate: zjFlowRate,
        vibration1: vibration1,
        vibration2: vibration2,
        leakDetected: false,
        leakZone: null,
      );

      // ------------------------------------------------------
      // RUN LEAK DETECTION
      // ------------------------------------------------------

      final SensorData processedData =
          LeakDetectionService.analyze(rawData);

      print(
        'PIPE-SENSE: '
        'YF=${processedData.yfFlowRate.toStringAsFixed(2)} L/min | '
        'ZJ=${processedData.zjFlowRate.toStringAsFixed(2)} L/min | '
        'V1=${processedData.vibration1.toStringAsFixed(2)} | '
        'V2=${processedData.vibration2.toStringAsFixed(2)} | '
        'Leak=${processedData.leakDetected} | '
        'Zone=${processedData.leakZone ?? "None"}',
      );

      return processedData;
    } catch (e) {
      print(
        'PIPE-SENSE: ESP32 connection error: $e',
      );

      return null;
    }
  }

  // ----------------------------------------------------------
  // SAFE NUMBER CONVERSION
  // ----------------------------------------------------------

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0.0;
  }
}