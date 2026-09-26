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
      final data = json['data'] as Map<String, dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>;
      return BookstoresResponse(
        stores: (data['shops'] as List<dynamic>)
            .map((item) => Bookstore.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        page: (pagination['page'] as num).toInt(),
        totalPages: (pagination['totalPages'] as num).toInt(),
      );
    },
  );
}
