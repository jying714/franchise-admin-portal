import 'package:flutter/material.dart';

class AdminMenuItemActionsRow extends StatelessWidget {
  final bool canEdit;
  final bool canDeleteOrExport;
  final VoidCallback onEdit;
  final VoidCallback onCustomize;
  final VoidCallback onDelete;

  const AdminMenuItemActionsRow({
    Key? key,
    required this.canEdit,
    required this.canDeleteOrExport,
    required this.onEdit,
    required this.onCustomize,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Edit',
          onPressed: canEdit ? onEdit : null,
        ),
        IconButton(
          icon: const Icon(Icons.list_alt),
          tooltip: 'Customize',
          onPressed: canEdit ? onCustomize : null,
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: 'Delete',
          onPressed: canDeleteOrExport ? onDelete : null,
        ),
      ],
    );
  }
}


