// ============================================================
//  EcoRover App — Root App Widget
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';
import '../screens/splash_screen.dart';
import '../screens/controller_screen.dart';

class EcoRoverApp extends StatefulWidget {
  const EcoRoverApp({super.key});

  @override
  State<EcoRoverApp> createState() => _EcoRoverAppState();
}

class _EcoRoverAppState extends State<EcoRoverApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Set status bar to light (white icons) on dark background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    // Portrait only
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoRover',
      debugShowCheckedModeBanner: false,
      theme: buildEcoTheme(),
      home: _showSplash
          ? SplashScreen(
              onComplete: () => setState(() => _showSplash = false),
            )
          : const ControllerScreen(),
    );
  }
}
