import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;

class MenuItemTemplatePickerDialog extends StatelessWidget {
  final AppLocalizations loc;

  const MenuItemTemplatePickerDialog({super.key, required this.loc});

  static Future<void> show(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      debugPrint('[MenuItemTemplatePickerDialog] ERROR: loc is null!');
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => MenuItemTemplatePickerDialog(loc: loc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;
    final menuItemProvider =
        Provider.of<shared.MenuItemProvider>(context, listen: false);

    // HQ shell may not provide FranchiseInfoProvider — resolve safely.
    String? restaurantType;
    try {
      restaurantType = Provider.of<shared.FranchiseInfoProvider>(
        context,
        listen: false,
      ).franchise?.restaurantType;
    } catch (_) {
      restaurantType = null;
    }

    // Fallback: common field on FranchiseProvider if exposed in your tree.
    if (restaurantType == null || restaurantType.isEmpty) {
      try {
        final fp =
            Provider.of<shared.FranchiseProvider>(context, listen: false);
        // ignore: avoid_dynamic_calls
        final dynamic maybe = fp;
        restaurantType = maybe.restaurantType as String? ??
            maybe.currentRestaurantType as String?;
      } catch (_) {}
    }

    if (restaurantType == null || restaurantType.isEmpty) {
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
                        final items = (data['items'] as List<dynamic>)
                            .map((e) => shared.MenuItem.fromMap(
                                  Map<String, dynamic>.from(e),
                                ))
                            .toList();

                        for (final item in items) {
                          menuItemProvider.addOrUpdateMenuItem(item);
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Templates imported successfully')),
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
                          },
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(loc.errorGeneric ?? 'Import failed')),
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
