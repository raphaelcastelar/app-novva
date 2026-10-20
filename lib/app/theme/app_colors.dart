import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const lightPrimary = Color(0xFF145C73);
  static const primaryDark = Color(0xFF0C3744);
  static const lightAccent = Color(0xFF2F9E8F);
  static const darkPrimary = Color(0xFF35BDE5);
  static const darkAccent = Color(0xFF42C7A9);

  static const lightBackground = Color(0xFFF6F8FA);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF1F2A32);
  static const lightMuted = Color(0xFF6B7780);
  static const lightBorder = Color(0xFFE3E9ED);
  static const lightSoftAccent = Color(0xFFE8F6F4);
  static const lightSoftPrimary = Color(0xFFE8F1F4);
  static const lightElevatedSurface = Color(0xFFFCFDFD);
  static const lightShadow = Color(0x1A0C3744);

  static const darkBackground = Color(0xFF061A23);
  static const darkSurface = Color(0xFF0D2731);
  static const darkText = Color(0xFFF3F8FA);
  static const darkMuted = Color(0xFFA1B3BB);
  static const darkBorder = Color(0xFF294550);
  static const darkSoftAccent = Color(0xFF103A39);
  static const darkSoftPrimary = Color(0xFF12333F);
  static const darkElevatedSurface = Color(0xFF13303A);
  static const darkShadow = Color(0x66000000);

  static bool get isDark =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get primary => isDark ? darkPrimary : lightPrimary;
  static Color get accent => isDark ? darkAccent : lightAccent;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get text => isDark ? darkText : lightText;
  static Color get muted => isDark ? darkMuted : lightMuted;
  static Color get border => isDark ? darkBorder : lightBorder;
  static const success = Color(0xFF198754);
  static const warning = Color(0xFFE8A100);
  static const danger = Color(0xFFD92D20);
  static const info = Color(0xFF2563EB);
  static Color get softAccent => isDark ? darkSoftAccent : lightSoftAccent;
  static Color get softPrimary => isDark ? darkSoftPrimary : lightSoftPrimary;
  static Color get elevatedSurface =>
      isDark ? darkElevatedSurface : lightElevatedSurface;
  static Color get shadow => isDark ? darkShadow : lightShadow;

  static LinearGradient get premiumGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDark, primary, accent],
      );
}
