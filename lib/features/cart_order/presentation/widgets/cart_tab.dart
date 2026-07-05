import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../home/application/store_controller.dart';
import '../../../home/domain/store_models.dart';
import 'cart_item_card.dart';

class CartTab extends ConsumerWidget {
  const CartTab({
    super.key,
    required this.onCheckoutTap,
    required this.onHomeTap,
  });

  final VoidCallback onCheckoutTap;
  final VoidCallback onHomeTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final storeState = ref.watch(storeControllerProvider);
    final catalog = ref.watch(storeCatalogProvider);

    final cartItems = storeState.cartQuantities.entries
        .where((e) => catalog.any((b) => b.id == e.key))
        .map((e) => MapEntry(catalog.firstWhere((b) => b.id == e.key), e.value))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          l10n.myCart,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243041),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : _buildFilledCart(context, cartItems, ref, storeState),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: CustomPaint(
          painter: _DashedRectPainter(color: const Color(0xFF5A91C4)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F8FC),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Color(0xFF5A91C4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.yourCartIsEmpty,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF243041),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.cartEmptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E98A5),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onHomeTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A91C4),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l10n.browseBooks,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilledCart(
    BuildContext context,
    List<MapEntry<BookItem, int>> cartItems,
    WidgetRef ref,
    StoreState storeState,
  ) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index].key;
              final quantity = cartItems[index].value;
              return CartItemCard(
                book: item,
                quantity: quantity,
                onAdd: () => ref.read(storeControllerProvider.notifier).addToCart(item),
                onRemove: () => ref.read(storeControllerProvider.notifier).setQuantity(item, quantity - 1),
                onDelete: () => ref.read(storeControllerProvider.notifier).setQuantity(item, 0),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.totalPrice,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E98A5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${ref.read(storeControllerProvider.notifier).subtotal(cartItems.map((e) => e.key).toList()).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF243041),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: onCheckoutTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A91C4),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l10n.proceedToCheckout,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    
    // Top border
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
    // Right border
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
    // Bottom border
    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(Offset(startX, size.height), Offset(startX - dashWidth, size.height), paint);
      startX -= dashWidth + dashSpace;
    }
    // Left border
    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
