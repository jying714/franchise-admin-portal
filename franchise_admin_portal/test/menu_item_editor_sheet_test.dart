import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider.dart';
import 'package:franchise_admin_portal/core/providers/menu_item_provider.dart';
import 'package:franchise_admin_portal/core/providers/category_provider.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/widgets/menu_items/menu_item_editor_sheet.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:mockito/mockito.dart'; // or build a Fake below

// Simple fake/mock for FirestoreService
class FakeFirestoreService extends Fake implements FirestoreService {}

void main() {
  group('MenuItemEditorSheet', () {
    Widget buildTestWidget({void Function()? onSaveCallback}) {
      final fakeFirestoreService = FakeFirestoreService();
      const fakeFranchiseId = 'test_franchise_id';

      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => IngredientMetadataProvider(
              firestoreService: fakeFirestoreService,
              franchiseId: fakeFranchiseId,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => MenuItemProvider(
              firestoreService: fakeFirestoreService,
              franchiseId: fakeFranchiseId,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => CategoryProvider(
              firestoreService: fakeFirestoreService,
              franchiseId: fakeFranchiseId,
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MenuItemEditorSheet(
              onSave: (_) {
                if (onSaveCallback != null) onSaveCallback();
              },
              onCancel: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders all core fields and buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.textContaining('Menu Item'), findsWidgets);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows error when required fields are empty',
        (WidgetTester tester) async {
      bool saveTriggered = false;

      await tester.pumpWidget(buildTestWidget(onSaveCallback: () {
        saveTriggered = true;
      }));

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveTriggered, isFalse);
      expect(find.textContaining('required'), findsWidgets);
    });

    testWidgets('updates live preview when name is entered',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(find.byType(TextFormField).first, 'Preview Test');
      await tester.pump();

      expect(find.text('Preview Test'), findsWidgets);
    });
  });
}
