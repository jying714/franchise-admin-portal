import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/widgets/header/franchise_app_bar.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/dynamic_form/dynamic_menu_item_form.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/delayed_loading_shimmer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class DynamicMenuItemEditorScreen extends StatefulWidget {
  final String? initialCategoryId;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onCategorySelected; // <-- Add this line

  const DynamicMenuItemEditorScreen(
      {super.key,
      this.initialCategoryId,
      this.onCancel,
      this.onCategorySelected});

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
      if (!mounted) return;
      setState(() {
        _selectedCategoryId = categoryId;
        _schema = _schemaCache[categoryId];
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _selectedCategoryId = categoryId;
      _schema = null;
    });

    final firestore = Provider.of<FirestoreService>(context, listen: false);

    try {
      final schema = await firestore.getCategorySchema(categoryId);

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

      if (!mounted) return;
      setState(() {
        _schemaCache[categoryId] = schema;
        _schema = schema;
        _selectedCategoryId = categoryId;
      });
    } catch (e) {
      try {
        final fallbackSchema = await firestore.getCategorySchema('default');
        if (!mounted) return;
        setState(() {
          _schemaCache[categoryId] = fallbackSchema;
          _schema = fallbackSchema;
          _selectedCategoryId = categoryId;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Using default fallback schema.'),
            backgroundColor:
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ),
        );
      } catch (fallbackError) {
        if (!mounted) return;
        setState(() => _schema = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load schema: $fallbackError'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<String>>(
      future: firestore.getAllCategorySchemaIds(),
      builder: (context, catSnapshot) {
        if (catSnapshot.hasError || catSnapshot.data == null) {
          return Center(
            child: EmptyStateWidget(
              title: loc.error,
              message:
                  catSnapshot.error?.toString() ?? loc.errorLoadingCategories,
            ),
          );
        }

        final allCategoryIds = catSnapshot.data!;

        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min, // Prevents infinite height!
            children: [
              if (_selectedCategoryId == null)
                DropdownButtonFormField<String>(
                  value: null,
                  decoration: InputDecoration(
                    labelText: loc.colCategory,
                    border: const OutlineInputBorder(),
                  ),
                  style: TextStyle(
                      color: colorScheme
                          .onSurface), // <-- text color for selected value
                  items: allCategoryIds.map((id) {
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(
                        id.isNotEmpty
                            ? id[0].toUpperCase() + id.substring(1)
                            : '',
                        style: TextStyle(
                            color: colorScheme
                                .onSurface), // <-- text color for dropdown items
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      print('Category selected: $v');
                      widget.onCategorySelected?.call(v);
                      _loadSchema(v);
                    }
                  },
                  validator: (v) => v == null ? loc.requiredField : null,
                ),
              if (_selectedCategoryId == null) const SizedBox(height: 30),
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
                  onCancel: () {
                    if (widget.onCancel != null) {
                      widget.onCancel!();
                    }
                  },
                ),
              if (_selectedCategoryId != null && _schema == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }
}
