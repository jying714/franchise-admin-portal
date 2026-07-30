// web-app/lib/core/services/firebase_storage_service_impl.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:flutter/foundation.dart' show Uint8List;

class FirebaseStorageServiceImpl implements shared.FirebaseStorageService {
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

    final bytes = await file.readAsBytes();
    return await uploadFranchiseImageBytes(
      bytes: bytes,
      fileName: file.path.split(Platform.pathSeparator).last,
      franchiseId: franchiseId,
      folder: folder,
    );
  }

  @override
  Future<String> uploadFranchiseImageBytes({
    required Uint8List bytes,
    required String fileName,
    required String franchiseId,
    String folder = 'menu_items',
  }) async {
    if (franchiseId == 'unknown' || franchiseId.isEmpty) {
      throw Exception('Invalid franchiseId for upload');
    }

    try {
      final extension = fileName.split('.').last.toLowerCase();
      final safeExt = (extension == 'jpeg') ? 'jpg' : extension;
      final safeFileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.$safeExt';
      final storagePath = 'franchises/$franchiseId/$folder/$safeFileName';

      final ref = _storage.ref().child(storagePath);

      final contentType = switch (safeExt) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'svg' => 'image/svg+xml',
        _ => 'application/octet-stream',
      };

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'franchiseId': franchiseId},
      );

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('[FirebaseStorageServiceImpl] Upload success: $downloadUrl');
      return downloadUrl;
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'uploadFranchiseImageBytes failed',
        stack: stack.toString(),
        source: 'FirebaseStorageServiceImpl',
        severity: 'error',
        contextData: {'franchiseId': franchiseId, 'fileName': fileName},
      );
      rethrow;
    }
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
