import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

// P1 Batch 2: Duplicated widgets cleanup (Address/ + categories/ + header/)

class CartIconBadge extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? tooltip;

  const CartIconBadge({
    super.key,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<shared.FranchiseProvider>(
      builder: (context, franchiseProvider, child) {
        // No franchise → plain icon (no stream).
        if (!franchiseProvider.hasValidFranchise) {
          return IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: onPressed,
            tooltip: tooltip,
          );
        }

        // Signed-out browse: cart is auth-scoped; never call Firestore with empty userId.
        final userId = shared.FirebaseAuth.instance.currentUser?.uid;
        if (userId == null || userId.isEmpty) {
          return IconButton(
            icon: Icon(
              Icons.shopping_cart_outlined,
              size: shared.DesignTokens.iconSize,
              color: shared.UiConfig.foregroundColor,
            ),
            onPressed: onPressed,
            tooltip: tooltip ?? 'Cart',
          );
        }

        return StreamBuilder<int>(
          stream: Provider.of<shared.FirestoreService>(context, listen: false)
              .getCartItemCountStream(
            userId,
            franchiseId: franchiseProvider.currentFranchiseId,
          ),
          initialData: 0,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;

            return IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: shared.DesignTokens.iconSize,
                    color: shared.UiConfig.foregroundColor,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: shared.UiConfig.errorColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: tooltip ?? 'Cart',
              onPressed: onPressed,
            );
          },
        );
      },
    );
  }
}
