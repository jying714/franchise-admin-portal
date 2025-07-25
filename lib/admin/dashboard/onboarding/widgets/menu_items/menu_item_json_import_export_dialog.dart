import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/providers/menu_item_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class MenuItemJsonImportExportDialog {
  static Future<void> show(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final menuItemProvider = context.read<MenuItemProvider>();
    final franchiseId = context.read<FranchiseProvider>().franchiseId;

    final controller = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(
        menuItemProvider.menuItems.map((e) => e.toMap()).toList(),
      ),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        backgroundColor: colorScheme.surface,
        title: Text(loc.importExportJson),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.pasteOrEditJson,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 500,
              child: TextField(
                controller: controller,
                maxLines: 18,
                minLines: 12,
                keyboardType: TextInputType.multiline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                final parsed = jsonDecode(controller.text);
                if (parsed is! List)
                  throw Exception('Invalid JSON: Not a List');
                final items = parsed.map<MenuItem>((e) {
                  return MenuItem.fromMap(Map<String, dynamic>.from(e));
                }).toList();

                await menuItemProvider.loadMenuItems(franchiseId);
                for (final item in items) {
                  menuItemProvider.addOrUpdateMenuItem(item);
                }

                Navigator.pop(context);
              } catch (e, stack) {
                await ErrorLogger.log(
                  message: 'Invalid JSON in MenuItemJsonImportExportDialog',
                  source: 'MenuItemJsonImportExportDialog',
                  screen: 'onboarding_menu_items_screen.dart',
                  severity: 'warning',
                  stack: stack.toString(),
                  contextData: {
                    'franchiseId': franchiseId,
                    'jsonPreview': controller.text
                        .substring(0, controller.text.length.clamp(0, 200)),
                  },
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.invalidJsonFormat)),
                  );
                }
              }
            },
            child: Text(loc.import),
          )
        ],
      ),
    );
  }
}
