import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';
import '../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';

/// AttachmentUploader
/// For payout attachments (detail or bulk), reusable for other models.
/// Accepts payoutId, existing attachments, and onUploaded/onDeleted callbacks.
class AttachmentUploader extends StatefulWidget {
  final String payoutId;
  final List<Map<String, dynamic>> existingAttachments;
  final VoidCallback? onUploaded;
  final VoidCallback? onDeleted;
  final bool developerMode;
  final List<String>? allowedExtensions;

  const AttachmentUploader({
    Key? key,
    required this.payoutId,
    this.existingAttachments = const [],
    this.onUploaded,
    this.onDeleted,
    this.developerMode = false,
    this.allowedExtensions,
  }) : super(key: key);

  @override
  State<AttachmentUploader> createState() => _AttachmentUploaderState();
}

class _AttachmentUploaderState extends State<AttachmentUploader> {
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        allowedExtensions: widget.allowedExtensions,
        type: widget.allowedExtensions == null ? FileType.any : FileType.custom,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _uploading = false);
        return; // User cancelled
      }
      final file = result.files.first;

      // (In a real app, upload to storage, get URL, etc. Here we just stub meta.)
      final meta = {
        'filename': file.name,
        'size': file.size,
        'uploadedAt': DateTime.now().toUtc().toIso8601String(),
        // 'url': ..., // Add if implementing storage!
      };

      await FirestoreService().addAttachmentToPayout(widget.payoutId, meta);
      widget.onUploaded?.call();
      setState(() {
        _uploading = false;
        _error = null;
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'AttachmentUploader: Failed to upload - $e',
        stack: stack.toString(),
        source: 'AttachmentUploader',
        screen: 'attachment_uploader.dart',
        severity: 'error',
      );
      setState(() {
        _uploading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteAttachment(Map<String, dynamic> att) async {
    try {
      await FirestoreService().removeAttachmentFromPayout(widget.payoutId, att);
      widget.onDeleted?.call();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'AttachmentUploader: Failed to delete attachment - $e',
        stack: stack.toString(),
        source: 'AttachmentUploader',
        screen: 'attachment_uploader.dart',
        severity: 'error',
      );
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disabled = !widget.developerMode;

    return Card(
      color: colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.addAttachment, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file),
              label: Text(
                _uploading ? loc.uploading : loc.attachFile ?? "Attach File",
              ),
              onPressed: disabled || _uploading ? null : _pickAndUpload,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                backgroundColor: colorScheme.background,
                textStyle: theme.textTheme.bodyMedium,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.error),
              ),
            ],
            if (widget.existingAttachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(loc.attachments ?? 'Attachments:',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              for (final att in widget.existingAttachments)
                ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(att['filename'] ?? att['url'] ?? 'Attachment'),
                  subtitle: Text(
                    att['uploadedAt'] != null ? att['uploadedAt'] : '',
                    style: theme.textTheme.labelSmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: loc.removeAttachment ?? "Remove",
                    onPressed: disabled ? null : () => _deleteAttachment(att),
                  ),
                ),
            ],
            if (disabled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  loc.featureDeveloperOnly,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
