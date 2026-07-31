import 'package:shared_core/shared_core.dart';

/// Updates one table's status on franchises/{id}/config/table_layout.
Future<void> setTableStatus({
  required String franchiseId,
  required String tableId,
  required String status,
}) async {
  if (tableId.isEmpty) return;
  final posFs = PosFirestoreService();
  final layout = await posFs.getTableLayout(franchiseId);
  final tables = layout.tables.map((t) {
    if (t.id != tableId) return t;
    return t.copyWith(status: status);
  }).toList();
  await posFs.saveTableLayout(
    layout.copyWith(tables: tables, updatedAt: DateTime.now()),
  );
}
