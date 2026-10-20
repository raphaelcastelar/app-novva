import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novva_app/app/theme/app_colors.dart';
import 'package:novva_app/app/theme/app_theme.dart';

void main() {
  testWidgets('follows the system brightness and exposes the dark palette',
      (tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.darkBackground);
    expect(AppColors.surface, AppColors.darkSurface);
    expect(AppColors.text, AppColors.darkText);
    expect(AppColors.primary, AppColors.darkPrimary);
  });
}
