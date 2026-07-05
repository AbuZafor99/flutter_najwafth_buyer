import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/order_models.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  static const Color _accentBlue = Color(0xFF2E9BE5);
  static const Color _titleColor = Color(0xFF243041);
  static const Color _subtleColor = Color(0xFF8E98A5);

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final firstItem = order.items.isNotEmpty ? order.items.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Book Cover
            _CoverImage(item: firstItem, size: 72),
            const SizedBox(width: 14),
            // Right: Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstItem?.title ?? l10n.unknownItem,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _titleColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              firstItem?.author ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: _subtleColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: _accentBlue,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '123 Library, Book City', // Static per requirements
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: _subtleColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      _StatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Thumbnails for items
                      _ItemThumbnails(items: order.items),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$ ${order.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _accentBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.itemCount(order.items.length),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: _accentBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: _accentBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded book cover with graceful fallback to the item's solid color.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.item, required this.size});

  final dynamic item;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEDF1F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.book_outlined, color: Color(0xFF9CA6B3)),
      );
    }

    final fallback = Container(
      color: item.coverColor,
      child: const Icon(Icons.book, color: Colors.white),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: item.coverImageUrl != null
            ? Image.network(
                item.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : Image.asset(
                item.coverImageAsset ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

/// Coloured status pill (Pending / Processing / Picked / Delivered).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label(l10n),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: status.textColor,
        ),
      ),
    );
  }
}

/// Overlapping circular thumbnails of the first few items in the order.
class _ItemThumbnails extends StatelessWidget {
  const _ItemThumbnails({required this.items});

  final List items;

  @override
  Widget build(BuildContext context) {
    final count = items.length > 3 ? 3 : items.length;
    if (count == 0) return const SizedBox(height: 28, width: 0);

    return SizedBox(
      height: 28,
      width: 28 + (count - 1) * 16.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(count, (index) {
          final item = items[index];
          return Positioned(
            left: index * 16.0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: item.coverColor,
                image: item.coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(item.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : item.coverImageAsset != null
                    ? DecorationImage(
                        image: AssetImage(item.coverImageAsset!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
