import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared; // Phase 3 scoped fix

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
    final franchiseId = context.read<shared.FranchiseProvider>().franchiseId;
    final franchiseInfo = context.read<FranchiseInfoProvider>().franchise;
    final menuItemProvider = context.read<MenuItemProvider>();

    final restaurantType = franchiseInfo?.restaurantType;

    if (restaurantType == null || restaurantType.isEmpty) {
      shared.ErrorLogger.log(
        message: 'Missing or invalid restaurant type',
        source: 'MenuItemTemplatePickerDialog',
        source: 'onboarding_menu_items_screen.dart' /* was screen, Phase 4 fix */,
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'restaurantType': restaurantType,
        },
      );
      return AlertDialog(
        title: Text(loc.error),
        content: Text(loc.errorGeneric),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(loc.loadDefaultTemplates),
      content: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('onboarding_templates')
            .doc(restaurantType)
            .collection('menu_items')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Text(loc.errorGeneric);
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Text(loc.noTemplatesFound);
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
                            .map((e) => MenuItem.fromMap(
                                  Map<String, dynamic>.from(e),
                                ))
                            .toList();

                        for (final item in items) {
                          menuItemProvider.addOrUpdateMenuItem(item);
                        }

                        Navigator.pop(context);
                      } catch (e, stack) {
                        await shared.ErrorLogger.log(
                          message: 'Failed to load menu item template',
                          source: 'MenuItemTemplatePickerDialog',
                          source: 'onboarding_menu_items_screen.dart' /* was screen, Phase 4 fix */,
                          severity: 'error',
                          stack: stack.toString(),
                          contextData: {
                            'franchiseId': franchiseId,
                            'templateId': doc.id,
                          },
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.errorGeneric)),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryColor,
                    ),
                    child: Text(loc.import),
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
          child: Text(loc.cancel),
        ),
      ],
    );
  }
}




