import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ErrorLogFilterBar extends StatelessWidget {
  final String? severity;
  final String? source;
  final String? screen;
  final DateTime? start;
  final DateTime? end;
  final String? search;
  final void Function({
    String? severity,
    String? source,
    String? screen,
    DateTime? start,
    DateTime? end,
    String? search,
  }) onFilterChanged;
  final Widget? trailing;

  const ErrorLogFilterBar({
    super.key,
    required this.severity,
    required this.source,
    required this.screen,
    required this.start,
    required this.end,
    required this.search,
    required this.onFilterChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    final searchController = TextEditingController(text: search ?? '');
    final sourceController = TextEditingController(text: source ?? '');
    final screenController = TextEditingController(text: screen ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Tooltip(
                  message: loc.severityTooltip,
                  child: DropdownButton<String>(
                    value: severity ?? 'all',
                    hint: Text(loc.severity),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(loc.all)),
                      DropdownMenuItem(value: 'fatal', child: Text(loc.fatal)),
                      DropdownMenuItem(
                          value: 'warning', child: Text(loc.warning)),
                      DropdownMenuItem(value: 'info', child: Text(loc.info)),
                    ],
                    onChanged: (val) => onFilterChanged(
                      severity: (val == null || val == 'all' || val == 'null')
                          ? null
                          : val,
                      source: source,
                      screen: screen,
                      start: start,
                      end: end,
                      search: search,
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Tooltip(
                    message: loc.sourceTooltip,
                    child: TextField(
                      controller: sourceController,
                      decoration: InputDecoration(
                        labelText: loc.source,
                        prefixIcon: const Icon(Icons.scatter_plot, size: 18),
                        isDense: true,
                      ),
                      onChanged: (val) => onFilterChanged(
                        severity: severity,
                        source: val.trim().isEmpty ? null : val.trim(),
                        screen: screen,
                        start: start,
                        end: end,
                        search: search,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Tooltip(
                    message: loc.screenTooltip,
                    child: TextField(
                      controller: screenController,
                      decoration: InputDecoration(
                        labelText: loc.screen,
                        prefixIcon: const Icon(Icons.smartphone, size: 18),
                        isDense: true,
                      ),
                      onChanged: (val) => onFilterChanged(
                        severity: severity,
                        source: source,
                        screen: val.trim().isEmpty ? null : val.trim(),
                        start: start,
                        end: end,
                        search: search,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: Tooltip(
                    message: loc.searchTooltip,
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: loc.search,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (val) => onFilterChanged(
                        severity: severity,
                        source: source,
                        screen: screen,
                        start: start,
                        end: end,
                        search: val.trim().isEmpty ? null : val.trim(),
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: loc.dateRangeTooltip,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      start != null && end != null
                          ? '${DateFormat('yyyy-MM-dd').format(start!)} - ${DateFormat('yyyy-MM-dd').format(end!)}'
                          : loc.dateRange,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(
                          color: colorScheme.primary.withOpacity(0.45)),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 2),
                        lastDate: now.add(const Duration(days: 1)),
                        initialDateRange: (start != null && end != null)
                            ? DateTimeRange(start: start!, end: end!)
                            : null,
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: colorScheme,
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        onFilterChanged(
                          severity: severity,
                          source: source,
                          screen: screen,
                          start: picked.start,
                          end: picked.end,
                          search: search,
                        );
                      }
                    },
                  ),
                ),
                if (start != null || end != null)
                  Tooltip(
                    message: loc.clearDateFilter,
                    child: IconButton(
                      tooltip: loc.clearDateFilter,
                      icon: Icon(Icons.clear, color: colorScheme.outline),
                      onPressed: () {
                        onFilterChanged(
                          severity: severity,
                          source: source,
                          screen: screen,
                          start: null,
                          end: null,
                          search: search,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ]
        ],
      ),
    );
  }
}


