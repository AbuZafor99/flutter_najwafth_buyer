import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/errors/app_failure.dart';
import 'book_card_mini.dart';

typedef CatalogPage<T> = ({List<T> items, bool hasMore});

/// Keeps loaded items visible when the next page fails; retries the same page.
class PaginatedCatalog<T> extends StatefulWidget {
  const PaginatedCatalog({
    super.key,
    required this.loadPage,
    required this.itemBuilder,
    required this.emptyMessage,
    this.header,
    this.bookGrid = false,
    this.itemKey,
  });
  final Future<CatalogPage<T>> Function(int page) loadPage;
  final Widget Function(T item) itemBuilder;
  final String emptyMessage;
  final Widget? header;
  final bool bookGrid;
  final Object Function(T item)? itemKey;

  @override
  State<PaginatedCatalog<T>> createState() => _PaginatedCatalogState<T>();
}

class _PaginatedCatalogState<T> extends State<PaginatedCatalog<T>> {
  final List<T> _items = [];
  int _nextPage = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.loadPage(_nextPage);
      if (!mounted) return;
      final items = <T>[];
      final itemKey = widget.itemKey;
      if (itemKey == null) {
        items.addAll(page.items);
      } else {
        final seen = _items.map(itemKey).toSet();
        for (final item in page.items) {
          if (seen.add(itemKey(item))) items.add(item);
        }
      }
      setState(() {
        _items.addAll(items);
        _hasMore = page.hasMore;
        _nextPage++;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AppFailure ? error.message : error.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _items.clear();
      _nextPage = 1;
      _hasMore = true;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: widget.bookGrid
                ? SliverGrid(
                    gridDelegate: BookCardMini.gridDelegate(context),
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => widget.itemBuilder(_items[index]),
                      childCount: _items.length,
                    ),
                  )
                : SliverList.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: widget.itemBuilder(_items[index]),
                        ),
                      ),
                    ),
                  ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_loading)
                    const CircularProgressIndicator()
                  else if (_error != null) ...[
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: Text(l10n.retry)),
                  ] else if (_items.isEmpty) ...[
                    Text(widget.emptyMessage, textAlign: TextAlign.center),
                    TextButton(onPressed: _refresh, child: Text(l10n.retry)),
                  ] else if (_hasMore)
                    OutlinedButton(
                      onPressed: _load,
                      child: Text(l10n.loadMore),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
