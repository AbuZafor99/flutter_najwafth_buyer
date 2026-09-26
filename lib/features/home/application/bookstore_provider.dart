import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/network_providers.dart';
import '../data/bookstore_repository.dart';
import '../domain/bookstore.dart';

final bookstoreRepositoryProvider = Provider<BookstoreRepository>(
  (ref) => BookstoreRepository(ref.watch(apiClientProvider)),
);

final homeBookstoresProvider = FutureProvider.autoDispose<List<Bookstore>>((
  ref,
) async {
  final result = await ref
      .watch(bookstoreRepositoryProvider)
      .getStores(limit: 6);
  return switch (result) {
    Success(data: final data) => data.stores,
    ResultFailure(error: final error) => throw error,
  };
});
