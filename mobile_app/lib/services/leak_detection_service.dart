import '../models/sensor_data.dart';

class LeakDetectionService {
  // --------------------------------------------------
  // FLOW THRESHOLD
  // --------------------------------------------------

  // Minimum difference between inlet and outlet flow
  // required before a leak is suspected.
  static const double flowDifferenceThreshold = 0.5;

  // --------------------------------------------------
  // VIBRATION THRESHOLD
  // --------------------------------------------------

  // Temporary software threshold.
  // This will be calibrated later using the real pipe
  // prototype and real MPU6050 measurements.
  static const double vibrationThreshold = 2.0;

  // --------------------------------------------------
  // THREE-ZONE CLASSIFICATION
  // --------------------------------------------------

  // The vibration ratio is:
  //
  // vibration1 / (vibration1 + vibration2)
  //
  // Near 1.0  -> closer to MPU #1 -> Zone 1
  // Near 0.5  -> between both MPUs -> Zone 2
  // Near 0.0  -> closer to MPU #2 -> Zone 3
  //
  // These are initial software boundaries and will be
  // calibrated with the physical prototype later.
  static const double zone1Boundary = 0.75;
  static const double zone3Boundary = 0.25;

  // --------------------------------------------------
  // MAIN ANALYSIS
  // --------------------------------------------------

  static SensorData analyze(SensorData data) {
    // Difference between the inlet flow and outlet flow.
    final double flowDifference =
        data.yfFlowRate - data.zjFlowRate;

    // --------------------------------------------------
    // STEP 1: FLOW CHECK
    // --------------------------------------------------

    // If both flow sensors report approximately the same
    // amount of water, there is no strong evidence of a
    // leak between them.
    if (flowDifference < flowDifferenceThreshold) {
      return _normal(data);
    }

    // --------------------------------------------------
    // STEP 2: READ VIBRATION
    // --------------------------------------------------

    final double vibration1 = data.vibration1;
    final double vibration2 = data.vibration2;

    final bool vibration1High =
        vibration1 >= vibrationThreshold;

    final bool vibration2High =
        vibration2 >= vibrationThreshold;

    // --------------------------------------------------
    // STEP 3: CHECK WHETHER WE HAVE ENOUGH
    // VIBRATION INFORMATION
    // --------------------------------------------------

    // A flow imbalance exists, but neither MPU has
    // detected meaningful vibration.
    //
    // Therefore:
    // Leak = YES
    // Zone  = NOT CONFIRMED
    if (!vibration1High && !vibration2High) {
      return _leakWithoutZone(data);
    }

    // --------------------------------------------------
    // STEP 4: CALCULATE VIBRATION RATIO
    // --------------------------------------------------

    final double totalVibration =
        vibration1 + vibration2;

    // Safety check.
    if (totalVibration <= 0) {
      return _leakWithoutZone(data);
    }

    final double vibrationRatio =
        vibration1 / totalVibration;

    // --------------------------------------------------
    // STEP 5: ZONE 1
    // --------------------------------------------------

    // MPU #1 is significantly stronger than MPU #2.
    //
    // Example:
    // MPU #1 = 3.6
    // MPU #2 = 0.8
    //
    // Ratio = 0.818
    // Result = Zone 1
    if (vibration1High &&
        vibrationRatio > zone1Boundary) {
      return _leakInZone(
        data,
        'Zone 1',
      );
    }

    // --------------------------------------------------
    // STEP 6: ZONE 3
    // --------------------------------------------------

    // MPU #2 is significantly stronger than MPU #1.
    //
    // Example:
    // MPU #1 = 1.2
    // MPU #2 = 3.8
    //
    // Ratio = 0.24
    // Result = Zone 3
    if (vibration2High &&
        vibrationRatio < zone3Boundary) {
      return _leakInZone(
        data,
        'Zone 3',
      );
    }

    // --------------------------------------------------
    // STEP 7: ZONE 2
    // --------------------------------------------------

    // Both MPUs detect meaningful vibration and neither
    // sensor is clearly dominant.
    //
    // Therefore the disturbance is approximately
    // between the two vibration reference points.
    if (vibration1High &&
        vibration2High) {
      return _leakInZone(
        data,
        'Zone 2',
      );
    }

    // --------------------------------------------------
    // STEP 8: FALLBACK
    // --------------------------------------------------

    // There is evidence of a leak, but the vibration
    // pattern is not strong enough to confidently assign
    // a zone.
    return _leakWithoutZone(data);
  }

  // --------------------------------------------------
  // NORMAL
  // --------------------------------------------------

  static SensorData _normal(
    SensorData data,
  ) {
    return SensorData(
      yfFlowRate: data.yfFlowRate,
      zjFlowRate: data.zjFlowRate,
      vibration1: data.vibration1,
      vibration2: data.vibration2,
      leakDetected: false,
      leakZone: null,
    );
  }

  // --------------------------------------------------
  // LEAK WITHOUT CONFIRMED ZONE
  // --------------------------------------------------

  static SensorData _leakWithoutZone(
    SensorData data,
  ) {
    return SensorData(
      yfFlowRate: data.yfFlowRate,
      zjFlowRate: data.zjFlowRate,
      vibration1: data.vibration1,
      vibration2: data.vibration2,
      leakDetected: true,
      leakZone: null,
    );
  }

  // --------------------------------------------------
  // LEAK WITH ZONE
  // --------------------------------------------------

  static SensorData _leakInZone(
    SensorData data,
    String zone,
  ) {
    return SensorData(
      yfFlowRate: data.yfFlowRate,
      zjFlowRate: data.zjFlowRate,
      vibration1: data.vibration1,
      vibration2: data.vibration2,
      leakDetected: true,
      leakZone: zone,
    );
  }
}