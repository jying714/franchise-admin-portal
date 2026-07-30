import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// Renders an image upload or URL field combo.
/// Used for admin editing of item preview image.
class ImageUploadField extends StatefulWidget {
  final String label;
  final String? url;
  final ValueChanged<String> onChanged;

  const ImageUploadField({
    super.key,
    required this.label,
    this.url,
    required this.onChanged,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.url ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final storageService =
        Provider.of<shared.FirebaseStorageService>(context, listen: false);
    final franchiseId = franchiseProvider.franchiseId;

    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a franchise before uploading.')),
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...')),
      );

      final bytes = await picked.readAsBytes();
      final uploadedUrl = await storageService.uploadFranchiseImageBytes(
        bytes: bytes,
        fileName: picked.name,
        franchiseId: franchiseId,
        folder: 'menu_items',
      );

      if (!mounted) return;
      setState(() => _urlController.text = uploadedUrl);
      widget.onChanged(uploadedUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _urlController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    BrandingConfig.defaultCategoryIcon,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            Expanded(
              child: TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'Paste image URL or upload...',
                ),
                onChanged: widget.onChanged,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.upload),
              tooltip: 'Upload Image',
              onPressed: _pickImage,
            ),
          ],
        ),
      ],
    );
  }
}
