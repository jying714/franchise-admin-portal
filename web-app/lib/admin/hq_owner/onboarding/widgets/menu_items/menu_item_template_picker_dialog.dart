import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;

class MenuItemTemplatePickerDialog extends StatelessWidget {
  final AppLocalizations loc;
  final shared.MenuItemProvider menuItemProvider;
  final String franchiseId;
  final String restaurantType;

  const MenuItemTemplatePickerDialog({
    super.key,
    required this.loc,
    required this.menuItemProvider,
    required this.franchiseId,
    required this.restaurantType,
  });

  static Future<void> show(
    BuildContext context, {
    String? restaurantTypeOverride,
  }) async {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      debugPrint('[MenuItemTemplatePickerDialog] ERROR: loc is null!');
      return;
    }

    // Resolve from the *caller* context (has providers), not dialog context.
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;
    final menuItemProvider =
        Provider.of<shared.MenuItemProvider>(context, listen: false);

    String? restaurantType = restaurantTypeOverride;
    if (restaurantType == null || restaurantType.isEmpty) {
      try {
        restaurantType = Provider.of<shared.FranchiseInfoProvider>(
          context,
          listen: false,
        ).franchise?.restaurantType;
      } catch (_) {}
    }
    // Your templates live under onboarding_templates/pizzeria
    restaurantType = (restaurantType == null || restaurantType.isEmpty)
        ? 'pizzeria'
        : restaurantType;

    await showDialog(
      context: context,
      builder: (ctx) => MenuItemTemplatePickerDialog(
        loc: loc,
        menuItemProvider: menuItemProvider,
        franchiseId: franchiseId,
        restaurantType: restaurantType!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (restaurantType.isEmpty) {
      shared.ErrorLogger.log(
        message: 'Missing or invalid restaurant type',
        source: 'MenuItemTemplatePickerDialog',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'restaurantType': restaurantType,
        },
      );
      return AlertDialog(
        title: Text(loc.error ?? 'Error'),
        content: Text(loc.errorGeneric ?? 'An error occurred'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel ?? 'Cancel'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(loc.loadDefaultTemplates ?? 'Load Default Templates'),
      content: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('onboarding_templates')
            .doc(restaurantType)
            .collection('menu_items')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Text(loc.errorGeneric ?? 'Failed to load templates');
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Text(loc.noTemplatesFound ?? 'No templates found');
          }

          return SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? doc.id;

                return ListTile(
                  title: Text(name),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      try {
                        // Schema: each doc under menu_items IS one MenuItem
                        // (not a pack with an "items" array).
                        final map = Map<String, dynamic>.from(data);
                        map['id'] = map['id'] ?? doc.id;

                        final item = shared.MenuItem.fromTemplate(
                          map,
                          idOverride: doc.id,
                        );
                        menuItemProvider.addOrUpdateMenuItem(item);

                        if (!context.mounted) return;
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Imported "${item.name.isNotEmpty ? item.name : doc.id}" from template',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e, stack) {
                        shared.ErrorLogger.log(
                          message: 'Failed to load menu item template',
                          source: 'MenuItemTemplatePickerDialog',
                          severity: 'error',
                          stack: stack.toString(),
                          contextData: {
                            'franchiseId': franchiseId,
                            'templateId': doc.id,
                            'error': e.toString(),
                          },
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Import failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryColor,
                    ),
                    child: Text(loc.import ?? 'Import'),
                  ),
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel ?? 'Cancel'),
        ),
      ],
    );
  }
}
