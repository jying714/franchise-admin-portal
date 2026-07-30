import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';

/// Industry-standard image upload field for onboarding menu items.
class ImageUploadField extends FormField<String?> {
  ImageUploadField({
    super.key,
    super.initialValue,
    String? label,
    bool required = false,
    super.onSaved,
    void Function(String?)? onChanged,
    String uploadFolder = 'menu_items',
  }) : super(
          validator: required
              ? (value) =>
                  (value == null || value.isEmpty) ? 'Image is required.' : null
              : null,
          builder: (FormFieldState<String?> state) {
            return Builder(
              builder: (context) {
                final loc = AppLocalizations.of(context)!;
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
                        style: shared.UiConfig.titleStyle,
                      ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickAndUploadImage(
                        context,
                        state,
                        storageService,
                        franchiseId,
                        uploadFolder,
                        onChanged,
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
                                    onPressed: () =>
                                        state.didChange(state.value),
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
                    const SizedBox(height: 8),
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
                            onChanged,
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                              loc.selectChangeImage ?? 'Select / Change Image'),
                        ),
                        if (state.value != null && state.value!.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              state.didChange(null);
                              onChanged?.call(null);
                            },
                            icon: const Icon(Icons.clear, size: 18),
                            label: Text(loc.clear ?? 'Clear'),
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
      key: ValueKey(safeUrl),
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) => _placeholderIcon(),
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

  static Future<void> _pickAndUploadImage(
    BuildContext context,
    FormFieldState<String?> state,
    shared.FirebaseStorageService storageService,
    String franchiseId,
    String uploadFolder,
    void Function(String?)? onChanged,
  ) async {
    final loc = AppLocalizations.of(context)!;

    if (franchiseId == 'unknown' || franchiseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.selectFranchiseFirst ??
                'Please select a franchise first.')),
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
        SnackBar(content: Text(loc.uploadingImage ?? 'Uploading image...')),
      );

      final bytes = await picked.readAsBytes();

      final uploadedUrl = await storageService.uploadFranchiseImageBytes(
        bytes: bytes,
        fileName: picked.name,
        franchiseId: franchiseId,
        folder: uploadFolder,
      );

      if (state.mounted) {
        state.didChange(uploadedUrl);
      }
      onChanged?.call(uploadedUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(loc.imageUploaded ?? 'Image uploaded successfully')),
        );
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Image upload failed',
        stack: stack.toString(),
        source: 'ImageUploadField',
        severity: 'error',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  loc.uploadFailed ?? 'Failed to upload image. Try again.')),
        );
      }
    }
  }
}
