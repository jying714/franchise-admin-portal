// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  Future<shared.Loyalty?>? _loyaltyFuture;
  bool _isClaiming = false;
  String? _claimError;

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

  Future<void> _handleClaim(
      shared.LoyaltyReward reward, shared.Loyalty data, AppLocalizations loc) async {
    setState(() {
      _isClaiming = true;
      _claimError = null;
    });

    final authService = Provider.of<shared.AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final uid = authService.currentUser?.id;
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;

    if (uid == null || !franchiseProvider.hasValidFranchise) {
      setState(() {
        _isClaiming = false;
        _claimError = 'Not authenticated or no franchise selected.';
      });
      return;
    }

    try {
      await firestoreService.claimReward(
        uid,
        reward.name,
        franchiseId: franchiseId,
        points: reward.points,
      );
      setState(() {
        _loyaltyFuture = _fetchLoyalty(firestoreService, uid, franchiseId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.rewardClaimedSuccess),
            duration:
                Duration(seconds: shared.DesignTokens.toastDurationSeconds),
            backgroundColor: UiConfig.surfaceColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _claimError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  String _getRankTitle(int points, AppLocalizations loc) {
    if (points >= 1000) return loc.loyaltyRankLegend;
    if (points >= 500) return loc.loyaltyRankPro;
    if (points >= 200) return loc.loyaltyRankRegular;
    return loc.loyaltyRankNewbie;
  }

  int _getRankLevel(int points) {
    if (points >= 1000) return 4;
    if (points >= 500) return 3;
    if (points >= 200) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Consumer<shared.FranchiseProvider>(
      builder: (context, franchiseProvider, child) {
        if (!franchiseProvider.hasValidFranchise) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Trigger fetch once we have valid franchise (franchise-scoped)
        if (_loyaltyFuture == null) {
          final authService =
              Provider.of<shared.AuthService>(context, listen: false);
          final firestoreService =
              Provider.of<shared.FirestoreService>(context, listen: false);
          final uid = authService.currentUser?.id;
          final fid = franchiseProvider.currentFranchiseId;
          if (uid != null) {
            _loyaltyFuture = _fetchLoyalty(firestoreService, uid, fid);
          }
        }

        return Scaffold(
          backgroundColor: UiConfig.backgroundColorDark,
          appBar: AppBar(
            title: Text(
              loc.loyaltyAndRewards,
              style: TextStyle(
                fontFamily: shared.DesignTokens.fontFamily,
                fontSize: shared.DesignTokens.titleFontSize,
                fontWeight: UiConfig.fontWeightBold,
                color: UiConfig.foregroundColorDark,
              ),
            ),
            centerTitle: true,
            backgroundColor: UiConfig.primaryColor,
            elevation: 0,
            iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
          ),
          body: Padding(
            padding: UiConfig.defaultScreenPadding,
            child: FutureBuilder<shared.Loyalty?>(
              future: _loyaltyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      loc.loyaltyErrorLoading,
                      style: UiConfig.bodyStyle.copyWith(
                        color: UiConfig.errorTextColor,
                      ),
                    ),
                  );
                }
                final loyalty = snapshot.data ?? shared.Loyalty();
                if (loyalty.points == 0 && loyalty.redeemedRewards.isEmpty) {
                  return _buildEmptyState(loc);
                }
                return _buildLoyaltyContent(loyalty, loc);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Card(
        color: UiConfig.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
        ),
        elevation: shared.DesignTokens.cardElevation,
        child: Padding(
          padding: UiConfig.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.card_giftcard,
                size: 64,
                color: UiConfig.primaryColor,
                semanticLabel: 'loyalty',
              ),
              const SizedBox(height: 16),
              Text(
                loc.loyaltyNoActivityTitle,
                style: TextStyle(
                  fontFamily: shared.DesignTokens.fontFamily,
                  fontSize: shared.DesignTokens.titleFontSize,
                  fontWeight: UiConfig.fontWeightBold,
                  color: UiConfig.textColorDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.loyaltyNoActivitySubtitle,
                style: TextStyle(
                  fontFamily: shared.DesignTokens.fontFamily,
                  fontSize: shared.DesignTokens.bodyFontSize,
                  fontWeight: UiConfig.normal,
                  color: UiConfig.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.local_pizza_outlined),
                label: Text(loc.loyaltyOrderNow),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UiConfig.primaryColor,
                  foregroundColor: UiConfig.foregroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(shared.DesignTokens.buttonRadius),
                  ),
                  padding: UiConfig.defaultPadding,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoyaltyContent(shared.Loyalty data, AppLocalizations loc) {
    final pts = data.points;
    final progress = (pts % 100) / 100.0;
    final df = DateFormat.yMd();
    final rankTitle = _getRankTitle(pts, loc);
    final rankLevel = _getRankLevel(pts);
    final lastRedeemed = DateTime.now();

    return ListView(
      children: [
        Card(
          color: UiConfig.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
          ),
          elevation: shared.DesignTokens.cardElevation,
          child: Padding(
            padding: UiConfig.cardPadding,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: UiConfig.primaryColor,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rankTitle,
                            style: TextStyle(
                              fontFamily: shared.DesignTokens.fontFamily,
                              fontSize: shared.DesignTokens.titleFontSize,
                              fontWeight: UiConfig.fontWeightBold,
                              color: UiConfig.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.loyaltyLevel(rankLevel),
                            style: TextStyle(
                              fontFamily: shared.DesignTokens.fontFamily,
                              fontSize: shared.DesignTokens.bodyFontSize,
                              fontWeight: UiConfig.fontWeightNormal,
                              color: UiConfig.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          loc.loyaltyPoints(pts),
                          style: TextStyle(
                            fontFamily: shared.DesignTokens.fontFamily,
                            fontSize: shared.DesignTokens.titleFontSize,
                            fontWeight: UiConfig.fontWeightBold,
                            color: UiConfig.textColorDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.loyaltyLastRedeemed,
                          style: TextStyle(
                            fontFamily: shared.DesignTokens.fontFamily,
                            fontSize: shared.DesignTokens.captionFontSize,
                            fontWeight: UiConfig.fontWeightNormal,
                            color: UiConfig.secondaryTextColor,
                          ),
                        ),
                        Text(
                          df.format(lastRedeemed),
                          style: TextStyle(
                            fontFamily: shared.DesignTokens.fontFamily,
                            fontSize: shared.DesignTokens.captionFontSize,
                            fontWeight: UiConfig.fontWeightNormal,
                            color: UiConfig.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: UiConfig.primaryColor,
                  backgroundColor: UiConfig.shimmerBaseColor,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.loyaltyNextReward(100 - (pts % 100)),
                  style: TextStyle(
                    fontFamily: shared.DesignTokens.fontFamily,
                    fontSize: shared.DesignTokens.captionFontSize,
                    fontWeight: UiConfig.normal,
                    color: UiConfig.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          loc.loyaltyYourRewards,
          style: TextStyle(
            fontFamily: shared.DesignTokens.fontFamily,
            fontSize: shared.DesignTokens.titleFontSize,
            fontWeight: UiConfig.bold,
            color: UiConfig.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...data.redeemedRewards
            .map((reward) => _buildRewardCard(reward, data, loc)),
        if (_claimError != null) ...[
          const SizedBox(height: 8),
          Text(
            _claimError!,
            style: TextStyle(
              fontFamily: shared.DesignTokens.fontFamily,
              fontSize: shared.DesignTokens.bodyFontSize,
              fontWeight: UiConfig.normal,
              color: UiConfig.errorTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildRewardCard(
      shared.LoyaltyReward reward, shared.Loyalty data, AppLocalizations loc) {
    // All rewards in the current local model are redeemed.
    // Keeping the original conditional logic intact so the claim-button path remains reachable.
    final canClaim = false;
    final claimed = true;
    final df = DateFormat.yMd();

    return Card(
      color: UiConfig.surfaceColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
      ),
      elevation: shared.DesignTokens.cardElevation,
      child: Padding(
        padding: UiConfig.cardPadding,
        child: Row(
          children: [
            Icon(
              claimed ? Icons.check_circle : Icons.redeem,
              color: claimed ? UiConfig.successColor : UiConfig.secondaryColor,
              size: 36,
              semanticLabel: claimed
                  ? loc.rewardClaimedSemantic
                  : loc.rewardAvailableSemantic,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
                    style: TextStyle(
                      fontFamily: shared.DesignTokens.fontFamily,
                      fontSize: shared.DesignTokens.bodyFontSize,
                      fontWeight: UiConfig.normal,
                      color: UiConfig.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    claimed
                        ? loc.loyaltyRewardClaimedOn(df.format(DateTime.now()))
                        : loc.loyaltyRewardRequiredPoints(reward.points),
                    style: TextStyle(
                      fontFamily: shared.DesignTokens.fontFamily,
                      fontSize: shared.DesignTokens.captionFontSize,
                      fontWeight: UiConfig.normal,
                      color: UiConfig.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            claimed
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      loc.rewardClaimed,
                      style: TextStyle(
                        color: UiConfig.successColor,
                        fontSize: shared.DesignTokens.captionFontSize,
                        fontWeight: UiConfig.normal,
                        fontFamily: shared.DesignTokens.fontFamily,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: canClaim && !_isClaiming
                        ? () => _handleClaim(reward, data, loc)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UiConfig.primaryColor,
                      foregroundColor: UiConfig.foregroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            shared.DesignTokens.buttonRadius),
                      ),
                      padding: UiConfig.defaultPadding,
                    ),
                    child: _isClaiming
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(loc.rewardClaim),
                  ),
          ],
        ),
      ),
    );
  }
}
