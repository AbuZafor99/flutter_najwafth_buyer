import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../../home/application/book_provider.dart';
import '../../../home/application/store_controller.dart';
import '../../../home/domain/store_models.dart';

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

                // ── Category chip ─────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
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
}
