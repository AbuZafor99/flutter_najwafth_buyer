import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../application/order_controller.dart';
import '../../domain/order_models.dart';
import '../widgets/review_bottom_sheet.dart';

/// Soft-shadowed white card used throughout the order details screen.
BoxDecoration _cardDecoration({double radius = 16}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ],
);

class OrderDetailsPage extends ConsumerWidget {
  const OrderDetailsPage({super.key, required this.order});

  static const Color _accentBlue = Color(0xFF2E9BE5);

  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF243041), size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.orderDetails,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243041),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDeliveryAndContact(context),
            const SizedBox(height: 16),
            _buildOrderSummary(context),
            const SizedBox(height: 16),
            _buildItemsList(context),
            const SizedBox(height: 16),
            _buildTimeline(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: order.status == OrderStatus.delivered
          ? FloatingActionButton.extended(
              onPressed: () => _openReview(context, ref),
              backgroundColor: _accentBlue,
              icon: const Icon(Icons.rate_review, color: Colors.white),
              label: Text(
                l10n.leaveAReview,
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Future<void> _openReview(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    final result = await ReviewBottomSheet.show(
      context,
      reviewerName: order.customerName,
    );
    if (result == null) return;

    final repository = ref.read(orderRepositoryProvider);
    final bookIds = order.items
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

    showTopToast(
      null,
      overlay: overlay,
      title: submitted ? l10n.reviewSubmitted : (errorMessage ?? l10n.reviewSubmitted),
      type: submitted ? ToastType.success : ToastType.error,
    );
  }

  Widget _buildDeliveryAndContact(BuildContext context) {
    final dateStr = '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: _accentBlue),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).deliveryAddress,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  order.address,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8E98A5), height: 1.5),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: const Color(0xFFE8EBF0), margin: const EdgeInsets.symmetric(horizontal: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_in_talk_outlined, size: 16, color: _accentBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).contactInformation,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow(AppLocalizations.of(context).orderDate, dateStr),
                const SizedBox(height: 4),
                _buildInfoRow(AppLocalizations.of(context).phone, order.phone),
                const SizedBox(height: 4),
                _buildInfoRow(AppLocalizations.of(context).orderId, order.orderNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8E98A5)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 20, color: _accentBlue),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).orderSummary,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(AppLocalizations.of(context).subtotal, '\$${order.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow(AppLocalizations.of(context).deliveryFee, '\$${order.deliveryFee.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE8EBF0), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).total,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF243041)),
              ),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _accentBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8E98A5)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
        ),
      ],
    );
  }

  Widget _buildItemsList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 20, color: _accentBlue),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).itemsCount(order.items.length),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...order.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: _cardDecoration(radius: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE8EBF0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.coverImageUrl != null
                            ? Image.network(
                                item.coverImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => Container(
                                  color: item.coverColor,
                                  child: const Icon(Icons.book, color: Colors.white),
                                ),
                              )
                            : Image.asset(
                                item.coverImageAsset ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => Container(
                                  color: item.coverColor,
                                  child: const Icon(Icons.book, color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF8E98A5), fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: _accentBlue),
                              const SizedBox(width: 4),
                              const Expanded(
                                child: Text(
                                  '123 Library, Book City',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10, color: Color(0xFF8E98A5)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
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
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$ ${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _accentBlue),
                                  ),
                                  Text(
                                    AppLocalizations.of(context).itemCount(1),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _accentBlue),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, size: 18, color: _accentBlue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    int currentStep = 0;
    if (order.status == OrderStatus.processing) currentStep = 1;
    if (order.status == OrderStatus.picked) currentStep = 2;
    if (order.status == OrderStatus.delivered) currentStep = 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 20, color: _accentBlue),
              const SizedBox(width: 8),
              Text(
                l10n.orderStatus,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTimelineItem(l10n.pending, l10n.orderReceivedByStore, isActive: currentStep >= 0, isLast: false),
          _buildTimelineItem(l10n.processing, l10n.storePreparingOrder, isActive: currentStep >= 1, isLast: false),
          _buildTimelineItem(l10n.picked, l10n.deliveryPartnerPickedUpOrder, isActive: currentStep >= 2, isLast: false),
          _buildTimelineItem(l10n.delivered, l10n.orderDeliveredSuccessfully, isActive: currentStep >= 3, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, {required bool isActive, required bool isLast}) {
    final color = isActive ? _accentBlue : const Color(0xFFD4D9E2);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : Colors.white,
                border: Border.all(color: color, width: 2),
              ),
              child: isActive
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: color,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isActive ? color : const Color(0xFF243041)),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: isActive ? color : const Color(0xFF8E98A5)),
              ),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
