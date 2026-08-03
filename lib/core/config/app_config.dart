import 'package:flutter/foundation.dart';

// ═════════════════════════════════════════════════════════════════════════
//  SERVER SWITCH — the only line you need to change.
//
//    true  → live server   (https://api.booksonwheeels.com)
//    false → local server  (http://$_localHost:$_localPort)
//
//  Can also be flipped without touching code:
//    flutter run --dart-define=USE_LIVE_SERVER=true
// ═════════════════════════════════════════════════════════════════════════
const bool kUseLiveServer = bool.fromEnvironment(
  'USE_LIVE_SERVER',
  defaultValue: true,
);

/// Live production API.
const String _liveBaseUrl = 'https://api.booksonwheeels.com/api/v1';

/// Local development server host.
///
/// Your machine's LAN IP works for ALL of these at once — physical Android
/// and iOS devices on the same Wi-Fi, the Android emulator, and the iOS
/// simulator (both route traffic through your machine's network):
const String _localHost = '10.10.26.111';
const int _localPort = 5002;

const String _localBaseUrl = 'http://$_localHost:$_localPort/api/v1';

enum AppEnvironment { development, staging, production }

final class AppConfig {
  const AppConfig({
    required this.appName,
    required this.environment,
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 20),
    this.receiveTimeout = const Duration(seconds: 20),
  });

  factory AppConfig.development() => AppConfig(
    appName: 'Najwafth Buyer',
    environment: kUseLiveServer
        ? AppEnvironment.production
        : AppEnvironment.development,
    baseUrl: _resolveBaseUrl(),
  );

  final String appName;
  final AppEnvironment environment;
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;
}

/// Explicit URL override still wins over the switch:
/// flutter run --dart-define=API_BASE_URL=https://staging.example.com/api/v1
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String _resolveBaseUrl() {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  if (kUseLiveServer) return _liveBaseUrl;
  // Web builds can't reach a LAN IP over cleartext HTTP in most setups, so
  // they always talk to the live server unless explicitly overridden.
  if (kIsWeb) return _liveBaseUrl;
  return _localBaseUrl;
}

/// Stripe publishable key (pk_test_... / pk_live_...). Overridable at build
/// time so the key never has to be committed:
/// flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
const String kStripePublishableKey = String.fromEnvironment(
  'STRIPE_PUBLISHABLE_KEY',
  // Stripe TEST publishable key (safe to embed — publishable keys are
  // public by design). Swap for the pk_live_ key before release.
  defaultValue:
      'pk_test_51S6pMbRZVOYD6qjBukBi2VyPiTtIhzAyYzmfyAo4izzIwemOo7I3fUYELhxmTJeNln7zMiztFA4CKihsybqrJlo800nWzvIXZY',
);

/// Apple Pay merchant identifier registered in the Apple Developer portal
/// and enabled in Stripe. Required for Apple Pay only.
const String kStripeMerchantIdentifier = String.fromEnvironment(
  'STRIPE_MERCHANT_ID',
  defaultValue: 'merchant.com.najwafth.buyer',
);
