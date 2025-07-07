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
  String? severity;
  String? source;
  String? screen;
  DateTime? start;
  DateTime? end;
  final _searchController = TextEditingController();

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
            value: severity,
            hint: const Text('Severity'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              const DropdownMenuItem(value: 'fatal', child: Text('Fatal')),
              const DropdownMenuItem(value: 'warning', child: Text('Warning')),
              const DropdownMenuItem(value: 'info', child: Text('Info')),
            ],
            onChanged: (val) {
              setState(() => severity = val);
              widget.onFilterChanged(
                severity: val,
                source: source,
                screen: screen,
                start: start,
                end: end,
                search: _searchController.text,
              );
            },
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
              onChanged: (val) => widget.onFilterChanged(
                severity: severity,
                source: source,
                screen: screen,
                start: start,
                end: end,
                search: val,
              ),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(
              start != null && end != null
                  ? '${DateFormat('yyyy-MM-dd').format(start!)} - ${DateFormat('yyyy-MM-dd').format(end!)}'
                  : 'Date Range',
            ),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 2),
                lastDate: now.add(const Duration(days: 1)),
                initialDateRange: start != null && end != null
                    ? DateTimeRange(start: start!, end: end!)
                    : null,
              );
              if (picked != null) {
                setState(() {
                  start = picked.start;
                  end = picked.end;
                });
                widget.onFilterChanged(
                  severity: severity,
                  source: source,
                  screen: screen,
                  start: picked.start,
                  end: picked.end,
                  search: _searchController.text,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
