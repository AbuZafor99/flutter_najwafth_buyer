import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/errors/app_failure.dart';
import '../../application/bookstore_provider.dart';
import '../pages/bookstore_books_page.dart';
import '../pages/bookstores_page.dart';
import 'bookstore_card.dart';
import 'section_title.dart';

class BookstoreCarousel extends ConsumerStatefulWidget {
  const BookstoreCarousel({super.key});
  @override
  ConsumerState<BookstoreCarousel> createState() => _BookstoreCarouselState();
}

class _BookstoreCarouselState extends ConsumerState<BookstoreCarousel> {
  final _controller = PageController(viewportFraction: .86);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stores = ref.watch(homeBookstoresProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        SectionTitle(
          title: l10n.bookstores,
          actionText: l10n.allBookstores,
          outlinedAction: true,
          onActionTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: '/bookstores'),
              builder: (_) => const BookstoresPage(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        stores.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  error is AppFailure ? error.message : error.toString(),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(homeBookstoresProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(l10n.noBookstores),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth.clamp(0.0, 650.0);
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(17) / 17;
                    return SizedBox(
                      width: width,
                      child: Column(
                        children: [
                          SizedBox(
                            height: (width * .86 - 10) / 2.2 + 84 * textScale,
                            child: PageView.builder(
                              controller: _controller,
                              padEnds: false,
                              itemCount: items.length,
                              onPageChanged: (page) =>
                                  setState(() => _page = page),
                              itemBuilder: (_, index) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: BookstoreCard(
                                  store: items[index],
                                  onTap: () => BookstoreBooksPage.open(
                                    context,
                                    items[index],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              items.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == _page
                                      ? const Color(0xFF3694F4)
                                      : const Color(0xFFD5DDE8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
