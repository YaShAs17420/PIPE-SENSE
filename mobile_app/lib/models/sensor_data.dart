class SensorData {
  final double yfFlowRate;
  final double zjFlowRate;
  final double vibration1;
  final double vibration2;
  final bool leakDetected;
  final String? leakZone;

  const SensorData({
    required this.yfFlowRate,
    required this.zjFlowRate,
    required this.vibration1,
    required this.vibration2,
    required this.leakDetected,
    this.leakZone,
  });
}