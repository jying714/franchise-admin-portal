import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads the image to Firebase Storage under the franchise-specific path.
  /// Returns the public URL of the uploaded image.
  Future<String> uploadFranchiseImage({
    required File file,
    required String franchiseId,
    required String folder, // e.g. 'menu_items', 'ingredients'
  }) async {
    final String uniqueId = const Uuid().v4();
    final String filePath = 'franchises/$franchiseId/$folder/$uniqueId.jpg';

    final ref = _storage.ref().child(filePath);
    final uploadTask = await ref.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  }

  /// Optional: Delete file from storage by URL
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (_) {
      // Suppress error if already deleted
    }
  }
}
