import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_data.dart';
import '../services/sensor_service.dart';
import '../services/app_mode.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late SensorData sensorData;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    // Start with simulation data
    sensorData = SensorService.getSensorData();

    // Update sensor data every 5 seconds
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        final data = await SensorService.getCurrentSensorData();

        if (mounted && data != null) {
          setState(() {
            sensorData = data;
          });
        }
      },
    );
  }

  Future<void> refreshSensorData() async {
    final data = await SensorService.getCurrentSensorData();

    if (mounted && data != null) {
      setState(() {
        sensorData = data;
      });
    }
  }

  void changeMode(bool useEsp32) {
    setState(() {
      if (useEsp32) {
        AppModeController.setMode(AppMode.esp32);
      } else {
        AppModeController.setMode(AppMode.simulation);
      }
    });

    refreshSensorData();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEsp32 = AppModeController.isEsp32;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PIPE-SENSE'),
      ),

      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [

              const SizedBox(height: 40),

              const Text(
                'Hidden Water Pipe Leak Detection',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              // SYSTEM STATUS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Text(
                        'System Status',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        '● System Ready',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        isEsp32
                            ? 'ESP32 mode'
                            : 'Simulation mode',
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // MODE SWITCH
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Simulation',
                            style: TextStyle(fontSize: 16),
                          ),

                          Switch(
                            value: isEsp32,
                            onChanged: changeMode,
                          ),

                          const Text(
                            'ESP32',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // LEAK STATUS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Text(
                        'Leak Status',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        sensorData.leakDetected
                            ? '⚠ LEAK DETECTED'
                            : '● No Leak Detected',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: sensorData.leakDetected
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        sensorData.leakDetected
                            ? 'Possible leak detected'
                            : 'Monitoring pipe continuously',
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // SENSOR READINGS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Text(
                        'Sensor Readings',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        'Pressure: ${sensorData.pressure} bar',
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Flow Rate: ${sensorData.flowRate} L/min',
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Vibration: ${sensorData.vibration}',
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // APPROXIMATE LEAK LOCATION
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Text(
                        'Approximate Leak Location',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        sensorData.leakLocation != null
                            ? 'Approx. ${sensorData.leakLocation} meters'
                            : 'Location not available',
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        sensorData.leakLocation != null
                            ? 'Leak location estimated'
                            : 'Waiting for sensor data',
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // REFRESH BUTTON
              ElevatedButton(
                onPressed: refreshSensorData,
                child: const Text(
                  'REFRESH SENSOR DATA',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}