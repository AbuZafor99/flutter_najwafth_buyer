import 'dart:developer' as dev_console show log;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notification/application/notification_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

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
      final canFetchToken = await _canFetchFirebaseToken();
      if (!canFetchToken) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) return;
      debugPrint('[push] token: ${_maskToken(token)}');
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
      final canFetchToken = await _canFetchFirebaseToken();
      if (!canFetchToken) {
        return null;
      }

      final token = _currentToken ?? await FirebaseMessaging.instance.getToken();
      debugPrint('[push] token: ${token == null ? null : _maskToken(token)}');
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _canFetchFirebaseToken() async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return true;
    }

    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken == null || apnsToken.isEmpty) {
      dev_console.log('[push] APNS token not ready; skipping FCM registration');
      return false;
    }

    return true;
  }

  String _maskToken(String token) {
    if (token.length <= 12) {
      return '***';
    }
    return '${token.substring(0, 6)}...${token.substring(token.length - 6)}';
  }
}
