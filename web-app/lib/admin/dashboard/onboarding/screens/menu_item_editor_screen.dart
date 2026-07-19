import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/schema_issue_sidebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemEditorScreen extends StatefulWidget {
  final shared.MenuItem? item;

  const MenuItemEditorScreen({Key? key, this.item}) : super(key: key);

  @override
  State<MenuItemEditorScreen> createState() => _MenuItemEditorScreenState();
}

class _MenuItemEditorScreenState extends State<MenuItemEditorScreen> {
  final GlobalKey<MenuItemEditorSheetState> _sheetKey =
      GlobalKey<MenuItemEditorSheetState>();

  List<shared.MenuItemSchemaIssue> _schemaIssues = [];

  void _handleSchemaIssueUpdate(List<shared.MenuItemSchemaIssue> updated) {
    if (mounted) {
      setState(() {
        _schemaIssues = updated;
      });
    }
  }

  void _handleRepair(shared.MenuItemSchemaIssue issue, String newValue) {
    _sheetKey.currentState?.repairSchemaIssue(issue, newValue);
  }

  @override
  Widget build(BuildContext context) {
    final showSidebar = _schemaIssues.any((issue) => !issue.resolved);
    // print('[MenuItemEditorScreen] Sidebar visibility: $showSidebar');

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
            firestore: FirebaseFirestore.instance,
            franchiseId:
                Provider.of<shared.FranchiseProvider>(context, listen: false)
                    .franchiseId,
          ),
        ),
        const VerticalDivider(width: 1),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: sidebarWidth,
          child: SchemaIssueSidebar(
            issues: _schemaIssues,
            franchiseId:
                Provider.of<shared.FranchiseProvider>(context, listen: false)
                    .franchiseId,
            onRepair: _handleRepair,
            onFullRefresh: () {
              _sheetKey.currentState?.repairSchemaIssue(
                const shared.MenuItemSchemaIssue(
                  type: shared.MenuItemSchemaIssueType.missingField,
                  missingReference: '',
                  field: 'refresh',
                ),
                '',
              );
            },
            onNormalizeAll: () {
              Provider.of<shared.MenuItemProvider>(context, listen: false)
                  .normalizeSchemaReferences();
              _sheetKey.currentState?.repairSchemaIssue(
                const shared.MenuItemSchemaIssue(
                  type: shared.MenuItemSchemaIssueType.missingField,
                  missingReference: '',
                  field: 'refresh',
                ),
                '',
              );
            },
          ),
        ),
      ],
    );
  }
}
