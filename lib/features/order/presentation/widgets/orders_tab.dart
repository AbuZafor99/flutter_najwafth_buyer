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
            height: 38,
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

  /// Color for a tab's count so it matches its order status at a glance.
  /// [isSelected] chips sit on the blue gradient, so they use brighter tints
  /// that stay legible; unselected chips use the saturated status colors.
  Color _countColor(String filter, bool isSelected) {
    return switch (filter) {
      'pending' => isSelected
          ? const Color(0xFFFFD54F)
          : const Color(0xFFB8860B),
      'processing' => isSelected
          ? const Color(0xFF8FE6AE)
          : const Color(0xFF1F7A3D),
      'picked' => isSelected
          ? const Color(0xFFFFC48A)
          : const Color(0xFFD2761F),
      'delivered' => isSelected
          ? const Color(0xFFCDE8FB)
          : const Color(0xFF2E9BE5),
      _ => isSelected ? const Color(0xFFFFD54F) : const Color(0xFF5A91C4),
    };
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
    final isSelected = _selectedFilter == filter;

    // Show the count on every tab (All, Pending, Processing, Picked,
    // Delivered) so each filter surfaces how many orders it holds — but only
    // when there's at least one; a "(0)" adds no information. The number is
    // tinted to match its status color so the user links tab → status at a
    // glance. On the selected (blue gradient) chip we use brighter variants so
    // the number stays legible.
    final labelColor = isSelected ? Colors.white : _countColor(filter, false);
    final countColor = _countColor(filter, isSelected);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected ? _kSelectedChipGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFF5A91C4), width: 1.4),
        ),
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
            children: [
              TextSpan(text: label),
              if (count > 0)
                TextSpan(
                  text: ' ($count)',
                  style: TextStyle(
                    color: countColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum OrderStatusFilter { all }
