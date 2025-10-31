import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Displays a shopping cart icon with a dynamic badge count.
/// Pass in a [cartItemCountStream] that emits the item count as an integer.
/// The [onPressed] callback is called when the icon is tapped.
/// [tooltip], [iconColor], [badgeColor], [iconSize] are all customizable.
class CartIconBadge extends StatelessWidget {
  final Stream<int> cartItemCountStream;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? iconColor;
  final Color? badgeColor;
  final double? iconSize;

  const CartIconBadge({
    Key? key,
    required this.cartItemCountStream,
    this.onPressed,
    this.tooltip,
    this.iconColor,
    this.badgeColor,
    this.iconSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: cartItemCountStream,
      initialData: 0,
      builder: (context, snapshot) {
        final cartItems = snapshot.data ?? 0;
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.shopping_cart,
                size: iconSize ?? DesignTokens.iconSize,
                color: iconColor ?? DesignTokens.foregroundColor,
                semanticLabel: tooltip,
              ),
              if (cartItems > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.all(DesignTokens.cartBadgePadding),
                    decoration: BoxDecoration(
                      color: badgeColor ?? DesignTokens.errorColor,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.badgeRadius),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: DesignTokens.badgeMinSize,
                      minHeight: DesignTokens.badgeMinSize,
                    ),
                    child: Text(
                      '$cartItems',
                      style: const TextStyle(
                        color: DesignTokens.foregroundColor,
                        fontSize: DesignTokens.captionFontSize,
                        fontWeight: DesignTokens.titleFontWeight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          tooltip: tooltip,
          onPressed: onPressed,
        );
      },
    );
  }
}


