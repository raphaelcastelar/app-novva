import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/env.dart';
import 'core/notifications/notification_navigation_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.validateForRelease(releaseMode: kReleaseMode);

  final pushNotifications = PushNotificationService.instance;
  pushNotifications.onNotificationOpened =
      NotificationNavigationService.instance.handle;
  await pushNotifications.initialize();

  authListenable.addListener(() {
    if (!authListenable.isAuthenticated) return;
    unawaited(pushNotifications.requestPermissionAndRegister());
    NotificationNavigationService.instance.openPending();
  });

  runApp(const ProviderScope(child: NovvaApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    pushNotifications.deliverInitialMessage();
  });
}
