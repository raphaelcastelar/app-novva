import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

typedef NotificationOpenedCallback = void Function(RemoteMessage message);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  final ValueNotifier<String?> registrationToken = ValueNotifier(null);
  final ValueNotifier<String?> apnsToken = ValueNotifier(null);
  final ValueNotifier<String?> registrationError = ValueNotifier(null);
  final ValueNotifier<AuthorizationStatus?> authorizationStatus =
      ValueNotifier(null);
  final ValueNotifier<String?> lastForegroundMessage = ValueNotifier(null);

  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  RemoteMessage? _initialMessage;
  bool _initialized = false;

  NotificationOpenedCallback? onNotificationOpened;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      _messaging = messaging;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // ignore: deprecated_member_use
      _tokenSubscription = messaging.onTokenRefresh.listen(
        (token) {
          registrationToken.value = token;
          registrationError.value = null;
        },
        onError: (Object error) {
          registrationError.value = error.toString();
        },
      );
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        final title = notification?.title ?? 'Mensagem sem título';
        final body = notification?.body ?? message.data.toString();
        lastForegroundMessage.value = '$title — $body';
        debugPrint(
            'Notificação recebida em primeiro plano: ${message.messageId}');
      });
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _notifyOpened,
      );
      _initialMessage = await messaging.getInitialMessage();
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('Falha ao inicializar notificações push: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<AuthorizationStatus?> requestPermissionAndRegister() async {
    final messaging = _messaging;
    if (!_initialized || messaging == null) return null;

    var settings = await messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }
    authorizationStatus.value = settings.authorizationStatus;

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      try {
        registrationError.value = null;
        await messaging.setAutoInitEnabled(true);

        final apnsToken = await _waitForApnsToken(messaging);
        if (apnsToken == null) {
          registrationError.value =
              'O token de notificações da Apple ainda não foi recebido.';
          debugPrint('Token APNs ainda não disponível após o registro.');
        } else {
          this.apnsToken.value = apnsToken;
          debugPrint('Token APNs recebido com sucesso.');

          // ignore: deprecated_member_use
          final token = await messaging.getToken();
          registrationToken.value = token;
        }
      } catch (error, stackTrace) {
        registrationError.value = error.toString();
        debugPrint('Falha ao registrar notificações push: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    } else {
      registrationError.value =
          'As notificações estão desativadas nos Ajustes do iPhone.';
    }

    return settings.authorizationStatus;
  }

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final token = await messaging.getAPNSToken();
      if (token != null && token.isNotEmpty) return token;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  void deliverInitialMessage() {
    final message = _initialMessage;
    _initialMessage = null;
    if (message != null) _notifyOpened(message);
  }

  void _notifyOpened(RemoteMessage message) {
    onNotificationOpened?.call(message);
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    registrationToken.dispose();
    apnsToken.dispose();
    registrationError.dispose();
    authorizationStatus.dispose();
    lastForegroundMessage.dispose();
  }
}
