import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/core/providers/category_provider_impl.dart';

class CategoriesTemplatePickerDialog extends StatefulWidget {
  final AppLocalizations loc;

  const CategoriesTemplatePickerDialog({super.key, required this.loc});

  static Future<void> show(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = Provider.of<CategoryProviderImpl>(context, listen: false);

    return showDialog(
      context: context,
      builder: (dialogContext) =>
          ChangeNotifierProvider<CategoryProviderImpl>.value(
        value: provider,
        child: CategoriesTemplatePickerDialog(loc: loc),
      ),
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
    final loc = widget.loc;
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;

    print(
        '[CategoriesTemplatePickerDialog] _loadTemplate STARTED - templateId: $templateId, franchiseId: $franchiseId');

    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.selectAFranchiseFirst)),
        );
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final provider =
          Provider.of<CategoryProviderImpl>(context, listen: false);

      await provider.loadTemplate(templateId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.templateLoadedSuccessfully)),
        );
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      print('[CategoriesTemplatePickerDialog] _loadTemplate ERROR: $e');

      shared.ErrorLogger.log(
        message: 'Failed to load category template',
        stack: stack.toString(),
        source: 'CategoriesTemplatePickerDialog',
        severity: 'error',
        contextData: {'templateId': templateId, 'franchiseId': franchiseId},
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
    // ... (your existing build method is fine - no change needed)
    final loc = widget.loc;
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
                  enabled: false,
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

  // _buildTemplateTile remains exactly as you had it
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
      leading: Text(icon, style: const TextStyle(fontSize: 28)),
      title: Text(label,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      onTap: enabled ? () => _loadTemplate(id) : null,
    );
  }
}
