import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/generated/app_localizations.dart';

/// A favorite heart button for menu items, handling loading, state, and Firestore.
class FavoriteButton extends StatefulWidget {
  final String itemId;
  final String? userId;

  /// Optionally provide the icon size (defaults to DesignTokens.iconSize)
  final double? iconSize;

  /// Optionally provide a callback when the favorite state changes.
  final void Function(bool isFavorited)? onChanged;

  const FavoriteButton({
    super.key,
    required this.itemId,
    required this.userId,
    this.iconSize,
    this.onChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isProcessing = false;

  void _toggleFavorite({
    required bool isFavorited,
    required shared.FirestoreService firestoreService,
    required AppLocalizations loc,
    required String franchiseId,
  }) async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.signInToFavoriteTooltip),
          duration: Duration(seconds: shared.DesignTokens.toastDurationSeconds),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final fid = franchiseId != 'unknown' ? franchiseId : null;
      if (isFavorited) {
        await firestoreService.removeFavoriteMenuItemForUser(
            widget.userId!, widget.itemId,
            franchiseId: fid);
        widget.onChanged?.call(false);
      } else {
        await firestoreService.addFavoriteMenuItemForUser(
            widget.userId!, widget.itemId,
            franchiseId: fid);
        widget.onChanged?.call(true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    // If not signed in, just show the disabled heart
    if (widget.userId == null) {
      return IconButton(
        icon: Icon(Icons.favorite_border,
            color: shared.UiConfig.hintTextColor,
            size: widget.iconSize ?? shared.DesignTokens.iconSize),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.signInToFavoriteTooltip),
              duration:
                  Duration(seconds: shared.DesignTokens.toastDurationSeconds),
              behavior: SnackBarBehavior.floating,
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
          width: widget.iconSize ?? shared.DesignTokens.iconSize,
          height: widget.iconSize ?? shared.DesignTokens.iconSize,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Franchise-aware + reactive favorite state via StreamBuilder (real-time from Firestore)
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;
    final fidForCall = franchiseId != 'unknown' ? franchiseId : null;

    return StreamBuilder<List<shared.MenuItem>>(
      stream: firestoreService.getFavoriteMenuItemsForUser(widget.userId!,
          franchiseId: fidForCall),
      builder: (context, snapshot) {
        final isFavorited = snapshot.hasData
            ? snapshot.data!.any((mi) => mi.id == widget.itemId)
            : false;
        return IconButton(
          icon: Icon(
            isFavorited ? Icons.favorite : Icons.favorite_border,
            color: isFavorited
                ? shared.UiConfig.accentColor
                : shared.UiConfig.hintTextColor,
            size: widget.iconSize ?? shared.DesignTokens.iconSize,
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
                    franchiseId: franchiseId,
                  ),
        );
      },
    );
  }
}
