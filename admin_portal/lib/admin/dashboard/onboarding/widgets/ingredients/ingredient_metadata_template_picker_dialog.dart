import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:admin_portal/core/providers/onboarding_progress_provider.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/core/models/ingredient_metadata.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientMetadataTemplatePickerDialog extends StatefulWidget {
  final AppLocalizations loc;

  const IngredientMetadataTemplatePickerDialog({super.key, required this.loc});

  static Future<List<IngredientMetadata>?> show(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      debugPrint(
          '[IngredientMetadataTemplatePickerDialog] ERROR: loc is null!');
      return Future.value();
    }

    return showDialog<List<IngredientMetadata>>(
      context: context,
      builder: (dialogContext) {
        return IngredientMetadataTemplatePickerDialog(loc: loc);
      },
    );
  }

  @override
  State<IngredientMetadataTemplatePickerDialog> createState() =>
      _IngredientMetadataTemplatePickerDialogState();
}

class _IngredientMetadataTemplatePickerDialogState
    extends State<IngredientMetadataTemplatePickerDialog> {
  bool _loading = false;

  Future<void> _loadTemplate(String templateId) async {
    final loc = widget.loc;
    final franchiseId = context.read<FranchiseProvider>().franchiseId;

    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.selectAFranchiseFirst)),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Fetch template data directly, DO NOT inject to provider here
      final snapshot = await FirebaseFirestore.instance
          .collection('onboarding_templates')
          .doc(templateId)
          .collection('ingredient_metadata')
          .get();

      final newItems = snapshot.docs
          .map((doc) => IngredientMetadata.fromMap(doc.data()))
          .toList();

      if (context.mounted) {
        Navigator.of(context).pop(newItems); // Return result!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.templateLoadedSuccessfully)),
        );
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'ingredient_metadata_template_load_failed',
        stack: stack.toString(),
        screen: 'onboarding_ingredients_screen',
        source: 'IngredientMetadataTemplatePickerDialog',
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
    try {
      final p = Provider.of<IngredientMetadataProvider>(context, listen: false);
      print(
          '[IngredientMetadataTemplatePickerDialog] build() provider hashCode=${p.hashCode}');
    } catch (e) {
      print('[IngredientMetadataTemplatePickerDialog] build() NO PROVIDER: $e');
    }
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
            loc.selectIngredientTemplate,
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
      title: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      onTap: enabled ? () => _loadTemplate(id) : null,
    );
  }

  @override
  void dispose() {
    print('[Ingredient metadata template picker dialog] DISPOSED');
    super.dispose();
  }
}
