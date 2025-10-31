import 'package:flutter/material.dart';
import '../../../../packages/shared_core/lib/src/core/models/franchise_info.dart';

class FranchiseSelector extends StatelessWidget {
  final List<FranchiseInfo> items;
  final String? selectedFranchiseId;
  final void Function(String franchiseId) onSelected;

  const FranchiseSelector({
    super.key,
    required this.items,
    required this.selectedFranchiseId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, idx) {
        final f = items[idx];
        final isSelected = f.id == selectedFranchiseId;

        return ListTile(
          leading: f.logoUrl != null
              ? CircleAvatar(backgroundImage: NetworkImage(f.logoUrl!))
              : const CircleAvatar(child: Icon(Icons.storefront)),
          title: Text(f.name),
          subtitle: Text(f.id),
          onTap: () {
            print('[FranchiseSelector] Franchise tapped: ${f.id}');
            this.onSelected(f.id);
          },
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.chevron_right),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
