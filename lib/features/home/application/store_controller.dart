import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../core/storage/key_value_storage.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../cart_order/data/cart_repository.dart';
import '../../../core/network/network_providers.dart';
import '../domain/store_models.dart';
import 'book_provider.dart';
import 'category_provider.dart';

// Sync view of the async books cache — returns [] while loading
final storeCatalogProvider = Provider<List<BookItem>>((ref) {
  return ref.watch(booksAsyncProvider).asData?.value ?? const [];
});

final storeCategoriesProvider = Provider<List<BookCategory>>((ref) {
  return ref.watch(categoriesAsyncProvider).asData?.value ?? const [];
});

final storeControllerProvider = NotifierProvider<StoreController, StoreState>(
  StoreController.new,
);

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(apiClientProvider));
});

final class StoreState {
  const StoreState({
    required this.selectedLanguage,
    required this.cartQuantities,
    required this.lastOrder,
  });

  final AppLanguage? selectedLanguage;
  final Map<String, int> cartQuantities;
  final OrderReceipt? lastOrder;

  int quantityFor(String bookId) => cartQuantities[bookId] ?? 0;

  int get totalItems =>
      cartQuantities.values.fold<int>(0, (sum, quantity) => sum + quantity);

  StoreState copyWith({
    AppLanguage? selectedLanguage,
    Map<String, int>? cartQuantities,
    OrderReceipt? lastOrder,
    bool clearLanguage = false,
    bool clearLastOrder = false,
  }) {
    return StoreState(
      selectedLanguage: clearLanguage
          ? null
          : selectedLanguage ?? this.selectedLanguage,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      lastOrder: clearLastOrder ? null : lastOrder ?? this.lastOrder,
    );
  }
}

final class StoreController extends Notifier<StoreState> {
  static const _languageKey = 'selected_language';
  static const _deliveryFee = 2.50;

  KeyValueStorage? _storage;

  @override
  StoreState build() {
    _storage ??= ref.watch(keyValueStorageProvider);
    final authState = ref.watch(authControllerProvider);
    final rawLanguage = _storage!.readString(_languageKey);
    AppLanguage? selectedLanguage;

    for (final language in AppLanguage.values) {
      if (language.name == rawLanguage) {
        selectedLanguage = language;
        break;
      }
    }

    selectedLanguage ??= AppLanguage.french;

    final initial = StoreState(
      selectedLanguage: selectedLanguage,
      cartQuantities: const {},
      lastOrder: null,
    );

    if (authState.isAuthenticated) {
      Future<void>.microtask(_loadRemoteCart);
    }

    ref.listen(authControllerProvider, (previous, next) {
      final wasAuthenticated = previous?.isAuthenticated ?? false;
      if (!wasAuthenticated && next.isAuthenticated) {
        Future<void>.microtask(_loadRemoteCart);
      }
      if (wasAuthenticated && !next.isAuthenticated) {
        state = state.copyWith(cartQuantities: const {}, clearLastOrder: true);
      }
    });

    return initial;
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(selectedLanguage: language);
    await _storage!.writeString(_languageKey, language.name);
  }

  Future<void> addToCart(BookItem book, {int quantity = 1}) async {
    if (quantity <= 0 || book.id.trim().isEmpty) return;
    final previous = state.cartQuantities;
    final updated = Map<String, int>.from(state.cartQuantities);
    updated.update(
      book.id,
      (value) => value + quantity,
      ifAbsent: () => quantity,
    );
    state = state.copyWith(cartQuantities: updated, clearLastOrder: true);

    final isAuthenticated = ref.read(authControllerProvider).isAuthenticated;
    if (!isAuthenticated) return;

    final result = await ref
        .read(cartRepositoryProvider)
        .addToCart(productId: book.id, quantity: quantity);
    switch (result) {
      case Success(data: final cart):
        state = state.copyWith(cartQuantities: cart.quantities);
      case ResultFailure():
        state = state.copyWith(cartQuantities: previous);
    }
  }

  Future<void> setQuantity(BookItem book, int quantity) async {
    if (book.id.trim().isEmpty) return;
    final previous = state.cartQuantities;
    final updated = Map<String, int>.from(state.cartQuantities);
    if (quantity <= 0) {
      updated.remove(book.id);
    } else {
      updated[book.id] = quantity;
    }
    state = state.copyWith(cartQuantities: updated);

    final isAuthenticated = ref.read(authControllerProvider).isAuthenticated;
    if (!isAuthenticated) return;

    final result = await ref
        .read(cartRepositoryProvider)
        .updateCart(productId: book.id, quantity: quantity);
    switch (result) {
      case Success(data: final cart):
        state = state.copyWith(cartQuantities: cart.quantities);
      case ResultFailure():
        state = state.copyWith(cartQuantities: previous);
    }
  }

  Future<void> clearCart() async {
    state = state.copyWith(cartQuantities: const {});

    final isAuthenticated = ref.read(authControllerProvider).isAuthenticated;
    if (!isAuthenticated) return;
    await ref.read(cartRepositoryProvider).clearCart();
  }

  double subtotal(List<BookItem> books) {
    return books.fold<double>(
      0,
      (sum, book) => sum + (book.price * state.quantityFor(book.id)),
    );
  }

  /// Flat delivery fee applied once per order. The authoritative value comes
  /// from the backend admin settings ([deliveryFeeProvider]); this constant is
  /// only a fallback for the legacy in-memory receipt path.
  double deliveryFee(List<BookItem> books) {
    return books.isEmpty ? 0 : _deliveryFee;
  }

  Future<OrderReceipt> placeOrder({
    required List<BookItem> catalog,
    required CheckoutInput input,
  }) async {
    final items = catalog
        .where((book) => state.quantityFor(book.id) > 0)
        .expand(
          (book) => List<BookItem>.filled(state.quantityFor(book.id), book),
        )
        .toList(growable: false);

    final subtotalAmount = items.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );
    final receipt = OrderReceipt(
      orderNumber:
          '#BK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      customerName: input.name,
      address: '${input.address}, ${input.city}',
      phone: input.phone,
      items: items,
      subtotal: subtotalAmount,
      deliveryFee: deliveryFee(items),
      paymentMethod: input.paymentMethod,
    );

    state = state.copyWith(cartQuantities: const {}, lastOrder: receipt);

    return receipt;
  }

  void clearOrderReceipt() {
    state = state.copyWith(clearLastOrder: true);
  }

  Future<void> _loadRemoteCart() async {
    final result = await ref.read(cartRepositoryProvider).getCart();
    switch (result) {
      case Success(data: final cart):
        state = state.copyWith(cartQuantities: cart.quantities);
      case ResultFailure():
        state = state.copyWith(cartQuantities: state.cartQuantities);
    }
  }
}
