import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategorySearchBar extends StatelessWidget {
  final void Function(String) onChanged;
  final void Function(String?)? onSortChanged;
  final String? currentSort;
  final bool ascending;
  final VoidCallback? onSortDirectionToggle;

  const CategorySearchBar({
    super.key,
    required this.onChanged,
    this.onSortChanged,
    this.currentSort,
    this.ascending = true,
    this.onSortDirectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: currentSort ?? 'name',
            items: [
              DropdownMenuItem(value: 'name', child: Text(loc.sortByName)),
              DropdownMenuItem(
                  value: 'description', child: Text(loc.sortByDescription)),
              // Add more sort options here as needed
            ],
            onChanged: onSortChanged,
            underline: const SizedBox(),
            style: Theme.of(context).textTheme.bodyMedium,
            icon: const Icon(Icons.sort),
            dropdownColor: colorScheme.surface,
          ),
          if (onSortDirectionToggle != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: ascending ? loc.sortAscending : loc.sortDescending,
              onPressed: onSortDirectionToggle,
              icon: Icon(
                ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: colorScheme.secondary,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
