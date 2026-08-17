import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/admin/hq_owner/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
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

  @override
  Widget build(BuildContext context) {
    return MenuItemEditorSheet(
      key: _sheetKey,
      existing: widget.item,
      onCancel: () => Navigator.of(context).pop(),
      onSave: (item) => Navigator.of(context).pop(item),
      firestore: FirebaseFirestore.instance,
      franchiseId: Provider.of<shared.FranchiseProvider>(context, listen: false)
          .franchiseId,
    );
  }
}
