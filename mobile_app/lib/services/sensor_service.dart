import '../models/sensor_data.dart';
import 'app_mode.dart';
import 'esp32_service.dart';

class SensorService {
  static SensorData getSensorData() {
    return const SensorData(
      pressure: 2.5,
      flowRate: 1.2,
      vibration: 'Normal',
      leakDetected: false,
      leakLocation: null,
    );
  }

  static Future<SensorData?> getCurrentSensorData() async {
    if (AppModeController.isSimulation) {
      return getSensorData();
    }

    return await Esp32Service.getSensorData();
  }
}