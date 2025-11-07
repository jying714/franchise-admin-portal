// web-app/lib/core/services/firebase_storage_service_impl.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_core/src/core/services/firebase_storage_service.dart';

class FirebaseStorageServiceImpl implements FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> uploadFranchiseImage({
    required String filePath,
    required String franchiseId,
    required String folder,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found: $filePath');
    }

    final uniqueId = _uuid.v4();
    final storagePath = 'franchises/$franchiseId/$folder/$uniqueId.jpg';
    final ref = _storage.ref().child(storagePath);

    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  @override
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (_) {
      // Suppress if already deleted or invalid URL
    }
  }
}
