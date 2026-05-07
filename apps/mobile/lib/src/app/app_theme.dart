import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const seed = Color(0xFF4E7D6A);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      scaffoldBackgroundColor: const Color(0xFFFBF8F1),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
