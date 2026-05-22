import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firestore/firestore_pagination.dart';
import '../core/firestore/firestore_stream_cache.dart';
import '../core/observability/error_ui.dart';
import '../core/observability/user_safe_error_mapper.dart';

/// First page via cached [Query.snapshots]; additional pages via [startAfterDocument].
/// Avoids duplicate listeners and keeps RBAC/shop filters on the base [queryBuilder].
class FirestorePaginatedList<T> extends StatefulWidget {
  const FirestorePaginatedList({
    super.key,
    required this.cacheKey,
    required this.queryBuilder,
    required this.parse,
    required this.itemBuilder,
    this.pageSize = FirestorePageSize.standard,
    this.emptyBuilder,
    this.padding,
    this.separatorBuilder,
    this.itemKey,
    this.filterItems,
  });

  final String cacheKey;
  final List<T> Function(List<T> items)? filterItems;
  final Query<Map<String, dynamic>> Function() queryBuilder;
  final T? Function(Map<String, dynamic> data, String docId) parse;
  final String Function(T item)? itemKey;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int pageSize;
  final WidgetBuilder? emptyBuilder;
  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  @override
  State<FirestorePaginatedList<T>> createState() =>
      _FirestorePaginatedListState<T>();
}

class _FirestorePaginatedListState<T> extends State<FirestorePaginatedList<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _initialWaiting = true;
  Object? _error;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _subscribeFirstPage();
  }

  void _subscribeFirstPage() {
    _subscription?.cancel();
    final query = firstPageQuery(
      widget.queryBuilder(),
      pageSize: widget.pageSize,
    );
    _subscription = FirestoreStreamCache.instance
        .querySnapshots(query, key: widget.cacheKey)
        .listen(
      (snap) {
        if (!mounted) return;
        final parsed = <T>[];
        for (final doc in snap.docs) {
          final item = widget.parse(doc.data(), doc.id);
          if (item != null) parsed.add(item);
        }
        setState(() {
          _items
            ..clear()
            ..addAll(parsed);
          _cursor = snap.docs.isNotEmpty ? snap.docs.last : null;
          _hasMore = snap.docs.length >= widget.pageSize;
          _initialWaiting = false;
          _error = null;
        });
      },
      onError: (e) {
        reportCatch(e, tag: 'FirestorePaginatedList.stream');
        if (!mounted) return;
        setState(() {
          _error = e;
          _initialWaiting = false;
        });
      },
    );
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _initialWaiting) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await fetchFirestorePage<T>(
        query: widget.queryBuilder(),
        parse: widget.parse,
        pageSize: widget.pageSize,
        startAfter: _cursor,
      );
      if (!mounted) return;
      setState(() {
        final existingIds = _items.map(_itemKey).toSet();
        for (final item in page.items) {
          final key = _itemKey(item);
          if (!existingIds.contains(key)) {
            _items.add(item);
            existingIds.add(key);
          }
        }
        _cursor = page.lastDocument ?? _cursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (e, st) {
      reportCatch(e, stackTrace: st, tag: 'FirestorePaginatedList.loadMore');
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = e;
      });
    }
  }

  String _itemKey(T item) => widget.itemKey?.call(item) ?? item.toString();

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialWaiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(UserSafeErrorMapper.messageFor(_error!)),
      );
    }
    final visible = widget.filterItems?.call(List<T>.from(_items)) ?? _items;
    if (visible.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(child: Text('No items found'));
    }

    final itemCount = visible.length + (_loadingMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: widget.separatorBuilder ??
          (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= visible.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.itemBuilder(context, visible[index]);
      },
    );
  }
}

/// Paginated list without realtime (fetch-only). Use for order history.
class FirestorePagedList<T> extends StatefulWidget {
  const FirestorePagedList({
    super.key,
    required this.queryBuilder,
    required this.parse,
    required this.itemBuilder,
    this.pageSize = FirestorePageSize.history,
    this.emptyBuilder,
    this.padding,
    this.onRefresh,
    this.itemKey,
  });

  final Query<Map<String, dynamic>> Function() queryBuilder;
  final T? Function(Map<String, dynamic> data, String docId) parse;
  final String Function(T item)? itemKey;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int pageSize;
  final WidgetBuilder? emptyBuilder;
  final EdgeInsetsGeometry? padding;
  final Future<void> Function()? onRefresh;

  @override
  State<FirestorePagedList<T>> createState() => _FirestorePagedListState<T>();
}

class _FirestorePagedListState<T> extends State<FirestorePagedList<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _cursor = null;
      _hasMore = true;
    });
    await _fetchPage(reset: true);
  }

  Future<void> _fetchPage({required bool reset}) async {
    if (!reset && (!_hasMore || _loadingMore)) return;
    if (reset) {
      if (!mounted) return;
      setState(() => _loading = true);
    } else {
      if (!mounted) return;
      setState(() => _loadingMore = true);
    }
    try {
      final page = await fetchFirestorePage<T>(
        query: widget.queryBuilder(),
        parse: widget.parse,
        pageSize: widget.pageSize,
        startAfter: reset ? null : _cursor,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(page.items);
        } else {
          final keys = _items
              .map((e) => widget.itemKey?.call(e) ?? e.toString())
              .toSet();
          for (final item in page.items) {
            final k = widget.itemKey?.call(item) ?? item.toString();
            if (!keys.contains(k)) {
              _items.add(item);
              keys.add(k);
            }
          }
        }
        _cursor = page.lastDocument;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e, st) {
      reportCatch(e, stackTrace: st, tag: 'FirestorePaginatedQuery.load');
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_loading || _loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    _fetchPage(reset: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(UserSafeErrorMapper.messageFor(_error!)),
      );
    }
    if (_items.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(child: Text('No items found'));
    }

    final child = ListView.builder(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.itemBuilder(context, _items[index]);
      },
    );

    if (widget.onRefresh == null) return child;
    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh?.call();
        await _loadInitial();
      },
      child: child,
    );
  }
}
