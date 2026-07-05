
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notification/application/notification_provider.dart';
import 'dart:developer' as dev_console show log;

/// Background isolate handler. Must be a top-level function annotated with
/// `@pragma('vm:entry-point')`. When a data/notification message arrives while
/// the app is terminated or backgrounded, the OS shows it in the system tray
/// automatically; this handler just exists so FCM can wake the isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: notification messages are rendered by the OS tray. We intentionally
  // avoid extra work here to keep the background isolate lightweight.
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

/// Owns the FCM lifecycle: permission, token registration with the backend,
/// token refresh, and refreshing the in-app notification list when a push
/// arrives while the app is in the foreground.
class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;

  bool _started = false;
  String? _currentToken;

  /// Call once the user is authenticated. Safe to call multiple times.
  Future<void> start() async {
    if (_started) {
      // Already running — just make sure the token is registered.
      await _registerCurrentToken();
      return;
    }
    _started = true;

    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // iOS needs the APNS token before the FCM token is available.
      await messaging.getAPNSToken();

      await _registerCurrentToken();

      messaging.onTokenRefresh.listen((token) {
        _currentToken = token;
        _safeRegister(token);
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    } catch (e) {
      // debugPrint('[push] start failed: $e');
      dev_console.log('[push] start failed: $e');
    }
  }

  /// Refreshes the in-app notification list/badge so a foreground push shows up
  /// immediately without the OS banner.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[push] foreground message: ${message.messageId}');
    _ref.invalidate(unreadNotificationCountProvider);
    // Refresh the list if it is currently being watched.
    final notifier = _ref.read(notificationsProvider.notifier);
    notifier.refresh();
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      _currentToken = token;
      await _safeRegister(token);
    } catch (e) {
      dev_console.log('[push] token fetch failed: $e');
      
    }
  }

  Future<void> _safeRegister(String token) async {
    await _ref
        .read(notificationRepositoryProvider)
        .registerDeviceToken(token);
  }

  /// Removes this device's token from the backend (call on logout).
  Future<void> unregister() async {
    final token = _currentToken ?? await _safeGetToken();
    if (token == null) return;
    await _ref.read(notificationRepositoryProvider).removeDeviceToken(token);
  }

  Future<String?> _safeGetToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
