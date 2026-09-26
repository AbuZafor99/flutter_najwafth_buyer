import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_najwafth_buyer/core/localization/app_localizations.dart';
import 'package:flutter_najwafth_buyer/core/network/api_client.dart';
import 'package:flutter_najwafth_buyer/core/network/network_providers.dart';
import 'package:flutter_najwafth_buyer/core/notifications/push_notification_service.dart';
import 'package:flutter_najwafth_buyer/core/storage/storage_providers.dart';
import 'package:flutter_najwafth_buyer/features/home/application/book_provider.dart';
import 'package:flutter_najwafth_buyer/features/home/domain/store_models.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/pages/home_page.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/pages/books_grid_page.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/pages/public_category_books_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const category = BookCategory(
  id: 'fiction-id',
  name: 'Fiction',
  color: Color(0xFFE8EEF6),
);

const cachedBook = BookItem(
  id: 'cached-book',
  title: 'Cached Fiction',
  author: 'Author',
  price: 8,
  categoryId: 'fiction-id',
);

class _TestPushService extends PushNotificationService {
  _TestPushService(super.ref);

  @override
  Future<void> start() async {}
}

String _unexpiredJwt() {
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'exp':
            DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch ~/
            1000,
      }),
    ),
  );
  return 'header.$payload.signature';
}

Map<String, dynamic> _booksPayload(String title, String id) => {
  'success': true,
  'data': {
    'books': [
      {
        '_id': id,
        'title': title,
        'author': 'Author',
        'price': 12,
        'stock': 3,
        'category': {'_id': category.id, 'name': category.name},
      },
    ],
    'meta': {'page': 1, 'limit': 100, 'total': 1, 'totalPage': 1},
  },
};

ApiClient _apiClient({
  bool failCategoryBooks = false,
  bool emptyCategory = false,
  Completer<void>? categoryGate,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/books' &&
            options.queryParameters['category'] != null) {
          if (failCategoryBooks) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 503,
                  data: {'success': false, 'message': 'Catalog unavailable'},
                ),
              ),
            );
            return;
          }
          if (categoryGate != null) {
            categoryGate.future.then((_) {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: _booksPayload('Category Book', 'category-book'),
                ),
              );
            });
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: emptyCategory
                  ? {
                      'success': true,
                      'data': {'books': <Object>[], 'meta': <String, Object>{}},
                    }
                  : _booksPayload('Category Book', 'category-book'),
            ),
          );
          return;
        }

        final data = switch (options.path) {
          '/books' => _booksPayload('Home Book', 'home-book'),
          '/books/category-book' => {
            'success': true,
            'data': {
              '_id': 'category-book',
              'title': 'Category Book',
              'author': 'Author',
              'price': 12,
              'stock': 3,
              'category': {'_id': category.id, 'name': category.name},
            },
          },
          '/shop/public' => {
            'success': true,
            'data': {
              'shops': <Object>[],
              'pagination': {'page': 1, 'totalPages': 0},
            },
          },
          '/category/tree/all' => {
            'success': true,
            'data': [
              {'_id': category.id, 'name': category.name},
            ],
          },
          _ => {'success': true, 'data': <String, Object>{}},
        };
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: data,
          ),
        );
      },
    ),
  );
  return ApiClient(dio);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'public category GET strips Authorization and sends category ID',
    () async {
      SharedPreferences.setMockInitialValues({
        'buyer_is_authenticated': true,
        'buyer_access_token': 'stored-access-token',
        'buyer_refresh_token': 'stored-refresh-token',
      });
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      final dio = container.read(dioProvider);
      RequestOptions? request;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: _booksPayload('Category Book', 'category-book'),
              ),
            );
          },
        ),
      );

      final result = await container
          .read(bookRepositoryProvider)
          .getPublicCategoryBooks(categoryId: category.id);

      expect(request?.path, '/books');
      expect(request?.queryParameters['category'], category.id);
      expect(
        request?.headers.keys.any(
          (key) => key.toLowerCase() == 'authorization',
        ),
        isFalse,
      );
      expect(result.dataOrNull?.books.single.title, 'Category Book');
    },
  );

  testWidgets('guest category opens books, details, and purchase gate', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiClientProvider.overrideWithValue(_apiClient()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          home: HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(category.name),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(category.name));
    await tester.pumpAndSettle();
    expect(find.byType(PublicCategoryBooksPage), findsOneWidget);
    expect(find.text('Category Book'), findsWidgets);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(
      find.text('Please sign in or create an account to purchase this book.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Category Book').first);
    await tester.pumpAndSettle();
    expect(find.text('Add to Cart'), findsOneWidget);
    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();
    expect(
      find.text('Please sign in or create an account to purchase this book.'),
      findsOneWidget,
    );
  });

  testWidgets('authenticated category keeps the original grid route', (
    tester,
  ) async {
    final jwt = _unexpiredJwt();
    SharedPreferences.setMockInitialValues({
      'buyer_is_authenticated': true,
      'buyer_access_token': jwt,
      'buyer_refresh_token': jwt,
      'buyer_role': 'buyer',
    });
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiClientProvider.overrideWithValue(_apiClient()),
          pushNotificationServiceProvider.overrideWith(_TestPushService.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          home: HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(category.name),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(category.name));
    await tester.pumpAndSettle();
    expect(find.byType(BooksGridPage), findsOneWidget);
    expect(find.byType(PublicCategoryBooksPage), findsNothing);
    expect(find.text('Category Book'), findsWidgets);
  });

  testWidgets('category request failure shows cached books and retry', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiClientProvider.overrideWithValue(
            _apiClient(failCategoryBooks: true),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: PublicCategoryBooksPage(
            category: category,
            cachedBooks: const [cachedBook],
            onBookTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cached Fiction'), findsWidgets);
    expect(
      find.text('Showing available books from the catalog.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('public category shows placeholders while loading', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final gate = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiClientProvider.overrideWithValue(_apiClient(categoryGate: gate)),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: PublicCategoryBooksPage(
            category: category,
            cachedBooks: const [],
            onBookTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('public-category-loading')), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Category Book'), findsWidgets);
  });

  testWidgets('empty public category explains that no books were found', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiClientProvider.overrideWithValue(_apiClient(emptyCategory: true)),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: PublicCategoryBooksPage(
            category: category,
            cachedBooks: const [],
            onBookTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No books found in this category'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
