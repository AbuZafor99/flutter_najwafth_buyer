import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../home/application/book_provider.dart';
import '../../../home/application/store_controller.dart';
import '../../../home/domain/store_models.dart';
import '../../../home/presentation/widgets/store_widgets.dart';
import '../../../order/application/order_controller.dart';
import '../../../order/domain/order_models.dart';
import '../../../order/presentation/widgets/review_bottom_sheet.dart';

class BookDetailsPage extends ConsumerStatefulWidget {
  const BookDetailsPage({super.key, required this.book});

  final BookItem book;

  @override
  ConsumerState<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends ConsumerState<BookDetailsPage> {
  int _quantity = 1;
  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bookAsync = ref.watch(bookDetailProvider(widget.book.id));
    final book = bookAsync.asData?.value ?? widget.book;
    final isLoading = bookAsync.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Color(0xFF243041), size: 28),
        ),
        title: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243041),
          ),
        ),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5A91C4)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Cover Image ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EBF0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildCoverImage(book),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Title + Rating ────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF243041),
                        ),
                      ),
                    ),
                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      book.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E98A5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // ── Author ────────────────────────────────────────────
                Text(
                 "BY ${book.author.toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E98A5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Shop / Location ───────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF5A91C4)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(
                        book.shopName ?? '123 Library, Book City',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 99, 105, 112)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Category chip + availability ──────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8FC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        book.categoryName.isNotEmpty ? book.categoryName : l10n.general,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A91C4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StockBadge(inStock: book.stock),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Description ───────────────────────────────────────
                Text(
                  l10n.description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF243041),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.description.isNotEmpty
                      ? book.description
                      : l10n.noDescriptionAvailable,
                  maxLines: _descriptionExpanded ? null : 3,
                  overflow: _descriptionExpanded ? null : TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF8E98A5),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
                  child: Text(
                    _descriptionExpanded ? l10n.showLess : l10n.readMore,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5A91C4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Price + Quantity stepper ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${(book.price * _quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5A91C4),
                          ),
                        ),
                        Text(
                          '\$${(book.price * 1.20 * _quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E98A5),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8FC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                            child: Container(
                              width: 32,
                              color: Colors.transparent,
                              child: const Center(
                                child: Icon(Icons.remove, size: 18, color: Color(0xFF243041)),
                              ),
                            ),
                          ),
                          Container(
                            width: 24,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF243041),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _quantity++),
                            child: Container(
                              width: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE8EBF0)),
                              ),
                              child: const Center(
                                child: Icon(Icons.add, size: 18, color: Color(0xFF243041)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildReviewsSection(book),
              ],
            ),
          ),

          // ── Add to Cart button ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: book.stock ? () => _addToCart(book) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A91C4),
                    disabledBackgroundColor: const Color(0xFFBDCAD8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                  label: Text(
                    book.stock ? l10n.addToCart : l10n.outOfStock,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(BookItem book) {
    final fallback = Container(
      color: book.coverColor,
      child: const Icon(Icons.book, color: Colors.white, size: 48),
    );
    if (book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty) {
      return Image.network(
        book.coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => fallback,
        loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
      );
    }
    if (book.coverImageAsset != null && book.coverImageAsset!.isNotEmpty) {
      return Image.asset(
        book.coverImageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => fallback,
      );
    }
    return fallback;
  }

  void _addToCart(BookItem book) {
    final l10n = AppLocalizations.of(context);
    ref.read(storeControllerProvider.notifier).addToCart(book, quantity: _quantity);
    showTopToast(
      context,
      type: ToastType.success,
      icon: Icons.shopping_cart_rounded,
      title: l10n.addedToCartTitle,
      subtitle: book.title,
    );
    Navigator.of(context).pop();
  }

  /// A review is only accepted by the backend once the user has received
  /// the book, so the button unlocks when a delivered order contains it.
  bool _canReview(BookItem book) {
    final orders = ref.watch(orderControllerProvider).asData?.value;
    if (orders == null) return false;
    return orders.any(
      (order) =>
          order.status == OrderStatus.delivered &&
          order.items.any((item) => item.id == book.id),
    );
  }

  // ── Reviews & Ratings ──────────────────────────────────────────────
  Widget _buildReviewsSection(BookItem book) {
    final l10n = AppLocalizations.of(context);
    final reviews = book.reviews;
    final canReview = _canReview(book);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.reviewsAndRatings,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF243041),
                ),
              ),
            ),
            if (reviews.isNotEmpty) ...[
              const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
              const SizedBox(width: 4),
              Text(
                book.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF243041),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${l10n.reviewsCount(reviews.length)})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8E98A5)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          l10n.seeWhatOthersSaying,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8E98A5)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canReview
                ? () => _openReview(book)
                : () => showTopToast(
                      context,
                      title: l10n.reviewAfterDelivery,
                      type: ToastType.info,
                      icon: Icons.local_shipping_outlined,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canReview
                  ? const Color(0xFF5A91C4)
                  : const Color(0xFFC5CDD6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(
              canReview ? Icons.edit_outlined : Icons.lock_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              l10n.writeAReview,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (!canReview) ...[
          const SizedBox(height: 8),
          Text(
            l10n.reviewAfterDelivery,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8E98A5)),
          ),
        ],
        const SizedBox(height: 16),
        if (reviews.isEmpty)
          Text(
            l10n.noReviewsYet,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E98A5),
              height: 1.5,
            ),
          )
        else
          ...reviews.map((review) => _ReviewTile(review: review)),
      ],
    );
  }

  Future<void> _openReview(BookItem book) async {
    final l10n = AppLocalizations.of(context);
    final reviewerName = ref.read(authControllerProvider).fullName;
    final result = await ReviewBottomSheet.show(
      context,
      reviewerName: reviewerName,
    );
    if (result == null || !mounted) return;

    final response = await ref
        .read(orderRepositoryProvider)
        .submitBookReview(
          bookId: book.id,
          rating: result.rating,
          comment: result.comment,
        );
    if (!mounted) return;

    switch (response) {
      case Success():
        showTopToast(
          context,
          title: l10n.reviewSubmitted,
          type: ToastType.success,
        );
        // Refetch so the new review + average rating appear immediately.
        ref.invalidate(bookDetailProvider(widget.book.id));
      case ResultFailure(error: final e):
        showTopToast(context, title: e.message, type: ToastType.error);
    }
  }
}

/// A single review row in the Book Details "Reviews & Ratings" list.
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final BookReview review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFF3F8FC),
                backgroundImage: AssetImage(
                  'assets/images/profile_placeholder.png',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName.isNotEmpty ? review.userName : 'Anonymous',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF243041),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 2),
                        Text(
                          review.rating.toDouble().toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E98A5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (review.createdAt != null)
                Text(
                  l10n.timeAgo(review.createdAt!),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8E98A5)),
                ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF56606B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
