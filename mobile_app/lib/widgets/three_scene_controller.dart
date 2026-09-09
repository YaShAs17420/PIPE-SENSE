import 'dart:js_interop';

@JS('pipeSense3D.updateSensorState')
external void _updateSensorState(
  double yfFlowRate,
  double zjFlowRate,
  double vibration1,
  double vibration2,
  bool leakDetected,
  String? leakZone,
);

class ThreeSceneController {
  static void updateSensorState({
    required double yfFlowRate,
    required double zjFlowRate,
    required double vibration1,
    required double vibration2,
    required bool leakDetected,
    String? leakZone,
  }) {
    try {
      _updateSensorState(
        yfFlowRate,
        zjFlowRate,
        vibration1,
        vibration2,
        leakDetected,
        leakZone,
      );
    } catch (_) {
      // The Three.js scene may not have finished loading yet.
      // The dashboard itself should continue working normally.
    }
  }
}