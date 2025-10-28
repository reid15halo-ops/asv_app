import 'package:flutter/material.dart';
import 'package:asv_app/models/member_group.dart';

// Standard Themes (Aktive)
final lightScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0B0B0B), brightness: Brightness.light);
final darkScheme  = ColorScheme.fromSeed(seedColor: const Color(0xFF0B0B0B), brightness: Brightness.dark);

// Jugend Themes - Moderne, lebhafte Farben mit starkem Kontrast
final jugendLightScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF00BCD4), // Cyan/Türkis
  brightness: Brightness.light,
).copyWith(
  primary: const Color(0xFF00BCD4),
  secondary: const Color(0xFFFF4081), // Pink Accent
  tertiary: const Color(0xFF7C4DFF), // Lila
  surface: const Color(0xFFF5F5F5),
  background: const Color(0xFFE0F7FA), // Leichter Cyan-Hintergrund
);

final jugendDarkScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF00BCD4),
  brightness: Brightness.dark,
).copyWith(
  primary: const Color(0xFF00E5FF), // Helleres Cyan für Dark Mode
  secondary: const Color(0xFFFF4081),
  tertiary: const Color(0xFF7C4DFF),
  surface: const Color(0xFF1A1A1A),
  background: const Color(0xFF0D1117), // Dunkler, moderner Hintergrund
);

// Jugend-spezifische Farbverläufe
class JugendGradients {
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF00BCD4), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFF4081), Color(0xFFFF80AB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const purpleGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const successGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Senioren Themes - Ruhige, warme Farben
final seniorenLightScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF8D6E63), // Warmes Braun
  brightness: Brightness.light,
);
final seniorenDarkScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF8D6E63),
  brightness: Brightness.dark,
);

ThemeData buildLightTheme([MemberGroup? group]) {
  ColorScheme scheme;
  switch (group) {
    case MemberGroup.jugend:
      scheme = jugendLightScheme;
      break;
    case MemberGroup.senioren:
      scheme = seniorenLightScheme;
      break;
    case MemberGroup.aktive:
    case null:
      scheme = lightScheme;
      break;
  }

  // Spezielle Konfiguration für Jugend
  if (group == MemberGroup.jugend) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      // Größere, rundere Buttons für Jugend
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      // Rundere Cards
      cardTheme: CardTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      // Größere Texte
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 16),
      ),
    );
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Roboto',
  );
}

ThemeData buildDarkTheme([MemberGroup? group]) {
  ColorScheme scheme;
  switch (group) {
    case MemberGroup.jugend:
      scheme = jugendDarkScheme;
      break;
    case MemberGroup.senioren:
      scheme = seniorenDarkScheme;
      break;
    case MemberGroup.aktive:
    case null:
      scheme = darkScheme;
      break;
  }

  // Spezielle Konfiguration für Jugend
  if (group == MemberGroup.jugend) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 16),
      ),
    );
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Roboto',
  );
}
