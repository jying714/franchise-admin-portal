import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' hide DesignTokens;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// HQ floor-plan editor. Reads/writes franchises/{id}/config/table_layout.
class TableLayoutEditorScreen extends StatefulWidget {
  const TableLayoutEditorScreen({super.key});

  @override
  State<TableLayoutEditorScreen> createState() =>
      _TableLayoutEditorScreenState();
}

class _TableLayoutEditorScreenState extends State<TableLayoutEditorScreen> {
  final _posFs = PosFirestoreService();
  final _transformController = TransformationController();

  PosTableLayout? _layout;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _selectedId;

  String get _franchiseId {
    final id =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    return (id.isEmpty || id == 'unknown') ? '' : id;
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final franchiseId = _franchiseId;
    if (franchiseId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No franchise selected';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final layout = await _posFs.getTableLayout(franchiseId);
      if (!mounted) return;
      setState(() {
        _layout = layout;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load layout';
      });
    }
  }

  bool _hasUncustomizedTables(PosTableLayout layout) {
    for (final t in layout.tables) {
      final label = t.label.trim();
      if (label.isEmpty) return true;
      if (t.id.startsWith('new_')) return true;
    }
    return false;
  }

  Future<void> _save() async {
    final layout = _layout;
    final franchiseId = _franchiseId;
    if (layout == null || franchiseId.isEmpty || _saving) return;

    if (_hasUncustomizedTables(layout)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Customize every new table (label required) before saving',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Merge live occupancy from server so Save does not free seated tables.
      final live = await _posFs.getTableLayout(franchiseId);
      final liveStatus = <String, String>{
        for (final t in live.tables) t.id: t.status,
      };
      final mergedTables = layout.tables.map((t) {
        final status = liveStatus[t.id];
        if (status == null) return t; // brand-new table → keep editor status
        return t.copyWith(status: status);
      }).toList();

      await _posFs.saveTableLayout(
        layout.copyWith(
          franchiseId: franchiseId,
          tables: mergedTables,
          updatedAt: DateTime.now(),
          version: layout.version + 1,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Floor plan saved')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _idFromLabel(String label) {
    var id = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (id.isEmpty) {
      id = 'table_${DateTime.now().millisecondsSinceEpoch % 100000}';
    }
    final layout = _layout;
    if (layout == null) return id;
    return id;
  }

  void _addTable({required String shape}) {
    final layout = _layout;
    if (layout == null) return;
    final n = layout.tables.length + 1;
    final tempId = 'new_${DateTime.now().millisecondsSinceEpoch}';
    final node = PosTableNode(
      id: tempId,
      label: '', // blank until customized
      x: 40.0 + (n * 20) % 200,
      y: 40.0 + (n * 20) % 160,
      width: shape == 'round' ? 72 : 80,
      height: shape == 'round' ? 72 : 80,
      seats: 4,
      status: 'free',
      shape: shape,
    );
    setState(() {
      _layout = layout.copyWith(tables: [...layout.tables, node]);
      _selectedId = tempId;
    });
  }

  Future<void> _openCustomize(PosTableNode table) async {
    final labelCtrl = TextEditingController(text: table.label);
    final seatsCtrl = TextEditingController(text: '${table.seats}');
    var shape = table.shape;
    final result = await showDialog<PosTableNode>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Customize table'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        hintText: 'e.g. T1 or Patio 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: seatsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Seats',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'rect', label: Text('Rect')),
                        ButtonSegment(value: 'round', label: Text('Round')),
                      ],
                      selected: {shape},
                      onSelectionChanged: (s) =>
                          setLocal(() => shape = s.first),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID will be derived from label (spaces → underscores).',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final label = labelCtrl.text.trim();
                    if (label.isEmpty) return;
                    final seats =
                        int.tryParse(seatsCtrl.text.trim()) ?? table.seats;
                    final newId = _idFromLabel(label);

                    final others = _layout?.tables
                            .where((t) => t.id != table.id)
                            .toList() ??
                        const <PosTableNode>[];

                    final labelTaken = others.any(
                      (t) =>
                          t.label.trim().toLowerCase() == label.toLowerCase(),
                    );
                    final idTaken = others.any((t) => t.id == newId);

                    if (labelTaken || idTaken) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Label or ID already used by another table',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      ctx,
                      table.copyWith(
                        id: newId,
                        label: label,
                        seats: seats < 1 ? 1 : seats,
                        shape: shape,
                        width: shape == 'round' ? 72 : 80,
                        height: shape == 'round' ? 72 : 80,
                      ),
                    );
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
    labelCtrl.dispose();
    seatsCtrl.dispose();
    if (result == null || _layout == null) return;

    setState(() {
      _layout = _layout!.copyWith(
        tables: _layout!.tables.map((t) {
          if (t.id != table.id) return t;
          return result;
        }).toList(),
      );
      _selectedId = result.id;
    });
  }

  void _deleteSelected() {
    final layout = _layout;
    final id = _selectedId;
    if (layout == null || id == null) return;

    PosTableNode? table;
    for (final t in layout.tables) {
      if (t.id == id) {
        table = t;
        break;
      }
    }
    if (table == null) return;

    if (table.status.trim().toLowerCase() != 'free') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete ${table.label.isNotEmpty ? table.label : table.id} while seated/occupied',
          ),
        ),
      );
      return;
    }

    setState(() {
      _layout = layout.copyWith(
        tables: layout.tables.where((t) => t.id != id).toList(),
      );
      _selectedId = null;
    });
  }

  void _moveSelected(double dx, double dy) {
    final layout = _layout;
    final id = _selectedId;
    if (layout == null || id == null) return;
    setState(() {
      _layout = layout.copyWith(
        tables: layout.tables.map((t) {
          if (t.id != id) return t;
          final nx = (t.x + dx).clamp(0, layout.canvasWidth - t.width);
          final ny = (t.y + dy).clamp(0, layout.canvasHeight - t.height);
          return t.copyWith(x: nx.toDouble(), y: ny.toDouble());
        }).toList(),
      );
    });
  }

  void _onTablePan(String id, DragUpdateDetails details) {
    final layout = _layout;
    if (layout == null) return;
    setState(() {
      _selectedId = id;
      _layout = layout.copyWith(
        tables: layout.tables.map((t) {
          if (t.id != id) return t;
          final nx =
              (t.x + details.delta.dx).clamp(0, layout.canvasWidth - t.width);
          final ny =
              (t.y + details.delta.dy).clamp(0, layout.canvasHeight - t.height);
          return t.copyWith(x: nx.toDouble(), y: ny.toDouble());
        }).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final layout = _layout;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Floor plan'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed:
                  _saving || _layout == null || _hasUncustomizedTables(_layout!)
                      ? null
                      : _save,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!, style: TextStyle(color: scheme.error)),
                )
              : layout == null
                  ? const Center(child: Text('No layout'))
                  : Row(
                      children: [
                        SizedBox(
                          width: 220,
                          child: Material(
                            color: scheme.surfaceContainerHighest,
                            child: ListView(
                              padding: const EdgeInsets.all(12),
                              children: [
                                Text(
                                  'Tools',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: () => _addTable(shape: 'rect'),
                                  icon: const Icon(Icons.crop_square),
                                  label: const Text('Add rect'),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: () => _addTable(shape: 'round'),
                                  icon: const Icon(Icons.circle_outlined),
                                  label: const Text('Add round'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _selectedId == null
                                      ? null
                                      : _deleteSelected,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete selected'),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: _saving ||
                                          _layout == null ||
                                          _hasUncustomizedTables(_layout!)
                                      ? null
                                      : _save,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label:
                                      Text(_saving ? 'Saving…' : 'Save plan'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _resetZoom,
                                  icon: const Icon(Icons.zoom_out_map),
                                  label: const Text('Reset zoom'),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nudge selected',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    IconButton(
                                      onPressed: _selectedId == null
                                          ? null
                                          : () => _moveSelected(0, -10),
                                      icon: const Icon(Icons.arrow_upward),
                                    ),
                                    IconButton(
                                      onPressed: _selectedId == null
                                          ? null
                                          : () => _moveSelected(0, 10),
                                      icon: const Icon(Icons.arrow_downward),
                                    ),
                                    IconButton(
                                      onPressed: _selectedId == null
                                          ? null
                                          : () => _moveSelected(-10, 0),
                                      icon: const Icon(Icons.arrow_back),
                                    ),
                                    IconButton(
                                      onPressed: _selectedId == null
                                          ? null
                                          : () => _moveSelected(10, 0),
                                      icon: const Icon(Icons.arrow_forward),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${layout.tables.length} tables · '
                                  '${layout.canvasWidth.toInt()}×${layout.canvasHeight.toInt()}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        VerticalDivider(width: 1, color: scheme.outlineVariant),
                        Expanded(
                          child: InteractiveViewer(
                            transformationController: _transformController,
                            minScale: 0.2,
                            maxScale: 4.0,
                            constrained: false,
                            boundaryMargin: const EdgeInsets.all(300),
                            panEnabled: true,
                            scaleEnabled: true,
                            child: SizedBox(
                              width: layout.canvasWidth,
                              height: layout.canvasHeight,
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    size: Size(
                                      layout.canvasWidth,
                                      layout.canvasHeight,
                                    ),
                                    painter: _EditorGridPainter(
                                      lineColor: scheme.outlineVariant
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                  ...layout.tables.map((t) {
                                    final selected = t.id == _selectedId;
                                    final free =
                                        t.status.trim().toLowerCase() == 'free';
                                    final fill = free
                                        ? Colors.green.shade600
                                        : Colors.red.shade600;
                                    return Positioned(
                                      left: t.x,
                                      top: t.y,
                                      width: t.width,
                                      height: t.height,
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (_selectedId == t.id) {
                                            await _openCustomize(t);
                                          } else {
                                            setState(() => _selectedId = t.id);
                                          }
                                        },
                                        onPanUpdate: (d) =>
                                            _onTablePan(t.id, d),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: fill,
                                            shape: t.shape == 'round'
                                                ? BoxShape.circle
                                                : BoxShape.rectangle,
                                            borderRadius: t.shape == 'round'
                                                ? null
                                                : BorderRadius.circular(8),
                                            border: Border.all(
                                              color: selected
                                                  ? DesignTokens.primaryColor
                                                  : Colors.white70,
                                              width: selected ? 3 : 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Text(
                                                t.label.trim().isNotEmpty
                                                    ? t.label
                                                    : 'Click to customize',
                                                textAlign: TextAlign.center,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize:
                                                      t.label.trim().isEmpty
                                                          ? 10
                                                          : 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _EditorGridPainter extends CustomPainter {
  final Color lineColor;

  _EditorGridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EditorGridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
