import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

/// Result of seating: table id + label for the open ticket.
class TablePickResult {
  final String tableId;
  final String tableLabel;
  final int seats;

  const TablePickResult({
    required this.tableId,
    required this.tableLabel,
    required this.seats,
  });
}

/// Lists free tables from franchise [PosTableLayout].
class TablePickSheet extends StatefulWidget {
  final String franchiseId;

  const TablePickSheet({super.key, required this.franchiseId});

  static Future<TablePickResult?> show(
    BuildContext context, {
    required String franchiseId,
  }) {
    return showDialog<TablePickResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TablePickSheet(franchiseId: franchiseId),
    );
  }

  @override
  State<TablePickSheet> createState() => _TablePickSheetState();
}

class _TablePickSheetState extends State<TablePickSheet> {
  final _posFs = PosFirestoreService();
  PosTableLayout? _layout;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final layout = await _posFs.getTableLayout(widget.franchiseId);
      if (!mounted) return;
      setState(() {
        _layout = layout;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load table layout';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tables = _layout?.tables ?? const <PosTableNode>[];
    final free = tables
        .where((t) => t.status.trim().toLowerCase() == 'free')
        .toList();

    return AlertDialog(
      title: const Text('Seat table'),
      content: SizedBox(
        width: 400,
        height: 360,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              )
            : tables.isEmpty
            ? Center(
                child: Text(
                  'No tables configured.\n'
                  'Add a layout under franchises/'
                  '${widget.franchiseId}/config/table_layout',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            : free.isEmpty
            ? Center(
                child: Text(
                  'No free tables',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            : ListView.builder(
                itemCount: free.length,
                itemBuilder: (context, index) {
                  final t = free[index];
                  return ListTile(
                    leading: Icon(
                      t.shape == 'round'
                          ? Icons.circle_outlined
                          : Icons.crop_square,
                      color: scheme.primary,
                    ),
                    title: Text(t.label.isNotEmpty ? t.label : t.id),
                    subtitle: Text('${t.seats} seats'),
                    onTap: () {
                      Navigator.of(context).pop(
                        TablePickResult(
                          tableId: t.id,
                          tableLabel: t.label.isNotEmpty ? t.label : t.id,
                          seats: t.seats,
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
