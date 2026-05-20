import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const title = TextStyle(
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const section = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AppColors.text,
  );
}
