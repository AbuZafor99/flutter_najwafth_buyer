import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../notification/application/notification_provider.dart';
import '../../../profile/application/profile_controller.dart';
import '../../application/store_controller.dart';
import '../../domain/store_models.dart';
import 'book_card_mini.dart';
import 'home_search_bar.dart';
import 'section_title.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({
    super.key,
    required this.featuredBooks,
    required this.categories,
    required this.popularBooks,
    required this.onBookTap,
    required this.onCategoryTap,
    required this.onFeaturedTap,
    required this.onPopularTap,
    required this.onNotificationsTap,
  });

  final List<BookItem> featuredBooks;
  final List<BookCategory> categories;
  final List<BookItem> popularBooks;
  final ValueChanged<BookItem> onBookTap;
  final ValueChanged<BookCategory> onCategoryTap;
  final VoidCallback onFeaturedTap;
  final VoidCallback onPopularTap;
  final VoidCallback onNotificationsTap;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final profileAsync = ref.watch(profileControllerProvider);
    final avatarUrl = profileAsync.asData?.value.avatarUrl.trim() ?? '';
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadAsync.asData?.value ?? 0;
    final allBooks = ref.watch(storeCatalogProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 22, 12, 16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFDCE3EC),
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : const AssetImage(
                        'assets/images/profile_placeholder.png',
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.goodMorning,
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA6B3)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onNotificationsTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    // color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_outlined,
                        color: Colors.black,
                        size: 30,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HomeSearchBar(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          if (_searchQuery.isNotEmpty)
            ..._buildSearchResults(context, allBooks)
          else ...[
            const SizedBox(height: 14),
            SectionTitle(
              title: l10n.featuredBookstores,
              actionText: l10n.seeAll,
              onActionTap: widget.onFeaturedTap,
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.featuredBooks.length.clamp(0, 6).toInt(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: .75,
              ),
              itemBuilder: (context, index) => BookCardMini(
                book: widget.featuredBooks[index],
                onTap: () => widget.onBookTap(widget.featuredBooks[index]),
              ),
            ),
            const SizedBox(height: 14),
            SectionTitle(
              title: l10n.categories,
              actionText: l10n.seeAll,
              onActionTap: widget.onFeaturedTap,
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final itemWidth = (screenWidth * 0.2)
                    .clamp(68.0, 86.0)
                    .toDouble();
                final thumbSize = (itemWidth * 0.82)
                    .clamp(54.0, 68.0)
                    .toDouble();
                final horizontalGap = (screenWidth * 0.018)
                    .clamp(6.0, 10.0)
                    .toDouble();
                final listHeight = (thumbSize + 28).toDouble();

                return SizedBox(
                  height: listHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.categories.length,
                    separatorBuilder: (_, _) => SizedBox(width: horizontalGap),
                    itemBuilder: (context, index) {
                      final category = widget.categories[index];
                      final previewPath = category.previewImageAsset;
                      final previewUrl = category.previewImageUrl;

                      return SizedBox(
                        width: itemWidth,
                        child: GestureDetector(
                          onTap: () => widget.onCategoryTap(category),
                          child: Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: thumbSize,
                                  height: thumbSize,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE8ECF1),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child:
                                        (previewUrl != null &&
                                            previewUrl.isNotEmpty)
                                        ? Image.network(
                                            previewUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                                  Icons.menu_book_outlined,
                                                  color: Color(0xFF9CA6B3),
                                                ),
                                          )
                                        : (previewPath == null ||
                                              previewPath.isEmpty)
                                        ? const Icon(
                                            Icons.menu_book_outlined,
                                            color: Color(0xFF9CA6B3),
                                          )
                                        : Image.asset(
                                            previewPath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                                  Icons.menu_book_outlined,
                                                  color: Color(0xFF9CA6B3),
                                                ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            SectionTitle(
              title: l10n.popularBooks,
              actionText: l10n.seeAll,
              onActionTap: widget.onPopularTap,
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final itemWidth = (screenWidth * 0.38)
                    .clamp(120.0, 170.0)
                    .toDouble();
                final listHeight = (itemWidth * 1.55)
                    .clamp(185.0, 280.0)
                    .toDouble();

                if (widget.popularBooks.isEmpty) {
                  return SizedBox(
                    height: listHeight,
                    child: Center(
                      child: Text(
                        l10n.noPopularBooksAvailable,
                        style: TextStyle(
                          color: Color(0xFF9CA6B3),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: listHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.popularBooks.length,
                    separatorBuilder: (_, _) => SizedBox(
                      width: (screenWidth * 0.025).clamp(8.0, 14.0).toDouble(),
                    ),
                    itemBuilder: (context, i) => SizedBox(
                      width: itemWidth,
                      child: BookCardMini(
                        book: widget.popularBooks[i],
                        onTap: () => widget.onBookTap(widget.popularBooks[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSearchResults(BuildContext context, List<BookItem> allBooks) {
    final l10n = AppLocalizations.of(context);
    final query = _searchQuery.toLowerCase();
    final filteredBooks = allBooks.where((book) {
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.price.toString().contains(query);
    }).toList();

    return [
      const SizedBox(height: 14),
      SectionTitle(title: l10n.searchResults),
      const SizedBox(height: 10),
      if (filteredBooks.isEmpty)
        Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              l10n.noBooksMatchSearch,
              style: TextStyle(color: Color(0xFF9CA6B3), fontSize: 14),
            ),
          ),
        )
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredBooks.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .75,
          ),
          itemBuilder: (context, index) => BookCardMini(
            book: filteredBooks[index],
            onTap: () => widget.onBookTap(filteredBooks[index]),
          ),
        ),
    ];
  }
}
