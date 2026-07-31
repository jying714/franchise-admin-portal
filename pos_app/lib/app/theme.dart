import 'package:flutter/material.dart';

ThemeData buildPosTheme({ColorScheme? scheme}) {
  final colorScheme =
      scheme ??
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFB71C1C),
        brightness: Brightness.light,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    ),
  );
}
