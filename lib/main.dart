import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:seller_ewaste/features/splash/splash_screen.dart';
import 'package:device_preview/device_preview.dart';

import 'options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // DevicePreview can prevent video_player from working on desktop.
  // Set to true only when previewing layouts (not for video testing).
  const useDevicePreview = false;

  runApp(
    DevicePreview(
      enabled: useDevicePreview,
      builder: (context) => const ReCircleSellApp(),
    ),
  );
}

class ReCircleSellApp extends StatelessWidget {
  const ReCircleSellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReCircle Sell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
