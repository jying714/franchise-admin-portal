import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// LAB.2 — week schedule editor (HQ). Assign staff to shifts via LaborFirestoreService.
class StaffScheduleScreen extends StatefulWidget {
  const StaffScheduleScreen({super.key});

  @override
  State<StaffScheduleScreen> createState() => _StaffScheduleScreenState();
}

class _StaffScheduleScreenState extends State<StaffScheduleScreen> {
  final _labor = shared.LaborFirestoreService();
  final _posFs = shared.PosFirestoreService();

  late DateTime _weekStart; // Monday 00:00 local

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  static DateTime _mondayOf(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    return local.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 7));

  String get _franchiseId {
    final id = Provider.of<shared.FranchiseProvider>(context, listen: false)
        .franchiseId;
    return id;
  }

  void _shiftWeek(int deltaWeeks) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks));
    });
  }

  String _fmtDay(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final name = names[d.weekday - 1];
    return '$name ${d.month}/${d.day}';
  }

  String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openAddShift(
    List<shared.Staff> activeStaff, {
    DateTime? day,
  }) async {
    final fid = _franchiseId;
    if (fid.isEmpty || fid == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a franchise first')),
      );
      return;
    }
    if (activeStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active staff — add staff on Station staff first'),
        ),
      );
      return;
    }

    final base = day ?? _weekStart;
    final result = await showDialog<_ShiftDraft>(
      context: context,
      builder: (ctx) => _AddShiftDialog(
        staff: activeStaff,
        initialDay: base,
      ),
    );
    if (result == null || !mounted) return;

    try {
      await _labor.saveShift(
        shared.Shift(
          id: '',
          franchiseId: fid,
          staffId: result.staff.id,
          staffName: result.staff.name,
          role: result.staff.role,
          startAt: result.start,
          endAt: result.end,
          status: 'scheduled',
          notes: result.notes,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scheduled ${result.staff.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _cancelShift(shared.Shift shift) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel shift?'),
        content: Text(
          '${shift.staffName} · ${_fmtDay(shift.startAt)} '
          '${_fmtTime(shift.startAt)}–${_fmtTime(shift.endAt)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel shift'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _labor.cancelShift(shift.franchiseId, shift.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancel failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fid = context.watch<shared.FranchiseProvider>().franchiseId;
    final hasFranchise = fid.isNotEmpty && fid != 'unknown';

    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff schedule'),
        actions: [
          IconButton(
            tooltip: 'Previous week',
            onPressed: () => _shiftWeek(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Center(
            child: Text(
              '${_fmtDay(_weekStart)} – ${_fmtDay(_weekStart.add(const Duration(days: 6)))}',
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: 'Next week',
            onPressed: () => _shiftWeek(1),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'This week',
            onPressed: () =>
                setState(() => _weekStart = _mondayOf(DateTime.now())),
            icon: const Icon(Icons.today_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !hasFranchise
          ? const Center(child: Text('Select a franchise to manage schedule'))
          : StreamBuilder<List<shared.Staff>>(
              stream: _posFs.streamStaff(fid),
              builder: (context, staffSnap) {
                if (staffSnap.hasError) {
                  return Center(
                    child: Text('Staff error: ${staffSnap.error}'),
                  );
                }
                if (!staffSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final activeStaff = staffSnap.data!
                    .where((s) => s.status.toLowerCase() == 'active')
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

                return Scaffold(
                  backgroundColor: Colors.transparent,
                  floatingActionButton: FloatingActionButton.extended(
                    onPressed: () => _openAddShift(activeStaff),
                    icon: const Icon(Icons.add),
                    label: const Text('Add shift'),
                    backgroundColor: DesignTokens.primaryColor,
                    foregroundColor: DesignTokens.foregroundColor,
                  ),
                  body: StreamBuilder<List<shared.Shift>>(
                    stream: _labor.streamShiftsInRange(
                      fid,
                      rangeStart: _weekStart,
                      rangeEnd: _weekEnd,
                    ),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(child: Text('Error: ${snap.error}'));
                      }
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final shifts = snap.data!
                          .where((s) => s.status != 'cancelled')
                          .toList();

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          final day = days[index];
                          final dayEnd = day.add(const Duration(days: 1));
                          final dayShifts = shifts
                              .where(
                                (s) =>
                                    !s.startAt.isBefore(day) &&
                                    s.startAt.isBefore(dayEnd),
                              )
                              .toList();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _fmtDay(day),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () => _openAddShift(
                                          activeStaff,
                                          day: day,
                                        ),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Shift'),
                                      ),
                                    ],
                                  ),
                                  if (dayShifts.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'No shifts',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  else
                                    ...dayShifts.map((s) {
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(s.staffName),
                                        subtitle: Text(
                                          '${_fmtTime(s.startAt)}–${_fmtTime(s.endAt)} · ${s.role}',
                                        ),
                                        trailing: IconButton(
                                          tooltip: 'Cancel shift',
                                          icon: const Icon(Icons.close),
                                          onPressed: () => _cancelShift(s),
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _ShiftDraft {
  final shared.Staff staff;
  final DateTime start;
  final DateTime end;
  final String? notes;

  _ShiftDraft({
    required this.staff,
    required this.start,
    required this.end,
    this.notes,
  });
}

class _AddShiftDialog extends StatefulWidget {
  final List<shared.Staff> staff;
  final DateTime initialDay;

  const _AddShiftDialog({
    required this.staff,
    required this.initialDay,
  });

  @override
  State<_AddShiftDialog> createState() => _AddShiftDialogState();
}

class _AddShiftDialogState extends State<_AddShiftDialog> {
  late shared.Staff _selected;
  late TimeOfDay _start;
  late TimeOfDay _end;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.staff.first;
    _start = const TimeOfDay(hour: 11, minute: 0);
    _end = const TimeOfDay(hour: 17, minute: 0);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime day, TimeOfDay t) =>
      DateTime(day.year, day.month, day.day, t.hour, t.minute);

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _start);
    if (t != null) setState(() => _start = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: _end);
    if (t != null) setState(() => _end = t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add shift'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<shared.Staff>(
              value: _selected,
              decoration: const InputDecoration(
                labelText: 'Staff',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.staff
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text('${s.name} (${s.role})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selected = v);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickStart,
                    child: Text('Start ${_start.format(context)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickEnd,
                    child: Text('End ${_end.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final start = _combine(widget.initialDay, _start);
            final end = _combine(widget.initialDay, _end);
            if (!end.isAfter(start)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('End must be after start')),
              );
              return;
            }
            Navigator.pop(
              context,
              _ShiftDraft(
                staff: _selected,
                start: start,
                end: end,
                notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
