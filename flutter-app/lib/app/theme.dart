// ============================================================
//  EcoRover App — Theme & Color Tokens
//  Matches dashboard.html V6 exactly
// ============================================================

import 'package:flutter/material.dart';

class EcoColors {
  EcoColors._();

  static const Color navy = Color(0xFF061039);
  static const Color blue = Color(0xFF079AF0);
  static const Color cyan = Color(0xFF16C4EC);
  static const Color green = Color(0xFF00C98A);
  static const Color red = Color(0xFFEF1E2B);
  static const Color purple = Color(0xFF754CF5);
  static const Color background = Color(0xFFF4FAFF);
  static const Color border = Color(0xFFDCE8F2);
  static const Color muted = Color(0xFF798AA7);
  static const Color dark = Color(0xFF22394E);
  static const Color cardBg = Colors.white;

  // Gradient stops
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF113D8A), Color(0xFF08A3EF)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00BD7D), Color(0xFF08DC98)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6848EC), Color(0xFF895CFF)],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [Color(0xFFDC1721), Color(0xFFF1282D), Color(0xFFD81720)],
  );

  // Drive button dark
  static const LinearGradient driveButtonDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF31485D), Color(0xFF1C3044)],
  );

  // Sensor colors
  static const Color sensorGood = Color(0xFF00B97A);
  static const Color sensorDanger = Color(0xFFED1723);

  // Online dot
  static const Color onlineDot = Color(0xFF00D99A);

  // Camera overlay bg
  static const Color cameraOverlay = Color(0xD612293F);
}

class EcoRadius {
  EcoRadius._();
  static const double card = 19;
  static const double innerCard = 16;
  static const double button = 15;
  static const double chip = 13;
  static const double small = 10;
  static const double tiny = 7;
}

class EcoShadows {
  EcoShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F1E5082),
      blurRadius: 18,
      offset: Offset(0, 5),
    ),
  ];

  static const List<BoxShadow> cameraCard = [
    BoxShadow(
      color: Color(0x1A1E5082),
      blurRadius: 22,
      offset: Offset(0, 7),
    ),
  ];
}

ThemeData buildEcoTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: EcoColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: EcoColors.blue,
      surface: EcoColors.background,
    ),
    fontFamily: 'Arial',
    appBarTheme: const AppBarTheme(
      backgroundColor: EcoColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: EcoColors.navy),
    ),
  );
}
