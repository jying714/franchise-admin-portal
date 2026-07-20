import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/features/loyalty/loyalty_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Reusable loyalty points summary widget for Profile and other screens.
/// Franchise-scoped via FranchiseProvider. Taps through to full LoyaltyScreen.
/// P2: Colors (primary) now fully dynamic via shared.UiConfig (driven by FranchiseProvider branding).
/// Uses only public shared_core barrel.
class LoyaltyPointsWidget extends StatefulWidget {
  const LoyaltyPointsWidget({super.key});

  @override
  State<LoyaltyPointsWidget> createState() => _LoyaltyPointsWidgetState();
}

class _LoyaltyPointsWidgetState extends State<LoyaltyPointsWidget> {
  // Real-time reactive via franchiseProfileStream (no more one-shot Future)

  String _getTierTitle(int points, AppLocalizations loc) {
    if (points >= 1000) return loc.loyaltyRankLegend;
    if (points >= 500) return loc.loyaltyRankPro;
    if (points >= 200) return loc.loyaltyRankRegular;
    return loc.loyaltyRankNewbie;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final authService = Provider.of<shared.AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final uid = authService.currentUser?.id;
    final fid = franchiseProvider.currentFranchiseId;

    if (uid == null || !franchiseProvider.hasValidFranchise) {
      return const SizedBox.shrink();
    }

    // Real-time reactive loyalty summary (franchise-scoped profile stream)
    return StreamBuilder<Map<String, dynamic>?>(
      stream: firestoreService.franchiseProfileStream(uid, fid),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? {};
        final map = (profile['loyalty'] as Map?)?.cast<String, dynamic>();
        final loyalty = map == null
            ? shared.Loyalty()
            : shared.Loyalty(
                points: (map['points'] as num?)?.toInt() ?? 0,
                redeemedRewards: const [],
                transactions: const [],
              );
        final pts = loyalty.points;
        final tier = _getTierTitle(pts, loc);
        final progress = (pts % 100) / 100.0;

        return Card(
          color: shared.UiConfig.surfaceColor,
          elevation: shared.DesignTokens.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoyaltyScreen()),
              );
            },
            child: Padding(
              padding: shared.UiConfig.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: shared.UiConfig.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier,
                              style: shared.UiConfig.bodyBoldStyle.copyWith(
                                color: shared.UiConfig.primaryColor,
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
                              style: shared.UiConfig.captionStyle,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            loc.loyaltyPoints(pts),
                            style: shared.UiConfig.bodyBoldStyle.copyWith(
                              fontSize: shared.DesignTokens.titleFontSize,
                            ),
                          ),
                          Text(
                            'Tap for details',
                            style: shared.UiConfig.captionStyle.copyWith(
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
                    backgroundColor: shared.UiConfig.shimmerBaseColor,
                    color: shared.UiConfig.primaryColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.loyaltyNextReward(100 - (pts % 100)),
                    style: shared.UiConfig.captionStyle,
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
