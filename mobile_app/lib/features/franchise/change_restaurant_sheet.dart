import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/core/services/franchise_bind_service.dart';
import 'package:franchise_mobile_app/features/ordering/qr_scan_screen.dart';
import 'package:franchise_mobile_app/features/franchise/franchise_directory_screen.dart';

/// CF4: Change restaurant sheet — current · recents · scan · directory stub.
/// All switches go through [FranchiseBindService.bind].
class ChangeRestaurantSheet extends StatefulWidget {
  const ChangeRestaurantSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ChangeRestaurantSheet(),
    );
  }

  @override
  State<ChangeRestaurantSheet> createState() => _ChangeRestaurantSheetState();
}

class _ChangeRestaurantSheetState extends State<ChangeRestaurantSheet> {
  List<String> _recents = const [];
  bool _loadingRecents = true;
  bool _binding = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final list = await FranchiseBindService.getRecents();
    if (!mounted) return;
    setState(() {
      _recents = list;
      _loadingRecents = false;
    });
  }

  Future<void> _bind(String franchiseId) async {
    if (_binding) return;
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    if (franchiseId == fp.currentFranchiseId) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _binding = true;
      _status = null;
    });

    try {
      // CF5 later: if cart non-empty → confirm → clear → then bind.
      final ok = await FranchiseBindService.bind(
        context,
        franchiseId,
        navigateToMainMenu: true,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _status = 'Could not switch restaurant';
          _binding = false;
        });
        return;
      }
      // bind already navigates to MainMenu; sheet is under that stack and is cleared.
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = e.toString().replaceAll('Exception: ', '');
          _binding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fp = context.watch<shared.FranchiseProvider>();
    final currentId = fp.currentFranchiseId;
    final currentName = fp.currentAppName;

    // Recents excluding current (current shown in its own row).
    final otherRecents =
        _recents.where((id) => id != currentId && id.isNotEmpty).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change restaurant',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Current
            ListTile(
              leading: Icon(Icons.storefront, color: scheme.primary),
              title: Text(currentName),
              subtitle: Text(
                fp.hasValidFranchise ? currentId : 'None selected',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: fp.hasValidFranchise
                  ? Chip(
                      label: const Text('Current'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.primaryContainer,
                    )
                  : null,
            ),

            const Divider(),

            // Recents
            Text(
              'Recent',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_loadingRecents)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (otherRecents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No other recent restaurants yet.\nScan a QR or open a link to add one.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...otherRecents.map(
                (id) => ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(id),
                  enabled: !_binding,
                  onTap: () => _bind(id),
                ),
              ),

            const Divider(),

            // Scan
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR code'),
              enabled: !_binding,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QrScanScreen()),
                );
              },
            ),

            // Directory foundation stub (CF7 fills this)
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Browse directory'),
              enabled: !_binding,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FranchiseDirectoryScreen(),
                  ),
                );
              },
            ),

            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(
                _status!,
                style: TextStyle(color: scheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            if (_binding) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
