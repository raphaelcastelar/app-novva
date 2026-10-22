import 'package:firebase_messaging/firebase_messaging.dart';

import '../../app/routes/app_router.dart';
import '../../app/routes/route_names.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final instance = NotificationNavigationService._();

  String? _pendingLocation;

  void handle(RemoteMessage message) {
    final location = _locationFor(message.data);
    if (!authListenable.isAuthenticated) {
      _pendingLocation = location;
      return;
    }
    appRouter.go(location);
  }

  void openPending() {
    if (!authListenable.isAuthenticated) return;
    final location = _pendingLocation;
    _pendingLocation = null;
    if (location != null) appRouter.go(location);
  }

  String _locationFor(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    switch (type) {
      case 'document_available':
        final documentId = data['entityId']?.toString();
        if (documentId != null && documentId.isNotEmpty) {
          return Uri(
            path: RouteNames.documents,
            queryParameters: {'documentId': documentId},
          ).toString();
        }
        return RouteNames.documents;
      case 'document_rejected':
        return RouteNames.documents;
      case 'obligation_available':
      case 'obligation_due':
        return RouteNames.obligations;
      case 'notice':
      case 'general':
      default:
        return RouteNames.notifications;
    }
  }
}
