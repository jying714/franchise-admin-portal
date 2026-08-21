import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _TipLine {
  final String orderId;
  final double amount;
  const _TipLine(this.orderId, this.amount);
}

class EndOfDayScreen extends StatefulWidget {
  final String franchiseId;

  const EndOfDayScreen({super.key, required this.franchiseId});

  @override
  State<EndOfDayScreen> createState() => _EndOfDayScreenState();
}

class _EndOfDayScreenState extends State<EndOfDayScreen> {
  bool _busy = true;
  String? _error;
  double _cash = 0;
  double _card = 0;
  double _cashTips = 0;
  double _cardTips = 0;
  int _count = 0;
  final Map<String, double> _cashBySource = {};
  final Map<String, double> _cardBySource = {};
  final Map<String, double> _allBySource = {};
  final Map<String, List<_TipLine>> _cashTipsByStaff = {};
  final Map<String, List<_TipLine>> _cardTipsByStaff = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _sourceKey(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'web') return 'Customer web';
    if (s == 'mobile') return 'Mobile app';
    if (s == 'pos') return 'POS';
    return s.isEmpty ? 'POS' : raw;
  }

  DateTime get _startLocal {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final start = _startLocal.toUtc().toIso8601String();
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(widget.franchiseId)
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .limit(200)
          .get();
      var cash = 0.0;
      var card = 0.0;
      var cashTips = 0.0;
      var cardTips = 0.0;
      var count = 0;
      final cashBy = <String, double>{};
      final cardBy = <String, double>{};
      final allBy = <String, double>{};
      final cashTipBy = <String, List<_TipLine>>{};
      final cardTipBy = <String, List<_TipLine>>{};

      void add(Map<String, double> m, String k, double v) {
        m[k] = (m[k] ?? 0) + v;
      }

      for (final d in snap.docs) {
        final data = d.data();
        final completed = (data['timestamps'] is Map)
            ? (data['timestamps'] as Map)['completed']?.toString()
            : data['timestamps.completed']?.toString();
        final paidAt = data['paidAt']?.toString() ?? '';
        final when = (completed != null && completed.isNotEmpty)
            ? completed
            : paidAt;
        if (when.isEmpty || when.compareTo(start) < 0) continue;
        count++;
        final total = (data['total'] as num?)?.toDouble() ?? 0;
        final method =
            (data['paymentMethod'] as String?)?.trim().toLowerCase() ?? '';
        final source = _sourceKey(data['source']?.toString() ?? '');
        final staff = (data['closedByStaffName'] as String?)?.trim();
        final staffKey = (staff != null && staff.isNotEmpty)
            ? staff
            : 'Unassigned';
        final cTip = (data['cashTip'] as num?)?.toDouble() ?? 0;
        final rTip = (data['cardTip'] as num?)?.toDouble() ?? 0;
        add(allBy, source, total);
        if (method == 'card') {
          card += total;
          add(cardBy, source, total);
          cardTips += rTip;
          if (rTip > 0) {
            cardTipBy.putIfAbsent(staffKey, () => []).add(_TipLine(d.id, rTip));
          }
        } else {
          cash += total;
          add(cashBy, source, total);
          cashTips += cTip;
          if (cTip > 0) {
            cashTipBy.putIfAbsent(staffKey, () => []).add(_TipLine(d.id, cTip));
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _cash = cash;
        _card = card;
        _cashTips = cashTips;
        _cardTips = cardTips;
        _count = count;
        _cashBySource
          ..clear()
          ..addAll(cashBy);
        _cardBySource
          ..clear()
          ..addAll(cardBy);
        _allBySource
          ..clear()
          ..addAll(allBy);
        _cashTipsByStaff
          ..clear()
          ..addAll(cashTipBy);
        _cardTipsByStaff
          ..clear()
          ..addAll(cardTipBy);
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  Widget _expandTips({
    required String title,
    required double total,
    required Map<String, List<_TipLine>> kids,
  }) {
    return ExpansionTile(
      title: Text(title),
      trailing: Text('\$${total.toStringAsFixed(2)}'),
      children: [
        if (kids.isEmpty)
          const ListTile(dense: true, title: Text('None today'))
        else
          ...kids.entries.map((e) {
            final staffTotal = e.value.fold<double>(0, (s, l) => s + l.amount);
            return ExpansionTile(
              title: Text(e.key),
              trailing: Text('\$${staffTotal.toStringAsFixed(2)}'),
              children: [
                for (final line in e.value)
                  ListTile(
                    dense: true,
                    title: Text(line.orderId),
                    trailing: Text('\$${line.amount.toStringAsFixed(2)}'),
                  ),
              ],
            );
          }),
      ],
    );
  }

  Widget _expand({
    required String title,
    required double total,
    required Map<String, double> kids,
  }) {
    return ExpansionTile(
      title: Text(title),
      trailing: Text('\$${total.toStringAsFixed(2)}'),
      children: [
        if (kids.isEmpty)
          const ListTile(dense: true, title: Text('None today'))
        else
          ...kids.entries.map(
            (e) => ListTile(
              dense: true,
              title: Text(e.key),
              trailing: Text('\$${e.value.toStringAsFixed(2)}'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('End of day'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('$_count completed tickets today'),
                ),
                _expand(title: 'Cash', total: _cash, kids: _cashBySource),
                _expand(title: 'Card', total: _card, kids: _cardBySource),
                _expand(
                  title: 'Overall',
                  total: _cash + _card,
                  kids: _allBySource,
                ),
                _expandTips(
                  title: 'Cash tips',
                  total: _cashTips,
                  kids: _cashTipsByStaff,
                ),
                _expandTips(
                  title: 'Card tips',
                  total: _cardTips,
                  kids: _cardTipsByStaff,
                ),
              ],
            ),
    );
  }
}
