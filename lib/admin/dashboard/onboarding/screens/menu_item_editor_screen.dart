import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/models/menu_item_schema_issue.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider.dart';
import 'package:franchise_admin_portal/core/providers/category_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
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

    // Don't use a Scaffold. Just the content body:
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IngredientTypeProvider()),
        ChangeNotifierProxyProvider2<FirestoreService, FranchiseProvider,
            CategoryProvider>(
          create: (_) => CategoryProvider(
            firestore: Provider.of<FirestoreService>(_, listen: false),
            franchiseId: '',
          ),
          update: (_, firestore, franchiseProvider, previous) {
            final fid = franchiseProvider.franchiseId;
            final provider = previous ??
                CategoryProvider(firestore: firestore, franchiseId: fid);

            // Only call .loadCategories() if the franchiseId changed
            if (fid.isNotEmpty && fid != provider.franchiseId) {
              provider.franchiseId = fid; // Update the id, but don't load yet!
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.loadCategories();
              });
            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<FirestoreService, FranchiseInfoProvider,
                IngredientMetadataProvider>(
            create: (_) => IngredientMetadataProvider(
                  firestoreService:
                      Provider.of<FirestoreService>(_, listen: false),
                  franchiseId: '',
                ),
            update: (_, firestore, franchiseInfo, previous) {
              final fid = franchiseInfo.franchise?.id ?? '';
              final provider = previous ??
                  IngredientMetadataProvider(
                    firestoreService: firestore,
                    franchiseId: fid,
                  );
              if (fid.isNotEmpty && fid != provider.franchiseId) {
                final newProvider = IngredientMetadataProvider(
                  firestoreService: firestore,
                  franchiseId: fid,
                );
                // Defer the load to next frame to avoid Provider build cycle error
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  newProvider.load();
                });
                return newProvider;
              }
              return provider;
            }),
      ],
      child: Row(
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
      ),
    );
  }
}
