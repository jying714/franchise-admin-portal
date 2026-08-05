import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// LAB.5 — hours worked per employee for a date range.
class StaffHoursSummaryScreen extends StatefulWidget {
  const StaffHoursSummaryScreen({super.key});

  @override
  State<StaffHoursSummaryScreen> createState() =>
      _StaffHoursSummaryScreenState();
}

class _StaffHoursSummaryScreenState extends State<StaffHoursSummaryScreen> {
  final _labor = shared.LaborFirestoreService();
  final _posFs = shared.PosFirestoreService();

  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  bool _loading = false;
  String? _error;
  List<_EmployeeHours> _rows = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    _rangeStart = monday;
    _rangeEnd = monday.add(const Duration(days: 7));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _franchiseId =>
      Provider.of<shared.FranchiseProvider>(context, listen: false).franchiseId;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtHours(double h) => h.toStringAsFixed(2);

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _rangeStart,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (d == null) return;
    setState(() {
      _rangeStart = DateTime(d.year, d.month, d.day);
      if (!_rangeEnd.isAfter(_rangeStart)) {
        _rangeEnd = _rangeStart.add(const Duration(days: 1));
      }
    });
    await _load();
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _rangeEnd.subtract(const Duration(days: 1)),
      firstDate: _rangeStart,
      lastDate: DateTime(2035),
    );
    if (d == null) return;
    setState(() {
      _rangeEnd = DateTime(d.year, d.month, d.day).add(const Duration(days: 1));
    });
    await _load();
  }

  Future<void> _load() async {
    final fid = _franchiseId;
    if (fid.isEmpty || fid == 'unknown') {
      setState(() {
        _rows = const [];
        _error = 'Select a franchise first';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final entries = await _labor.getEntriesInRange(
        fid,
        rangeStart: _rangeStart,
        rangeEnd: _rangeEnd,
      );
      final staffList = await _posFs.streamStaff(fid).first;
      final staffById = {for (final s in staffList) s.id: s};

      final map = <String, _EmployeeHours>{};
      for (final e in entries) {
        final hours = e.workedHours;
        final existing = map[e.staffId];
        final pay = staffById[e.staffId]?.hourlyPay;
        if (existing == null) {
          map[e.staffId] = _EmployeeHours(
            staffId: e.staffId,
            staffName: e.staffName,
            punches: 1,
            openPunches: e.isOpen ? 1 : 0,
            hours: hours,
            hourlyPay: pay,
          );
        } else {
          map[e.staffId] = existing.copyWith(
            punches: existing.punches + 1,
            openPunches: existing.openPunches + (e.isOpen ? 1 : 0),
            hours: existing.hours + hours,
          );
        }
      }

      final rows = map.values.toList()
        ..sort((a, b) => a.staffName.compareTo(b.staffName));

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
        _rows = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalHours = _rows.fold<double>(0, (s, r) => s + r.hours);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Hours summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _pickStart,
                  child: Text('From ${_fmtDate(_rangeStart)}'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _pickEnd,
                  child: Text(
                    'To ${_fmtDate(_rangeEnd.subtract(const Duration(days: 1)))}',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Clock punches in range · open punches use hours through now',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_rows.isEmpty)
              const Expanded(
                child: Center(child: Text('No time entries in this range')),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = _rows[i];
                          final est = r.hourlyPay == null
                              ? null
                              : r.hours * r.hourlyPay!;
                          return ListTile(
                            title: Text(r.staffName),
                            subtitle: Text(
                              [
                                '${r.punches} punch${r.punches == 1 ? '' : 'es'}',
                                if (r.openPunches > 0)
                                  '${r.openPunches} still open',
                                if (r.hourlyPay != null)
                                  '\$${r.hourlyPay!.toStringAsFixed(2)}/hr',
                              ].join(' · '),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_fmtHours(r.hours)} h',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (est != null)
                                  Text(
                                    '~\$${est.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            'Total',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.primaryColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_fmtHours(totalHours)} h',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeHours {
  final String staffId;
  final String staffName;
  final int punches;
  final int openPunches;
  final double hours;
  final double? hourlyPay;

  const _EmployeeHours({
    required this.staffId,
    required this.staffName,
    required this.punches,
    required this.openPunches,
    required this.hours,
    this.hourlyPay,
  });

  _EmployeeHours copyWith({
    int? punches,
    int? openPunches,
    double? hours,
  }) {
    return _EmployeeHours(
      staffId: staffId,
      staffName: staffName,
      punches: punches ?? this.punches,
      openPunches: openPunches ?? this.openPunches,
      hours: hours ?? this.hours,
      hourlyPay: hourlyPay,
    );
  }
}
