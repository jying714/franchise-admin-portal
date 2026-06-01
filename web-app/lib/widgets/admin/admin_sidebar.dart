import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

class AdminSidebar extends StatelessWidget {
  final List<shared.DashboardSection> sections;
  final int selectedIndex;
  final void Function(int index) onSelect;
  final List<Widget>? extraWidgets;

  const AdminSidebar({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
    this.extraWidgets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        color: colorScheme.surface,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ...List.generate(sections.length, (index) {
            final section = sections[index];
            final isSelected = selectedIndex == index;

            return Material(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              child: ListTile(
                leading: Icon(
                  section.icon,
                  color:
                      isSelected ? colorScheme.primary : theme.iconTheme.color,
                ),
                title: Text(
                  section.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colorScheme.primary
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
                onTap: () => onSelect(index),
                selected: isSelected,
                selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
              ),
            );
          }),
          if (extraWidgets != null && extraWidgets!.isNotEmpty) ...[
            const Divider(height: 24, thickness: 1),
            ...extraWidgets!,
          ],
        ],
      ),
    );
  }
}
