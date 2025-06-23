import 'package:flutter/material.dart';

class AdminMenuEditorPopupMenu extends StatelessWidget {
  final bool showDeleted;
  final bool canDeleteOrExport;
  final VoidCallback onShowColumns;
  final VoidCallback onBulkUpload;
  final VoidCallback onToggleShowDeleted;
  final VoidCallback onExportCSV;
  final String columnsLabel;
  final String importCSVLabel;
  final String showDeletedLabel;
  final String exportCSVLabel;

  const AdminMenuEditorPopupMenu({
    Key? key,
    required this.showDeleted,
    required this.canDeleteOrExport,
    required this.onShowColumns,
    required this.onBulkUpload,
    required this.onToggleShowDeleted,
    required this.onExportCSV,
    required this.columnsLabel,
    required this.importCSVLabel,
    required this.showDeletedLabel,
    required this.exportCSVLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      constraints: const BoxConstraints(
        minWidth: 0,
        maxWidth: 180,
      ),
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 0) {
          onShowColumns();
        } else if (value == 1) {
          onBulkUpload();
        } else if (value == 2) {
          onToggleShowDeleted();
        } else if (value == 3) {
          if (!canDeleteOrExport) return;
          onExportCSV();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: 0,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.view_column, size: 18),
                const SizedBox(width: 8),
                Text(
                  columnsLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          enabled: canDeleteOrExport,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.upload_file, size: 18),
                const SizedBox(width: 8),
                Text(
                  importCSVLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Container(
            color: showDeleted ? Colors.blue.withOpacity(0.1) : null,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(
                    showDeletedLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: showDeleted
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        PopupMenuItem<int>(
          value: 3,
          enabled: canDeleteOrExport,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download, size: 18),
                const SizedBox(width: 8),
                Text(
                  exportCSVLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
