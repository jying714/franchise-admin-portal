import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

/// Callback with the file's contents (as String) if successful, null if canceled.
typedef CsvFilePickedCallback = void Function(String? csvContent);

class ImportCsvFileButton extends StatefulWidget {
  /// Display label for the button (should be localized).
  final String label;

  /// Called with the CSV file's text contents if picked, or null if canceled.
  final CsvFilePickedCallback onCsvPicked;

  /// Optional icon for the button.
  final IconData icon;

  /// Can disable the button.
  final bool enabled;

  const ImportCsvFileButton({
    Key? key,
    required this.label,
    required this.onCsvPicked,
    this.icon = Icons.file_upload,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ImportCsvFileButton> createState() => _ImportCsvFileButtonState();
}

class _ImportCsvFileButtonState extends State<ImportCsvFileButton> {
  bool _loading = false;

  Future<void> _pickCsvFile() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Ensures we get file content as bytes
      );
      if (result != null && result.files.single.bytes != null) {
        // Try reading as UTF-8. Fallback to Latin1 if necessary.
        String content;
        try {
          content = String.fromCharCodes(result.files.single.bytes!);
        } catch (e) {
          // If weird encoding, fallback to Latin1.
          content = const Latin1Decoder().convert(result.files.single.bytes!);
        }
        widget.onCsvPicked(content);
      } else {
        // User canceled
        widget.onCsvPicked(null);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import file: $e')),
      );
      widget.onCsvPicked(null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Icon(widget.icon, size: 20),
      label: Text(widget.label, style: const TextStyle(fontSize: 15)),
      onPressed: (!widget.enabled || _loading) ? null : _pickCsvFile,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        backgroundColor: widget.enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).disabledColor,
        foregroundColor: widget.enabled ? Colors.white : Colors.black45,
      ),
    );
  }
}


