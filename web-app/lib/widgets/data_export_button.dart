import 'package:flutter/material.dart';

/// Button to trigger data export (CSV/PDF).
/// Accepts export type(s), callback, and optional icon.
enum ExportType { csv, pdf, xlsx }

class DataExportButton extends StatelessWidget {
  final void Function(ExportType) onExport;
  final List<ExportType> exportTypes;
  final String? label;

  const DataExportButton({
    Key? key,
    required this.onExport,
    this.exportTypes = const [ExportType.csv],
    this.label,
  }) : super(key: key);

  String _typeLabel(ExportType type) {
    switch (type) {
      case ExportType.csv:
        return 'CSV';
      case ExportType.pdf:
        return 'PDF';
      case ExportType.xlsx:
        return 'Excel';
    }
  }

  IconData _typeIcon(ExportType type) {
    switch (type) {
      case ExportType.csv:
        return Icons.table_view;
      case ExportType.pdf:
        return Icons.picture_as_pdf;
      case ExportType.xlsx:
        return Icons.grid_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (exportTypes.length == 1) {
      final type = exportTypes.first;
      return ElevatedButton.icon(
        onPressed: () => onExport(type),
        icon: Icon(_typeIcon(type)),
        label: Text(label ?? 'Export ${_typeLabel(type)}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      return PopupMenuButton<ExportType>(
        icon: const Icon(Icons.file_download),
        tooltip: 'Export data',
        itemBuilder: (context) => exportTypes
            .map((type) => PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_typeIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Text(_typeLabel(type)),
                    ],
                  ),
                ))
            .toList(),
        onSelected: onExport,
      );
    }
  }
}


