import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_najwafth_buyer/core/localization/app_localizations.dart';
import 'package:flutter_najwafth_buyer/core/network/api_client.dart';
import 'package:flutter_najwafth_buyer/core/network/network_providers.dart';
import 'package:flutter_najwafth_buyer/core/notifications/push_notification_service.dart';
import 'package:flutter_najwafth_buyer/core/storage/storage_providers.dart';
import 'package:flutter_najwafth_buyer/core/widgets/splash/presentation/splash_page.dart';
import 'package:flutter_najwafth_buyer/features/auth/presentation/auth_routes.dart';
import 'package:flutter_najwafth_buyer/features/auth/data/apple_sign_in_service.dart';
import 'package:flutter_najwafth_buyer/features/auth/presentation/pages/sign_in_page.dart';
import 'package:flutter_najwafth_buyer/features/cart_order/presentation/pages/book_details_page.dart';
import 'package:flutter_najwafth_buyer/features/home/application/book_provider.dart';
import 'package:flutter_najwafth_buyer/features/home/application/store_controller.dart';
import 'package:flutter_najwafth_buyer/features/home/domain/store_models.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/pages/home_page.dart';
import 'package:flutter_najwafth_buyer/features/home/presentation/widgets/home_tab.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const book = BookItem(
  id: 'book-1',
  title: 'Public Book',
  author: 'Author',
  price: 12,
);

ApiClient _publicApiClient({List<RequestOptions>? requests}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests?.add(options);
        final data = switch (options.path) {
          '/books' => {
            'success': true,
            'data': {
              'books': [
                {
                  '_id': book.id,
                  'title': book.title,
                  'author': book.author,
                  'price': book.price,
                },
              ],
              'meta': {'page': 1, 'limit': 20, 'total': 1, 'totalPage': 1},
            },
          },
          '/category/tree/all' ||
          '/category' => {'success': true, 'data': <Object>[]},
          '/shop/public' => {
            'success': true,
            'data': {
              'shops': <Object>[],
              'pagination': {'page': 1, 'totalPages': 0},
            },
          },
          '/user/me' => {
            'success': true,
            'data': {'name': 'Reader'},
          },
          '/auth/social-login' => {
            'success': true,
            'data': {
              'accessToken': _unexpiredJwt(),
              'refreshToken': _unexpiredJwt(),
              'role': 'buyer',
              '_id': 'apple-user',
              'user': {
                '_id': 'apple-user',
                'name': 'Apple Reader',
                'email': 'reader@privaterelay.appleid.com',
                'role': 'buyer',
              },
            },
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

class _TestPushService extends PushNotificationService {
  _TestPushService(super.ref);

  @override
  Future<void> start() async {}

  @override
  Future<void> unregister() async {}
}

class _TestAppleSignInService implements AppleSignInService {
  int signOutCalls = 0;

  @override
  Future<AppleIdentity> signIn() async {
    return const AppleIdentity(idToken: 'firebase-apple-token', name: 'Reader');
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final onboardingCompleted in [false, true]) {
    testWidgets(
      onboardingCompleted
          ? 'returning guest reaches public home after splash'
          : 'new guest reaches onboarding after splash',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'buyer_onboarding_completed': onboardingCompleted,
        });
        final preferences = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(preferences),
            ],
            child: MaterialApp(
              initialRoute: AuthRoutes.splash,
              routes: {
                AuthRoutes.splash: (_) => const SplashPage(),
                AuthRoutes.onboarding: (_) =>
                    const Scaffold(body: Text('Onboarding page')),
                AuthRoutes.home: (_) =>
                    const Scaffold(body: Text('Public home page')),
              },
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pumpAndSettle();
        expect(
          find.text(
            onboardingCompleted ? 'Public home page' : 'Onboarding page',
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('guest home shows catalog and sign in action', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          storeCatalogProvider.overrideWithValue(const [book]),
          apiClientProvider.overrideWithValue(_publicApiClient()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: Scaffold(
            body: HomeTab(
              featuredBooks: const [book],
              categories: const [],
              popularBooks: const [book],
              onBookTap: (_) {},
              onCategoryTap: (_) {},
              onFeaturedTap: () {},
              onPopularTap: () {},
              onAllBooksTap: () {},
              onNotificationsTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Books on Wheels'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Public Book'), findsWidgets);
    expect(find.byIcon(Icons.notifications_none_outlined), findsNothing);
  });

  testWidgets('guest bottom tabs stay on home and offer login', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiClientProvider.overrideWithValue(_publicApiClient()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: const HomePage(),
          routes: {
            AuthRoutes.signIn: (_) => const Scaffold(body: Text('Login page')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final tab in ['Order', 'Cart', 'Profile']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(find.text('Sign In Required'), findsOneWidget);
      expect(
        find.text('Please sign in or create an account to access your $tab.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        0,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log In / Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Login page'), findsOneWidget);
  });

  testWidgets('authenticated user can switch bottom tabs', (tester) async {
    final jwt = _unexpiredJwt();
    SharedPreferences.setMockInitialValues({
      'buyer_is_authenticated': true,
      'buyer_access_token': jwt,
      'buyer_refresh_token': jwt,
      'buyer_role': 'buyer',
      'buyer_full_name': 'Reader',
    });
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiClientProvider.overrideWithValue(_publicApiClient()),
          pushNotificationServiceProvider.overrideWith(_TestPushService.new),
          appleSignInServiceProvider.overrideWithValue(
            _TestAppleSignInService(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          home: HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      3,
    );
    expect(find.text('Sign In Required'), findsNothing);
  });

  testWidgets('explicit logout clears session and navigation stack', (
    tester,
  ) async {
    final jwt = _unexpiredJwt();
    SharedPreferences.setMockInitialValues({
      'buyer_is_authenticated': true,
      'buyer_access_token': jwt,
      'buyer_refresh_token': jwt,
      'buyer_role': 'buyer',
      'buyer_full_name': 'Reader',
    });
    final preferences = await SharedPreferences.getInstance();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiClientProvider.overrideWithValue(_publicApiClient()),
          pushNotificationServiceProvider.overrideWith(_TestPushService.new),
          appleSignInServiceProvider.overrideWithValue(
            _TestAppleSignInService(),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: const [AppLocalizations.delegate],
          home: const HomePage(),
          routes: {
            AuthRoutes.signIn: (_) => const Scaffold(body: Text('Login page')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Log Out'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Log Out').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out').last);
    await tester.pumpAndSettle();

    expect(find.text('Login page'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
    expect(preferences.getString('buyer_access_token'), isNull);
    expect(preferences.getString('buyer_refresh_token'), isNull);
  });

  testWidgets('account deletion requires confirmation and clears local data', (
    tester,
  ) async {
    final jwt = _unexpiredJwt();
    SharedPreferences.setMockInitialValues({
      'buyer_is_authenticated': true,
      'buyer_access_token': jwt,
      'buyer_refresh_token': jwt,
      'buyer_role': 'buyer',
      'buyer_full_name': 'Reader',
      'unrelated_cached_value': 'remove-me',
    });
    final preferences = await SharedPreferences.getInstance();
    final requests = <RequestOptions>[];
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiClientProvider.overrideWithValue(
            _publicApiClient(requests: requests),
          ),
          pushNotificationServiceProvider.overrideWith(_TestPushService.new),
          appleSignInServiceProvider.overrideWithValue(
            _TestAppleSignInService(),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: const [AppLocalizations.delegate],
          home: const HomePage(),
          routes: {
            AuthRoutes.signIn: (_) => const Scaffold(body: Text('Login page')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Delete Account'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    final deleteButton = find.widgetWithText(TextButton, 'Delete');
    expect(tester.widget<TextButton>(deleteButton).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'CONFIRM');
    await tester.pump();
    expect(tester.widget<TextButton>(deleteButton).onPressed, isNotNull);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(
      requests.any(
        (request) =>
            request.method == 'DELETE' && request.path == '/user/account',
      ),
      isTrue,
    );
    expect(find.text('Login page'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
    expect(preferences.getKeys(), isEmpty);
    expect(
      find.text('Your account has been successfully deleted.'),
      findsOneWidget,
    );
  });

  testWidgets('Apple sign-in exchanges Firebase identity for app session', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final preferences = await SharedPreferences.getInstance();
    final requests = <RequestOptions>[];
    final appleService = _TestAppleSignInService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiClientProvider.overrideWithValue(
            _publicApiClient(requests: requests),
          ),
          appleSignInServiceProvider.overrideWithValue(appleService),
          pushNotificationServiceProvider.overrideWith(_TestPushService.new),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: const SignInPage(),
          routes: {
            AuthRoutes.home: (_) => const Scaffold(body: Text('Home page')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Continue with Apple'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Continue with Facebook'), findsNothing);
    await tester.tap(find.text('Continue with Apple'));
    await tester.pumpAndSettle();

    final request = requests.singleWhere(
      (item) => item.path == '/auth/social-login',
    );
    expect(request.method, 'POST');
    expect(request.data, {
      'idToken': 'firebase-apple-token',
      'provider': 'apple.com',
      'name': 'Reader',
    });
    expect(find.text('Home page'), findsOneWidget);
    expect(preferences.getBool('buyer_is_authenticated'), isTrue);
    expect(
      preferences.getString('buyer_email'),
      'reader@privaterelay.appleid.com',
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('guest purchase prompts sign in and keeps book intent', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    Object? signInArgument;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          bookDetailProvider(book.id).overrideWith((ref) async => book),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: const BookDetailsPage(book: book),
          onGenerateRoute: (settings) {
            if (settings.name == AuthRoutes.signIn) {
              signInArgument = settings.arguments;
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Sign in page')),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();
    expect(
      find.text('Please sign in or create an account to purchase this book.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue to sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in page'), findsOneWidget);
    expect(signInArgument, book.id);
  });
}
