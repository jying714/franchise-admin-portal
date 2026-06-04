import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // Phase 3 scoped fix
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class MenuItemTemplateDropdown extends StatefulWidget {
  final void Function(shared.MenuItem template) onTemplateApplied;
  final String? selectedTemplateId;

  const MenuItemTemplateDropdown({
    super.key,
    required this.onTemplateApplied,
    this.selectedTemplateId,
  });

  @override
  State<MenuItemTemplateDropdown> createState() =>
      _MenuItemTemplateDropdownState();
}

class _MenuItemTemplateDropdownState extends State<MenuItemTemplateDropdown> {
  String? _selectedTemplateId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTemplateId = widget.selectedTemplateId;

    // Preload templateRefs if needed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider =
          Provider.of<shared.MenuItemProvider>(context, listen: false);
      if (provider.templateRefs.isEmpty && !provider.templateRefsLoading) {
        await provider.loadTemplateRefs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final templateRefs = context.watch<shared.MenuItemProvider>().templateRefs;
    final loading =
        context.watch<shared.MenuItemProvider>().templateRefsLoading;

    print('[DEBUG] selectedTemplateId: $_selectedTemplateId');
    // print(
    //     '[DEBUG] Available templateRefs: ${templateRefs.map((t) => t.id).toList()}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: templateRefs.any((t) => t.id == _selectedTemplateId)
              ? _selectedTemplateId
              : null,
          isExpanded: true,
          hint: Text(loc.chooseTemplate),
          decoration: InputDecoration(
            labelText: loc.template,
          ),
          items: templateRefs
              .map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name),
                  ))
              .toList(),
          onChanged: (templateId) async {
            setState(() {
              _selectedTemplateId = templateId;
              _isLoading = true;
            });

            try {
              final restaurantType = Provider.of<shared.FranchiseInfoProvider>(
                      context,
                      listen: false)
                  .franchise
                  ?.restaurantType;

              if (restaurantType == null || restaurantType.isEmpty) {
                shared.ErrorLogger.log(
                  message:
                      'Missing or invalid restaurantType during template prefill',
                  source: 'MenuItemTemplateDropdown',
                  severity: 'error',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.errorGeneric)),
                  );
                }
                return;
              }

              final template = await ReadContext(context)
                  .read<shared.MenuItemProvider>()
                  .fetchMenuItemTemplateById(
                    restaurantType: restaurantType,
                    templateId: templateId!,
                  );

              if (template != null && mounted) {
                widget.onTemplateApplied(template);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.errorGeneric)),
                );
              }
            } catch (e, stack) {
              shared.ErrorLogger.log(
                message: 'Failed to apply template',
                stack: stack.toString(),
                source: 'MenuItemTemplateDropdown',
                severity: 'error',
                contextData: {'templateId': templateId},
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.errorGeneric)),
                );
              }
            } finally {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          },
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}
