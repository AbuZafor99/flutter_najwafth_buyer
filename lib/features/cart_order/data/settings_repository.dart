import '../../../core/errors/result.dart';
import '../../../core/network/api_client.dart';

/// Global, admin-configured settings fetched from `GET /admin-settings`.
/// Defaults mirror the backend (`deliveryFee: 5`, `adminCommissionRate: 15`)
/// so the app degrades gracefully if the request fails.
final class AppSettings {
  const AppSettings({this.deliveryFee = 5.0, this.adminCommissionRate = 15.0});

  final double deliveryFee;
  final double adminCommissionRate;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 5.0,
      adminCommissionRate:
          (json['adminCommissionRate'] as num?)?.toDouble() ?? 15.0,
    );
  }
}

final class SettingsRepository {
  const SettingsRepository(this._client);

  final ApiClient _client;

  /// Fetches the global admin settings (delivery fee, commission rate).
  Future<Result<AppSettings>> getSettings() {
    return _client.get<AppSettings>(
      '/admin-settings',
      parser: (data) {
        if (data is! Map<String, dynamic>) return const AppSettings();
        final payload = data['data'];
        if (payload is! Map<String, dynamic>) return const AppSettings();
        return AppSettings.fromJson(payload);
      },
    );
  }
}
