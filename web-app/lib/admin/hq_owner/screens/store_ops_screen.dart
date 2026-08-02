import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// HQ Owner — tax rate + daily store hours (franchise-scoped).
///
/// Path: franchises/{franchiseId}/config/store_ops
/// Does not touch BrandingConfig / ui_config / DesignTokens.
class StoreOpsScreen extends StatefulWidget {
  /// When true (Restaurant settings → Store ops tab), no AppBar.
  final bool embeddedInSettingsShell;

  const StoreOpsScreen({
    super.key,
    this.embeddedInSettingsShell = false,
  });

  @override
  State<StoreOpsScreen> createState() => _StoreOpsScreenState();
}

class _StoreOpsScreenState extends State<StoreOpsScreen> {
  final _taxController = TextEditingController(text: '9.25');
  final _deliveryFeeController = TextEditingController(text: '0');
  final _deliveryMinimumController = TextEditingController(text: '0');
  bool _deliveryEnabled = false;
  bool _pickupEnabled = true;
  bool _acceptingOnlineOrders = true;

  static const _dayKeys = <String>[
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
    'sat',
    'sun',
  ];
  static const _dayLabels = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Per-day open/close text (HH:mm) and closed flag.
  final Map<String, TextEditingController> _openByDay = {
    for (final k in _dayKeys) k: TextEditingController(text: '11:00'),
  };
  final Map<String, TextEditingController> _closeByDay = {
    for (final k in _dayKeys) k: TextEditingController(text: '21:00'),
  };
  final Map<String, bool> _closedByDay = {
    for (final k in _dayKeys) k: false,
  };

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _syncedFranchiseId;

  @override
  void dispose() {
    _taxController.dispose();
    _deliveryFeeController.dispose();
    _deliveryMinimumController.dispose();
    for (final c in _openByDay.values) {
      c.dispose();
    }
    for (final c in _closeByDay.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id =
        Provider.of<shared.FranchiseProvider>(context).franchiseId.trim();
    if (id.isEmpty || id == 'unknown') return;
    if (_syncedFranchiseId == id) return;
    _syncedFranchiseId = id;
    _load(id);
  }

  Future<void> _load(String franchiseId) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('store_ops')
          .get();
      final data = snap.data();
      if (data != null) {
        final rate = (data['taxRate'] as num?)?.toDouble();
        if (rate != null) {
          _taxController.text = (rate * 100).toStringAsFixed(2);
        }

        _deliveryEnabled = data['deliveryEnabled'] == true;
        _pickupEnabled = data['pickupEnabled'] != false;
        _acceptingOnlineOrders = data['acceptingOnlineOrders'] != false;
        final fee = (data['deliveryFee'] as num?)?.toDouble();
        if (fee != null) {
          _deliveryFeeController.text = fee.toStringAsFixed(2);
        }
        final minOrder = (data['deliveryMinimum'] as num?)?.toDouble();
        if (minOrder != null) {
          _deliveryMinimumController.text = minOrder.toStringAsFixed(2);
        }

        final hoursRaw = data['hours'];
        if (hoursRaw is Map) {
          for (final key in _dayKeys) {
            final day = hoursRaw[key];
            if (day is! Map) continue;
            final closed = day['closed'] == true;
            _closedByDay[key] = closed;
            final openH = day['openHour'] as int? ?? 11;
            final openM = day['openMinute'] as int? ?? 0;
            final closeH = day['closeHour'] as int? ?? 21;
            final closeM = day['closeMinute'] as int? ?? 0;
            _openByDay[key]!.text =
                '${openH.toString().padLeft(2, '0')}:${openM.toString().padLeft(2, '0')}';
            _closeByDay[key]!.text =
                '${closeH.toString().padLeft(2, '0')}:${closeM.toString().padLeft(2, '0')}';
          }
        } else {
          // Legacy single daily pair → seed all days.
          final openH = data['openHour'] as int? ?? 11;
          final openM = data['openMinute'] as int? ?? 0;
          final closeH = data['closeHour'] as int? ?? 21;
          final closeM = data['closeMinute'] as int? ?? 0;
          final openStr =
              '${openH.toString().padLeft(2, '0')}:${openM.toString().padLeft(2, '0')}';
          final closeStr =
              '${closeH.toString().padLeft(2, '0')}:${closeM.toString().padLeft(2, '0')}';
          for (final key in _dayKeys) {
            _openByDay[key]!.text = openStr;
            _closeByDay[key]!.text = closeStr;
            _closedByDay[key] = false;
          }
        }
      }
    } catch (e) {
      _loadError = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  (int hour, int minute)? _parseHm(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return (h, m);
  }

  Future<void> _save() async {
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = fp.franchiseId.trim();
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No franchise selected')),
      );
      return;
    }

    final taxPct = double.tryParse(_taxController.text.trim());
    if (taxPct == null || taxPct < 0 || taxPct > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tax rate must be 0–100 (%)')),
      );
      return;
    }
    final deliveryFee = double.tryParse(_deliveryFeeController.text.trim());
    final deliveryMinimum =
        double.tryParse(_deliveryMinimumController.text.trim());
    if (deliveryFee == null || deliveryFee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery fee must be ≥ 0')),
      );
      return;
    }
    if (deliveryMinimum == null || deliveryMinimum < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery minimum must be ≥ 0')),
      );
      return;
    }

    final hoursPayload = <String, dynamic>{};
    for (final key in _dayKeys) {
      final closed = _closedByDay[key] == true;
      if (closed) {
        hoursPayload[key] = {
          'closed': true,
          'openHour': 0,
          'openMinute': 0,
          'closeHour': 0,
          'closeMinute': 0,
        };
        continue;
      }
      final open = _parseHm(_openByDay[key]!.text);
      final close = _parseHm(_closeByDay[key]!.text);
      if (open == null || close == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_dayLabels[_dayKeys.indexOf(key)]}: hours must be HH:mm',
            ),
          ),
        );
        return;
      }
      hoursPayload[key] = {
        'closed': false,
        'openHour': open.$1,
        'openMinute': open.$2,
        'closeHour': close.$1,
        'closeMinute': close.$2,
      };
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('store_ops')
          .set({
        'taxRate': taxPct / 100.0,
        'hours': hoursPayload,
        'deliveryEnabled': _deliveryEnabled,
        'pickupEnabled': _pickupEnabled,
        'acceptingOnlineOrders': _acceptingOnlineOrders,
        'deliveryFee': deliveryFee,
        'deliveryMinimum': deliveryMinimum,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tax & hours saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: true);
    final franchiseId = fp.franchiseId;
    final hasFranchise = franchiseId.isNotEmpty && franchiseId != 'unknown';

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      appBar: widget.embeddedInSettingsShell
          ? null
          : AppBar(
              elevation: DesignTokens.appBarElevation,
              backgroundColor: DesignTokens.appBarBackgroundColor,
              foregroundColor: DesignTokens.appBarForegroundColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: const Text('Tax & hours'),
            ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(DesignTokens.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      hasFranchise
                          ? 'Franchise: $franchiseId'
                          : 'Franchise: not selected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (_loadError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Load warning: $_loadError',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Card(
                      elevation: DesignTokens.adminCardElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.adminCardRadius,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(DesignTokens.paddingLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sales tax',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _taxController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Tax rate (%)',
                                hintText: '9.25',
                                border: OutlineInputBorder(),
                                isDense: true,
                                helperText:
                                    'Stored as decimal (9.25 → 0.0925). Mobile + POS will read this next.',
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Fulfillment',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Accepting online orders'),
                              subtitle: const Text(
                                'Master kill switch for web + mobile intake',
                              ),
                              value: _acceptingOnlineOrders,
                              onChanged: (v) =>
                                  setState(() => _acceptingOnlineOrders = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Pickup enabled'),
                              value: _pickupEnabled,
                              onChanged: (v) =>
                                  setState(() => _pickupEnabled = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Delivery enabled'),
                              value: _deliveryEnabled,
                              onChanged: (v) =>
                                  setState(() => _deliveryEnabled = v),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _deliveryFeeController,
                              enabled: _deliveryEnabled,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Delivery fee (\$)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _deliveryMinimumController,
                              enabled: _deliveryEnabled,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Delivery minimum (\$)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Store hours (per day, 24h)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            for (var i = 0; i < _dayKeys.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              _DayHoursRow(
                                label: _dayLabels[i],
                                openController: _openByDay[_dayKeys[i]]!,
                                closeController: _closeByDay[_dayKeys[i]]!,
                                closed: _closedByDay[_dayKeys[i]] == true,
                                onClosedChanged: (v) {
                                  setState(() {
                                    _closedByDay[_dayKeys[i]] = v;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Closed days skip open/close. Holidays = later.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed:
                                  (!hasFranchise || _saving) ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined, size: 18),
                              label: Text(_saving ? 'Saving…' : 'Save'),
                              style: FilledButton.styleFrom(
                                backgroundColor: DesignTokens.primaryColor,
                                foregroundColor: DesignTokens.foregroundColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DayHoursRow extends StatelessWidget {
  final String label;
  final TextEditingController openController;
  final TextEditingController closeController;
  final bool closed;
  final ValueChanged<bool> onClosedChanged;

  const _DayHoursRow({
    required this.label,
    required this.openController,
    required this.closeController,
    required this.closed,
    required this.onClosedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: openController,
            enabled: !closed,
            decoration: const InputDecoration(
              labelText: 'Open',
              hintText: '11:00',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: closeController,
            enabled: !closed,
            decoration: const InputDecoration(
              labelText: 'Close',
              hintText: '21:00',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Column(
          children: [
            const Text('Closed', style: TextStyle(fontSize: 11)),
            Checkbox(
              value: closed,
              onChanged: (v) => onClosedChanged(v == true),
            ),
          ],
        ),
      ],
    );
  }
}
