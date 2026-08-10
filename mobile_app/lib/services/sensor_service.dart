import 'dart:math';

import '../models/sensor_data.dart';
import 'app_mode.dart';
import 'esp32_service.dart';

class SensorService {
  static final Random _random = Random();

  static SensorData getSensorData() {
    // Randomly decide whether the system is in a normal
    // condition or a leak condition.
    final bool leakDetected = _random.nextInt(4) == 0;

    double pressure;
    double flowRate;
    String vibration;
    double? leakLocation;

    if (leakDetected) {
      // LEAK CONDITION
      pressure = 1.5 + _random.nextDouble() * 0.7;
      flowRate = 1.8 + _random.nextDouble() * 1.0;
      vibration = 'High';

      // Simulated approximate leak position
      leakLocation = 5.0 + _random.nextDouble() * 15.0;
    } else {
      // NORMAL CONDITION
      pressure = 2.2 + _random.nextDouble() * 0.8;
      flowRate = 0.8 + _random.nextDouble() * 0.6;

      // Mostly normal, sometimes moderate
      final bool moderateVibration = _random.nextInt(4) == 0;

      vibration = moderateVibration ? 'Moderate' : 'Normal';

      leakLocation = null;
    }

    return SensorData(
      pressure: pressure,
      flowRate: flowRate,
      vibration: vibration,
      leakDetected: leakDetected,
      leakLocation: leakLocation,
    );
  }

  static Future<SensorData?> getCurrentSensorData() async {
    if (AppModeController.isSimulation) {
      return getSensorData();
    }

    return await Esp32Service.getSensorData();
  }
}