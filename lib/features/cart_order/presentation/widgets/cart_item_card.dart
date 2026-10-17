import 'package:flutter/material.dart';
import '../../../home/domain/store_models.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.book,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  final BookItem book;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EBF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Book Cover
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8EBF0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverImageUrl != null
                  ? Image.network(
                      book.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        color: book.coverColor,
                        child: const Icon(Icons.book, color: Colors.white),
                      ),
                    )
                  : Image.asset(
                      book.coverImageAsset ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        color: book.coverColor,
                        child: const Icon(Icons.book, color: Colors.white),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Right: Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF243041),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline, color: Color(0xFFE55B5B), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E98A5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF5A91C4)),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        '123 Library St, Book City',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8E98A5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '£${book.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5A91C4),
                          ),
                        ),
                        Text(
                          'Total: £${(book.price * quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8E98A5),
                          ),
                        ),
                      ],
                    ),
                    // Stepper
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8FC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              width: 28,
                              color: Colors.transparent,
                              child: const Center(
                                child: Icon(Icons.remove, size: 16, color: Color(0xFF243041)),
                              ),
                            ),
                          ),
                          Container(
                            width: 24,
                            alignment: Alignment.center,
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF243041),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onAdd,
                            child: Container(
                              width: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE8EBF0)),
                              ),
                              child: const Center(
                                child: Icon(Icons.add, size: 16, color: Color(0xFF243041)),
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
        ],
      ),
    );
  }
}
