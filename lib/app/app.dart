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
    authListenable.addListener(_scheduleBiometricOffer);
  }

  bool _offeringBiometrics = false;

  void _scheduleBiometricOffer() {
    if (!mounted || !authListenable.isAuthenticated || _offeringBiometrics) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_offerBiometricSetup());
    });
  }

  Future<void> _offerBiometricSetup() async {
    _offeringBiometrics = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted || !authListenable.isAuthenticated) return;
      final biometrics = ref.read(biometricAuthServiceProvider);
      if (!await biometrics.shouldOfferSetup()) return;
      final context = rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      final activate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.face_outlined),
          title: const Text('Ativar Face ID?'),
          content: const Text(
            'Use o Face ID para acessar sua conta Novva nas próximas vezes, sem precisar digitar CPF e senha.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Agora não'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ativar'),
            ),
          ],
        ),
      );
      if (activate != true) {
        await biometrics.markOfferHandled();
        return;
      }
      final enabled = await biometrics.enable();
      final currentContext = rootNavigatorKey.currentContext;
      if (currentContext != null && currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(enabled
                ? 'Face ID ativado com sucesso.'
                : 'Não foi possível ativar o Face ID.'),
          ),
        );
      }
    } finally {
      _offeringBiometrics = false;
    }
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
    authListenable.removeListener(_scheduleBiometricOffer);
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
