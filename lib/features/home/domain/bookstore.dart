/// Public storefront data. [id] is the seller User ID used by /books?shopId=.
class Bookstore {
  const Bookstore({
    required this.id,
    required this.name,
    this.logoUrl,
    this.bannerUrls = const [],
    this.description = '',
    this.address = '',
    this.bookCount = 0,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final List<String> bannerUrls;
  final String description;
  final String address;
  final int bookCount;

  String? get bannerUrl => bannerUrls.isEmpty ? null : bannerUrls.first;
  String? get primaryImageUrl => bannerUrl ?? logoUrl;

  factory Bookstore.fromJson(Map<String, dynamic> json, {String? apiBaseUrl}) {
    final id = json['id']?.toString() ?? '';
    if (!RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id)) {
      throw const FormatException('Invalid bookstore ID');
    }
    final rawBanners = json['banner'];
    final banners = rawBanners is List<dynamic>
        ? rawBanners
        : const <dynamic>[];
    final urls = banners
        .map(
          (banner) => banner is Map<String, dynamic>
              ? banner['url']?.toString()
              : banner?.toString(),
        )
        .map((url) => _publicImageUrl(url, apiBaseUrl))
        .whereType<String>()
        .toList(growable: false);
    return Bookstore(
      id: id,
      name: json['name']?.toString() ?? '',
      logoUrl: _publicImageUrl(json['logo']?.toString(), apiBaseUrl),
      bannerUrls: urls,
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      bookCount: switch (json['bookCount']) {
        final num value => value.toInt(),
        final String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
    );
  }
}

class BookstoresResponse {
  const BookstoresResponse({
    required this.stores,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
  });
  final List<Bookstore> stores;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
}

String? _publicImageUrl(String? rawValue, String? apiBaseUrl) {
  final value = rawValue?.trim();
  if (value == null || value.isEmpty || value == 'null') return null;

  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return uri.toString();
  }
  if (apiBaseUrl == null || apiBaseUrl.isEmpty) return value;

  final base = Uri.tryParse(apiBaseUrl);
  if (base == null || !base.hasScheme || base.host.isEmpty) return value;
  if (value.startsWith('//')) return '${base.scheme}:$value';

  return base
      .replace(
        path: value.startsWith('/') ? value : '/$value',
        query: null,
        fragment: null,
      )
      .toString();
}
