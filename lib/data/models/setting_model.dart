import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_parse.dart';

class SettingModel {
  final String settingId;
  final String scope; // 'shop' or 'system'
  final String? shopId; // required when scope == 'shop'
  final String key;
  final dynamic value;
  final DateTime updatedAt;

  const SettingModel({
    required this.settingId,
    required this.scope,
    this.shopId,
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  factory SettingModel.fromMap(Map<String, dynamic> map) {
    final scope = FirestoreParse.stringField(map['scope'], fallback: 'shop');
    final shopIdRaw = map['shopId'];
    return SettingModel(
      settingId: FirestoreParse.stringField(map['settingId']),
      scope: scope,
      shopId: shopIdRaw == null
          ? null
          : FirestoreParse.stringField(shopIdRaw),
      key: FirestoreParse.stringField(map['key']),
      value: map['value'],
      updatedAt: FirestoreParse.dateTimeField(map['updatedAt']),
    );
  }

  static SettingModel? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final setting = SettingModel.fromMap(map);
    if (setting.key.isEmpty) return null;
    return setting;
  }

  static SettingModel? tryFromQueryDocument(QueryDocumentSnapshot doc) {
    return FirestoreParse.tryParseQuery(
      doc,
      SettingModel.fromMap,
      validate: (s) => s.key.isNotEmpty,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'settingId': settingId,
      'scope': scope,
      'key': key,
      'value': value,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    if (scope == 'shop' && shopId != null) {
      map['shopId'] = shopId;
    }
    return map;
  }
}
