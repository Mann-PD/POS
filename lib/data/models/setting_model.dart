import 'package:cloud_firestore/cloud_firestore.dart';

class SettingModel {
  final String settingId;
  final String scope; // 'shop' or 'system'
  final String key;
  final dynamic value;
  final DateTime updatedAt;

  const SettingModel({
    required this.settingId,
    required this.scope,
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  factory SettingModel.fromMap(Map<String, dynamic> map) {
    return SettingModel(
      settingId: map['settingId'] as String? ?? '',
      scope: map['scope'] as String? ?? 'shop',
      key: map['key'] as String? ?? '',
      value: map['value'],
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'settingId': settingId,
      'scope': scope,
      'key': key,
      'value': value,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
