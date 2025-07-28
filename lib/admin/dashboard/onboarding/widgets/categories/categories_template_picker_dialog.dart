import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/category_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class CategoriesTemplatePickerDialog extends StatefulWidget {
  const CategoriesTemplatePickerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const CategoriesTemplatePickerDialog(),
    );
  }

  @override
  State<CategoriesTemplatePickerDialog> createState() =>
      _CategoriesTemplatePickerDialogState();
}

class _CategoriesTemplatePickerDialogState
    extends State<CategoriesTemplatePickerDialog> {
  bool _loading = false;

  Future<void> _loadTemplate(String templateId) async {
    final loc = AppLocalizations.of(context)!;
    final provider = context.read<CategoryProvider>();
    final franchiseId = context.read<FranchiseProvider>().franchiseId;

    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.selectAFranchiseFirst)),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await provider.loadTemplate(templateId);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.templateLoadedSuccessfully)),
        );
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'category_template_load_failed',
        stack: stack.toString(),
        screen: 'onboarding_categories_screen',
        source: 'CategoriesTemplatePickerDialog',
        severity: 'error',
        contextData: {
          'templateId': templateId,
          'franchiseId': franchiseId,
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: DesignTokens.surfaceColor,
      titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      title: Row(
        children: [
          Icon(Icons.library_add, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            loc.selectCategoryTemplate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTemplateTile(
                  id: 'pizzeria',
                  icon: '🍕',
                  label: loc.pizzaShopTemplateLabel,
                  subtitle: loc.pizzaShopTemplateSubtitle,
                ),
                const SizedBox(height: 12),
                _buildTemplateTile(
                  id: 'wing_bar',
                  icon: '🍗',
                  label: loc.wingBarTemplateLabel,
                  subtitle: loc.wingBarTemplateSubtitle,
                  enabled: false, // Reserved for future
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
      ],
    );
  }

  Widget _buildTemplateTile({
    required String id,
    required String icon,
    required String label,
    required String subtitle,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      enabled: enabled,
      tileColor: enabled
          ? colorScheme.surfaceVariant.withOpacity(0.2)
          : Colors.grey.withOpacity(0.1),
      leading: Text(
        icon,
        style: const TextStyle(fontSize: 28),
      ),
      title: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      onTap: enabled ? () => _loadTemplate(id) : null,
    );
  }
}
