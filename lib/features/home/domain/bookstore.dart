/// Public storefront data. [ownerId] is the seller ID used by /books?shopId=.
class Bookstore {
  const Bookstore({
    required this.ownerId,
    required this.name,
    this.description = '',
    this.address = '',
    this.bannerUrl,
  });

  final String ownerId;
  final String name;
  final String description;
  final String address;
  final String? bannerUrl;

  factory Bookstore.fromJson(Map<String, dynamic> json) {
    final ownerId = json['ownerId']?.toString() ?? '';
    if (!RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(ownerId)) {
      throw const FormatException('Invalid bookstore owner ID');
    }
    final banners = json['banner'] as List<dynamic>? ?? [];
    final urls = banners
        .whereType<Map<String, dynamic>>()
        .map((banner) => banner['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty);
    return Bookstore(
      ownerId: ownerId,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      bannerUrl: urls.isEmpty ? null : urls.first,
    );
  }
}

class BookstoresResponse {
  const BookstoresResponse({
    required this.stores,
    required this.page,
    required this.totalPages,
  });
  final List<Bookstore> stores;
  final int page;
  final int totalPages;
}
