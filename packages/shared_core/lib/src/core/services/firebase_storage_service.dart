// packages/shared_core/lib/src/core/services/firebase_storage_service.dart
import 'package:flutter/foundation.dart' show Uint8List;

/// Pure interface — no Firebase, no dart:io, no Flutter
abstract class FirebaseStorageService {
  /// Uploads an image file and returns the public download URL
  /// [filePath] = local path to image
  /// [franchiseId] = owner
  /// [folder] = subfolder (e.g. 'menu_items')
  Future<String> uploadFranchiseImage({
    required String filePath,
    required String franchiseId,
    required String folder,
  });

  /// Deletes image by full public URL
  Future<void> deleteImageByUrl(String imageUrl);

  /// Web + Mobile safe: Uploads raw image bytes
  /// Preferred for web (ImagePicker returns bytes, not File)
  Future<String> uploadFranchiseImageBytes({
    required Uint8List bytes,
    required String fileName,
    required String franchiseId,
    String folder = 'menu_items',
  });
}
