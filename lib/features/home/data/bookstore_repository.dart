import 'package:dio/dio.dart';

import '../../../core/errors/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/bookstore.dart';

class BookstoreRepository {
  const BookstoreRepository(this._client);
  final ApiClient _client;

  Future<Result<BookstoresResponse>> getStores({
    int page = 1,
    int limit = 12,
  }) => _client.get(
    '/shop/public',
    queryParameters: {'page': page, 'limit': limit},
    options: Options(extra: const {'skipAuth': true}),
    parser: (json) {
      if (json is! Map<String, dynamic> || json['success'] != true) {
        throw const FormatException('Invalid bookstore response');
      }
      final data = json['data'];
      final pagination = json['pagination'];
      if (data is! List<dynamic> || pagination is! Map<String, dynamic>) {
        throw const FormatException('Invalid bookstore response');
      }
      final currentPage = _intValue(pagination['page'], fallback: page);
      final totalPages = _intValue(pagination['totalPages']);
      return BookstoresResponse(
        stores: data
            .whereType<Map<String, dynamic>>()
            .map(
              (item) => Bookstore.fromJson(item, apiBaseUrl: _client.baseUrl),
            )
            .toList(growable: false),
        page: currentPage,
        limit: _intValue(pagination['limit'], fallback: limit),
        total: _intValue(pagination['total']),
        totalPages: totalPages,
        hasNextPage:
            pagination['hasNextPage'] == true || currentPage < totalPages,
      );
    },
  );
}

int _intValue(Object? value, {int fallback = 0}) => switch (value) {
  final num number => number.toInt(),
  final String text => int.tryParse(text) ?? fallback,
  _ => fallback,
};
