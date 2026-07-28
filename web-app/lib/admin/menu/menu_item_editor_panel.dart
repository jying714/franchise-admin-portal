import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/core/services/admin_firestore_service.dart';

class MenuItemEditorPanel extends StatefulWidget {
  final bool isOpen;
  final String? initialCategoryId;
  final shared.MenuItem? initialItem;
  final VoidCallback onClose;
  final VoidCallback? onCategoryCleared;
  final ValueChanged<String>? onCategorySelected; // <-- Add this

  const MenuItemEditorPanel({
    Key? key,
    required this.isOpen,
    this.initialCategoryId,
    this.initialItem,
    required this.onClose,
    this.onCategoryCleared,
    this.onCategorySelected, // <-- Add this
  }) : super(key: key);

  @override
  State<MenuItemEditorPanel> createState() => _MenuItemEditorPanelState();
}

class _MenuItemEditorPanelState extends State<MenuItemEditorPanel> {
  String? _categoryId;
  shared.MenuItem? _editingMenuItem;
  bool _showEditorPanel = false;

  @override
  void didUpdateWidget(MenuItemEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      setState(() {
        _categoryId = widget.initialCategoryId;
      });
    }
    if (widget.initialItem != oldWidget.initialItem ||
        widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _ensureFoundationLoaded();
        });
      }
    }
    if (!widget.isOpen) {
      setState(() {
        _categoryId = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureFoundationLoaded();
    });
  }

  Future<void> _ensureFoundationLoaded() async {
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;

    final typeProvider =
        Provider.of<shared.IngredientTypeProvider>(context, listen: false);
    final metadataProvider =
        Provider.of<shared.IngredientMetadataProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<shared.CategoryProvider>(context, listen: false);
    final menuProvider =
        Provider.of<shared.MenuItemProvider>(context, listen: false);

    await Future.wait([
      typeProvider.load(
        franchiseIdOverride: franchiseId,
        forceReloadFromFirestore: true,
      ),
      metadataProvider.load(forceReloadFromFirestore: true),
      categoryProvider.load(
        franchiseIdOverride: franchiseId,
        forceReloadFromFirestore: true,
      ),
      menuProvider.load(
        franchiseIdOverride: franchiseId,
        forceReloadFromFirestore: true,
      ),
    ]);
    if (mounted) setState(() {});
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: theme.colorScheme.surface,
      child: MenuItemEditorSheet(
        key: ValueKey(widget.initialItem?.id ?? _categoryId ?? 'new'),
        existing: widget.initialItem,
        franchiseId:
            Provider.of<shared.FranchiseProvider>(context, listen: false)
                .franchiseId,
        firestore: FirebaseFirestore.instance,
        onSave: (item) async {
          final franchiseId =
              Provider.of<shared.FranchiseProvider>(context, listen: false)
                  .franchiseId;
          final adminService = AdminFirestoreService();
          final menuProvider =
              Provider.of<shared.MenuItemProvider>(context, listen: false);
          try {
            menuProvider.addOrUpdateMenuItem(item);
            await adminService.saveMenuItem(
              franchiseId: franchiseId,
              menuItem: item,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Item saved'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            widget.onClose();
          } catch (e, stack) {
            shared.ErrorLogger.log(
              message: 'admin_menu_item_save_failed',
              stack: stack.toString(),
              source: 'menu_item_editor_panel',
              severity: 'error',
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Save failed: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () {
          if (_categoryId != null) {
            setState(() {
              _categoryId = null;
            });
            widget.onCategoryCleared?.call();
          } else {
            widget.onClose();
          }
        },
      ),
    );
  }

  Future<void> _addOrEditMenuItemPanel({shared.MenuItem? item}) async {
    setState(() {
      _editingMenuItem = item;
      _categoryId = item?.categoryId;
      _showEditorPanel = true;
    });
  }
}
