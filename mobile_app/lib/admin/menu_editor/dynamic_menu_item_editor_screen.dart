// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doughboys_pizzeria_final/widgets/header/franchise_app_bar.dart';
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';
//import 'package:doughboys_pizzeria_final/core/models/menu_item.dart';
import 'package:doughboys_pizzeria_final/widgets/dynamic_form/dynamic_menu_item_form.dart';
import 'package:doughboys_pizzeria_final/widgets/loading_shimmer_widget.dart';
import 'package:doughboys_pizzeria_final/widgets/empty_state_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DynamicMenuItemEditorScreen extends StatefulWidget {
  final String? initialCategoryId;

  const DynamicMenuItemEditorScreen({super.key, this.initialCategoryId});

  @override
  State<DynamicMenuItemEditorScreen> createState() =>
      _DynamicMenuItemEditorScreenState();
}

class _DynamicMenuItemEditorScreenState
    extends State<DynamicMenuItemEditorScreen> {
  String? _selectedCategoryId;
  Map<String, dynamic>? _schema;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    if (_selectedCategoryId != null) {
      _loadSchema(_selectedCategoryId!);
    }
  }

  Future<void> _loadSchema(String categoryId) async {
    setState(() {
      _schema = null;
    });

    final firestore = Provider.of<FirestoreService>(context, listen: false);

    try {
      final schema = await firestore.getCategorySchema(categoryId);

      // Resolve customizations if templateRef is used
      if (schema != null && schema['customizations'] is List) {
        schema['customizations'] =
            await _resolveCustomizations(schema['customizations']);
      }
      if (schema != null && schema['customizationGroups'] is List) {
        schema['customizationGroups'] = List<Map<String, dynamic>>.from(
          (schema['customizationGroups'] as List).map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );
      }

      setState(() {
        _schema = schema;
        _selectedCategoryId = categoryId;
      });
      print('[DEBUG] Final resolved schema: ${schema?.keys}');
    } catch (e) {
      print('[WARN] Failed to load category schema for "$categoryId": $e');
      try {
        final fallbackSchema = await firestore.getCategorySchema('default');
        setState(() {
          _schema = fallbackSchema;
          _selectedCategoryId = categoryId;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using default fallback schema.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      } catch (fallbackError) {
        setState(() => _schema = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load schema: $fallbackError'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _resolveCustomizations(
      List<dynamic> rawCustomizations) async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final List<Map<String, dynamic>> resolved = [];

    for (final entry in rawCustomizations) {
      if (entry is Map<String, dynamic> && entry.containsKey('templateRef')) {
        final templateId = entry['templateRef'];
        try {
          final template = await firestore.getCustomizationTemplate(templateId);
          if (template != null) {
            resolved.add(template);
          }
        } catch (e) {
          await firestore.logSchemaError(
            message: 'Failed to load customization template',
            templateId: templateId,
            stackTrace: e.toString(),
          );
        }
      } else if (entry is Map<String, dynamic>) {
        resolved.add(entry);
      }
    }

    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: FranchiseAppBar(title: loc.addMenuItem),
      body: FutureBuilder<List<String>>(
        future: firestore.getAllCategorySchemaIds(),
        // Must return List<Map<String, dynamic>>

        builder: (context, catSnapshot) {
          if (catSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerWidget();
          }

          if (catSnapshot.hasError || catSnapshot.data == null) {
            return EmptyStateWidget(
              title: loc.error,
              message:
                  catSnapshot.error?.toString() ?? loc.errorLoadingCategories,
            );
          }

          final allCategoryIds = catSnapshot.data!;

          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedCategoryId == null) ...[
                    DropdownButtonFormField<String>(
                      value: null,
                      decoration: InputDecoration(
                        labelText: loc.colCategory,
                        border: const OutlineInputBorder(),
                      ),
                      items: allCategoryIds.map((id) {
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(id.isNotEmpty
                              ? id[0].toUpperCase() + id.substring(1)
                              : ''),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          _loadSchema(v);
                        }
                      },
                      validator: (v) => v == null ? loc.requiredField : null,
                    ),
                    const SizedBox(height: 30),
                  ],
                  if (_selectedCategoryId != null && _schema == null)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: LoadingShimmerWidget(),
                    ),
                  if (_schema != null)
                    DynamicMenuItemForm(
                      schema: _schema!,
                      initialItem: null,
                      onSave: (menuItem) async {
                        try {
                          await firestore.addMenuItem(menuItem);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.itemAdded)),
                          );
                          Navigator.pop(context);
                        } catch (e, stack) {
                          print('[ERROR] Failed to save item: $e');
                          print(stack);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${loc.error}: $e')),
                          );
                        }
                      },
                      onCancel: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
