// import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Theme/theme.dart';

// Enum for available themes
enum AppTheme {
  light,
  lightHighContrast,
  lightMediumContrast,
  dark,
  darkHighContrast,
  darkMediumContrast,
}

// StateNotifier to manage theme
class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier() : super(AppTheme.light);

  void setTheme(AppTheme theme) {
    state = theme;
  }

  void toggleDarkLight() {
    if (state == AppTheme.light ||
        state == AppTheme.lightHighContrast ||
        state == AppTheme.lightMediumContrast) {
      state = AppTheme.dark;
    } else {
      state = AppTheme.light;
    }
  }

  ThemeData getThemeData(AppTheme appTheme, MaterialTheme theme) {
    switch (appTheme) {
      case AppTheme.light:
        return theme.light();
      case AppTheme.lightHighContrast:
        return theme.lightHighContrast();
      case AppTheme.lightMediumContrast:
        return theme.lightMediumContrast();
      case AppTheme.dark:
        return theme.dark();
      case AppTheme.darkHighContrast:
        return theme.darkHighContrast();
      case AppTheme.darkMediumContrast:
        return theme.darkMediumContrast();
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>(
  (ref) => ThemeNotifier(),
);
