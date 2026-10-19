import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/push_notification_service.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class NovvaApp extends ConsumerStatefulWidget {
  const NovvaApp({super.key});

  @override
  ConsumerState<NovvaApp> createState() => _NovvaAppState();
}

class _NovvaAppState extends ConsumerState<NovvaApp> {
  final _pushNotifications = PushNotificationService.instance;
  bool _registering = false;
  String? _registeredToken;
  Timer? _registrationRetry;

  @override
  void initState() {
    super.initState();
    _pushNotifications.registrationToken.addListener(_scheduleRegistration);
    authListenable.addListener(_scheduleRegistration);
  }

  void _scheduleRegistration() {
    if (!mounted) return;
    if (!authListenable.isAuthenticated) {
      _registeredToken = null;
      _registrationRetry?.cancel();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerDevice());
  }

  Future<void> _registerDevice() async {
    final token = _pushNotifications.registrationToken.value;
    if (!authListenable.isAuthenticated ||
        token == null ||
        token.isEmpty ||
        token == _registeredToken ||
        _registering) {
      return;
    }
    _registering = true;
    try {
      await ref.read(pushDeviceRemoteDataSourceProvider).register(token);
      _registeredToken = token;
      debugPrint('Dispositivo registrado para notificações do backend.');
    } catch (error) {
      debugPrint('Falha ao registrar o dispositivo no backend: $error');
      _registrationRetry?.cancel();
      _registrationRetry = Timer(
        const Duration(seconds: 15),
        _scheduleRegistration,
      );
    } finally {
      _registering = false;
      if (_pushNotifications.registrationToken.value != token) {
        _scheduleRegistration();
      }
    }
  }

  @override
  void dispose() {
    _registrationRetry?.cancel();
    _pushNotifications.registrationToken.removeListener(_scheduleRegistration);
    authListenable.removeListener(_scheduleRegistration);
    super.dispose();
  }

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
