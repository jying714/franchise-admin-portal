import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/core/services/admin_firestore_service.dart';

class TemplateImportDialog extends StatefulWidget {
  const TemplateImportDialog({super.key});

  @override
  State<TemplateImportDialog> createState() => _TemplateImportDialogState();
}

class _TemplateImportDialogState extends State<TemplateImportDialog> {
  bool _importIngredientTypes = true;
  bool _importIngredients = true;
  bool _importCategories = true;
  bool _importStarterMenuItems = true;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(loc?.templateImportTitle ?? 'Quick Start with Template'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc?.templateImportSubtitle ??
                  'Select what to import for Classic Pizzeria template:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Ingredient Types'),
              subtitle: const Text('Sauces, Toppings, Cheeses, etc.'),
              value: _importIngredientTypes,
              onChanged: (val) =>
                  setState(() => _importIngredientTypes = val ?? true),
            ),
            CheckboxListTile(
              title: const Text('Ingredients'),
              subtitle: const Text('All individual ingredients with metadata'),
              value: _importIngredients,
              onChanged: (val) =>
                  setState(() => _importIngredients = val ?? true),
            ),
            CheckboxListTile(
              title: const Text('Categories'),
              subtitle: const Text('Pizza, Calzones, Appetizers, etc.'),
              value: _importCategories,
              onChanged: (val) =>
                  setState(() => _importCategories = val ?? true),
            ),
            CheckboxListTile(
              title: const Text('Starter Menu Items'),
              subtitle: const Text('15–20 ready-to-use items (recommended)'),
              value: _importStarterMenuItems,
              onChanged: (val) =>
                  setState(() => _importStarterMenuItems = val ?? true),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Text(
              'This will populate editable data. You can modify everything afterward.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final selection = {
              'ingredientTypes': _importIngredientTypes,
              'ingredients': _importIngredients,
              'categories': _importCategories,
              'starterMenuItems': _importStarterMenuItems,
            };

            final adminService = AdminFirestoreService();
            final franchiseProvider =
                Provider.of<shared.FranchiseProvider>(context, listen: false);
            final franchiseId = franchiseProvider.franchiseId;

            if (franchiseId.isEmpty || franchiseId == 'unknown') {
              Navigator.of(context).pop(selection);
              return;
            }

            try {
              // Import selected parts
              if (_importIngredientTypes) {
                await adminService.copyIngredientTypesFromTemplate(
                  franchiseId: franchiseId,
                  templateId: 'pizzeria',
                );
              }
              if (_importIngredients) {
                await adminService.importIngredientsFromTemplate(
                  franchiseId: franchiseId,
                  templateId: 'pizzeria',
                );
              }
              if (_importCategories) {
                await adminService.loadTemplateWithFranchiseId(
                  franchiseId: franchiseId,
                  templateId: 'pizzeria',
                );
              }
              if (_importStarterMenuItems) {
                await adminService.importMenuItemsFromTemplate(
                  franchiseId: franchiseId,
                  templateId: 'pizzeria',
                );
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Template import completed successfully!')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Import failed: $e')),
              );
            }

            Navigator.of(context).pop(selection);
          },
          child: const Text('Import Selected'),
        ),
      ],
    );
  }
}
