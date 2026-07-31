import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  bool _isClaiming = false;
  String? _claimError;

  // Basic available rewards foundation (using shared LoyaltyReward model)
  List<shared.LoyaltyReward> _getAvailableRewards(
      int points, AppLocalizations loc) {
    final rewards = <shared.LoyaltyReward>[];
    if (points >= 100) {
      rewards.add(shared.LoyaltyReward(name: 'Free Drink', points: 100));
    }
    if (points >= 250) {
      rewards.add(shared.LoyaltyReward(name: 'Free Appetizer', points: 250));
    }
    if (points >= 500) {
      rewards.add(shared.LoyaltyReward(name: 'Free Medium Pizza', points: 500));
    }
    return rewards;
  }

  Future<void> _handleClaim(shared.LoyaltyReward reward, shared.Loyalty current,
      AppLocalizations loc) async {
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
      // Real-time stream will reflect update; show immediate feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.rewardClaimedSuccess),
            duration:
                Duration(seconds: shared.DesignTokens.toastDurationSeconds),
            backgroundColor: Theme.of(context).colorScheme.surface,
            behavior: SnackBarBehavior.floating,
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

        final authService =
            Provider.of<shared.AuthService>(context, listen: false);
        final firestoreService =
            Provider.of<shared.FirestoreService>(context, listen: false);
        final uid = authService.currentUser?.id;
        final fid = franchiseProvider.currentFranchiseId;

        return Scaffold(
          backgroundColor: shared.UiConfig.backgroundColorDark,
          appBar: FranchiseAppBar(
            title: loc.loyaltyAndRewards,
            showLogo: true,
            logoUrl: shared.UiConfig.currentLogoUrl,
            logoAsset: shared.BrandingConfig.appBarLogoAsset,
            centerTitle: true,
          ),
          body: SafeArea(
            bottom: true,
            child: Padding(
              padding: shared.UiConfig.defaultScreenPadding,
              child: (uid != null && franchiseProvider.hasValidFranchise)
                  ? StreamBuilder<Map<String, dynamic>?>(
                      stream: firestoreService.franchiseProfileStream(uid, fid),
                      builder: (context, profileSnap) {
                        if (profileSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (profileSnap.hasError) {
                          return Center(
                            child: Text(
                              loc.loyaltyErrorLoading,
                              style: shared.UiConfig.bodyStyle.copyWith(
                                  color: shared.UiConfig.errorTextColor),
                            ),
                          );
                        }
                        final profile = profileSnap.data ?? {};
                        final map = (profile['loyalty'] as Map?)
                            ?.cast<String, dynamic>();
                        final loyalty = map == null
                            ? shared.Loyalty()
                            : shared.Loyalty(
                                points: (map['points'] as num?)?.toInt() ?? 0,
                                redeemedRewards:
                                    (map['redeemedRewards'] as List<dynamic>? ??
                                            [])
                                        .map((item) {
                                  final r = item as Map<String, dynamic>;
                                  return shared.LoyaltyReward(
                                    name:
                                        r['rewardId'] ?? r['name'] ?? 'Reward',
                                    points: (r['points'] as num?)?.toInt() ?? 0,
                                  );
                                }).toList(),
                                transactions: map['transactions'] ?? const [],
                              );
                        if (loyalty.points == 0 &&
                            loyalty.redeemedRewards.isEmpty) {
                          return _buildEmptyState(loc);
                        }
                        return _buildLoyaltyContent(loyalty, loc);
                      },
                    )
                  : _buildEmptyState(loc),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
        ),
        elevation: shared.DesignTokens.cardElevation,
        child: Padding(
          padding: shared.UiConfig.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.card_giftcard,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
                semanticLabel: 'loyalty',
              ),
              const SizedBox(height: 16),
              Text(
                loc.loyaltyNoActivityTitle,
                style: TextStyle(
                  fontFamily: shared.DesignTokens.fontFamily,
                  fontSize: shared.DesignTokens.titleFontSize,
                  fontWeight: shared.UiConfig.fontWeightBold,
                  color: shared.UiConfig.textColorDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.loyaltyNoActivitySubtitle,
                style: TextStyle(
                  fontFamily: shared.DesignTokens.fontFamily,
                  fontSize: shared.DesignTokens.bodyFontSize,
                  fontWeight: shared.UiConfig.normal,
                  color: shared.UiConfig.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.local_pizza_outlined),
                label: Text(loc.loyaltyOrderNow),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(shared.DesignTokens.buttonRadius),
                  ),
                  padding: shared.UiConfig.defaultPadding,
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
    final available = _getAvailableRewards(pts, loc);

    return ListView(
      children: [
        Card(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
          ),
          elevation: shared.DesignTokens.cardElevation,
          child: Padding(
            padding: shared.UiConfig.cardPadding,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Theme.of(context).colorScheme.primary,
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
                              fontWeight: shared.UiConfig.fontWeightBold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.loyaltyLevel(rankLevel),
                            style: TextStyle(
                              fontFamily: shared.DesignTokens.fontFamily,
                              fontSize: shared.DesignTokens.bodyFontSize,
                              fontWeight: shared.UiConfig.fontWeightNormal,
                              color: shared.UiConfig.secondaryTextColor,
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
                            fontWeight: shared.UiConfig.fontWeightBold,
                            color: shared.UiConfig.textColorDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.loyaltyLastRedeemed,
                          style: TextStyle(
                            fontFamily: shared.DesignTokens.fontFamily,
                            fontSize: shared.DesignTokens.captionFontSize,
                            fontWeight: shared.UiConfig.fontWeightNormal,
                            color: shared.UiConfig.secondaryTextColor,
                          ),
                        ),
                        Text(
                          df.format(DateTime.now()),
                          style: TextStyle(
                            fontFamily: shared.DesignTokens.fontFamily,
                            fontSize: shared.DesignTokens.captionFontSize,
                            fontWeight: shared.UiConfig.fontWeightNormal,
                            color: shared.UiConfig.secondaryTextColor,
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
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.loyaltyNextReward(100 - (pts % 100)),
                  style: TextStyle(
                    fontFamily: shared.DesignTokens.fontFamily,
                    fontSize: shared.DesignTokens.captionFontSize,
                    fontWeight: shared.UiConfig.normal,
                    color: shared.UiConfig.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Basic available rewards display foundation
        if (available.isNotEmpty) ...[
          Text(
            'Available Rewards',
            style: TextStyle(
              fontFamily: shared.DesignTokens.fontFamily,
              fontSize: shared.DesignTokens.titleFontSize,
              fontWeight: shared.UiConfig.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...available
              .map((r) => _buildRewardCard(r, data, loc, isAvailable: true)),
          const SizedBox(height: 16),
        ],
        Text(
          loc.loyaltyYourRewards,
          style: TextStyle(
            fontFamily: shared.DesignTokens.fontFamily,
            fontSize: shared.DesignTokens.titleFontSize,
            fontWeight: shared.UiConfig.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (data.redeemedRewards.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No rewards redeemed yet.',
              style: TextStyle(
                fontFamily: shared.DesignTokens.fontFamily,
                fontSize: shared.DesignTokens.captionFontSize,
                color: shared.UiConfig.secondaryTextColor,
              ),
            ),
          )
        else
          ...data.redeemedRewards
              .map((reward) => _buildRewardCard(reward, data, loc)),
        if (_claimError != null) ...[
          const SizedBox(height: 8),
          Text(
            _claimError!,
            style: TextStyle(
              fontFamily: shared.DesignTokens.fontFamily,
              fontSize: shared.DesignTokens.bodyFontSize,
              fontWeight: shared.UiConfig.normal,
              color: shared.UiConfig.errorTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildRewardCard(
      shared.LoyaltyReward reward, shared.Loyalty data, AppLocalizations loc,
      {bool isAvailable = false}) {
    final claimed = !isAvailable;
    final df = DateFormat.yMd();

    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
      ),
      elevation: shared.DesignTokens.cardElevation,
      child: Padding(
        padding: shared.UiConfig.cardPadding,
        child: Row(
          children: [
            Icon(
              claimed ? Icons.check_circle : Icons.redeem,
              color: claimed
                  ? shared.UiConfig.successColor
                  : shared.UiConfig.secondaryColor,
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
                      fontWeight: shared.UiConfig.normal,
                      color: shared.UiConfig.textColor,
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
                      fontWeight: shared.UiConfig.normal,
                      color: shared.UiConfig.secondaryTextColor,
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
                        color: shared.UiConfig.successColor,
                        fontSize: shared.DesignTokens.captionFontSize,
                        fontWeight: shared.UiConfig.normal,
                        fontFamily: shared.DesignTokens.fontFamily,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: !_isClaiming
                        ? () => _handleClaim(reward, data, loc)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: shared.UiConfig.foregroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            shared.DesignTokens.buttonRadius),
                      ),
                      padding: shared.UiConfig.defaultPadding,
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
