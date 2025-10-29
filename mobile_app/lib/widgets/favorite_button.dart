import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A favorite heart button for menu items, handling loading, state, and Firestore.
class FavoriteButton extends StatefulWidget {
  final String itemId;
  final String? userId;

  /// Optionally provide the icon size (defaults to DesignTokens.iconSize)
  final double? iconSize;

  /// Optionally provide a callback when the favorite state changes.
  final void Function(bool isFavorited)? onChanged;

  const FavoriteButton({
    Key? key,
    required this.itemId,
    required this.userId,
    this.iconSize,
    this.onChanged,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isProcessing = false;

  void _toggleFavorite(
      {required bool isFavorited,
      required FirestoreService firestoreService,
      required AppLocalizations loc}) async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.signInToFavoriteTooltip),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      if (isFavorited) {
        await firestoreService.removeFavoriteMenuItemForUser(
            widget.userId!, widget.itemId);
        widget.onChanged?.call(false);
      } else {
        await firestoreService.addFavoriteMenuItemForUser(
            widget.userId!, widget.itemId);
        widget.onChanged?.call(true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    // If not signed in, just show the disabled heart
    if (widget.userId == null) {
      return IconButton(
        icon: Icon(Icons.favorite_border,
            color: DesignTokens.hintTextColor,
            size: widget.iconSize ?? DesignTokens.iconSize),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.signInToFavoriteTooltip),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        tooltip: loc.signInToFavoriteTooltip,
      );
    }

    // If in processing, show spinner
    if (_isProcessing) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: widget.iconSize ?? DesignTokens.iconSize,
          height: widget.iconSize ?? DesignTokens.iconSize,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Listen to favorite state via StreamBuilder
    return StreamBuilder<List<MenuItem>>(
      stream: firestoreService.getFavoriteMenuItemsForUser(widget.userId!),
      builder: (context, snapshot) {
        final isFavorited = snapshot.hasData
            ? snapshot.data!.any((mi) => mi.id == widget.itemId)
            : false;
        return IconButton(
          icon: Icon(
            isFavorited ? Icons.favorite : Icons.favorite_border,
            color: isFavorited
                ? DesignTokens.accentColor
                : DesignTokens.hintTextColor,
            size: widget.iconSize ?? DesignTokens.iconSize,
          ),
          tooltip: widget.userId == null
              ? loc.signInToFavoriteTooltip
              : isFavorited
                  ? loc.removeFromFavoritesTooltip
                  : loc.addToFavoritesTooltip,
          onPressed: _isProcessing
              ? null
              : () => _toggleFavorite(
                    isFavorited: isFavorited,
                    firestoreService: firestoreService,
                    loc: loc,
                  ),
        );
      },
    );
  }
}
