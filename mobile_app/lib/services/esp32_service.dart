
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/sensor_data.dart';
import 'esp32_config.dart';

enum Esp32ConnectionStatus {
  connecting,
  connected,
  disconnected,
}

class Esp32Service {
  static Esp32ConnectionStatus _connectionStatus =
      Esp32ConnectionStatus.disconnected;

  static Esp32ConnectionStatus get connectionStatus =>
      _connectionStatus;

  static bool get isConnected =>
      _connectionStatus == Esp32ConnectionStatus.connected;

  static bool get isConnecting =>
      _connectionStatus == Esp32ConnectionStatus.connecting;

  static const int _failuresBeforeDisconnect = 3;
  static const Duration _requestTimeout = Duration(seconds: 3);

  static int _consecutiveFailures = 0;
  static Future<SensorData?>? _inFlightRequest;

  static Future<SensorData?> getSensorData() {
    final existingRequest = _inFlightRequest;

    if (existingRequest != null) {
      return existingRequest;
    }

    final request = _fetchSensorData();
    _inFlightRequest = request;

    return request.whenComplete(() {
      if (identical(_inFlightRequest, request)) {
        _inFlightRequest = null;
      }
    });
  }

  static Future<SensorData?> _fetchSensorData() async {
    if (_connectionStatus != Esp32ConnectionStatus.connected) {
      _connectionStatus = Esp32ConnectionStatus.connecting;
    }

    try {
      final uri = Uri.parse(Esp32Config.dataUrl).replace(
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      debugPrint(
        'PIPE-SENSE: Requesting ESP32 sensor data: $uri',
      );

      // Avoid custom headers that may trigger browser CORS preflight.
      final response = await http.get(uri).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        return _recordFailure(
          'HTTP status ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return _recordFailure('Invalid JSON response');
      }

      final double? yfFlowRate =
          _tryToDouble(decoded['yfFlowRate']);
      final double? zjFlowRate =
          _tryToDouble(decoded['zjFlowRate']);
      final double? vibration1 =
          _tryToDouble(decoded['vibration1']);
      final double? vibration2 =
          _tryToDouble(decoded['vibration2']);

      if (yfFlowRate == null ||
          zjFlowRate == null ||
          vibration1 == null ||
          vibration2 == null) {
        return _recordFailure(
          'Missing or invalid sensor values',
        );
      }

      // The ESP32 firmware is the source of truth for leak detection.
      // Do not run LeakDetectionService.analyze() on hardware readings.
      final bool? leakDetected =
          _tryToBool(decoded['leakDetected']);

      final dynamic rawZone = decoded['leakZone'];
      final String? leakZone = rawZone is String &&
              rawZone.trim().isNotEmpty &&
              rawZone.toUpperCase() != 'NONE'
          ? rawZone.trim()
          : null;

      if (leakDetected == null) {
        return _recordFailure(
          'Missing or invalid leakDetected value from ESP32',
        );
      }

      if (leakDetected && leakZone == null) {
        return _recordFailure(
          'ESP32 reports a leak but no leak zone',
        );
      }

      final sensorData = SensorData(
        yfFlowRate: yfFlowRate,
        zjFlowRate: zjFlowRate,
        vibration1: vibration1,
        vibration2: vibration2,
        leakDetected: leakDetected,
        leakZone: leakDetected ? leakZone : null,
      );

      _consecutiveFailures = 0;
      _connectionStatus = Esp32ConnectionStatus.connected;

      debugPrint(
        'PIPE-SENSE: ESP32 connected | '
        'YF=${yfFlowRate.toStringAsFixed(2)} L/min | '
        'ZJ=${zjFlowRate.toStringAsFixed(2)} L/min | '
        'V1=${vibration1.toStringAsFixed(4)} | '
        'V2=${vibration2.toStringAsFixed(4)} | '
        'Leak=$leakDetected | '
        'Zone=${leakZone ?? "NONE"}',
      );

      return sensorData;
    } catch (error) {
      return _recordFailure('Request failed: $error');
    }
  }

  static SensorData? _recordFailure(String reason) {
    _consecutiveFailures++;

    debugPrint(
      'PIPE-SENSE: $reason '
      '($_consecutiveFailures/$_failuresBeforeDisconnect failures)',
    );

    if (_consecutiveFailures >= _failuresBeforeDisconnect) {
      _connectionStatus = Esp32ConnectionStatus.disconnected;
    } else if (_connectionStatus !=
        Esp32ConnectionStatus.connected) {
      _connectionStatus = Esp32ConnectionStatus.connecting;
    }

    return null;
  }

  static double? _tryToDouble(dynamic value) {
    if (value is num) {
      final result = value.toDouble();
      return result.isFinite ? result : null;
    }

    if (value is String) {
      final result = double.tryParse(value);

      if (result != null && result.isFinite) {
        return result;
      }
    }

    return null;
  }

  static bool? _tryToBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      if (value == 1) return true;
      if (value == 0) return false;
    }

    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;
        case 'false':
        case '0':
          return false;
      }
    }

    return null;
  }
}
