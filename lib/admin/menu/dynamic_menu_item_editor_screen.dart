import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/widgets/header/franchise_app_bar.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/dynamic_menu_item_form.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/delayed_loading_shimmer.dart';
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
  final Map<String, Map<String, dynamic>?> _schemaCache = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    if (_selectedCategoryId != null) {
      _loadSchema(_selectedCategoryId!);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSchema(String categoryId) async {
    if (_schemaCache.containsKey(categoryId)) {
      setState(() {
        _selectedCategoryId = categoryId;
        _schema = _schemaCache[categoryId];
      });
      return;
    }

    setState(() {
      _selectedCategoryId = categoryId;
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
        _schemaCache[categoryId] = schema;
        _schema = schema;
        _selectedCategoryId = categoryId;
      });
      print('[DEBUG] Final resolved schema: ${schema?.keys}');
    } catch (e) {
      print('[WARN] Failed to load category schema for "$categoryId": $e');
      try {
        final fallbackSchema = await firestore.getCategorySchema('default');
        setState(() {
          _schemaCache[categoryId] = fallbackSchema;
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

    return FutureBuilder<List<String>>(
      future: firestore.getAllCategorySchemaIds(),
      builder: (context, catSnapshot) {
        return DelayedLoadingShimmer(
          loading: catSnapshot.connectionState == ConnectionState.waiting,
          child: Builder(
            builder: (context) {
              if (catSnapshot.hasError || catSnapshot.data == null) {
                return Center(
                  child: EmptyStateWidget(
                    title: loc.error,
                    message: catSnapshot.error?.toString() ??
                        loc.errorLoadingCategories,
                  ),
                );
              }

              final allCategoryIds = catSnapshot.data!;

              return SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        loc.addMenuItem,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                            child: Text(
                              id.isNotEmpty
                                  ? id[0].toUpperCase() + id.substring(1)
                                  : '',
                            ),
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
                    if (_selectedCategoryId != null && _schema == null)
                      DelayedLoadingShimmer(
                        loading: true,
                        child: const SizedBox.shrink(),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
