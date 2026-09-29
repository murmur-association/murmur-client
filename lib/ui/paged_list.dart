import 'package:flutter/material.dart';

import 'l10n.dart';

/// A list that shows as many items as fill the screen, plus one, and
/// [pageSize] more each time it's scrolled to the bottom. Items come from
/// [fetch], which only has to produce the first few, so the source can be as
/// long as the chain.
///
/// When the source can grow (older blocks not fetched yet, [loadingMore]),
/// a list that has fewer items than it wants calls [onNeedMore], and shows a
/// loading line at its end until they arrive.
class PagedList<T> extends StatefulWidget {
  const PagedList({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    this.header = const [],
    this.empty,
    this.resetKey,
    this.dividerIndent = 72,
    this.loadingMore = false,
    this.onNeedMore,
  });

  /// The first `count` items (fewer when there aren't that many).
  final List<T> Function(int count) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Slivers above the list, scrolled with it.
  final List<Widget> header;

  /// Shown instead of the list when there are no items (and none coming).
  final Widget? empty;

  /// Changing it starts over: back to the top, one screen's worth of items.
  final Object? resetKey;

  /// Indent of the dividers between items; null for no dividers.
  final double? dividerIndent;

  /// Whether more items may still come from older blocks.
  final bool loadingMore;
  final VoidCallback? onNeedMore;

  static const pageSize = 10;

  @override
  State<PagedList<T>> createState() => _PagedListState<T>();
}

class _PagedListState<T> extends State<PagedList<T>> {
  /// A generous row height: the first guess undershoots the screen, and
  /// [_fill] adds rows one at a time until it's full.
  static const _tallRow = 96.0;

  final _scroll = ScrollController();

  /// Items to show; 0 until the first layout sizes it from the screen.
  int _count = 0;

  /// Whether the one row beyond a full screen has been added.
  bool _extraAdded = false;
  bool _more = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PagedList<T> old) {
    super.didUpdateWidget(old);
    if (old.resetKey != widget.resetKey) {
      _count = 0;
      _extraAdded = false;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Checked after every build: while the list doesn't fill the screen and
  /// there are more items, adds one per frame; once it overflows, one more,
  /// so there's always something to scroll to. Checking every time (not just
  /// at first) matters: items can arrive after the first build (older blocks
  /// are still being fetched), and the screen can grow.
  void _fill() {
    if (!mounted || !_more || !_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
    final overflowing = _scroll.position.maxScrollExtent > 0;
    if (overflowing && _extraAdded) return;
    setState(() {
      _extraAdded = overflowing;
      _count++;
    });
  }

  void _onScroll() {
    if (_loadingMore || !_more) return;
    if (_scroll.position.extentAfter > 48) return;
    _loadingMore = true;
    setState(() => _count += PagedList.pageSize);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (_count == 0) _count = (constraints.maxHeight / _tallRow).floor().clamp(1, 1000);
      final items = widget.fetch(_count + 1);
      _more = items.length > _count;
      final shown = items.length > _count ? items.sublist(0, _count) : items;
      // Short of what the screen wants, and older blocks can still add some.
      final waiting = !_more && widget.loadingMore;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fill();
        if (waiting && mounted) widget.onNeedMore?.call();
      });

      final indent = widget.dividerIndent;
      return CustomScrollView(controller: _scroll, slivers: [
        ...widget.header,
        if (shown.isEmpty && !waiting && widget.empty != null)
          SliverFillRemaining(hasScrollBody: false, child: widget.empty)
        else
          SliverList.separated(
            itemCount: shown.length,
            itemBuilder: (context, i) => widget.itemBuilder(context, shown[i]),
            separatorBuilder: (_, __) =>
                indent == null ? const SizedBox.shrink() : Divider(height: 1, indent: indent),
          ),
        if (waiting)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Text(context.l10n.loadingOlder, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
        // Clear of the floating button. Reaching this space loads the next ten.
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ]);
    });
  }
}
