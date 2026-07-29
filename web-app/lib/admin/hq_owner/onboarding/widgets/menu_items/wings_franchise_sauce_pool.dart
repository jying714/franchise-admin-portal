import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// W2: franchises/{id}/config/menu_profile_wings
/// { sauceIngredientIds: string[], maxFlavorPortions: 2 }
class WingsFranchiseSaucePool extends StatefulWidget {
  final String franchiseId;
  final List<shared.IngredientMetadata> sauceIngredients;
  final List<String> itemBoundSauceIds;
  final ValueChanged<List<String>> onApplyPoolToItem;

  const WingsFranchiseSaucePool({
    super.key,
    required this.franchiseId,
    required this.sauceIngredients,
    required this.itemBoundSauceIds,
    required this.onApplyPoolToItem,
  });

  @override
  State<WingsFranchiseSaucePool> createState() =>
      _WingsFranchiseSaucePoolState();
}

class _WingsFranchiseSaucePoolState extends State<WingsFranchiseSaucePool> {
  final Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection('franchises')
      .doc(widget.franchiseId)
      .collection('config')
      .doc('menu_profile_wings');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _doc.get();
      final raw = snap.data()?['sauceIngredientIds'];
      _selected.clear();
      if (raw is List) {
        for (final e in raw) {
          final id = e.toString();
          if (id.isNotEmpty) _selected.add(id);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _savePool() async {
    setState(() => _saving = true);
    try {
      await _doc.set({
        'sauceIngredientIds': _selected.toList(),
        'maxFlavorPortions': 2,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Franchise wings sauce pool saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save pool: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Franchise wings sauce pool (W2)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Default sauces for wings items that have no item-level bind. '
              'Mobile falls back here after item lists / modifier groups.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.sauceIngredients.map((ing) {
                final selected = _selected.contains(ing.id);
                return FilterChip(
                  label: Text(ing.name),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selected.add(ing.id);
                      } else {
                        _selected.remove(ing.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saving ? null : _savePool,
                  child: Text(_saving ? 'Saving…' : 'Save franchise pool'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => widget.onApplyPoolToItem(_selected.toList()),
                  child: const Text('Apply pool to this item'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected
                        ..clear()
                        ..addAll(widget.itemBoundSauceIds);
                    });
                  },
                  child: const Text('Copy from this item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
