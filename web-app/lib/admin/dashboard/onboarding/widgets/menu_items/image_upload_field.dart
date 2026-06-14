// lib/admin/dashboard/onboarding/widgets/menu_items/image_upload_field.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

import 'package:franchise_admin_portal/config/ui_config.dart'; // For consistent styling

/// Industry-standard image upload field for onboarding menu items.
/// Supports: upload, preview with error fallback, change, clear, progress.
class ImageUploadField extends FormField<String?> {
  ImageUploadField({
    super.key,
    super.initialValue,
    String? label,
    bool required = false,
    super.onSaved,
    String uploadFolder = 'menu_items',
  }) : super(
          validator: required
              ? (value) =>
                  (value == null || value.isEmpty) ? 'Image is required.' : null
              : null,
          builder: (FormFieldState<String?> state) {
            return Builder(
              builder: (context) {
                final franchiseProvider = Provider.of<shared.FranchiseProvider>(
                    context,
                    listen: false);
                final storageService =
                    Provider.of<shared.FirebaseStorageService>(context,
                        listen: false);
                final franchiseId = franchiseProvider.franchiseId;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null)
                      Text(
                        label,
                        style:
                            UiConfig.titleStyle, // Project-consistent styling
                      ),
                    const SizedBox(height: 8),
                    // Preview with robust error handling + fallback + Refresh
                    // Preview with robust error handling + Refresh button
                    GestureDetector(
                      onTap: () => _pickAndUploadImage(
                        context,
                        state,
                        storageService,
                        franchiseId,
                        uploadFolder,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            children: [
                              _buildPreviewImage(state.value),
                              if (state.value != null &&
                                  state.value!.isNotEmpty)
                                Positioned(
                                  bottom: -6,
                                  right: -6,
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh,
                                        size: 18, color: Colors.blue),
                                    onPressed: () => state
                                        .didChange(state.value), // Force reload
                                    tooltip: 'Refresh Image Preview',
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.9),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Action buttons (restored + improved spacing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickAndUploadImage(
                            context,
                            state,
                            storageService,
                            franchiseId,
                            uploadFolder,
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Select / Change Image'),
                        ),
                        if (state.value != null && state.value!.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => state.didChange(null),
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          state.errorText ?? '',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );

  // Private helper for safe preview
  static Widget _buildPreviewImage(String? imageUrl) {
    final safeUrl = _getSafeImageUrl(imageUrl);

    if (safeUrl.startsWith('assets/')) {
      return Image.asset(
        safeUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderIcon(),
      );
    }

    return Image.network(
      safeUrl,
      key: ValueKey(
          '${safeUrl}_${DateTime.now().millisecondsSinceEpoch}'), // Force cache bust
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Reduced logging for fresh uploads
        return _placeholderIcon();
      },
    );
  }

  static String _getSafeImageUrl(String? url) {
    if (url == null || url.isEmpty || url.contains('example.com')) {
      return 'assets/images/pizza.png';
    }
    return url;
  }

  static Widget _placeholderIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 36, color: Colors.grey),
    );
  }

  // Upload handler - Web + Mobile compatible
  static Future<void> _pickAndUploadImage(
    BuildContext context,
    FormFieldState<String?> state,
    shared.FirebaseStorageService storageService,
    String franchiseId,
    String uploadFolder,
  ) async {
    if (franchiseId == 'unknown' || franchiseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a franchise first.')),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...')),
      );

      // Web-safe: Use bytes instead of path
      final bytes = await picked.readAsBytes();

      final uploadedUrl = await storageService.uploadFranchiseImageBytes(
        bytes: bytes,
        fileName: picked.name,
        franchiseId: franchiseId,
        folder: uploadFolder,
      );

      // Increased delay + force rebuild via didChange
      // Longer delay for CDN propagation + force rebuild
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (state.mounted) {
          state.didChange(uploadedUrl);
        }
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Image upload failed: $e',
        stack: stack.toString(),
        source: 'ImageUploadField',
        severity: 'error',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image. Try again.')),
        );
      }
    }
  }
}
