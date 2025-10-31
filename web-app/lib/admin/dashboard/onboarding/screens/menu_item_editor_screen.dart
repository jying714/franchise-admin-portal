import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/models/menu_item.dart';
import '../../../../../../packages/shared_core/lib/src/core/models/menu_item_schema_issue.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/franchise_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/franchise_info_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/ingredient_metadata_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/ingredient_type_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/providers/category_provider.dart';
import '../../../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/schema_issue_sidebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemEditorScreen extends StatefulWidget {
  final MenuItem? item;

  const MenuItemEditorScreen({Key? key, this.item}) : super(key: key);

  @override
  State<MenuItemEditorScreen> createState() => _MenuItemEditorScreenState();
}

class _MenuItemEditorScreenState extends State<MenuItemEditorScreen> {
  final GlobalKey<MenuItemEditorSheetState> _sheetKey =
      GlobalKey<MenuItemEditorSheetState>();

  List<MenuItemSchemaIssue> _schemaIssues = [];

  void _handleSchemaIssueUpdate(List<MenuItemSchemaIssue> updated) {
    print('[MenuItemEditorScreen] Schema issues updated:');
    for (final issue in updated) {
      print(' - ${issue.displayMessage} | resolved=${issue.resolved}');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _schemaIssues = updated;
          debugPrint(
              '[DEBUG] Schema issues updated: ${updated.length} issue(s)');
        });
      }
    });
  }

  void _handleRepair(MenuItemSchemaIssue issue, String newValue) {
    final sheet = _sheetKey.currentState;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(
          '[MenuItemEditorScreen] Repair requested for: ${issue.displayMessage}, newValue=$newValue');
      sheet?.repairSchemaIssue(issue, newValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSidebar = _schemaIssues.any((issue) => !issue.resolved);
    print('[MenuItemEditorScreen] Sidebar visibility: $showSidebar');

    final sidebarWidth = showSidebar ? 420.0 : 64.0;

    // USE ONLY global/singleton context providers. No local MultiProvider.
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: MenuItemEditorSheet(
            key: _sheetKey,
            existing: widget.item,
            onCancel: () => Navigator.of(context).pop(),
            onSave: (item) => Navigator.of(context).pop(item),
            onSchemaIssuesChanged: _handleSchemaIssueUpdate,
            firestore: FirebaseFirestore.instance,
            franchiseId: context.read<FranchiseProvider>().franchiseId,
          ),
        ),
        const VerticalDivider(width: 1),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: sidebarWidth,
          child: SchemaIssueSidebar(
            issues: _schemaIssues,
            onRepair: _handleRepair,
            onClose: () => setState(() => _schemaIssues.clear()),
          ),
        ),
      ],
    );
  }
}
