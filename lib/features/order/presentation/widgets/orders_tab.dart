import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/order_controller.dart';
import '../../domain/order_models.dart';
import '../pages/order_details_page.dart';
import 'order_card.dart';

/// Brand gradient used for the selected filter chip (matches the Figma design).
const LinearGradient _kSelectedChipGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF6BA3D6), Color(0xFF5680AB)],
);

class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key, required this.onCheckoutTap});

  final VoidCallback onCheckoutTap;

  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> {
  String _selectedFilter = OrderStatusFilter.all.name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ordersAsync = ref.watch(orderControllerProvider);

    final orders = ordersAsync.asData?.value ?? const <OrderModel>[];
    final filteredOrders = _selectedFilter == OrderStatusFilter.all.name
        ? orders
        : orders
              .where(
                (o) =>
                    o.status.name == _selectedFilter,
              )
              .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          l10n.myOrders,
          style: TextStyle(
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
      body: Column(
        children: [
          // Filter Chips Row
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(context, OrderStatusFilter.all.name, orders.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  OrderStatus.pending.name,
                  orders.where((o) => o.status == OrderStatus.pending).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  OrderStatus.processing.name,
                  orders
                      .where((o) => o.status == OrderStatus.processing)
                      .length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  OrderStatus.picked.name,
                  orders.where((o) => o.status == OrderStatus.picked).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  OrderStatus.delivered.name,
                  orders.where((o) => o.status == OrderStatus.delivered).length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Order List
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF5A91C4)),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.failedToLoadOrders,
                      style: TextStyle(color: Color(0xFF8E98A5), fontSize: 14),
                    ),
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
                  ? Center(
                      child: Text(
                        l10n.noOrdersFound,
                        style: TextStyle(
                          color: Color(0xFF8E98A5),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(orderControllerProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return OrderCard(
                            order: order,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      OrderDetailsPage(order: order),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String filter, int count) {
    final l10n = AppLocalizations.of(context);
    final label = switch (filter) {
      'pending' => l10n.pending,
      'processing' => l10n.processing,
      'picked' => l10n.picked,
      'delivered' => l10n.delivered,
      _ => l10n.all,
    };
    String displayLabel = label;
    if (filter == OrderStatus.pending.name || filter == OrderStatus.picked.name) {
      if (count > 0) {
        displayLabel = '$label ($count)';
      }
    }

    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected ? _kSelectedChipGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFF5A91C4), width: 1.4),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF5A91C4),
          ),
        ),
      ),
    );
  }
}

enum OrderStatusFilter { all }
