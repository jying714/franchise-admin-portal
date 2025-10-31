import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/src/core/models/user.dart'
    as admin_user;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FeatureToggleList extends StatelessWidget {
  final String franchiseId;
  final admin_user.User user;
  final Future<void> Function(
    String,
    bool,
    admin_user.User,
    Map<String, dynamic>,
  ) onUpdateFeature;

  const FeatureToggleList({
    super.key,
    required this.franchiseId,
    required this.user,
    required this.onUpdateFeature,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    return StreamBuilder<Map<String, dynamic>>(
      stream: Provider.of<FirestoreService>(context, listen: false)
          .streamFranchiseFeatureToggles(franchiseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingShimmerWidget();
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(loc.featureToggleLoadError),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => (context as Element).reassemble(),
                  child: Text(loc.retryButton),
                )
              ],
            ),
          );
        }
        final toggles = snapshot.data ?? {};
        final meta = toggles['_meta'] as Map<String, dynamic>? ?? {};

        // Use stable sorted order
        final ownerToggleableKeys = meta.entries
            .where((entry) => entry.value['owner_togglable'] == true)
            .map((entry) => entry.key)
            .toList()
          ..sort();
        final devOnlyKeys = meta.entries
            .where((entry) => entry.value['owner_togglable'] != true)
            .map((entry) => entry.key)
            .toList()
          ..sort();

        List<Widget> tileWidgets(List<String> keys) => keys.map((key) {
              final featureMeta = meta[key] as Map<String, dynamic>? ?? {};
              final value = toggles[key] ?? false;
              return FeatureToggleTile(
                key: ValueKey(key),
                toggleKey: key,
                label: loc.featureDisplayName(key),
                description: featureMeta['description'],
                value: value,
                meta: featureMeta,
                user: user,
                onUpdate: (val) => onUpdateFeature(
                  key,
                  val,
                  user,
                  featureMeta,
                ),
              );
            }).toList();

        if (ownerToggleableKeys.isEmpty &&
            (!user.isDeveloper || devOnlyKeys.isEmpty)) {
          return Center(child: Text(loc.noFeaturesFound));
        }

        return ListView(
          children: [
            if (ownerToggleableKeys.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  loc.ownerTogglesSection,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ...tileWidgets(ownerToggleableKeys),
            if (user.isDeveloper && devOnlyKeys.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32.0, bottom: 8.0),
                child: Text(
                  loc.devOnlyTogglesSection,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            if (user.isDeveloper) ...tileWidgets(devOnlyKeys),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class FeatureToggleTile extends StatefulWidget {
  final String toggleKey;
  final String label;
  final String? description;
  final bool value;
  final Map<String, dynamic> meta;
  final admin_user.User user;
  final Future<void> Function(bool) onUpdate;

  const FeatureToggleTile({
    super.key,
    required this.toggleKey,
    required this.label,
    this.description,
    required this.value,
    required this.meta,
    required this.user,
    required this.onUpdate,
  });

  @override
  State<FeatureToggleTile> createState() => _FeatureToggleTileState();
}

class _FeatureToggleTileState extends State<FeatureToggleTile> {
  bool? _optimisticValue;
  bool _loading = false;

  @override
  void didUpdateWidget(covariant FeatureToggleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Firestore confirms, clear local optimistic value
    if (_optimisticValue != null && widget.value == _optimisticValue) {
      setState(() => _optimisticValue = null);
    }
    if (_loading && widget.value == _optimisticValue) {
      setState(() => _loading = false);
    }
  }

  Future<void> _onChanged(bool newValue) async {
    if (_loading) return;
    setState(() {
      _optimisticValue = newValue;
      _loading = true;
    });
    try {
      await widget.onUpdate(newValue);
    } catch (e) {
      setState(() => _optimisticValue = null); // Roll back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update toggle.')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.meta['paid_service'] == true;
    final isLocked = widget.meta['locked'] == true;
    final shouldDisable =
        _loading || (!widget.user.isDeveloper && isPaid) || isLocked;
    final value = _optimisticValue ?? widget.value;

    return ListTile(
      key: widget.key,
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      title: Text(
        widget.label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: shouldDisable ? Colors.grey : Colors.black,
        ),
      ),
      subtitle: widget.description != null
          ? Text(
              widget.description!,
              style: const TextStyle(fontSize: 12),
            )
          : null,
      trailing: _loading
          ? const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: value,
              onChanged: shouldDisable ? null : _onChanged,
              activeColor: DesignTokens.primaryColor,
              inactiveThumbColor: Colors.grey,
            ),
      enabled: !shouldDisable,
    );
  }
}


