import 'package:cloud_firestore/cloud_firestore.dart';

/// Reuses Firestore snapshot streams so [StreamBuilder] rebuilds do not
/// register duplicate listeners (extra reads, leaks, jank).
class FirestoreStreamCache {
  FirestoreStreamCache._();

  static final FirestoreStreamCache instance = FirestoreStreamCache._();

  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>> _queryStreams =
      {};
  final Map<String, Stream<dynamic>> _streams = {};

  /// Cached [Query.snapshots] for the same [key].
  Stream<QuerySnapshot<Map<String, dynamic>>> querySnapshots(
    Query<Map<String, dynamic>> query, {
    required String key,
  }) {
    return _queryStreams.putIfAbsent(key, () => query.snapshots());
  }

  /// Cached arbitrary stream (e.g. mapped order/expense lists).
  Stream<T> stream<T>(String key, Stream<T> Function() factory) {
    return _streams.putIfAbsent(key, factory) as Stream<T>;
  }

  /// Drop cached streams (e.g. on logout). Optional [prefix] clears matching keys.
  void clear({String? prefix}) {
    if (prefix == null) {
      _queryStreams.clear();
      _streams.clear();
      return;
    }
    _queryStreams.removeWhere((k, _) => k.startsWith(prefix));
    _streams.removeWhere((k, _) => k.startsWith(prefix));
  }
}
