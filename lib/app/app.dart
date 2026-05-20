import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class NovvaApp extends StatelessWidget {
  const NovvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Novva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
