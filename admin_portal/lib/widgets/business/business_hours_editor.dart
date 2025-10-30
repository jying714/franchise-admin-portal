import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/config/design_tokens.dart';

const _DAYS = [
  'sun',
  'mon',
  'tue',
  'wed',
  'thu',
  'fri',
  'sat',
];

const _DAY_LABELS = {
  'sun': 'Sun',
  'mon': 'Mon',
  'tue': 'Tue',
  'wed': 'Wed',
  'thu': 'Thu',
  'fri': 'Fri',
  'sat': 'Sat',
};

class BusinessHourInterval {
  List<String> days;
  TimeOfDay open;
  TimeOfDay close;

  BusinessHourInterval({
    required this.days,
    required this.open,
    required this.close,
  });

  Map<String, dynamic> toJson() => {
        'days': days,
        'open': '${open.hour.toString().padLeft(2, '0')}:'
            '${open.minute.toString().padLeft(2, '0')}',
        'close': '${close.hour.toString().padLeft(2, '0')}:'
            '${close.minute.toString().padLeft(2, '0')}',
      };

  static BusinessHourInterval fromJson(Map<String, dynamic> json) {
    final openParts = (json['open'] as String).split(':');
    final closeParts = (json['close'] as String).split(':');
    return BusinessHourInterval(
      days: List<String>.from(json['days'] ?? []),
      open: TimeOfDay(
        hour: int.parse(openParts[0]),
        minute: int.parse(openParts[1]),
      ),
      close: TimeOfDay(
        hour: int.parse(closeParts[0]),
        minute: int.parse(closeParts[1]),
      ),
    );
  }
}

class BusinessHoursEditor extends StatefulWidget {
  final List<Map<String, dynamic>> initialHours;
  final void Function(List<Map<String, dynamic>>)? onChanged;
  final bool enabled;

  const BusinessHoursEditor({
    Key? key,
    this.initialHours = const [],
    this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<BusinessHoursEditor> createState() => _BusinessHoursEditorState();
}

class _BusinessHoursEditorState extends State<BusinessHoursEditor> {
  late List<BusinessHourInterval> _intervals;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _intervals = widget.initialHours.isNotEmpty
        ? widget.initialHours
            .map((e) => BusinessHourInterval.fromJson(e))
            .toList()
        : [
            BusinessHourInterval(
              days: ['mon', 'tue', 'wed', 'thu', 'fri'],
              open: const TimeOfDay(hour: 9, minute: 0),
              close: const TimeOfDay(hour: 17, minute: 0),
            ),
          ];
  }

  void _addInterval() {
    setState(() {
      _intervals.add(
        BusinessHourInterval(
          days: [],
          open: const TimeOfDay(hour: 9, minute: 0),
          close: const TimeOfDay(hour: 17, minute: 0),
        ),
      );
      _validationError = null;
    });
    _notifyChange();
  }

  void _removeInterval(int index) {
    setState(() {
      _intervals.removeAt(index);
      _validationError = null;
    });
    _notifyChange();
  }

  void _updateInterval(
      int index, List<String> days, TimeOfDay open, TimeOfDay close) {
    setState(() {
      _intervals[index] = BusinessHourInterval(
        days: days,
        open: open,
        close: close,
      );
      _validationError = null;
    });
    _notifyChange();
  }

  void _notifyChange() {
    widget.onChanged?.call(_intervals.map((e) => e.toJson()).toList());
  }

  String? _validateIntervals(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_intervals.isEmpty) {
      return loc?.mustSetAtLeastOneInterval ??
          'Set at least one business hour.';
    }
    final coveredDays = <String>{};
    for (final interval in _intervals) {
      if (interval.days.isEmpty) {
        return loc?.mustSelectDays ?? 'Select days for each interval.';
      }
      if (interval.open.hour > interval.close.hour ||
          (interval.open.hour == interval.close.hour &&
              interval.open.minute >= interval.close.minute)) {
        return loc?.openMustBeforeClose ??
            'Open time must be before close time.';
      }
      for (final day in interval.days) {
        if (coveredDays.contains(day)) {
          return loc?.daysOverlap ??
              'Overlapping days across intervals are not allowed.';
        }
        coveredDays.add(day);
      }
    }
    if (coveredDays.isEmpty) {
      return loc?.mustSelectDays ?? 'Select days for each interval.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = widget.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc?.setupBusinessHours ?? "Setup business hours",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          loc?.setupBusinessHoursDesc ??
              "Your business hours are used for on-duty calculation, "
                  "and shown on your restaurant page.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        ..._intervals
            .asMap()
            .entries
            .map((entry) => _buildInterval(context, entry.key, entry.value))
            .toList(),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(loc?.addMore ?? "[+] add more"),
            onPressed: enabled ? _addInterval : null,
          ),
        ),
        if (_validationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _validationError!,
              style: TextStyle(color: colorScheme.error, fontSize: 13),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildInterval(
      BuildContext context, int index, BusinessHourInterval interval) {
    final enabled = widget.enabled;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      color: enabled ? colorScheme.surface : colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: _TimePickerField(
                    label: AppLocalizations.of(context)?.openAt ?? 'open at',
                    time: interval.open,
                    enabled: enabled,
                    onChanged: (t) {
                      final days = List<String>.from(interval.days);
                      _updateInterval(index, days, t, interval.close);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: _TimePickerField(
                    label: AppLocalizations.of(context)?.closeAt ?? 'close at',
                    time: interval.close,
                    enabled: enabled,
                    onChanged: (t) {
                      final days = List<String>.from(interval.days);
                      _updateInterval(index, days, interval.open, t);
                    },
                  ),
                ),
                if (enabled)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeInterval(index),
                    tooltip: AppLocalizations.of(context)?.remove ?? 'Remove',
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 9,
              children: _DAYS
                  .map((d) => FilterChip(
                        selected: interval.days.contains(d),
                        label: Text(_DAY_LABELS[d]!),
                        onSelected: enabled
                            ? (selected) {
                                final days = List<String>.from(interval.days);
                                if (selected) {
                                  days.add(d);
                                } else {
                                  days.remove(d);
                                }
                                _updateInterval(
                                  index,
                                  days,
                                  interval.open,
                                  interval.close,
                                );
                              }
                            : null,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Validate and expose to parent
  bool validate(BuildContext context) {
    final error = _validateIntervals(context);
    setState(() => _validationError = error);
    return error == null;
  }

  // Expose current value as List<Map<String, dynamic>>
  List<Map<String, dynamic>> get value =>
      _intervals.map((e) => e.toJson()).toList();
}

/// Helper time picker for hour/min selection
class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final bool enabled;
  final void Function(TimeOfDay) onChanged;

  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) onChanged(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabled: enabled,
          isDense: true,
        ),
        child: Text(
          time.format(context),
          style: TextStyle(
            color: enabled
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
