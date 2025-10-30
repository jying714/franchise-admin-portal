import 'package:flutter/material.dart';

class AdminBulkSelectionToolbar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onClearSelection;
  final String deleteLabel;
  final String clearSelectionTooltip;
  final String selectedLabel;

  const AdminBulkSelectionToolbar({
    Key? key,
    required this.selectedCount,
    required this.onDelete,
    required this.onClearSelection,
    required this.deleteLabel,
    required this.clearSelectionTooltip,
    required this.selectedLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(
            selectedLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: Text(deleteLabel),
            onPressed: onDelete,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: clearSelectionTooltip,
            onPressed: onClearSelection,
          ),
        ],
      ),
    );
  }
}
