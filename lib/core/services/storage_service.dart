import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage helper for POS system.
/// All methods are thin wrappers over FirebaseStorage and do not
/// contain any business or RBAC logic.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a receipt PDF for the given orderId.
  /// Returns the public download URL on success.
  Future<String> uploadReceipt({
    required String orderId,
    required Uint8List pdfBytes,
  }) async {
    final ref = _storage.ref().child('receipts').child('$orderId.pdf');

    final taskSnapshot = await ref.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    return taskSnapshot.ref.getDownloadURL();
  }

  /// Uploads a product image for the given productId.
  /// Caller is responsible for providing appropriate bytes and content type.
  /// Returns the public download URL on success.
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List imageBytes,
    String contentType = 'image/jpeg',
  }) async {
    final ref =
        _storage.ref().child('product_images').child('$productId.jpg');

    final taskSnapshot = await ref.putData(
      imageBytes,
      SettableMetadata(contentType: contentType),
    );

    return taskSnapshot.ref.getDownloadURL();
  }
}

