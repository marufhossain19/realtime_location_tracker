import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'real_time_location_tracker_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const RealTimeLocationTrackerApp());
}

class RealTimeLocationTrackerApp extends StatelessWidget {
  const RealTimeLocationTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Location Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
        ),
        useMaterial3: true,
      ),
      home: const RealTimeLocationTrackerScreen(),
    );
  }
}

