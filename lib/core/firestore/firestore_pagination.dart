import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_parse.dart';

/// Default page sizes for Firestore list/history queries.
abstract final class FirestorePageSize {
  static const int standard = 30;
  static const int history = 40;
  static const int audit = 50;
  /// Cap for report dashboards that still use live streams (date-filtered in UI).
  static const int reportStreamCap = 150;
  /// Safety cap for POS active catalog (realtime; typical shops stay well below).
  static const int posCatalogCap = 500;
  /// Default lookback for report range queries when no range is chosen.
  static const int reportRangeDays = 90;
}

/// Result of a single paginated fetch (non-streaming).
class FirestorePage<T> {
  const FirestorePage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  static FirestorePage<T> empty<T>() => FirestorePage<T>(
        items: const [],
        lastDocument: null,
        hasMore: false,
      );
}

/// Fetches one page from [query]. [startAfter] is the last doc from the previous page.
Future<FirestorePage<T>> fetchFirestorePage<T>({
  required Query<Map<String, dynamic>> query,
  required T? Function(Map<String, dynamic> data, String docId) parse,
  int pageSize = FirestorePageSize.standard,
  DocumentSnapshot<Map<String, dynamic>>? startAfter,
}) async {
  Query<Map<String, dynamic>> q = query.limit(pageSize);
  if (startAfter != null) {
    q = q.startAfterDocument(startAfter);
  }
  final snap = await q.get();
  final items = <T>[];
  for (final doc in snap.docs) {
    final map = FirestoreParse.queryDocumentData(doc);
    if (map == null) continue;
    final item = parse(map, doc.id);
    if (item != null) items.add(item);
  }
  final last = snap.docs.isNotEmpty ? snap.docs.last : null;
  return FirestorePage(
    items: items,
    lastDocument: last,
    hasMore: snap.docs.length >= pageSize,
  );
}

/// Applies [limit] to a query used for realtime listeners (first page only).
Query<Map<String, dynamic>> firstPageQuery(
  Query<Map<String, dynamic>> query, {
  int pageSize = FirestorePageSize.standard,
}) {
  return query.limit(pageSize);
}

/// Report default range: last [days] through end of today.
DateTime reportRangeStart({int days = FirestorePageSize.reportRangeDays}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: days));
}

DateTime reportRangeEnd() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
}
