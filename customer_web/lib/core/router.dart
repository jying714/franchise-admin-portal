// customer_web/lib/core/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import '../widgets/branding_shell.dart';
import 'franchise_bind.dart';
import '../features/menu/menu_browse_screen.dart';

/// Phase 1 router: path bind only.
/// Hostname auto-bind hooks in later; do not invent domain schema here.
GoRouter createCustomerRouter({
  required shared.FranchiseProvider franchiseProvider,
}) {
  // Hosting rewrite keeps the browser path; Flutter exposes it here.
  // Requires usePathUrlStrategy() in main.dart so we don't get /path#/path.
  var start = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  if (start.isEmpty) start = '/';

  return GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const _LandingScreen(),
      ),
      GoRoute(
        path: '/f/:franchiseId',
        name: 'franchise',
        builder: (context, state) {
          final id = state.pathParameters['franchiseId'] ?? '';
          return _FranchiseGate(franchiseId: id);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Not found: ${state.uri}'))),
  );
}

class _LandingScreen extends StatelessWidget {
  const _LandingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'No restaurant selected',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Open a restaurant link or scan a QR code.\n'
                'Example: /f/{franchiseId}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Dev-only convenience — remove or gate before production polish.
              FilledButton(
                onPressed: () => context.go('/f/doughboyspizzeria'),
                child: const Text('Dev: open Doughboys'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loads franchise by path id, then shows a temporary bound home.
class _FranchiseGate extends StatefulWidget {
  const _FranchiseGate({required this.franchiseId});

  final String franchiseId;

  @override
  State<_FranchiseGate> createState() => _FranchiseGateState();
}

class _FranchiseGateState extends State<_FranchiseGate> {
  bool _loading = true;
  bool _ok = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  Future<void> _bind() async {
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final ok = await FranchiseBind.bindById(fp, widget.franchiseId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _ok = ok;
      _error = ok ? null : 'Invalid restaurant id';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_ok) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Could not open restaurant'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    return const MenuBrowseScreen();
  }
}
