import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../notifications/push_notification_service.dart';
import '../storage/storage_providers.dart';

final class AppBootstrap {
  const AppBootstrap._();

  static Future<ProviderScope> createProviderScope({
    required Widget child,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialise Firebase before anything tries to use FCM. Failures are
    // swallowed so the app still launches (in-app notifications keep working).
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('[push] Firebase init failed: $e');
    }

    final preferences = await SharedPreferences.getInstance();

    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: child,
    );
  }
}
