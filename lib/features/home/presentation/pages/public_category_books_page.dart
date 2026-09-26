import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/book_provider.dart';
import '../../data/book_repository.dart';
import '../../domain/store_models.dart';
import '../widgets/book_card_mini.dart';

/// Public catalog view. It loads after navigation so slow requests never leave
/// a guest waiting on the home screen with no feedback.
class PublicCategoryBooksPage extends ConsumerStatefulWidget {
  const PublicCategoryBooksPage({
    super.key,
    required this.category,
    required this.cachedBooks,
    required this.onBookTap,
  });

  static String routeName(String categoryId) =>
      '/public/categories/$categoryId';

  final BookCategory category;
  final List<BookItem> cachedBooks;
  final ValueChanged<BookItem> onBookTap;

  @override
  ConsumerState<PublicCategoryBooksPage> createState() =>
      _PublicCategoryBooksPageState();
}

class _PublicCategoryBooksPageState
    extends ConsumerState<PublicCategoryBooksPage> {
  late Future<Result<BooksResponse>> _request;

  @override
  void initState() {
    super.initState();
    _request = _fetch();
  }

  Future<Result<BooksResponse>> _fetch() => ref
      .read(bookRepositoryProvider)
      .getPublicCategoryBooks(categoryId: widget.category.id);

  void _retry() => setState(() => _request = _fetch());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cached = widget.cachedBooks
        .where((book) => book.categoryId == widget.category.id)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text(
          widget.category.name,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFFF5F6F8),
      ),
      body: FutureBuilder<Result<BooksResponse>>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _CategorySkeleton();
          }

          final result = snapshot.data;
          if (result case Success<BooksResponse>(data: final response)) {
            if (response.books.isNotEmpty) {
              return _BookGrid(
                books: response.books,
                onBookTap: widget.onBookTap,
              );
            }
            if (cached.isNotEmpty) {
              return _cachedGrid(cached, l10n);
            }
            return _CategoryMessage(
              icon: Icons.menu_book_outlined,
              message: l10n.noBooksFoundInCategory,
              onRetry: _retry,
            );
          }

          if (cached.isNotEmpty) {
            return _cachedGrid(cached, l10n);
          }
          final message = switch (result) {
            ResultFailure<BooksResponse>(error: final error) => error.message,
            _ => l10n.couldNotLoadBooks,
          };
          return _CategoryMessage(
            icon: Icons.cloud_off_outlined,
            message: message,
            onRetry: _retry,
          );
        },
      ),
    );
  }

  Widget _cachedGrid(List<BookItem> books, AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Expanded(child: Text(l10n.showingCachedCategoryBooks)),
              TextButton(onPressed: _retry, child: Text(l10n.retry)),
            ],
          ),
        ),
        Expanded(
          child: _BookGrid(books: books, onBookTap: widget.onBookTap),
        ),
      ],
    );
  }
}

class _BookGrid extends StatelessWidget {
  const _BookGrid({required this.books, required this.onBookTap});

  final List<BookItem> books;
  final ValueChanged<BookItem> onBookTap;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
    itemCount: books.length,
    gridDelegate: BookCardMini.gridDelegate(context),
    itemBuilder: (context, index) =>
        BookCardMini(book: books[index], onTap: () => onBookTap(books[index])),
  );
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) => GridView.builder(
    key: const Key('public-category-loading'),
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
    itemCount: 6,
    gridDelegate: BookCardMini.gridDelegate(context),
    itemBuilder: (_, _) => Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF1),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

class _CategoryMessage extends StatelessWidget {
  const _CategoryMessage({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF9CA6B3)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
