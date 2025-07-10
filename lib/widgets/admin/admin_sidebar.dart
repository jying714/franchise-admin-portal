import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class AdminSidebar extends StatelessWidget {
  final List<DashboardSection> sections;
  final int selectedIndex;
  final void Function(int index) onSelect;

  const AdminSidebar({
    Key? key,
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
        color: theme.colorScheme.surface,
      ),
      child: ListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          final isSelected = selectedIndex == index;

          return Material(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.08)
                : Colors.transparent,
            child: ListTile(
              leading: Icon(
                section.icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color,
              ),
              title: Text(
                section.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyLarge?.color,
                ),
              ),
              onTap: () => onSelect(index),
              selected: isSelected,
              selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
            ),
          );
        },
      ),
    );
  }
}
