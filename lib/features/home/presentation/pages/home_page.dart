import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../../cart_order/presentation/pages/book_details_page.dart';
import '../../../cart_order/presentation/pages/checkout_page.dart';
import '../../../../core/errors/result.dart';
import '../../application/book_provider.dart';
import '../../application/store_controller.dart';
import '../../domain/store_models.dart';
import '../../../cart_order/presentation/widgets/cart_tab.dart';
import '../widgets/home_tab.dart';
import '../../../order/application/order_controller.dart';
import '../../../order/domain/order_models.dart';
import '../../../order/presentation/widgets/orders_tab.dart';
import '../../../order/presentation/widgets/review_bottom_sheet.dart';
import '../../../profile/presentation/widgets/profile_tab.dart';
import '../../../profile/presentation/pages/notifications_page.dart';
import 'books_grid_page.dart';
import 'featured_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _StoreShell();
  }
}

class _StoreShell extends ConsumerStatefulWidget {
  const _StoreShell();

  @override
  ConsumerState<_StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends ConsumerState<_StoreShell> {
  /// Storage key for order numbers we've already shown the review popup for.
  static const _kReviewPromptedOrdersKey = 'review_prompted_order_ids';

  int _currentIndex = 0;
  bool _reviewPromptActive = false;

  /// Called whenever the orders list updates: if an order has just been
  /// delivered and we haven't asked yet, pop up the review sheet for it.
  Future<void> _maybePromptDeliveredReview(List<OrderModel> orders) async {
    if (_reviewPromptActive || !mounted) return;

    final storage = ref.read(keyValueStorageProvider);
    final prompted =
        (storage.readStringList(_kReviewPromptedOrdersKey) ?? const [])
            .toSet();

    OrderModel? candidate;
    for (final order in orders) {
      if (order.status == OrderStatus.delivered &&
          order.orderNumber.isNotEmpty &&
          order.items.isNotEmpty &&
          !prompted.contains(order.orderNumber)) {
        candidate = order;
        break;
      }
    }
    if (candidate == null) return;

    _reviewPromptActive = true;
    // Persist immediately so dismissing the sheet doesn't re-nag on the
    // next refresh — each delivered order prompts exactly once.
    prompted.add(candidate.orderNumber);
    await storage.writeStringList(
      _kReviewPromptedOrdersKey,
      prompted.toList(),
    );
    if (!mounted) {
      _reviewPromptActive = false;
      return;
    }

    final l10n = AppLocalizations.of(context);
    final result = await ReviewBottomSheet.show(
      context,
      reviewerName: candidate.customerName,
      title: l10n.rateThisOrder,
      subtitle:
          '${l10n.orderDeliveredSuccessfully} · #${candidate.orderNumber}',
    );
    _reviewPromptActive = false;
    if (result == null || !mounted) return;

    final repository = ref.read(orderRepositoryProvider);
    final bookIds = candidate.items
        .map((item) => item.id)
        .where((id) => id.isNotEmpty)
        .toSet();

    String? errorMessage;
    var submitted = false;
    for (final bookId in bookIds) {
      final response = await repository.submitBookReview(
        bookId: bookId,
        rating: result.rating,
        comment: result.comment,
      );
      switch (response) {
        case Success():
          submitted = true;
        case ResultFailure(error: final failure):
          errorMessage ??= failure.message;
      }
    }
    if (!mounted) return;

    showTopToast(
      context,
      title: submitted ? l10n.reviewSubmitted : (errorMessage ?? l10n.somethingWentWrong),
      type: submitted ? ToastType.success : ToastType.error,
    );
    if (submitted) {
      // Refetch books so the new reviews and averages appear immediately.
      ref.invalidate(booksAsyncProvider);
    }

    // Handle any further delivered orders that are still waiting.
    final remaining = ref.read(orderControllerProvider).asData?.value;
    if (remaining != null) {
      _maybePromptDeliveredReview(remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final booksAsync = ref.watch(booksAsyncProvider);
    final categories = ref.watch(storeCategoriesProvider);

    ref.listen(orderControllerProvider, (previous, next) {
      final orders = next.asData?.value;
      if (orders != null) {
        _maybePromptDeliveredReview(orders);
      }
    });

    final homeTab = booksAsync.when(
      loading: () => const _BooksLoadingView(),
      error: (error, _) => _BooksErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(booksAsyncProvider),
      ),
      data: (books) => HomeTab(
        featuredBooks: books.take(6).toList(),
        categories: categories,
        popularBooks: books,
        onBookTap: _openBookDetails,
        onCategoryTap: _openCategory,
        onNotificationsTap: _openNotifications,
        onFeaturedTap: _openFeatured,
        onPopularTap: _openPopular,
      ),
    );

    final pages = [
      homeTab,
      OrdersTab(onCheckoutTap: _openCheckout),
      CartTab(
        onCheckoutTap: _openCheckout,
        onHomeTap: () => setState(() => _currentIndex = 0),
      ),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFFF7F7F8),
        elevation: 0,
        selectedItemColor: const Color(0xFF4A9AF0),
        unselectedItemColor: const Color(0xFF6F6F72),
        selectedFontSize: 13,
        unselectedFontSize: 13,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          height: 1.25,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          height: 1.25,
        ),
        iconSize: 28,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_outlined),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2_outlined),
            label: l10n.order,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_checkout_outlined),
            activeIcon: Icon(Icons.shopping_cart_checkout_outlined),
            label: l10n.cart,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }

  void _openFeatured() {
    final books = ref.read(storeCatalogProvider);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeaturedPage(
          categories: ref.read(storeCategoriesProvider),
          popularBooks: books,
          onBookTap: _openBookDetails,
          onCategoryTap: _openCategory,
        ),
      ),
    );
  }

  void _openPopular() {
    final l10n = AppLocalizations.of(context);
    final books = ref.read(storeCatalogProvider);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BooksGridPage(
          title: l10n.popularBooks,
          books: books,
          onBookTap: _openBookDetails,
        ),
      ),
    );
  }

  Future<void> _openCategory(BookCategory category) async {
    final all = ref.read(storeCatalogProvider);
    final result = await ref
        .read(bookRepositoryProvider)
        .getBooks(categoryId: category.id, limit: 100);
    final filtered = switch (result) {
      Success(data: final data) => data.books,
      ResultFailure() => all.where((b) => b.categoryId == category.id).toList(),
    };

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BooksGridPage(
          title: category.name,
          books: filtered,
          onBookTap: _openBookDetails,
        ),
      ),
    );
  }

  void _openBookDetails(BookItem book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookDetailsPage(book: book)),
    );
  }

  void _openCheckout() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CheckoutPage()));
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NotificationsPage()));
  }
}

class _BooksLoadingView extends StatelessWidget {
  const _BooksLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F6F8),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF5A91C4))),
    );
  }
}

class _BooksErrorView extends StatelessWidget {
  const _BooksErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: Color(0xFF9CA6B3),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.couldNotLoadBooks,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF243041),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8E98A5)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A91C4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  l10n.retry,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
