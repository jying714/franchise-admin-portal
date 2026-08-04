// customer_web/lib/widgets/branding_shell.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../features/auth/sign_in_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/orders/order_history_screen.dart';

Color hexToColor(String hex, {Color fallback = const Color(0xFFE31837)}) {
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return fallback;
  final value = int.tryParse(h, radix: 16);
  if (value == null) return fallback;
  return Color(value);
}

ThemeData themeFromFranchise(shared.FranchiseProvider fp) {
  final primary = hexToColor(fp.currentPrimaryColorHex);
  final secondary = hexToColor(
    fp.currentSecondaryColorHex,
    fallback: const Color(0xFFFFD700),
  );

  // Parchment cream — pairs with Dough Boys red/green without competing.
  const scaffoldBg = Color(0xFFFAF7F2);

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: scaffoldBg,
    canvasColor: scaffoldBg,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.black87,
      surface: Colors.white,
      onSurface: Colors.black87,
      surfaceContainerLowest: scaffoldBg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    ),
  );
}

/// Thin branded chrome for bound franchise screens.
class BrandingShell extends StatelessWidget {
  const BrandingShell({super.key, required this.child, this.actions});

  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<shared.FranchiseProvider>();
    final name = fp.currentAppName;
    final logoUrl = fp.currentLogoUrl;

    return Scaffold(
      appBar: AppBar(
        title: Row(
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
                      const Icon(Icons.storefront, size: 24),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cart',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CartScreen()),
              );
            },
          ),
          Consumer<User?>(
            builder: (context, user, _) {
              if (user == null) {
                return IconButton(
                  tooltip: 'Sign in',
                  icon: const Icon(Icons.person_outline),
                  onPressed: () {
                    Navigator.of(context).push(
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
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    );
                  } else if (value == 'signOut') {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Signed out')));
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      user.email ?? 'Signed in',
                      style: Theme.of(context).textTheme.bodySmall,
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
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.person),
                ),
              );
            },
          ),
          ...?actions,
        ],
      ),
      body: child,
    );
  }
}
