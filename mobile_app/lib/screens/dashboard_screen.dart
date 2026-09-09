import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_data.dart';
import '../services/app_mode.dart';
import '../services/sensor_service.dart';
import '../widgets/three_scene_view_web.dart';
import '../widgets/three_scene_controller.dart';

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

    sensorData = SensorService.getSensorData();

    _sendSensorStateToThreeJs();

    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        await refreshSensorData();
      },
    );
  }

  Future<void> refreshSensorData() async {
    final data = await SensorService.getCurrentSensorData();

    if (!mounted || data == null) {
      return;
    }

    setState(() {
      sensorData = data;
    });

    _sendSensorStateToThreeJs();
  }

  void _sendSensorStateToThreeJs() {
    ThreeSceneController.updateSensorState(
      yfFlowRate: sensorData.yfFlowRate,
      zjFlowRate: sensorData.zjFlowRate,
      vibration1: sensorData.vibration1,
      vibration2: sensorData.vibration2,
      leakDetected: sensorData.leakDetected,
      leakZone: sensorData.leakZone,
    );
  }

  void changeMode(bool useEsp32) {
    if (useEsp32) {
      AppModeController.setMode(AppMode.esp32);
    } else {
      AppModeController.setMode(AppMode.simulation);
    }

    refreshSensorData();

    setState(() {});
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEsp32 = AppModeController.isEsp32;
    final bool leakDetected = sensorData.leakDetected;

    final String zone =
        sensorData.leakZone ?? 'Location unavailable';

    final double flowDifference =
        sensorData.yfFlowRate - sensorData.zjFlowRate;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isEsp32, leakDetected),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroSection(),

                    const SizedBox(height: 18),

                    // --------------------------------------------------
                    // 3D PIPE NETWORK
                    // --------------------------------------------------

                    Container(
                      height: 520,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEFE4),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 30,
                            spreadRadius: 0,
                            offset: const Offset(0, 12),
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: ThreeSceneView(),
                          ),

                          Positioned(
                            top: 22,
                            left: 22,
                            child: _pill(
                              icon: Icons.view_in_ar_rounded,
                              text: '3D PIPE NETWORK',
                            ),
                          ),

                          Positioned(
                            top: 22,
                            right: 22,
                            child: _pill(
                              icon: Icons.account_tree_rounded,
                              text: '3 ZONES',
                            ),
                          ),

                          Positioned(
                            left: 22,
                            bottom: 22,
                            child: _statusPill(leakDetected),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSensorCards(flowDifference),

                    const SizedBox(height: 24),

                    _buildAttentionCard(
                      leakDetected,
                      zone,
                      isEsp32,
                    ),

                    const SizedBox(height: 24),

                    _buildZoneSection(),

                    const SizedBox(height: 24),

                    _buildSystemInformation(),

                    const SizedBox(height: 24),

                    _buildRefreshButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildTopBar(
    bool isEsp32,
    bool leakDetected,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        18,
        24,
        8,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF10231A),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Color(0xFF6BE3AA),
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PIPE-SENSE',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF17231D),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'SMART WATER MONITORING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: Color(0xFF718078),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: leakDetected
                        ? const Color(0xFFFF4F6D)
                        : const Color(0xFF2DCB83),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  leakDetected ? 'ALERT' : 'LIVE',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Color(0xFF34423A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF17251D),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SIM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 5),
                Switch(
                  value: isEsp32,
                  onChanged: changeMode,
                  activeThumbColor: const Color(0xFF6BE3AA),
                  activeTrackColor: const Color(0xFF2C4B3B),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFF53625A),
                ),
                const SizedBox(width: 5),
                const Text(
                  'ESP32',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF10231A),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensorData.leakDetected
                      ? 'ATTENTION REQUIRED'
                      : 'EVERYTHING LOOKS GOOD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: sensorData.leakDetected
                        ? const Color(0xFFFF6C82)
                        : const Color(0xFF6BE3AA),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  sensorData.leakDetected
                      ? 'Leak detected in ${sensorData.leakZone ?? 'unknown zone'}'
                      : 'The pipeline is being monitored continuously.',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sensorData.leakDetected
                      ? 'Check the highlighted leak zone and sensor readings.'
                      : 'Flow and vibration sensors are reporting normal operation.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCards(double flowDifference) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 850;

        final List<Widget> cards = [
          _sensorCard(
            icon: Icons.water_drop_rounded,
            iconBackground: const Color(0xFFE0F4FB),
            iconColor: const Color(0xFF2BAEDB),
            title: 'FLOW',
            value:
                '${sensorData.yfFlowRate.toStringAsFixed(1)} L/min',
            subtitle: 'YF-S201 INLET',
          ),
          _sensorCard(
            icon: Icons.compare_arrows_rounded,
            iconBackground: const Color(0xFFECEEFF),
            iconColor: const Color(0xFF7284F4),
            title: 'FLOW BALANCE',
            value:
                '${flowDifference.clamp(0, double.infinity).toStringAsFixed(1)} L/min',
            subtitle: 'INLET VS OUTLET',
          ),
          _sensorCard(
            icon: Icons.graphic_eq_rounded,
            iconBackground: const Color(0xFFE1F7EC),
            iconColor: const Color(0xFF32C989),
            title: 'VIBRATION',
            value:
                '${sensorData.vibration1.toStringAsFixed(1)} / ${sensorData.vibration2.toStringAsFixed(1)}',
            subtitle: 'MPU6050 #1 / #2',
          ),
        ];

        if (compact) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 14),
              cards[1],
              const SizedBox(height: 14),
              cards[2],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 18),
            Expanded(child: cards[1]),
            const SizedBox(width: 18),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _sensorCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      height: 165,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 27,
            ),
          ),

          const SizedBox(width: 17),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF78857E),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18221D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF9AA59F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionCard(
    bool leakDetected,
    String zone,
    bool isEsp32,
  ) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF10231A),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leakDetected
                      ? 'ATTENTION REQUIRED'
                      : 'SYSTEM STATUS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: leakDetected
                        ? const Color(0xFFFF6C82)
                        : const Color(0xFF6BE3AA),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  leakDetected
                      ? zone
                      : 'Pipeline Normal',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  leakDetected
                      ? 'Check the highlighted leak zone and sensor readings.'
                      : 'The pipeline is being monitored continuously.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF26372F),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEsp32 ? 'ESP32' : 'SIMULATION',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEsp32
                        ? const Color(0xFF6BE3AA)
                        : const Color(0xFF8B98FF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LEAK ZONES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Color(0xFF77847D),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '3 monitored zones',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18221D),
            ),
          ),
          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 700;

              final List<Widget> zones = [
                _zoneCard(
                  'ZONE 1',
                  'MPU6050 #1',
                  sensorData.leakZone == 'Zone 1',
                ),
                _zoneCard(
                  'ZONE 2',
                  'MPU6050 #2',
                  sensorData.leakZone == 'Zone 2',
                ),
                _zoneCard(
                  'ZONE 3',
                  'MONITORED',
                  sensorData.leakZone == 'Zone 3',
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    zones[0],
                    const SizedBox(height: 12),
                    zones[1],
                    const SizedBox(height: 12),
                    zones[2],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: zones[0]),
                  const SizedBox(width: 12),
                  Expanded(child: zones[1]),
                  const SizedBox(width: 12),
                  Expanded(child: zones[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _zoneCard(
    String name,
    String sensor,
    bool active,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFFFEEF1)
            : const Color(0xFFF5F8F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? const Color(0xFFFF6C82)
              : const Color(0xFFE8EEE9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? const Color(0xFFFFD8DF)
                  : const Color(0xFFDDF5E8),
            ),
            child: Icon(
              active
                  ? Icons.warning_rounded
                  : Icons.check_rounded,
              color: active
                  ? const Color(0xFFFF4F6D)
                  : const Color(0xFF2DCB83),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sensor,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF87938C),
                  ),
                ),
              ],
            ),
          ),
          Text(
            active ? 'ALERT' : 'OK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: active
                  ? const Color(0xFFFF4F6D)
                  : const Color(0xFF2DCB83),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInformation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F3EB),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PIPE-SENSE SYSTEM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              color: Color(0xFF68766E),
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(
            Icons.water_drop_outlined,
            'YF-S201',
            'Inlet flow sensor',
          ),
          _infoRow(
            Icons.water_drop_outlined,
            'ZJ-S201',
            'Outlet flow sensor',
          ),
          _infoRow(
            Icons.graphic_eq_rounded,
            'MPU6050 #1 / #2',
            'Vibration monitoring',
          ),
          _infoRow(
            Icons.location_on_outlined,
            '3 zones',
            'Approximate leak localization',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFF2C8F65),
          ),
          const SizedBox(width: 13),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF78857E),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: refreshSensorData,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text(
          'REFRESH SENSOR DATA',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF17251D),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        14,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF10231A),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _navItem(
            Icons.home_rounded,
            'Home',
            true,
          ),
          _navItem(
            Icons.monitor_heart_rounded,
            'Monitor',
            false,
          ),
          _navItem(
            Icons.account_tree_rounded,
            'Zones',
            false,
          ),
          _navItem(
            Icons.settings_rounded,
            'Settings',
            false,
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool selected,
  ) {
    return Expanded(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6BE3AA)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? const Color(0xFF10231A)
                  : Colors.white60,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected
                    ? const Color(0xFF10231A)
                    : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF34443B),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF34443B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(bool leakDetected) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            leakDetected
                ? Icons.warning_rounded
                : Icons.check_circle_rounded,
            size: 19,
            color: leakDetected
                ? const Color(0xFFFF4F6D)
                : const Color(0xFF2DCB83),
          ),
          const SizedBox(width: 9),
          Text(
            leakDetected
                ? 'LEAK DETECTED'
                : 'SYSTEM NORMAL',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Color(0xFF27342D),
            ),
          ),
        ],
      ),
    );
  }
}