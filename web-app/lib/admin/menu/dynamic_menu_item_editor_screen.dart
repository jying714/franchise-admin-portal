import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/widgets/header/franchise_app_bar.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/widgets/dynamic_form/dynamic_menu_item_form.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/delayed_loading_shimmer.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class DynamicMenuItemEditorScreen extends StatefulWidget {
  final String franchiseId;
  final String? initialCategoryId;
  final shared.MenuItem? initialItem;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onCategorySelected; // <-- Add this line

  const DynamicMenuItemEditorScreen(
      {super.key,
      required this.franchiseId,
      this.initialCategoryId,
      this.initialItem,
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
    if (widget.initialItem != null) {
      _selectedCategoryId = widget.initialItem!.categoryId;
    } else if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Force load if we have a category but no schema yet
    if (_selectedCategoryId != null && _schema == null) {
      final franchiseId = widget.franchiseId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadSchema(franchiseId, _selectedCategoryId!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _resolveCustomizations(
      String franchiseId, List<dynamic> rawCustomizations) async {
    final firestore =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final List<Map<String, dynamic>> resolved = [];

    for (final entry in rawCustomizations) {
      if (entry is Map<String, dynamic> && entry.containsKey('templateRef')) {
        final templateId = entry['templateRef'];
        try {
          final template =
              await firestore.getCustomizationTemplate(franchiseId, templateId);
          if (template != null) {
            resolved.add(template);
          }
        } catch (e) {
          await firestore.logSchemaError(
            franchiseId,
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
    final franchiseId = widget.franchiseId;
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Scaffold(body: Center(child: Text('Localization missing!')));
    }

    final firestore =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<String>>(
      future: firestore.getAllCategorySchemaIds(franchiseId),
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
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown ONLY for truly new items (no initialItem)
              if (_selectedCategoryId == null && widget.initialItem == null)
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
                      widget.onCategorySelected?.call(v);
                      _loadSchema(franchiseId, v);
                    }
                  },
                )
              // Loading schema (for both new and edit)
              else if (_schema == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              // Form shows as soon as schema is loaded
              else if (_schema != null)
                DynamicMenuItemForm(
                  franchiseId: franchiseId,
                  schema: _schema!,
                  initialItem: widget.initialItem,
                  onSave: (menuItem) async {
                    try {
                      final finalItem = widget.initialItem != null
                          ? menuItem.copyWith(id: widget.initialItem!.id)
                          : menuItem;

                      if (widget.initialItem != null) {
                        await firestore.updateMenuItem(franchiseId, finalItem);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(loc.itemUpdated ?? 'Item updated')),
                        );
                      } else {
                        await firestore.addMenuItem(franchiseId, finalItem);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(loc.itemAdded ?? 'Item added')),
                        );
                      }

                      widget.onCancel?.call(); // Use panel's close logic
                    } catch (e, stack) {
                      shared.ErrorLogger.log(
                        message: 'Failed to save menu item',
                        source: 'DynamicMenuItemEditorScreen',
                        severity: 'error',
                        stack: stack.toString(),
                        contextData: {
                          'franchiseId': franchiseId,
                          'itemId': widget.initialItem?.id,
                          'error': e.toString(),
                        },
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.errorGeneric ??
                              'An error occurred while saving'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
                  onCancel: () {
                    if (widget.onCancel != null) {
                      widget.onCancel!();
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSchema(String franchiseId, String categoryId) async {
    print(
        '[DynamicMenuItemEditorScreen] _loadSchema STARTED for category: $categoryId');

    if (_schemaCache.containsKey(categoryId)) {
      if (!mounted) return;
      setState(() {
        _selectedCategoryId = categoryId;
        _schema = _schemaCache[categoryId];
      });
      print(
          '[DynamicMenuItemEditorScreen] _loadSchema CACHE HIT for $categoryId');
      return;
    }

    if (!mounted) return;
    setState(() {
      _selectedCategoryId = categoryId;
      _schema = null;
    });

    final firestore =
        Provider.of<shared.FirestoreService>(context, listen: false);

    try {
      print(
          '[DynamicMenuItemEditorScreen] _loadSchema calling getCategorySchema for $categoryId');
      final schema = await firestore.getCategorySchema(franchiseId, categoryId);
      print(
          '[DynamicMenuItemEditorScreen] _loadSchema getCategorySchema returned: ${schema != null ? "SUCCESS" : "null"}');

      if (schema != null && schema['customizations'] is List) {
        schema['customizations'] =
            await _resolveCustomizations(franchiseId, schema['customizations']);
      }
      if (schema != null && schema['customizationGroups'] is List) {
        schema['customizationGroups'] = List<Map<String, dynamic>>.from(
          (schema['customizationGroups'] as List)
              .map((e) => Map<String, dynamic>.from(e)),
        );
      }

      if (!mounted) return;
      setState(() {
        _schemaCache[categoryId] = schema;
        _schema = schema;
        _selectedCategoryId = categoryId;
      });
      print(
          '[DynamicMenuItemEditorScreen] _loadSchema COMPLETE - schema loaded for $categoryId');
    } catch (e, stack) {
      print('[DynamicMenuItemEditorScreen] _loadSchema ERROR: $e');
      shared.ErrorLogger.log(
        message: '_loadSchema failed',
        source: 'DynamicMenuItemEditorScreen',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'categoryId': categoryId},
      );

      try {
        print(
            '[DynamicMenuItemEditorScreen] _loadSchema trying fallback schema');
        final fallbackSchema =
            await firestore.getCategorySchema(franchiseId, 'default');
        if (!mounted) return;
        setState(() {
          _schemaCache[categoryId] = fallbackSchema;
          _schema = fallbackSchema;
          _selectedCategoryId = categoryId;
        });
        print('[DynamicMenuItemEditorScreen] _loadSchema FALLBACK SUCCESS');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Using default fallback schema.')),
        );
      } catch (fallbackError, fallbackStack) {
        print(
            '[DynamicMenuItemEditorScreen] _loadSchema FALLBACK FAILED: $fallbackError');
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
}
