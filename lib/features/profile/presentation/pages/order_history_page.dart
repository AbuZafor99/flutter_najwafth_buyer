import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../order/application/order_controller.dart';
import '../../../order/domain/order_models.dart';
import '../../../order/presentation/pages/order_details_page.dart';
import '../../../order/presentation/widgets/order_card.dart';

class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(orderControllerProvider);
    final orders = ordersAsync.asData?.value ?? const <OrderModel>[];

    final filteredOrders = orders.where((order) {
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'completed') {
        return order.status == OrderStatus.delivered;
      }
      if (_selectedFilter == 'picked') {
        return order.status == OrderStatus.picked;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.chevron_left,
            color: Color(0xFF243041),
            size: 28,
          ),
        ),
        title: Text(
          l10n.orderHistory,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243041),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip(context, 'all'),
                const SizedBox(width: 12),
                _buildFilterChip(
                  context,
                  'completed',
                  count: orders
                      .where((o) => o.status == OrderStatus.delivered)
                      .length,
                ),
                const SizedBox(width: 12),
                _buildFilterChip(
                  context,
                  'picked',
                  count: orders
                      .where((o) => o.status == OrderStatus.picked)
                      .length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF5A91C4)),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.failedToLoadOrders),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(orderControllerProvider.notifier).refresh(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (_) => filteredOrders.isEmpty
                  ? Center(child: Text(l10n.noOrdersFound))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return OrderCard(
                          order: order,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsPage(order: order),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String filter, {int? count}) {
    final l10n = AppLocalizations.of(context);
    final label = switch (filter) {
      'completed' => l10n.completed,
      'picked' => l10n.picked,
      _ => l10n.all,
    };
    final isSelected = _selectedFilter == filter;
    final displayLabel = count != null ? '$label ($count)' : label;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A91C4) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5A91C4)
                : const Color(0xFFE8EBF0),
            width: 1,
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF5A91C4),
          ),
        ),
      ),
    );
  }
}
