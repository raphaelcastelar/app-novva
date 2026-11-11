import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_navigation_service.dart';
import '../core/notifications/push_notification_service.dart';
import '../core/security/biometric_copy.dart';
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
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  @override
  void initState() {
    super.initState();
    _pushNotifications.registrationToken.addListener(_scheduleRegistration);
    authListenable.addListener(_scheduleRegistration);
    authListenable.addListener(_scheduleBiometricOffer);
    // No Android o FCM não mostra a notificação com o app aberto; no iOS o
    // sistema já exibe o banner (setForegroundNotificationPresentationOptions).
    if (defaultTargetPlatform == TargetPlatform.android) {
      _foregroundMessageSubscription =
          _pushNotifications.foregroundMessages.listen(_showForegroundMessage);
    }
  }

  void _showForegroundMessage(RemoteMessage message) {
    if (!mounted || !authListenable.isAuthenticated) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final notification = message.notification;
    final title = notification?.title?.trim();
    final body = notification?.body?.trim();
    final text = [
      if (title != null && title.isNotEmpty) title,
      if (body != null && body.isNotEmpty) body,
    ].join('\n');
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Text(text.isEmpty ? 'Você tem uma nova notificação.' : text),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () =>
                NotificationNavigationService.instance.handle(message),
          ),
        ),
      );
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
      final copy = BiometricCopy.current;
      final activate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(copy.icon),
          title: Text(copy.offerTitle),
          content: Text(copy.offerBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Agora não'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Ativar'),
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
            content:
                Text(enabled ? copy.enabledMessage : copy.enableFailedMessage),
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
    _foregroundMessageSubscription?.cancel();
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
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
