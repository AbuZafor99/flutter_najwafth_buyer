import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/store_models.dart';
import '../widgets/featured_book_card.dart';

class FeaturedPage extends StatelessWidget {
  const FeaturedPage({
    super.key,
    required this.categories,
    required this.popularBooks,
    required this.onBookTap,
    required this.onCategoryTap,
  });

  final List<BookCategory> categories;
  final List<BookItem> popularBooks;
  final ValueChanged<BookItem> onBookTap;
  final ValueChanged<BookCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F6F8),
        leading: BackButton(color: Colors.black,),
        titleSpacing: 0,
        title: Text(
          l10n.featuredBookstores,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
        children: [
          const _FeaturedSearchBar(),
          const SizedBox(height: 14),
          Text(
            l10n.categories,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              return GestureDetector(
                onTap: () => onCategoryTap(category),
                child: Container(
                  padding: EdgeInsets.all(7),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7EBF0)),
                  ),

                  // color: Colors.red,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE7EBF0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                (category.previewImageUrl != null &&
                                    category.previewImageUrl!.isNotEmpty)
                                ? Image.network(
                                    category.previewImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.menu_book_outlined,
                                      color: Color(0xFF9CA6B3),
                                    ),
                                  )
                                : (category.previewImageAsset == null ||
                                      category.previewImageAsset!.isEmpty)
                                ? const Icon(
                                    Icons.menu_book_outlined,
                                    color: Color(0xFF9CA6B3),
                                  )
                                : Image.asset(
                                    category.previewImageAsset!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.menu_book_outlined,
                                      color: Color(0xFF9CA6B3),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.popularBooks,
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                l10n.seeAll,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F8FC5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: popularBooks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 230,
                child: FeaturedBookCard(
                  book: popularBooks[index],
                  onTap: () => onBookTap(popularBooks[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedSearchBar extends StatelessWidget {
  const _FeaturedSearchBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 52,
      child: TextField(
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA6AFBA)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDE2E9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDE2E9)),
          ),
          suffixIcon: Container(
            width: 56,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF5A91C4),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
