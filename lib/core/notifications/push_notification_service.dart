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

  final ValueNotifier<String?> registrationId = ValueNotifier(null);

  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _registrationSubscription;
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
      await messaging.setAutoInitEnabled(false);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _registrationSubscription = messaging.onRegistered.listen((identifier) {
        registrationId.value = identifier;
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

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await messaging.register();
    }

    return settings.authorizationStatus;
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
    await _registrationSubscription?.cancel();
    await _openedSubscription?.cancel();
    registrationId.dispose();
  }
}
