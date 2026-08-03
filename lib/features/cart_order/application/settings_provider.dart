import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../core/network/network_providers.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(apiClientProvider));
});

/// The global admin settings (delivery fee, commission). Fetched once and
/// cached; falls back to backend defaults on error so checkout always has a
/// usable delivery fee.
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final result = await ref.watch(settingsRepositoryProvider).getSettings();
  return switch (result) {
    Success(data: final settings) => settings,
    ResultFailure() => const AppSettings(),
  };
});

/// Convenience view of just the delivery fee, with a backend-matching default
/// while the settings request is still in flight or has failed.
final deliveryFeeProvider = Provider<double>((ref) {
  return ref.watch(appSettingsProvider).asData?.value.deliveryFee ?? 5.0;
});
