class SensorData {
  final double pressure;
  final double flowRate;
  final String vibration;
  final bool leakDetected;
  final double? leakLocation;

  const SensorData({
    required this.pressure,
    required this.flowRate,
    required this.vibration,
    required this.leakDetected,
    this.leakLocation,
  });
}