import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategorySearchBar extends StatelessWidget {
  final void Function(String) onChanged;
  final void Function(String?)? onSortChanged;
  final String? currentSort;

  const CategorySearchBar({
    super.key,
    required this.onChanged,
    this.onSortChanged,
    this.currentSort,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: loc.searchCategories,
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: currentSort ?? loc.sortByName,
            items: [
              DropdownMenuItem(
                  value: loc.sortByName, child: Text(loc.sortByName)),
            ],
            onChanged: onSortChanged,
            underline: const SizedBox(),
            style: Theme.of(context).textTheme.bodyMedium,
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
    );
  }
}
