import 'package:flutter/material.dart';
import 'package:asv_app/models/member_group.dart';

// Standard Themes (Aktive)
final lightScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0B0B0B), brightness: Brightness.light);
final darkScheme  = ColorScheme.fromSeed(seedColor: const Color(0xFF0B0B0B), brightness: Brightness.dark);

// Jugend Themes - Frische, lebhafte Farben
final jugendLightScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF00BCD4), // Cyan/Türkis
  brightness: Brightness.light,
);
final jugendDarkScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF00BCD4),
  brightness: Brightness.dark,
);

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
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Roboto',
  );
}
