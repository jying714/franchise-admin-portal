// packages/shared_core/lib/src/core/services/firebase_storage_service.dart

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
}
