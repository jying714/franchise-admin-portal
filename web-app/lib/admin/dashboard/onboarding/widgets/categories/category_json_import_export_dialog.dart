import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/category_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider_impl.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/shared_core.dart' as shared;

class CategoryJsonImportExportDialog extends StatefulWidget {
  final AppLocalizations loc;

  const CategoryJsonImportExportDialog({
    super.key,
    required this.loc,
  });

  static Future<void> show(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final categoryProvider =
        Provider.of<shared.CategoryProvider>(context, listen: false);
    final onboardingProvider =
        Provider.of<shared.OnboardingProgressProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (dialogContext) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CategoryProviderImpl>.value(
              value: categoryProvider as CategoryProviderImpl),
          ChangeNotifierProvider<OnboardingProgressProviderImpl>.value(
              value: onboardingProvider as OnboardingProgressProviderImpl),
        ],
        child: CategoryJsonImportExportDialog(loc: loc),
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
    final template = shared.pizzaShopCategoriesTemplate;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(template);
    _controller = TextEditingController(text: jsonStr);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _importCategories() async {
    setState(() {
      _isImporting = true;
      _message = null;
    });

    try {
      final List<dynamic> decoded = json.decode(_controller.text);
      final categories = decoded
          .map((e) => shared.Category.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      final franchiseId =
          Provider.of<shared.FranchiseProvider>(context, listen: false)
              .franchiseId;

      final categoryProvider =
          Provider.of<CategoryProviderImpl>(context, listen: false);

      for (final cat in categories) {
        categoryProvider.addOrUpdateCategory(cat); // staged or direct
      }

      await Provider.of<shared.OnboardingProgressProvider>(context,
              listen: false)
          .markStepComplete('categories');

      setState(() {
        _message = widget.loc.importSuccess;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.loc.importSuccess)),
        );
      }
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'category_json_import_error',
        stack: stack.toString(),
        source: 'CategoryJsonImportExportDialog',
        severity: 'error',
      );

      setState(() {
        _message = widget.loc.importError;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.loc.importError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
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
