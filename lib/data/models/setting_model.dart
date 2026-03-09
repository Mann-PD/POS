import 'package:cloud_firestore/cloud_firestore.dart';

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
    return SettingModel(
      settingId: map['settingId'] as String? ?? '',
      scope: map['scope'] as String? ?? 'shop',
      shopId: map['shopId'] as String?,
      key: map['key'] as String? ?? '',
      value: map['value'],
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
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
