import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/bookstore_provider.dart';
import '../../domain/bookstore.dart';
import '../widgets/bookstore_card.dart';
import '../widgets/paginated_catalog.dart';
import '../widgets/store_widgets.dart';
import 'bookstore_books_page.dart';

class BookstoresPage extends ConsumerWidget {
  const BookstoresPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => StorePageScaffold(
    title: AppLocalizations.of(context).allBookstores,
    backgroundColor: const Color(0xFFF5F6F8),
    child: PaginatedCatalog<Bookstore>(
      emptyMessage: AppLocalizations.of(context).noBookstores,
      loadPage: (page) async {
        final result = await ref
            .read(bookstoreRepositoryProvider)
            .getStores(page: page);
        return switch (result) {
          Success(data: final data) => (
            items: data.stores,
            hasMore: data.page < data.totalPages,
          ),
          ResultFailure(error: final error) => throw error,
        };
      },
      itemBuilder: (store) => BookstoreCard(
        store: store,
        onTap: () => BookstoreBooksPage.open(context, store),
      ),
    ),
  );
}
