import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/network_providers.dart';
import '../../home/domain/store_models.dart';
import '../data/order_repository.dart';
import '../data/payment_repository.dart';
import '../domain/order_models.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(apiClientProvider));
});

final orderControllerProvider =
    AsyncNotifierProvider<OrderController, List<OrderModel>>(
      OrderController.new,
    );

class OrderController extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() => _fetchOrders();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchOrders);
  }

  Future<Result<OrderModel>> placeOrder({
    required List<BookItem> catalog,
    required Map<String, int> quantities,
    required CheckoutInput input,
  }) async {
    final catalogById = {for (final book in catalog) book.id: book};
    final items = quantities.entries
        .where((entry) => entry.value > 0 && catalogById.containsKey(entry.key))
        .map(
          (entry) =>
              OrderCreateItem(productId: entry.key, quantity: entry.value),
        )
        .toList(growable: false);

    if (items.isEmpty) {
      return const ResultFailure(
        AppFailure(message: 'No valid cart items found for order placement.'),
      );
    }

    final address = '${input.address}, ${input.city}';
    final result = await ref
        .read(orderRepositoryProvider)
        .createOrder(
          items: items,
          address: address,
          name: input.name,
          phone: input.phone,
          addressDetails: input.addressDetails,
        );

    switch (result) {
      case Success(data: final created):
        final current = state.asData?.value ?? const <OrderModel>[];
        state = AsyncData([created, ...current]);
      case ResultFailure():
        break;
    }

    return result;
  }

  Future<List<OrderModel>> _fetchOrders() async {
    final result = await ref.read(orderRepositoryProvider).getMyOrders();
    return switch (result) {
      Success(data: final orders) => orders,
      ResultFailure(error: final e) => throw e,
    };
  }
}
