import 'package:flutter/material.dart';
import '../../domain/bookstore.dart';

class BookstoreCard extends StatelessWidget {
  const BookstoreCard({super.key, required this.store, this.onTap});
  final Bookstore store;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE3EAF3)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 2.2,
            child: store.primaryImageUrl == null
                ? const _BannerPlaceholder()
                : Image.network(
                    store.primaryImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : const _BannerPlaceholder(),
                    errorBuilder: (_, _, _) => const _BannerPlaceholder(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF243041),
                  ),
                ),
                if (store.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF9CA6B3),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA6B3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/bookstore_placeholder.png',
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    semanticLabel: 'Default bookstore image',
    errorBuilder: (context, error, stackTrace) => const ColoredBox(
      color: Color(0xFFE6EFF8),
      child: Center(
        child: Icon(
          Icons.storefront_outlined,
          size: 44,
          color: Color(0xFF5A91C4),
        ),
      ),
    ),
  );
}
