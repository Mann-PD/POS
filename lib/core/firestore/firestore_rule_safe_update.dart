import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/category_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/setting_model.dart';
import '../../data/models/shop_model.dart';
import '../../data/models/user_model.dart';

/// Builds Firestore [update] payloads that include immutable fields required by
/// [firebase/firestore.rules]. Partial patches can fail rules when merged document
/// fields are missing, mistyped, or when explicit equality checks need stable values.
class FirestoreRuleSafeUpdate {
  FirestoreRuleSafeUpdate._();

  /// Products: shopId, productId, createdAt, stock, measurementType must not change.
  static Map<String, dynamic> product(
    ProductModel existing, {
    required Map<String, dynamic> changes,
  }) {
    return {
      'shopId': existing.shopId,
      'productId': existing.productId,
      'createdAt': Timestamp.fromDate(existing.createdAt),
      'measurementType': existing.measurementType,
      'stock': existing.stock,
      ...changes,
    };
  }

  /// Categories: shopId and categoryId must not change.
  static Map<String, dynamic> category(
    CategoryModel existing, {
    required Map<String, dynamic> changes,
  }) {
    return {
      'shopId': existing.shopId,
      'categoryId': existing.categoryId,
      ...changes,
    };
  }

  /// Customers: shopId, customerId, createdAt must not change.
  static Map<String, dynamic> customer(
    CustomerModel existing, {
    required Map<String, dynamic> changes,
  }) {
    return {
      'shopId': existing.shopId,
      'customerId': existing.customerId,
      'createdAt': Timestamp.fromDate(existing.createdAt),
      ...changes,
    };
  }

  /// Users: userId, role, createdAt must not change; shopId immutable for non-SuperAdmin.
  static Map<String, dynamic> user(
    UserModel existing, {
    required Map<String, dynamic> changes,
  }) {
    return {
      'userId': existing.userId,
      'role': existing.role,
      'shopId': existing.shopId,
      'createdAt': Timestamp.fromDate(existing.createdAt),
      ...changes,
    };
  }

  /// Settings: settingId and scope must not change; shopId preserved for shop scope.
  static Map<String, dynamic> setting(
    SettingModel existing, {
    required Map<String, dynamic> changes,
  }) {
    final payload = <String, dynamic>{
      'settingId': existing.settingId,
      'scope': existing.scope,
      'key': existing.key,
      ...changes,
    };
    if (existing.scope == 'shop' && existing.shopId != null) {
      payload['shopId'] = existing.shopId;
    }
    return payload;
  }

  /// Settings from a raw Firestore map (e.g. stream documents without a model).
  static Map<String, dynamic> settingFromMap(
    Map<String, dynamic> existing, {
    required Map<String, dynamic> changes,
  }) {
    final payload = <String, dynamic>{
      'settingId': existing['settingId'],
      'scope': existing['scope'],
      'key': existing['key'],
      ...changes,
    };
    final shopId = existing['shopId'];
    if (shopId != null) {
      payload['shopId'] = shopId;
    }
    return payload;
  }

  /// Shops: no immutable-field rule checks, but preserve identity fields on patch.
  static Map<String, dynamic> shop(
    ShopModel existing, {
    required Map<String, dynamic> changes,
  }) {
    return {
      'shopId': existing.shopId,
      'createdAt': Timestamp.fromDate(existing.createdAt),
      ...changes,
    };
  }
}
