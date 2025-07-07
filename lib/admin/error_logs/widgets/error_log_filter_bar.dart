import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ErrorLogFilterBar extends StatefulWidget {
  final void Function({
    String? severity,
    String? source,
    String? screen,
    DateTime? start,
    DateTime? end,
    String? search,
  }) onFilterChanged;

  const ErrorLogFilterBar({super.key, required this.onFilterChanged});

  @override
  State<ErrorLogFilterBar> createState() => _ErrorLogFilterBarState();
}

class _ErrorLogFilterBarState extends State<ErrorLogFilterBar> {
  String? severity = 'all'; // Use 'all' as real default, not null!
  String? source;
  String? screen;
  DateTime? start;
  DateTime? end;
  final _searchController = TextEditingController();
  final _sourceController = TextEditingController();
  final _screenController = TextEditingController();

  void _fireOnFilterChanged() {
    print(
        'Filter: severity=$severity, source=$source, screen=$screen, start=$start, end=$end, search=${_searchController.text.trim()}');
    widget.onFilterChanged(
      severity: severity == 'all' ? null : severity,
      source: source,
      screen: screen,
      start: start,
      end: end,
      search: _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<String>(
            value: severity ?? 'all',
            hint: const Text('Severity'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'fatal', child: Text('Fatal')),
              DropdownMenuItem(value: 'warning', child: Text('Warning')),
              DropdownMenuItem(value: 'info', child: Text('Info')),
            ],
            onChanged: (val) {
              setState(() => severity = val);
              _fireOnFilterChanged();
            },
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                prefixIcon: Icon(Icons.scatter_plot, size: 18),
                isDense: true,
              ),
              onChanged: (val) {
                setState(() => source = val.trim().isEmpty ? null : val.trim());
                _fireOnFilterChanged();
              },
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _screenController,
              decoration: const InputDecoration(
                labelText: 'Screen',
                prefixIcon: Icon(Icons.smartphone, size: 18),
                isDense: true,
              ),
              onChanged: (val) {
                setState(() => screen = val.trim().isEmpty ? null : val.trim());
                _fireOnFilterChanged();
              },
            ),
          ),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (val) => _fireOnFilterChanged(),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(
              start != null && end != null
                  ? '${DateFormat('yyyy-MM-dd').format(start!)} - ${DateFormat('yyyy-MM-dd').format(end!)}'
                  : 'Date Range',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary.withOpacity(0.45)),
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
                setState(() {
                  start = picked.start;
                  end = picked.end;
                });
                _fireOnFilterChanged();
              }
            },
          ),
          if (start != null || end != null)
            IconButton(
              tooltip: "Clear date filter",
              icon: Icon(Icons.clear, color: colorScheme.outline),
              onPressed: () {
                setState(() {
                  start = null;
                  end = null;
                });
                _fireOnFilterChanged();
              },
            ),
        ],
      ),
    );
  }
}
