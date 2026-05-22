import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../observability/app_logger.dart';
import '../observability/error_reporter.dart';

/// Null-safe Firestore document and field parsing helpers.
class FirestoreParse {
  FirestoreParse._();

  /// Sentinel when [createdAt] / [timestamp] is missing (not [DateTime.now]).
  static final DateTime missingDateTime =
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// Converts [DocumentSnapshot.data] to a string-keyed map, or null.
  static Map<String, dynamic>? documentData(DocumentSnapshot doc) {
    return asStringMap(doc.data());
  }

  /// Converts [QueryDocumentSnapshot.data] to a string-keyed map, or null.
  static Map<String, dynamic>? queryDocumentData(QueryDocumentSnapshot doc) {
    return asStringMap(doc.data());
  }

  /// Normalizes dynamic Firestore map payloads.
  static Map<String, dynamic>? asStringMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  static String stringField(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static double doubleField(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int intField(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool boolField(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return fallback;
  }

  static Map<String, dynamic>? mapField(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Parses Firestore [Timestamp], epoch ms, or ISO-8601 string.
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is num) {
      final ms = value.toInt();
      if (ms > 0) return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Required date fields: missing/invalid → [missingDateTime], never [DateTime.now].
  static DateTime dateTimeField(
    dynamic value, {
    DateTime? fallback,
  }) {
    return parseDateTime(value) ?? fallback ?? missingDateTime;
  }

  static T? tryParse<T>(
    DocumentSnapshot doc,
    T Function(Map<String, dynamic> map) fromMap, {
    bool Function(T value)? validate,
  }) {
    final map = documentData(doc);
    if (map == null) return null;
    return _fromMap(map, fromMap, validate, docId: doc.id);
  }

  static T? tryParseQuery<T>(
    QueryDocumentSnapshot doc,
    T Function(Map<String, dynamic> map) fromMap, {
    bool Function(T value)? validate,
  }) {
    final map = queryDocumentData(doc);
    if (map == null) return null;
    return _fromMap(map, fromMap, validate, docId: doc.id);
  }

  static List<T> parseQueryDocs<T>(
    Iterable<QueryDocumentSnapshot> docs,
    T? Function(Map<String, dynamic> map) tryFromMap,
  ) {
    final results = <T>[];
    for (final doc in docs) {
      final map = queryDocumentData(doc);
      if (map == null) continue;
      try {
        final item = tryFromMap(map);
        if (item != null) results.add(item);
      } catch (e, st) {
        AppLogger.debug(
          'Skip doc ${doc.id}: $e',
          tag: 'FirestoreParse',
          error: e,
        );
        if (kReleaseMode) {
          ErrorReporter.instance.report(
            e,
            stackTrace: st,
            tag: 'FirestoreParse.parseQueryDocs',
          );
        }
      }
    }
    return results;
  }

  static T? _fromMap<T>(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic> map) fromMap,
    bool Function(T value)? validate, {
    required String docId,
  }) {
    try {
      final value = fromMap(map);
      if (validate != null && !validate(value)) {
        AppLogger.debug(
          'Validation failed for doc $docId',
          tag: 'FirestoreParse',
        );
        return null;
      }
      return value;
    } catch (e, st) {
      AppLogger.debug('Skip doc $docId: $e', tag: 'FirestoreParse', error: e);
      if (kReleaseMode) {
        ErrorReporter.instance.report(
          e,
          stackTrace: st,
          tag: 'FirestoreParse._fromMap',
        );
      }
      return null;
    }
  }
}
