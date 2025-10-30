import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/dashboard_section.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class DevToolsSidebarGroup extends StatefulWidget {
  final List<DashboardSection> tools;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String label;
  final IconData icon;
  final int startIndexOffset;

  const DevToolsSidebarGroup({
    super.key,
    required this.tools,
    required this.selectedIndex,
    required this.onSelect,
    this.label = 'Dev Tools',
    this.icon = Icons.build_outlined,
    this.startIndexOffset = 0,
  });

  @override
  State<DevToolsSidebarGroup> createState() => _DevToolsSidebarGroupState();
}

class _DevToolsSidebarGroupState extends State<DevToolsSidebarGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelectedGroup = widget.tools.any((section) =>
        widget.selectedIndex == section.sidebarOrder + widget.startIndexOffset);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(widget.icon,
              color: isSelectedGroup
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant),
          title: Text(
            widget.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  isSelectedGroup ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          ...widget.tools.map((section) {
            final index = section.sidebarOrder + widget.startIndexOffset;
            final selected = index == widget.selectedIndex;

            return Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Material(
                color: selected
                    ? colorScheme.primaryContainer.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => widget.onSelect(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          section.icon,
                          size: 20,
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
      ],
    );
  }
}
