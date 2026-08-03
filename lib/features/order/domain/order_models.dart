import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../home/domain/store_models.dart';

enum OrderStatus { pending, processing, picked, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String label(AppLocalizations l10n) => switch (this) {
    OrderStatus.pending => l10n.pending,
    OrderStatus.processing => l10n.processing,
    OrderStatus.picked => l10n.picked,
    OrderStatus.delivered => l10n.delivered,
    OrderStatus.cancelled => l10n.cancelled,
  };

  Color get backgroundColor => switch (this) {
    OrderStatus.pending => const Color(0xFFFCE8A6),
    OrderStatus.processing => const Color(0xFF9FD7B4),
    OrderStatus.picked => const Color(0xFFFAD0AC),
    OrderStatus.delivered => const Color(0xFFCFE6FA),
    OrderStatus.cancelled => const Color(0xFFF6C9C9),
  };

  Color get textColor => switch (this) {
    OrderStatus.pending => const Color(0xFFB8860B),
    OrderStatus.processing => const Color(0xFF1F7A3D),
    OrderStatus.picked => const Color(0xFFD2761F),
    OrderStatus.delivered => const Color(0xFF2E9BE5),
    OrderStatus.cancelled => const Color(0xFFC0392B),
  };
}

final class OrderModel {
  const OrderModel({
    this.id = '',
    required this.orderNumber,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  /// Backend database id (`_id`), required for payment API calls.
  final String id;

  final String orderNumber;
  final String customerName;
  final String address;
  final String phone;
  final List<BookItem> items;
  final double subtotal;
  final double deliveryFee;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;

  double get total => subtotal + deliveryFee;

  OrderModel copyWith({OrderStatus? status}) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      customerName: customerName,
      address: address,
      phone: phone,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory OrderModel.fromReceipt(
    OrderReceipt receipt, {
    OrderStatus status = OrderStatus.pending,
  }) {
    return OrderModel(
      orderNumber: receipt.orderNumber,
      customerName: receipt.customerName,
      address: receipt.address,
      phone: receipt.phone,
      items: receipt.items,
      subtotal: receipt.subtotal,
      deliveryFee: receipt.deliveryFee,
      paymentMethod: receipt.paymentMethod,
      status: status,
      createdAt: DateTime.now(),
    );
  }

  factory OrderModel.fromApi(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final expandedItems = <BookItem>[];
    var subtotal = 0.0;

    for (final item in rawItems) {
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      final unitPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
      final product = item['product'];
      if (product is! Map<String, dynamic>) continue;

      final normalized = Map<String, dynamic>.from(product);
      normalized['price'] = unitPrice;
      if (normalized['_id'] == null) {
        normalized['_id'] = product['id']?.toString() ?? '';
      }

      final parsedBook = BookItem.fromJson(normalized);
      subtotal += unitPrice * quantity;
      for (var i = 0; i < quantity; i++) {
        expandedItems.add(parsedBook);
      }
    }

    final totalAmount = (json['totalAmount'] as num?)?.toDouble() ?? subtotal;
    // The backend stores the delivery charge in a dedicated `shippingFee`
    // field (see order.controller.createOrder). Prefer it; fall back to any
    // gap between totalAmount and the item subtotal for legacy orders.
    final shippingFee = (json['shippingFee'] as num?)?.toDouble();
    final deliveryFee =
        shippingFee ?? (totalAmount > subtotal ? (totalAmount - subtotal) : 0.0);
    final createdAtRaw = json['createdAt']?.toString();
    final addressRaw = json['address'];
    final details = json['addressDetails'];

    // Prefer the structured fields the app now stores; fall back to legacy
    // orders that only carried a customer populate / address string.
    final recipientName = json['recipientName']?.toString();
    final topLevelPhone = json['phone']?.toString();

    return OrderModel(
      id: json['_id']?.toString() ?? '',
      orderNumber: json['orderId']?.toString() ?? '',
      customerName: (recipientName != null && recipientName.trim().isNotEmpty)
          ? recipientName.trim()
          : _readCustomerName(json['customer']),
      address: _readAddress(details) ?? _readAddress(addressRaw) ?? 'N/A',
      phone: (topLevelPhone != null && topLevelPhone.trim().isNotEmpty)
          ? topLevelPhone.trim()
          : _readPhone(addressRaw),
      items: expandedItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      paymentMethod: PaymentMethod.stripe,
      status: _mapApiStatus(json['status']?.toString()),
      createdAt: createdAtRaw == null
          ? DateTime.now()
          : DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
    );
  }
}

OrderStatus _mapApiStatus(String? status) {
  return switch (status) {
    'pending' => OrderStatus.pending,
    'in_progress' => OrderStatus.processing,
    'processing' => OrderStatus.processing,
    'shipped' => OrderStatus.picked,
    'picked' => OrderStatus.picked,
    'delivered' => OrderStatus.delivered,
    'cancelled' => OrderStatus.cancelled,
    'canceled' => OrderStatus.cancelled,
    _ => OrderStatus.pending,
  };
}

String _readCustomerName(dynamic customer) {
  if (customer is Map<String, dynamic>) {
    final name = customer['name']?.toString();
    if (name != null && name.trim().isNotEmpty) return name.trim();
  }
  return 'Customer';
}

/// Builds a readable address from either the structured `addressDetails`
/// object, a legacy map, or a plain string. Returns null when nothing usable
/// is present so callers can fall back.
String? _readAddress(dynamic address) {
  if (address is String) {
    final trimmed = address.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (address is Map<String, dynamic>) {
    final parts = [
      address['line1'] ?? address['line'],
      address['line2'],
      [address['postalCode'], address['city'] ?? address['area']]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join(' '),
      address['state'],
      address['country'],
    ];
    final raw = parts
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');
    return raw.isEmpty ? null : raw;
  }
  return null;
}

String _readPhone(dynamic address) {
  if (address is Map<String, dynamic>) {
    final phone = address['phone']?.toString();
    if (phone != null && phone.trim().isNotEmpty) return phone.trim();
  }
  return 'N/A';
}
