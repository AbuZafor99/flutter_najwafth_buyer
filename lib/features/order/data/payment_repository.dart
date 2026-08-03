import '../../../core/errors/result.dart';
import '../../../core/network/api_client.dart';

/// Server-created Stripe PaymentIntent handles needed by the PaymentSheet.
final class PaymentIntentInfo {
  const PaymentIntentInfo({
    required this.clientSecret,
    required this.paymentIntentId,
  });

  final String clientSecret;
  final String paymentIntentId;
}

final class PaymentRepository {
  const PaymentRepository(this._client);

  final ApiClient _client;

  /// Creates a PaymentIntent for [orderId] and returns its client secret,
  /// which the Stripe PaymentSheet uses to collect card / Apple Pay /
  /// Google Pay payment on-device.
  Future<Result<PaymentIntentInfo>> createOrderPayment({
    required String orderId,
    required double price,
  }) {
    return _client.post<PaymentIntentInfo>(
      '/payment/create',
      data: {'orderId': orderId, 'price': price, 'type': 'order'},
      parser: (data) {
        final root = data as Map<String, dynamic>;
        final clientSecret = root['clientSecret']?.toString();
        if (root['success'] != true ||
            clientSecret == null ||
            clientSecret.isEmpty) {
          throw Exception(
            root['error']?.toString() ?? 'Could not start the payment.',
          );
        }
        return PaymentIntentInfo(
          clientSecret: clientSecret,
          paymentIntentId: root['paymentIntentId']?.toString() ?? '',
        );
      },
    );
  }

  /// Verifies the PaymentIntent server-side after the sheet completes and
  /// marks the order as paid.
  Future<Result<void>> confirmPayment(String paymentIntentId) async {
    final result = await _client.post<dynamic>(
      '/payment/confirm',
      data: {'paymentIntentId': paymentIntentId},
      parser: (data) {
        final root = data as Map<String, dynamic>;
        if (root['success'] != true) {
          throw Exception(
            root['error']?.toString() ?? 'Payment confirmation failed.',
          );
        }
        return null;
      },
    );
    return switch (result) {
      Success() => const Success(null),
      ResultFailure(error: final e) => ResultFailure(e),
    };
  }
}
