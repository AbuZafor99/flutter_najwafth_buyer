import '../../../core/errors/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/order_models.dart';

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
