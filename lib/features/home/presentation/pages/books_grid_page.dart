import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/store_models.dart';
import '../widgets/book_card_mini.dart';

class BooksGridPage extends StatelessWidget {
  const BooksGridPage({
    super.key,
    required this.title,
    required this.books,
    required this.onBookTap,
  });

  final String title;
  final List<BookItem> books;
  final ValueChanged<BookItem> onBookTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFFF5F6F8),
      ),
      body: books.isEmpty
          ? Center(
              child: Text(
                l10n.noBooksFoundInCategory,
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: books.length,
              gridDelegate: BookCardMini.gridDelegate(context),
              itemBuilder: (context, index) => BookCardMini(
                book: books[index],
                onTap: () => onBookTap(books[index]),
              ),
            ),
    );
  }
}
