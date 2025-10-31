import 'package:flutter/material.dart';
import '../../../../packages/shared_core/lib/src/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class AdminSidebar extends StatelessWidget {
  final List<DashboardSection> sections;
  final int selectedIndex;
  final void Function(int index) onSelect;
  final List<Widget>? extraWidgets;

  const AdminSidebar({
    Key? key,
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
    this.extraWidgets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
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
                  ? colorScheme.primary.withOpacity(0.08)
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
                selectedTileColor: colorScheme.primary.withOpacity(0.1),
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
