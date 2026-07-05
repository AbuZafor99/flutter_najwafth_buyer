import 'package:flutter/material.dart';

enum AppLanguage { english, french }

enum PaymentMethod { paypal, stripe }

extension AppLanguageX on AppLanguage {
  Locale get locale => switch (this) {
    AppLanguage.english => const Locale('en'),
    AppLanguage.french => const Locale('fr'),
  };

  String get label => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.french => 'France',
  };

  String get flag => switch (this) {
    AppLanguage.english => '🇬🇧',
    AppLanguage.french => '🇫🇷',
  };
}

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.paypal => 'Paypal',
    PaymentMethod.stripe => 'stripe',
  };
}

final class BookCategory {
  const BookCategory({
    required this.id,
    required this.name,
    required this.color,
    this.previewImageAsset,
    this.previewImageUrl,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    String? imageUrl;

    if (image is Map<String, dynamic>) {
      imageUrl = image['url']?.toString();
    }

    return BookCategory(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      color: _parseCategoryColor(json['color']),
      previewImageUrl: (imageUrl != null && imageUrl.isNotEmpty)
          ? imageUrl
          : null,
    );
  }

  final String id;
  final String name;
  final Color color;
  final String? previewImageAsset;
  final String? previewImageUrl;
}

Color _parseCategoryColor(dynamic input) {
  final fallback = const Color(0xFFE8EEF6);
  if (input == null) return fallback;

  final raw = input.toString().trim();
  if (raw.isEmpty) return fallback;

  final hex = raw.startsWith('#') ? raw.substring(1) : raw;
  final normalized = hex.length == 6 ? 'FF$hex' : hex;

  final value = int.tryParse(normalized, radix: 16);
  return value == null ? fallback : Color(value);
}

final class BookItem {
  const BookItem({
    required this.id,
    required this.title,
    required this.author,
    this.coverImageAsset,
    this.coverImageUrl,
    required this.price,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.description = '',
    this.categoryId = '',
    this.categoryName = '',
    this.coverColor = const Color(0xFF4A7CC8),
    this.coverAccent = const Color(0xFFE8F0FE),
    this.stock = true,
    this.shopName,
    this.isFeatured = false,
    this.isPopular = false,
  });

  factory BookItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final shop = json['shopId'];

    String categoryId = '';
    String categoryName = '';
    if (category is Map<String, dynamic>) {
      categoryId = category['_id']?.toString() ?? '';
      categoryName = category['name']?.toString() ?? '';
    } else if (category != null) {
      categoryId = category.toString();
    }

    String? shopName;
    if (shop is Map<String, dynamic>) {
      shopName = shop['name']?.toString();
    }

    var coverImage = json['coverImage']?.toString();
    if (coverImage == null || coverImage.isEmpty) {
      final photos = json['photos'];
      if (photos is List && photos.isNotEmpty) {
        coverImage = photos.first?.toString();
      }
    }

    final rawId = (json['_id'] ?? json['id'])?.toString() ?? '';
    final rawStock = json['stock'];
    final inStock = switch (rawStock) {
      bool value => value,
      num value => value > 0,
      String value => int.tryParse(value) != null
          ? int.parse(value) > 0
          : value.toLowerCase() == 'true',
      _ => true,
    };

    return BookItem(
      id: rawId,
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      coverImageUrl: (coverImage != null && coverImage.isNotEmpty)
          ? coverImage
          : null,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      categoryId: categoryId,
      categoryName: categoryName,
      stock: inStock,
      shopName: shopName,
      isPopular: true,
    );
  }

  final String id;
  final String title;
  final String author;
  final String? coverImageAsset;
  final String? coverImageUrl;
  final double price;
  final double rating;
  final int reviewCount;
  final String description;
  final String categoryId;
  final String categoryName;
  final Color coverColor;
  final Color coverAccent;
  final bool stock;
  final String? shopName;
  final bool isFeatured;
  final bool isPopular;
}

final class CheckoutInput {
  const CheckoutInput({
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.paymentMethod,
  });

  final String name;
  final String address;
  final String city;
  final String phone;
  final PaymentMethod paymentMethod;
}

final class OrderReceipt {
  const OrderReceipt({
    required this.orderNumber,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.paymentMethod,
  });

  final String orderNumber;
  final String customerName;
  final String address;
  final String phone;
  final List<BookItem> items;
  final double subtotal;
  final double deliveryFee;
  final PaymentMethod paymentMethod;

  double get total => subtotal + deliveryFee;
}
