import 'dart:math';

import '../models/sensor_data.dart';
import 'app_mode.dart';
import 'esp32_service.dart';
import 'leak_detection_service.dart';

class SensorService {
  static final Random _random = Random();

  static SensorData getSensorData() {
    // Randomly select a test condition.
    //
    // 0 = Normal
    // 1 = Normal
    // 2 = Zone 1 leak
    // 3 = Zone 2 leak
    final int testCase = _random.nextInt(4);

    double yfFlowRate;
    double zjFlowRate;
    double vibration1;
    double vibration2;

    if (testCase == 2) {
      // ZONE 1 LEAK
      yfFlowRate = 2.5 + _random.nextDouble() * 0.5;
      zjFlowRate = 0.8 + _random.nextDouble() * 0.3;

      vibration1 = 3.0 + _random.nextDouble() * 2.0;
      vibration2 = 0.5 + _random.nextDouble() * 0.8;
    } else if (testCase == 3) {
      // ZONE 2 LEAK
      yfFlowRate = 2.5 + _random.nextDouble() * 0.5;
      zjFlowRate = 0.8 + _random.nextDouble() * 0.3;

      vibration1 = 0.5 + _random.nextDouble() * 0.8;
      vibration2 = 3.0 + _random.nextDouble() * 2.0;
    } else {
      // NORMAL CONDITION
      yfFlowRate = 0.9 + _random.nextDouble() * 0.5;
      zjFlowRate = 0.9 + _random.nextDouble() * 0.4;

      vibration1 = 0.5 + _random.nextDouble() * 0.8;
      vibration2 = 0.5 + _random.nextDouble() * 0.8;
    }

    final SensorData rawData = SensorData(
      yfFlowRate: yfFlowRate,
      zjFlowRate: zjFlowRate,
      vibration1: vibration1,
      vibration2: vibration2,
      leakDetected: false,
      leakZone: null,
    );

    // Send the simulated sensor readings through
    // the same detection logic that will later be
    // used with the real ESP32.
    return LeakDetectionService.analyze(rawData);
  }

  static Future<SensorData?> getCurrentSensorData() async {
    if (AppModeController.isSimulation) {
      return getSensorData();
    }

    return await Esp32Service.getSensorData();
  }
}