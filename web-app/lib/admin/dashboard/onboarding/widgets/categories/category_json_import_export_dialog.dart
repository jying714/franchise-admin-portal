import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import '../package:shared_core/src/core/services/firestore_service.dart';
import '../package:shared_core/src/core/utils/error_logger.dart';
import '../package:shared_core/src/core/providers/franchise_provider.dart';
import '../package:shared_core/src/core/providers/franchise_info_provider.dart';
import '../package:shared_core/src/core/providers/onboarding_progress_provider.dart';
import '../package:shared_core/src/core/models/category.dart';
import '../package:shared_core/src/core/utils/schema_templates.dart';
import '../package:shared_core/src/core/providers/category_provider.dart';

class CategoryJsonImportExportDialog extends StatefulWidget {
  final AppLocalizations loc;
  final BuildContext parentContext; // <-- add this line

  const CategoryJsonImportExportDialog({
    super.key,
    required this.loc,
    required this.parentContext, // <-- add this line
  });

  static Future<void> show(BuildContext parentContext) {
    final loc = AppLocalizations.of(parentContext)!;
    final categoryProvider =
        Provider.of<CategoryProvider>(parentContext, listen: false);
    final onboardingProvider =
        Provider.of<OnboardingProgressProvider>(parentContext, listen: false);

    return showDialog(
      context: parentContext,
      builder: (dialogContext) =>
          ChangeNotifierProvider<OnboardingProgressProvider>.value(
        value: onboardingProvider,
        child: ChangeNotifierProvider<CategoryProvider>.value(
          value: categoryProvider,
          child: CategoryJsonImportExportDialog(
            loc: loc,
            parentContext: parentContext,
          ),
        ),
      ),
    );
  }

  @override
  State<CategoryJsonImportExportDialog> createState() =>
      _CategoryJsonImportExportDialogState();
}

class _CategoryJsonImportExportDialogState
    extends State<CategoryJsonImportExportDialog> {
  late TextEditingController _controller;
  bool _isImporting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final template = pizzaShopCategoriesTemplate;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(template);
    _controller = TextEditingController(text: jsonStr);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _importCategories() async {
    final loc = widget.loc;
    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    final firestore = context.read<FirestoreService>();
    final onboardingProgress =
        context.read<OnboardingProgressProvider>().stepStatus;

    setState(() {
      _isImporting = true;
      _message = null;
    });

    try {
      final List<dynamic> decoded = json.decode(_controller.text);
      final categories = decoded.map((e) => Category.fromMap(e)).toList();

      for (final cat in categories) {
        await firestore.addCategory(
          franchiseId: franchiseId,
          category: cat,
        );
      }

      if (onboardingProgress['categories'] != true) {
        await context
            .read<OnboardingProgressProvider>()
            .markStepComplete('categories');
      }

      setState(() {
        _message = loc.importSuccess;
      });

      // --- Success SnackBar (optional) ---
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text(loc.importSuccess)),
        );
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'category_json_import_error',
        source: 'CategoryJsonImportExportDialog',
        screen: 'onboarding_categories_screen',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'raw': _controller.text},
      );

      setState(() {
        _message = loc.importError;
      });

      // --- Error SnackBar ---
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text(loc.importError)),
        );
      }
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(loc.importExportCategories),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.importExportInstruction),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 14,
              minLines: 10,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: loc.jsonData,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(
                  color: _message == loc.importSuccess
                      ? Colors.green
                      : colorScheme.error,
                ),
              )
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primaryColor,
            foregroundColor: DesignTokens.foregroundColor,
          ),
          icon: _isImporting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          onPressed: _isImporting ? null : _importCategories,
          label: Text(loc.import),
        ),
      ],
    );
  }
}


