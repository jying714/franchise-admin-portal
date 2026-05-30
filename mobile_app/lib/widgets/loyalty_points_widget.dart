import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/features/loyalty/loyalty_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Reusable loyalty points summary widget for Profile and other screens.
/// Franchise-scoped via FranchiseProvider. Taps through to full LoyaltyScreen.
/// P2: Colors (primary) now fully dynamic via UiConfig (driven by FranchiseProvider branding).
/// Uses only public shared_core barrel.
class LoyaltyPointsWidget extends StatefulWidget {
  const LoyaltyPointsWidget({super.key});

  @override
  State<LoyaltyPointsWidget> createState() => _LoyaltyPointsWidgetState();
}

class _LoyaltyPointsWidgetState extends State<LoyaltyPointsWidget> {
  Future<shared.Loyalty?>? _loyaltyFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loyaltyFuture == null) {
      final authService =
          Provider.of<shared.AuthService>(context, listen: false);
      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final franchiseProvider =
          Provider.of<shared.FranchiseProvider>(context, listen: false);

      final uid = authService.currentUser?.id;
      final franchiseId = franchiseProvider.currentFranchiseId;

      if (uid != null && franchiseProvider.hasValidFranchise) {
        _loyaltyFuture = _fetchLoyalty(firestoreService, uid, franchiseId);
      }
    }
  }

  Future<shared.Loyalty?> _fetchLoyalty(
    shared.FirestoreService fs,
    String uid,
    String franchiseId,
  ) async {
    final map = await fs.getLoyaltyForUser(uid, franchiseId: franchiseId);
    if (map == null) return shared.Loyalty();

    final redeemedList =
        (map['redeemedRewards'] as List<dynamic>? ?? []).map((item) {
      final r = item as Map<String, dynamic>;
      return shared.LoyaltyReward(
        name: r['rewardId'] ?? r['name'] ?? 'Reward',
        points: (r['points'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return shared.Loyalty(
      points: (map['points'] as num?)?.toInt() ?? 0,
      redeemedRewards: redeemedList,
      transactions: map['transactions'] ?? const [],
    );
  }

  String _getTierTitle(int points, AppLocalizations loc) {
    if (points >= 1000) return loc.loyaltyRankLegend;
    if (points >= 500) return loc.loyaltyRankPro;
    if (points >= 200) return loc.loyaltyRankRegular;
    return loc.loyaltyRankNewbie;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_loyaltyFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<shared.Loyalty?>(
      future: _loyaltyFuture,
      builder: (context, snapshot) {
        final loyalty = snapshot.data ?? shared.Loyalty();
        final pts = loyalty.points;
        final tier = _getTierTitle(pts, loc);
        final progress = (pts % 100) / 100.0;

        return Card(
          color: UiConfig.surfaceColor,
          elevation: shared.DesignTokens.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(shared.DesignTokens.cardRadius),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(shared.DesignTokens.cardRadius),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoyaltyScreen()),
              );
            },
            child: Padding(
              padding: UiConfig.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: UiConfig.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier,
                              style: UiConfig.bodyBoldStyle.copyWith(
                                color: UiConfig.primaryColor,
                                fontSize: shared.DesignTokens.bodyFontSize,
                              ),
                            ),
                            Text(
                              loc.loyaltyLevel(pts >= 1000
                                  ? 4
                                  : pts >= 500
                                      ? 3
                                      : pts >= 200
                                          ? 2
                                          : 1),
                              style: UiConfig.captionStyle,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            loc.loyaltyPoints(pts),
                            style: UiConfig.bodyBoldStyle.copyWith(
                              fontSize: shared.DesignTokens.titleFontSize,
                            ),
                          ),
                          Text(
                            'Tap for details',
                            style: UiConfig.captionStyle.copyWith(
                              fontSize: shared.DesignTokens.captionFontSize - 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: UiConfig.shimmerBaseColor,
                    color: UiConfig.primaryColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.loyaltyNextReward(100 - (pts % 100)),
                    style: UiConfig.captionStyle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
