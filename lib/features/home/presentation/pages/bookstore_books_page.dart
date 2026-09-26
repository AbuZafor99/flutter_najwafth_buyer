import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/auth_routes.dart';
import '../../../cart_order/presentation/pages/book_details_page.dart';
import '../../application/book_provider.dart';
import '../../domain/bookstore.dart';
import '../../domain/store_models.dart';
import '../widgets/book_card_mini.dart';
import '../widgets/bookstore_card.dart';
import '../widgets/paginated_catalog.dart';
import '../widgets/store_widgets.dart';

class BookstoreBooksPage extends ConsumerWidget {
  const BookstoreBooksPage({super.key, required this.store});
  final Bookstore store;

  static void open(BuildContext context, Bookstore store) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: '/bookstores/${store.ownerId}'),
          builder: (_) => BookstoreBooksPage(store: store),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) => StorePageScaffold(
    title: store.name,
    backgroundColor: const Color(0xFFF5F6F8),
    child: PaginatedCatalog<BookItem>(
      bookGrid: true,
      emptyMessage: AppLocalizations.of(context).noStoreBooks,
      header: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookstoreCard(store: store),
                if (store.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(store.description),
                  ),
              ],
            ),
          ),
        ),
      ),
      loadPage: (page) async {
        final result = await ref
            .read(bookRepositoryProvider)
            .getBooks(shopId: store.ownerId, page: page, publicRequest: true);
        return switch (result) {
          Success(data: final data) => (
            items: data.books,
            hasMore: data.meta.page < data.meta.totalPage,
          ),
          ResultFailure(error: final error) => throw error,
        };
      },
      itemBuilder: (book) => BookCardMini(
        book: book,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: RouteSettings(name: AuthRoutes.bookDetails(book.id)),
            builder: (_) => BookDetailsPage(book: book),
          ),
        ),
      ),
    ),
  );
}
