import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/pos_printer_config.dart';
import '../../services/print_service.dart';
import '../../services/drawer_service.dart';

/// Pilot settings: franchise bind + store_ops summary (read-only).
class StationSettingsScreen extends StatefulWidget {
  final String franchiseId;

  const StationSettingsScreen({super.key, required this.franchiseId});

  @override
  State<StationSettingsScreen> createState() => _StationSettingsScreenState();
}

class _StationSettingsScreenState extends State<StationSettingsScreen> {
  bool _loading = true;
  String? _error;
  double? _taxRate;
  String _todayHours = '—';
  bool _todayClosed = false;
  late final TextEditingController _printerHostCtrl;

  static String _weekdayKey(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      default:
        return 'sun';
    }
  }

  String _hm(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _printerHostCtrl = TextEditingController(text: PosPrinterConfig.host);
    _load();
  }

  @override
  void dispose() {
    _printerHostCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(widget.franchiseId)
          .collection('config')
          .doc('store_ops')
          .get();
      final data = snap.data();
      double? rate;
      var hoursLabel = 'Not configured (fallback 11:00–21:00)';
      var closed = false;

      if (data != null) {
        rate = (data['taxRate'] as num?)?.toDouble();
        final key = _weekdayKey(DateTime.now());
        final hoursRaw = data['hours'];
        if (hoursRaw is Map && hoursRaw[key] is Map) {
          final day = Map<String, dynamic>.from(hoursRaw[key] as Map);
          closed = day['closed'] == true;
          if (closed) {
            hoursLabel = 'Closed today';
          } else {
            hoursLabel =
                '${_hm(day['openHour'] as int? ?? 11, day['openMinute'] as int? ?? 0)}'
                '–'
                '${_hm(day['closeHour'] as int? ?? 21, day['closeMinute'] as int? ?? 0)}';
          }
        } else if (data['openHour'] != null) {
          hoursLabel =
              '${_hm(data['openHour'] as int? ?? 11, data['openMinute'] as int? ?? 0)}'
              '–'
              '${_hm(data['closeHour'] as int? ?? 21, data['closeMinute'] as int? ?? 0)}';
        }
      }

      if (!mounted) return;
      setState(() {
        _taxRate = rate;
        _todayHours = hoursLabel;
        _todayClosed = closed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Station settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: TextStyle(color: scheme.error)),
                  ),
                ListTile(
                  title: const Text('Franchise'),
                  subtitle: Text(widget.franchiseId),
                ),
                ListTile(
                  title: const Text('Tax rate'),
                  subtitle: Text(
                    _taxRate == null
                        ? 'Not set — using 9.25% fallback'
                        : '${(_taxRate! * 100).toStringAsFixed(2)}%',
                  ),
                ),
                ListTile(
                  title: const Text("Today's hours"),
                  subtitle: Text(_todayHours),
                  trailing: _todayClosed
                      ? Chip(
                          label: const Text('Closed'),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: scheme.errorContainer,
                        )
                      : null,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Card payments'),
                  subtitle: const Text(
                    'PaymentSheet (Connect). Physical reader = later.',
                  ),
                ),
                const Text(
                  'Printer (this station)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _printerHostCtrl,
                  decoration: const InputDecoration(
                    labelText: 'TSP100 IP or host',
                    hintText: '192.168.1.21',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    await PosPrinterConfig.save(_printerHostCtrl.text);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Printer host saved')),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save printer host'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await PosPrinterConfig.save(_printerHostCtrl.text);
                    final ok = await const PrintService().printTestPage();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Test page sent' : 'Test page failed — see log',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Test print'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await PosPrinterConfig.save(_printerHostCtrl.text);
                    final ok = await const DrawerService().openDrawer(
                      reason: 'settings_test',
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Drawer kick sent'
                              : 'Drawer kick failed — see log',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('Test drawer'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload from HQ'),
                ),
              ],
            ),
    );
  }
}
