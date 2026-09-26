import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_najwafth_buyer/core/errors/result.dart';
import 'package:flutter_najwafth_buyer/core/localization/app_localizations.dart';
import 'package:flutter_najwafth_buyer/core/network/api_client.dart';
import 'package:flutter_najwafth_buyer/core/network/network_providers.dart';
import 'package:flutter_najwafth_buyer/core/storage/storage_providers.dart';
import 'package:flutter_najwafth_buyer/features/auth/presentation/auth_routes.dart';
import 'package:flutter_najwafth_buyer/features/cart_order/presentation/pages/book_details_page.dart';
import 'package:flutter_najwafth_buyer/features/home/application/bookstore_provider.dart';
import 'package:flutter_najwafth_buyer/features/home/application/book_provider.dart';
import 'package:flutter_najwafth_buyer/features/home/domain/bookstore.dart';
import 'package:flutter_najwafth_buyer/features/home/domain/store_models.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/pages/bookstores_page.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/pages/bookstore_books_page.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/widgets/bookstore_card.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/widgets/bookstore_carousel.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/widgets/book_card_mini.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/widgets/store_widgets.dart';

const ownerId = '111111111111111111111111';
const secondOwnerId = '333333333333333333333333';
const store = Bookstore(
  id: ownerId,
  name: 'First bookstore',
  address: 'Store address',
);
const book = BookItem(
  id: 'book-1',
  title: 'Store book',
  author: 'Author',
  price: 12,
);

Map<String, dynamic> storesPayload(int page, {bool empty = false}) => {
  'success': true,
  'data': empty
      ? []
      : [
          {
            'id': page == 1 ? ownerId : secondOwnerId,
            'name': page == 1 ? 'First bookstore' : 'Second bookstore',
            'logo': '/public/store-logo.png',
            'address': 'Store address',
            'banner': [],
            'bookCount': 2,
          },
        ],
  'pagination': {
    'page': page,
    'limit': 12,
    'total': empty ? 0 : 2,
    'totalPages': empty ? 0 : 2,
    'hasNextPage': !empty && page < 2,
  },
};

Map<String, dynamic> bookJson(int page) => {
  '_id': 'book-$page',
  'title': 'Store book $page',
  'author': 'Author',
  'price': 12,
  'stock': 3,
  'shopId': {'_id': ownerId, 'name': 'First bookstore'},
};

Map<String, dynamic> booksPayload(int page, {bool empty = false}) => {
  'success': true,
  'data': {
    'books': empty ? [] : [bookJson(page)],
    'meta': {
      'page': page,
      'limit': 20,
      'total': empty ? 0 : 2,
      'totalPage': empty ? 0 : 2,
    },
  },
};

class FakeCatalog {
  final requests = <RequestOptions>[];
  int? failingPage;
  bool empty = false;
  Completer<void>? gate;

  void intercept(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests.add(options);
          if (gate != null) await gate!.future;
          final page = options.queryParameters['page'] as int? ?? 1;
          if (page == failingPage) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 503,
                  data: {'message': 'Catalog temporarily unavailable'},
                ),
              ),
            );
            return;
          }
          final data = options.path == '/shop/public'
              ? storesPayload(page, empty: empty)
              : options.path.startsWith('/books/')
              ? {'success': true, 'data': bookJson(1)}
              : booksPayload(page, empty: empty);
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: data),
          );
        },
      ),
    );
  }

  ApiClient get client {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    intercept(dio);
    return ApiClient(dio);
  }
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget page,
  FakeCatalog fake,
) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        apiClientProvider.overrideWithValue(fake.client),
      ],
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: page,
        routes: {
          AuthRoutes.signIn: (_) => const Scaffold(body: Text('Login page')),
        },
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('bookstore parsing tolerates missing optional storefront fields', () {
    final parsed = Bookstore.fromJson({
      'id': ownerId,
      'name': 'Optional fields store',
      'logo': null,
      'banner': [null, '/public/banner.png'],
      'description': null,
      'address': null,
      'bookCount': null,
      'ignoredFutureField': true,
    }, apiBaseUrl: 'https://example.test/api/v1');

    expect(parsed.logoUrl, isNull);
    expect(parsed.bannerUrls, ['https://example.test/public/banner.png']);
    expect(parsed.description, '');
    expect(parsed.address, '');
    expect(parsed.bookCount, 0);
  });

  testWidgets('bookstore card uses the default image when no image exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookstoreCard(store: store, onTap: () {}),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      image.image,
      const AssetImage('assets/images/bookstore_placeholder.png'),
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'public directory and store books strip even a stored account token',
    () async {
      SharedPreferences.setMockInitialValues({
        'buyer_is_authenticated': true,
        'buyer_access_token': 'expired-token',
        'buyer_refresh_token': 'refresh-token',
      });
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      final fake = FakeCatalog();
      fake.intercept(container.read(dioProvider));
      final stores = await container
          .read(bookstoreRepositoryProvider)
          .getStores(page: 2);
      expect(stores, isA<Success<BookstoresResponse>>());
      expect(stores.dataOrNull!.stores.single.id, secondOwnerId);
      final resolvedLogo = Uri.parse(stores.dataOrNull!.stores.single.logoUrl!);
      expect(resolvedLogo.hasScheme, isTrue);
      expect(resolvedLogo.path, '/public/store-logo.png');
      await container
          .read(bookRepositoryProvider)
          .getBooks(shopId: ownerId, page: 2, publicRequest: true);
      expect(fake.requests.last.queryParameters['shopId'], ownerId);
      expect(fake.requests.last.queryParameters['page'], 2);
      for (final request in fake.requests) {
        expect(request.extra['skipAuth'], true);
        expect(
          request.headers.keys.map((key) => key.toLowerCase()),
          isNot(contains('authorization')),
        );
      }
    },
  );

  testWidgets(
    'directory retries failures, preserves first page, and opens the chosen store',
    (tester) async {
      final fake = FakeCatalog()..failingPage = 1;
      await pumpPage(tester, const BookstoresPage(), fake);
      await tester.pumpAndSettle();
      expect(find.text('Catalog temporarily unavailable'), findsOneWidget);
      fake.failingPage = 2;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('First bookstore'), findsOneWidget);
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(find.text('First bookstore'), findsOneWidget);
      expect(find.text('Catalog temporarily unavailable'), findsOneWidget);
      fake.failingPage = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Second bookstore'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second bookstore'));
      await tester.pumpAndSettle();
      expect(find.byType(BookstoreBooksPage), findsOneWidget);
      expect(fake.requests.last.queryParameters['shopId'], secondOwnerId);
      expect(
        fake.requests
            .where((r) => r.path == '/shop/public')
            .map((r) => r.queryParameters['page']),
        [1, 1, 2, 2],
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(BookstoresPage), findsOneWidget);
    },
  );

  testWidgets('carousel opens store books and all bookstores', (tester) async {
    final fake = FakeCatalog();
    await pumpPage(
      tester,
      const Scaffold(body: SingleChildScrollView(child: BookstoreCarousel())),
      fake,
    );
    await tester.pumpAndSettle();
    expect(
      fake.requests
          .singleWhere((request) => request.path == '/shop/public')
          .queryParameters['limit'],
      4,
    );
    await tester.tap(find.byType(BookstoreCard));
    await tester.pumpAndSettle();
    expect(fake.requests.last.queryParameters['shopId'], ownerId);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Bookstores'));
    await tester.pumpAndSettle();
    expect(find.byType(BookstoresPage), findsOneWidget);
  });

  testWidgets(
    'store books show loading, paginate, retain guest purchase guard and details',
    (tester) async {
      final gate = Completer<void>();
      final fake = FakeCatalog()..gate = gate;
      await pumpPage(tester, const BookstoreBooksPage(store: store), fake);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Load more'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(fake.requests.last.queryParameters['page'], 2);
      expect(fake.requests.last.queryParameters['shopId'], ownerId);
      await tester.scrollUntilVisible(
        find.byIcon(Icons.add).first,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      expect(
        find.text('Please sign in or create an account to purchase this book.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Store book 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Store book 1').last);
      await tester.pumpAndSettle();
      expect(find.byType(BookDetailsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty stores and empty store books provide clear messages', (
    tester,
  ) async {
    final fake = FakeCatalog()..empty = true;
    await pumpPage(tester, const BookstoresPage(), fake);
    await tester.pumpAndSettle();
    expect(find.text('No bookstores available.'), findsOneWidget);
    await pumpPage(tester, const BookstoreBooksPage(store: store), fake);
    await tester.pumpAndSettle();
    expect(find.text('This bookstore has no books yet.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  for (final screenWidth in [320.0, 800.0]) {
    testWidgets(
      'portrait cards fit screen width $screenWidth with large text',
      (tester) async {
        tester.view.physicalSize = Size(screenWidth, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final preferences = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(preferences),
            ],
            child: MaterialApp(
              localizationsDelegates: const [AppLocalizations.delegate],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => GridView(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: BookCardMini.gridDelegate(context),
                    children: [BookCardMini(book: book, onTap: () {})],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final cover = tester.widget<BookCover>(find.byType(BookCover));
        expect(cover.fit, BoxFit.contain);
        final size = tester.getSize(find.byType(BookCover));
        expect(size.height, greaterThan(size.width));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
