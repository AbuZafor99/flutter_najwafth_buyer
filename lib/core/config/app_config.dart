import 'package:flutter/foundation.dart';

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
    environment: AppEnvironment.development,
    baseUrl: _defaultDevBaseUrl(),
  );

  final String appName;
  final AppEnvironment environment;
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;
}

/// Overridable at build time:
/// flutter run --dart-define=API_BASE_URL=https://api.booksonwheeels.com/api/v1
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String _defaultDevBaseUrl() {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;

  if (kIsWeb) {
    return 'http://localhost:5001/api/v1';
  }

  return switch (defaultTargetPlatform) {
    // Android emulators reach the host machine via 10.0.2.2, not localhost.
    TargetPlatform.android => 'http://10.0.2.2:5001/api/v1',
    _ => 'http://localhost:5001/api/v1',
  };
}
