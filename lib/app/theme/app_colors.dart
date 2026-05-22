import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF145C73);
  static const primaryDark = Color(0xFF0C3744);
  static const accent = Color(0xFF2F9E8F);
  static const background = Color(0xFFF6F8FA);
  static const surface = Colors.white;
  static const text = Color(0xFF1F2A32);
  static const muted = Color(0xFF6B7780);
  static const border = Color(0xFFE3E9ED);
  static const success = Color(0xFF198754);
  static const warning = Color(0xFFE8A100);
  static const danger = Color(0xFFD92D20);
  static const info = Color(0xFF2563EB);
  static const softAccent = Color(0xFFE8F6F4);
  static const softPrimary = Color(0xFFE8F1F4);
  static const elevatedSurface = Color(0xFFFCFDFD);
  static const shadow = Color(0x1A0C3744);

  static const premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, accent],
  );
}
