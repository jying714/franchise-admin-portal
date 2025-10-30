import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:admin_portal/core/services/firebase_storage_service.dart';

/// A form field widget to allow image selection from device gallery or camera,
/// then upload it to Firebase Storage and store the public URL.
///
/// ✅ Features:
/// - Thumbnail preview
/// - Clear/reset support
/// - Firebase upload on selection
/// - Displays validation error if required but not selected
/// - Uses FranchiseProvider to scope uploads per franchise
class ImageUploadField extends FormField<String?> {
  ImageUploadField({
    Key? key,
    String? initialValue,
    String? label,
    bool required = false,
    FormFieldSetter<String?>? onSaved,
    FormFieldValidator<String?>? validator,
    String uploadFolder = 'menu_items',
  }) : super(
          key: key,
          initialValue: initialValue,
          validator: validator ??
              (required
                  ? (value) => (value == null || value.isEmpty)
                      ? 'Image is required.'
                      : null
                  : null),
          onSaved: onSaved,
          builder: (FormFieldState<String?> state) {
            return Builder(builder: (context) {
              final franchiseId = context.read<FranchiseProvider>().franchiseId;
              final storageService = FirebaseStorageService();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (state.value != null && state.value!.isNotEmpty)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                state.value!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => state.didChange(null),
                                tooltip: 'Clear Image',
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image,
                              size: 36, color: Colors.grey),
                        ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                              source: ImageSource.gallery);

                          if (picked != null) {
                            final file = File(picked.path);

                            try {
                              final uploadedUrl =
                                  await storageService.uploadFranchiseImage(
                                file: file,
                                franchiseId: franchiseId,
                                folder: uploadFolder,
                              );
                              state.didChange(uploadedUrl);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Failed to upload image. Try again.'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select Image'),
                      ),
                    ],
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        state.errorText ?? '',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              );
            });
          },
        );
}
