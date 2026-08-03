import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class OrderConfirmedSheet extends StatelessWidget {
  const OrderConfirmedSheet({
    super.key,
    required this.onBackToHome,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  final VoidCallback onBackToHome;
  final double subtotal;
  final double deliveryFee;
  final double total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Party popper icon - we can use an emoji or Icon
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            l10n.orderConfirmed,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A91C4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.orderPlacedSuccessfully,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8E98A5),
            ),
          ),
          const SizedBox(height: 24),
          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.status}:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.pending,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF5A623)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Order Summary
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.orderSummary,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(l10n.subtotal, '\$${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow(l10n.deliveryFee, '\$${deliveryFee.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE8EBF0), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.total,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF243041)),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF5A91C4)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Payment
          Row(
            children: [
              const Icon(Icons.payment_outlined, size: 16, color: Color(0xFF5A91C4)),
              const SizedBox(width: 8),
              Text(
                l10n.payment,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF243041)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.stripe,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6772E5)),
            ),
          ),
          const SizedBox(height: 16),
          // Review-after-delivery hint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.rate_review_outlined, size: 18, color: Color(0xFF5A91C4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.reviewAfterDelivery,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF56606B),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Back to home button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onBackToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A91C4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.home_outlined, color: Colors.white, size: 20),
              label: Text(
                l10n.backToHome,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
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

  static Future<void> show(BuildContext context, {
    required VoidCallback onBackToHome,
    required double subtotal,
    required double deliveryFee,
    required double total,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => OrderConfirmedSheet(
        onBackToHome: onBackToHome,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
      ),
    );
  }
}
