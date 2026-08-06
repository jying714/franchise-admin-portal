// customer_web/lib/widgets/storefront_shell.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../features/auth/sign_in_screen.dart';
import '../features/storefront/storefront_landing.dart';
import '../features/orders/order_history_screen.dart';

/// Wave 1 shell: floating slim top bar + nested navigator body.
/// No full AppBar. Cart lives in the home menu section (in-place swap).
class StorefrontShell extends StatefulWidget {
  const StorefrontShell({super.key});

  /// Home attaches this key to the Menu section so Order now / Order online can scroll to it.
  static final GlobalKey menuSectionKey = GlobalKey();

  @override
  State<StorefrontShell> createState() => _StorefrontShellState();
}

class _StorefrontShellState extends State<StorefrontShell> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  /// Home registers this so the floating "Order now" can scroll to the menu.
  static final GlobalKey menuSectionKey = GlobalKey();

  void _scrollToMenu() {
    final ctx = StorefrontShell.menuSectionKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<shared.FranchiseProvider>();
    final name = fp.currentAppName;
    final logoUrl = fp.currentLogoUrl;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // No AppBar — floating bar overlays the body
      body: Stack(
        children: [
          // Main content (home under nested navigator)
          Navigator(
            key: _navKey,
            onGenerateInitialRoutes: (navigator, initialRoute) {
              return [
                MaterialPageRoute<void>(
                  builder: (_) => const StorefrontLanding(),
                  settings: const RouteSettings(name: '/'),
                ),
              ];
            },
            onGenerateRoute: (settings) => null,
          ),

          // Floating slim top bar (~half typical AppBar height)
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 280,
                    maxWidth: 420,
                  ),
                  child: Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(28),
                    color: scheme.surface.withValues(alpha: 0.96),
                    child: SizedBox(
                      height: 44,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            if (logoUrl != null && logoUrl.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: logoUrl,
                                  height: 28,
                                  width: 28,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) =>
                                      const Icon(Icons.storefront, size: 22),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _scrollToMenu,
                              child: const Text('Order now'),
                            ),
                            Consumer<User?>(
                              builder: (context, user, _) {
                                if (user == null) {
                                  return IconButton(
                                    tooltip: 'Sign in',
                                    icon: const Icon(Icons.person_outline),
                                    iconSize: 22,
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const SignInScreen(),
                                        ),
                                      );
                                    },
                                  );
                                }
                                return PopupMenuButton<String>(
                                  tooltip: 'Account',
                                  onSelected: (value) async {
                                    if (value == 'orders') {
                                      _navKey.currentState?.push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const OrderHistoryScreen(),
                                        ),
                                      );
                                    } else if (value == 'signOut') {
                                      await FirebaseAuth.instance.signOut();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Signed out'),
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem<String>(
                                      enabled: false,
                                      child: Text(
                                        user.email ?? 'Signed in',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'orders',
                                      child: Text('My orders'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'signOut',
                                      child: Text('Sign out'),
                                    ),
                                  ],
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Icon(Icons.person, size: 22),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
