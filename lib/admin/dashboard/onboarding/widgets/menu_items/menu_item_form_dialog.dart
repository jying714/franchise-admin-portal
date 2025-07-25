import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class MenuItemFormDialog extends StatefulWidget {
  final MenuItem? initialItem;

  const MenuItemFormDialog({super.key, this.initialItem});

  static Future<void> show(BuildContext context,
      {MenuItem? initialItem}) async {
    await showDialog(
      context: context,
      builder: (_) => MenuItemFormDialog(initialItem: initialItem),
    );
  }

  @override
  State<MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends State<MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _categoryIdController;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _priceController = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(2) : '',
    );
    _categoryIdController = TextEditingController(text: item?.categoryId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _categoryIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final franchiseId = context.read<FranchiseProvider>().franchiseId;

    if (!_formKey.currentState!.validate()) return;

    try {
      final menuItem = MenuItem(
        id: widget.initialItem?.id ?? UniqueKey().toString(),
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        availability: true,
        category: '',
        categoryId: _categoryIdController.text.trim(),
        taxCategory: 'default',
        customizations: [],
        customizationGroups: [],
      );

      if (!mounted) return;
      Navigator.of(context).pop(menuItem);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to create menu item',
        source: 'menu_item_form_dialog',
        screen: 'menu_item_form_dialog',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(widget.initialItem == null
          ? loc.addMenuItem
          : loc.editMenuItem(widget.initialItem!.name)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: loc.name),
                validator: (val) => val == null || val.trim().isEmpty
                    ? loc.fieldRequired
                    : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: loc.description),
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: loc.basePrice),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^[0-9]*[.]?[0-9]*')),
                ],
              ),
              TextFormField(
                controller: _categoryIdController,
                decoration: InputDecoration(labelText: loc.categoryId),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primaryColor,
          ),
          child: Text(loc.save),
        ),
      ],
    );
  }
}
