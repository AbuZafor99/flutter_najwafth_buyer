import '../../../core/errors/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/order_models.dart';

/// The recipient + delivery address saved from a previous order, used to
/// pre-fill the checkout form.
final class SavedAddress {
  const SavedAddress({
    this.name = '',
    this.phone = '',
    this.line1 = '',
    this.line2 = '',
    this.city = '',
    this.postalCode = '',
    this.state = '',
    this.country = '',
  });

  final String name;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String postalCode;
  final String state;
  final String country;

  bool get hasAddress => line1.isNotEmpty || city.isNotEmpty;

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    final details = json['addressDetails'];
    final d = details is Map<String, dynamic> ? details : const {};
    String s(dynamic v) => v?.toString().trim() ?? '';
    return SavedAddress(
      name: s(json['name']),
      phone: s(json['phone']),
      line1: s(d['line1']),
      line2: s(d['line2']),
      city: s(d['city']),
      postalCode: s(d['postalCode']),
      state: s(d['state']),
      country: s(d['country']),
    );
  }
}

final class OrderRepository {
  const OrderRepository(this._client);

  final ApiClient _client;

  Future<Result<List<OrderModel>>> getMyOrders() async {
    final myOrders = await _client.get<List<OrderModel>>(
      '/order/my-orders',
      parser: _parseOrderListResponse,
    );

    return switch (myOrders) {
      Success(data: final orders) when orders.isNotEmpty => Success(orders),
      _ => _client.get<List<OrderModel>>(
        '/order',
        parser: _parseOrderListResponse,
      ),
    };
  }

  Future<Result<OrderModel>> createOrder({
    required List<OrderCreateItem> items,
    required String address,
    String? name,
    String? phone,
    Map<String, dynamic>? addressDetails,
  }) {
    return _client.post<OrderModel>(
      '/order/create',
      data: {
        'items': items
            .map(
              (item) => {'product': item.productId, 'quantity': item.quantity},
            )
            .toList(growable: false),
        'address': address,
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'addressDetails': ?addressDetails,
      },
      parser: (data) {
        _assertSuccess(data);
        final root = data as Map<String, dynamic>;
        final order = root['data'];
        if (order is! Map<String, dynamic>) {
          throw Exception('Invalid create order response');
        }
        return OrderModel.fromApi(order);
      },
    );
  }

  /// Posts a book review. The backend derives the order from the user's
  /// purchase history, so only the book id, rating and comment are sent.
  Future<Result<void>> submitBookReview({
    required String bookId,
    required int rating,
    required String comment,
  }) async {
    final result = await _client.post<dynamic>(
      '/user/write-review',
      data: {'book': bookId, 'rating': rating, 'comment': comment},
      parser: (data) {
        _assertSuccess(data);
        return null;
      },
    );
    return switch (result) {
      Success() => const Success(null),
      ResultFailure(error: final e) => ResultFailure(e),
    };
  }

  /// Fetches the recipient + delivery address from the user's most recent
  /// order so checkout can pre-fill it. Returns null when there's nothing
  /// saved yet (or the request fails — pre-fill is best-effort).
  Future<SavedAddress?> getLastAddress() async {
    final result = await _client.get<SavedAddress?>(
      '/order/last-address',
      parser: (data) {
        final root = data as Map<String, dynamic>;
        final payload = root['data'];
        if (payload is! Map<String, dynamic>) return null;
        return SavedAddress.fromJson(payload);
      },
    );
    return switch (result) {
      Success(data: final address) => address,
      ResultFailure() => null,
    };
  }

  static List<OrderModel> _parseOrderListResponse(dynamic data) {
    _assertSuccess(data);
    final root = data as Map<String, dynamic>;
    final raw = root['data'];

    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromApi)
          .toList(growable: false);
    }

    if (raw is Map<String, dynamic>) {
      final orders = raw['orders'];
      if (orders is List) {
        return orders
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromApi)
            .toList(growable: false);
      }
    }

    return const [];
  }

  static void _assertSuccess(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid server response');
    }
    if (data['success'] == false) {
      throw Exception(data['message']?.toString() ?? 'Request failed');
    }
  }
}

final class OrderCreateItem {
  const OrderCreateItem({required this.productId, required this.quantity});

  final String productId;
  final int quantity;
}
