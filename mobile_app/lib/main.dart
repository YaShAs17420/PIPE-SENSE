import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const PipeSenseApp());
}

class PipeSenseApp extends StatelessWidget {
  const PipeSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIPE-SENSE',
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
    );
  }
}