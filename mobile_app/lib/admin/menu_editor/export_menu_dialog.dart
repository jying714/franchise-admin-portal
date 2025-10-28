import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';
import 'package:doughboys_pizzeria_final/core/models/menu_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExportMenuDialog extends StatefulWidget {
  const ExportMenuDialog({Key? key}) : super(key: key);

  @override
  State<ExportMenuDialog> createState() => _ExportMenuDialogState();
}

class _ExportMenuDialogState extends State<ExportMenuDialog> {
  String? _csvData;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _exportMenu();
  }

  Future<void> _exportMenu() async {
    setState(() => _loading = true);
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final List<MenuItem> items = await firestore.getMenuItemsOnce();

    final header = [
      'Category',
      'Category ID',
      'Name',
      'Price',
      'Description',
      'Image',
      'Tax Category',
      'SKU',
      'Available',
      'Dietary Tags',
      'Allergens',
      'Prep Time',
      'Nutrition (calories/fat/carbs/protein)',
      'Customizations'
    ];
    final rows = items.map((i) {
      final nutrition = i.nutrition != null
          ? '${i.nutrition!.calories}/${i.nutrition!.fat}/${i.nutrition!.carbs}/${i.nutrition!.protein}'
          : '';
      final customizations = i.customizations.isNotEmpty
          ? i.customizations.map((c) => '${c.name}:${c.price}').join(' | ')
          : '';
      return [
        i.category,
        i.categoryId ?? '',
        i.name,
        i.price.toString(),
        i.description,
        i.image ?? '',
        i.taxCategory,
        i.sku ?? '',
        i.availability ? 'Yes' : 'No',
        i.dietaryTags.join(';'),
        i.allergens.join(';'),
        i.prepTime?.toString() ?? '',
        nutrition,
        customizations,
      ];
    }).toList();

    String escape(String s) {
      if (s.contains(',') || s.contains('"') || s.contains('\n')) {
        return '"${s.replaceAll('"', '""')}"';
      }
      return s;
    }

    final csv = StringBuffer();
    csv.writeln(header.map(escape).join(','));
    for (final row in rows) {
      csv.writeln(row.map((col) => escape(col)).join(','));
    }
    setState(() {
      _csvData = csv.toString();
      _loading = false;
    });
  }

  Future<void> _downloadCsv(BuildContext context, String csvData) async {
    final localizations = AppLocalizations.of(context)!;
    final fileName = "menu_export_${DateTime.now().millisecondsSinceEpoch}.csv";

    try {
      // Ask for permission on Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.exportError)),
          );
          return;
        }
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) throw Exception('Cannot access file system');

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(utf8.encode(csvData));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.exportError)),
        );
      }
    }
  }

  Future<void> _shareCsv(BuildContext context) async {
    if (_csvData == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/menu_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(_csvData!, flush: true);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Doughboys Menu Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.shareError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localizations.exportMenu,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 16),
              if (_loading)
                const CircularProgressIndicator()
              else if (_csvData != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.exportStarted,
                        style: const TextStyle(color: Colors.green)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SelectableText(
                          _csvData!,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.share),
                          label: Text(localizations.share),
                          onPressed: () => _shareCsv(context),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: Text(localizations.close),
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary, // Optional: make Close visually distinct
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
