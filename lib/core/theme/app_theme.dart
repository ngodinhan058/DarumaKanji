import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'DarumaSans',
      scaffoldBackgroundColor: AppColors.washiBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.shintoVermilion,
        primary: AppColors.shintoVermilion,
        secondary: AppColors.kinpaGold,
        surface: AppColors.washiCard,
      ),
      fontFamilyFallback: const ['DarumaMincho'],
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'DarumaMincho',
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.shintoVermilion),
      ),
    );
  }
}
