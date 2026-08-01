import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../orders/open_orders_screen.dart';
import '../settings/station_settings_screen.dart';
import '../orders/closed_orders_screen.dart';
import '../../providers/pin_session_provider.dart';
import 'widgets/order_type_tile.dart';
import '../ordering/order_entry_screen.dart';
import '../dine_in/dine_in_floor_map_screen.dart';

class StationHomeScreen extends StatefulWidget {
  final String franchiseId;

  const StationHomeScreen({super.key, required this.franchiseId});

  @override
  State<StationHomeScreen> createState() => _StationHomeScreenState();
}

class _StationHomeScreenState extends State<StationHomeScreen> {
  bool _offline = false;

  static bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final now = await Connectivity().checkConnectivity();
      if (mounted) setState(() => _offline = _isOffline(now));
      Connectivity().onConnectivityChanged.listen((results) {
        if (!mounted) return;
        setState(() => _offline = _isOffline(results));
      });
    } catch (e) {
      debugPrint('[POS] connectivity watch failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId = widget.franchiseId;
    final session = context.watch<PinSessionProvider>();
    final staff = session.staff;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Station'),
        actions: [
          IconButton(
            tooltip: 'Station settings',
            icon: Icon(Icons.settings_outlined, color: scheme.onPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      StationSettingsScreen(franchiseId: franchiseId),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                staff?.name ?? '',
                style: TextStyle(color: scheme.onPrimary),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Provider.of<PinSessionProvider>(context, listen: false).lock();
            },
            child: Text('Lock', style: TextStyle(color: scheme.onPrimary)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_offline)
            Material(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: scheme.onErrorContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Offline — card payments blocked. Cash only.',
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (session.staff?.role.trim().toLowerCase() != 'driver') ...[
                  Text(
                    'New order',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OrderTypeTile(
                    title: 'Dine-in',
                    subtitle: 'Floor map → seat table → pay at close',
                    icon: Icons.table_restaurant,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              DineInFloorMapScreen(franchiseId: franchiseId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  OrderTypeTile(
                    title: 'Carry-out',
                    subtitle: 'Full menu + modifiers → pay',
                    icon: Icons.takeout_dining,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrderEntryScreen(
                            franchiseId: franchiseId,
                            orderType: 'carryout',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  OrderTypeTile(
                    title: 'Delivery',
                    subtitle: 'Customer + address → order → driver at complete',
                    icon: Icons.delivery_dining,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrderEntryScreen(
                            franchiseId: franchiseId,
                            orderType: 'delivery',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Board',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                OrderTypeTile(
                  title: 'Open orders',
                  subtitle: 'POS + mobile + web in one list',
                  icon: Icons.receipt_long,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            OpenOrdersScreen(franchiseId: franchiseId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                OrderTypeTile(
                  title: 'Closed orders',
                  subtitle: 'Paid, completed, cancelled, refunded',
                  icon: Icons.history,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ClosedOrdersScreen(franchiseId: franchiseId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Franchise: $franchiseId',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
