import 'package:flutter/material.dart';

final lightScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0B0B0B), brightness: Brightness.light);
final darkScheme  = ColorScheme.fromSeed(seedColor: const Color(0xFF0B0B0B), brightness: Brightness.dark);

ThemeData buildLightTheme() => ThemeData(useMaterial3: true, colorScheme: lightScheme, fontFamily: 'Roboto');
ThemeData buildDarkTheme()  => ThemeData(useMaterial3: true, colorScheme: darkScheme,  fontFamily: 'Roboto');
