import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';
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

    // Configure Stripe for the PaymentSheet (card / Apple Pay / Google Pay).
    // Skipped on web (flutter_stripe is mobile-only) and when no publishable
    // key is provided, so the rest of the app keeps working either way.
    if (!kIsWeb && kStripePublishableKey.isNotEmpty) {
      try {
        Stripe.publishableKey = kStripePublishableKey;
        Stripe.merchantIdentifier = kStripeMerchantIdentifier;
        await Stripe.instance.applySettings();
      } catch (e) {
        debugPrint('[stripe] init failed: $e');
      }
    }

    final preferences = await SharedPreferences.getInstance();

    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: child,
    );
  }
}
