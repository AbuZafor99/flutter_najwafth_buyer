import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/store_models.dart';

final _currencyFormatter = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 2,
);

String formatPrice(double value) => _currencyFormatter.format(value);

/// Small availability pill shown on book cards: a soft green "In Stock" or
/// a soft red "Stock Out", with a matching status dot.
class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.inStock, this.compact = false});

  final bool inStock;

  /// Slightly smaller variant for tight card layouts.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = inStock ? const Color(0xFF1E9E4A) : const Color(0xFFE5484D);
    final background =
        inStock ? const Color(0xFFE7F6EC) : const Color(0xFFFDECEC);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            inStock ? l10n.inStock : l10n.stockOut,
            style: TextStyle(
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class StorePageScaffold extends StatelessWidget {
  const StorePageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.actions = const [],
    this.bottomNavigationBar,
    this.backgroundColor = Colors.white,
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottomNavigationBar;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: bottomNavigationBar,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        leading: leading,
        titleSpacing: leading == null ? 16 : 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF28303F),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: actions,
      ),
      body: SafeArea(child: child),
    );
  }
}

class StoreSearchField extends StatelessWidget {
  const StoreSearchField({super.key, required this.hintText, this.onChanged});

  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF4F5F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF738194),
          size: 20,
        ),
        suffixIcon: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6E93BD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.tune, color: Colors.white, size: 18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6E93BD)),
        ),
      ),
    );
  }
}

class SectionTitleRow extends StatelessWidget {
  const SectionTitleRow({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF28303F),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: Color(0xFF6E93BD),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class CategoryChipCard extends StatelessWidget {
  const CategoryChipCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final BookCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EBF0)),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BookCover(
              title: category.name,
              imageAsset: category.previewImageAsset,
              color: category.color,
              accentColor: Colors.white.withValues(alpha: .85),
              height: 56,
              radius: 10,
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF344053),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.width = 126,
    this.compact = false,
    this.trailing,
  });

  final BookItem book;
  final VoidCallback onTap;
  final double width;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                BookCover(
                  title: book.title,
                  imageAsset: book.coverImageAsset,
                  imageUrl: book.coverImageUrl,
                  color: book.coverColor,
                  accentColor: book.coverAccent,
                  height: compact ? 110 : 118,
                ),
                if (trailing != null)
                  Positioned(top: 8, right: 8, child: trailing!),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF243041),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF95A0AF),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFF1BA3C), size: 13),
                const SizedBox(width: 4),
                Text(
                  book.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF677385),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatPrice(book.price),
              style: const TextStyle(
                color: Color(0xFF4B91F1),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookGridTile extends StatelessWidget {
  const BookGridTile({super.key, required this.book, required this.onTap});

  final BookItem book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EBF0)),
      ),
      child: BookCard(
        book: book,
        onTap: onTap,
        width: double.infinity,
        compact: true,
      ),
    );
  }
}

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    this.imageAsset,
    this.imageUrl,
    required this.color,
    required this.accentColor,
    this.height = 118,
    this.radius = 14,
  });

  final String title;
  final String? imageAsset;
  final String? imageUrl;
  final Color color;
  final Color accentColor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = _BookCoverFallback(
      title: title,
      color: color,
      accentColor: accentColor,
      height: height,
      radius: radius,
    );

    Widget? imageWidget;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      );
    } else if (imageAsset != null && imageAsset!.isNotEmpty) {
      imageWidget = Image.asset(
        imageAsset!,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => fallback,
      );
    }

    if (imageWidget == null) return fallback;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: imageWidget,
      ),
    );
  }
}

class _BookCoverFallback extends StatelessWidget {
  const _BookCoverFallback({
    required this.title,
    required this.color,
    required this.accentColor,
    required this.height,
    required this.radius,
  });

  final String title;
  final Color color;
  final Color accentColor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: .85)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Icon(Icons.auto_stories, color: accentColor, size: 18),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .82),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF293241),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onTap,
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF364152),
            ),
          ),
          if (count > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF4B91F1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9DEE8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove,
            onTap: () => onChanged(quantity - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 16, color: const Color(0xFF475569)),
      ),
    );
  }
}
