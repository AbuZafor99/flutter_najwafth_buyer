import 'package:dio/dio.dart';

import '../../../core/errors/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/store_models.dart';

final class BooksResponse {
  const BooksResponse({required this.books, required this.meta});

  final List<BookItem> books;
  final BooksMeta meta;
}

final class BooksMeta {
  const BooksMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPage,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPage;
}

final class BookRepository {
  const BookRepository(this._client);

  final ApiClient _client;

  Future<Result<BooksResponse>> getBooks({
    String? search,
    String? categoryId,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
    };

    return _client.get<BooksResponse>(
      '/books',
      queryParameters: query,
      parser: _parseListResponse,
    );
  }

  Future<Result<BookItem>> getBook(String id) {
    return _client.get<BookItem>(
      '/books/$id',
      parser: (data) {
        _assertSuccess(data);
        final bookData = (data as Map<String, dynamic>)['data'];
        if (bookData is! Map<String, dynamic>) {
          throw Exception('Book data not found');
        }
        return BookItem.fromJson(bookData);
      },
    );
  }

  /// The catalog route is public. The request marker keeps any stored account
  /// header off guest category requests without changing authenticated calls.
  Future<Result<BooksResponse>> getPublicCategoryBooks({
    required String categoryId,
    int page = 1,
    int limit = 100,
  }) {
    return _client.get<BooksResponse>(
      '/books',
      queryParameters: {
        'category': categoryId,
        'page': page,
        'limit': limit,
        'sortBy': 'createdAt',
        'sortOrder': 'desc',
      },
      options: Options(extra: const {'skipAuth': true}),
      parser: _parseListResponse,
    );
  }

  static BooksResponse _parseListResponse(dynamic data) {
    _assertSuccess(data);
    final root = data as Map<String, dynamic>;
    final responseData = root['data'] as Map<String, dynamic>? ?? {};

    final books = (responseData['books'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(BookItem.fromJson)
        .toList(growable: false);

    final meta = responseData['meta'] as Map<String, dynamic>? ?? {};
    return BooksResponse(
      books: books,
      meta: BooksMeta(
        page: (meta['page'] as num?)?.toInt() ?? 1,
        limit: (meta['limit'] as num?)?.toInt() ?? 20,
        total: (meta['total'] as num?)?.toInt() ?? 0,
        totalPage: (meta['totalPage'] as num?)?.toInt() ?? 1,
      ),
    );
  }

  static void _assertSuccess(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid server response');
    }
    if (data['success'] == false) {
      throw Exception(data['message']?.toString() ?? 'Request failed');
    }
  }
}
