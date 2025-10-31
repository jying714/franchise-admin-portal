// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:franchise_mobile_app/core/models/loyalty.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  late FirestoreService _firestoreService;
  Future<Loyalty?>? _loyaltyFuture;
  bool _isClaiming = false;
  String? _claimError;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final uid = _firestoreService.auth.currentUser?.uid;
      if (uid != null) {
        _loyaltyFuture = _fetchLoyalty(uid);
      }
      _initialized = true;
    }
  }

  Future<Loyalty?> _fetchLoyalty(String uid) async {
    final user = await _firestoreService.getUser(uid);
    final Loyalty? result = user?.loyalty;
    return result;
  }

  Future<void> _handleClaim(
      LoyaltyReward reward, Loyalty data, AppLocalizations loc) async {
    setState(() {
      _isClaiming = true;
      _claimError = null;
    });

    final uid = _firestoreService.auth.currentUser!.uid;
    try {
      await _firestoreService.claimReward(uid, reward);
      setState(() {
        _loyaltyFuture = _fetchLoyalty(uid);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.rewardClaimedSuccess),
            duration: DesignTokens.toastDuration,
            backgroundColor: DesignTokens.surfaceColor,
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

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.loyaltyAndRewards,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.titleFontSize,
            fontWeight: DesignTokens.titleFontWeight,
            color: DesignTokens.foregroundColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: DesignTokens.primaryColor,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(DesignTokens.cardRadius),
          ),
        ),
      ),
      body: Padding(
        padding: DesignTokens.gridPadding,
        child: FutureBuilder<Loyalty?>(
          future: _loyaltyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  loc.loyaltyErrorLoading,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.bodyFontSize,
                    fontWeight: DesignTokens.bodyFontWeight,
                    color: DesignTokens.errorTextColor,
                  ),
                ),
              );
            }
            final loyalty = snapshot.data;
            if (loyalty == null ||
                (loyalty.points == 0 && loyalty.redeemedRewards.isEmpty)) {
              return _buildEmptyState(loc);
            }
            return _buildLoyaltyContent(loyalty, loc);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Card(
        color: DesignTokens.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        elevation: DesignTokens.cardElevation,
        child: Padding(
          padding: DesignTokens.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.card_giftcard,
                size: 64,
                color: DesignTokens.primaryColor,
                semanticLabel: 'loyalty', // For accessibility
              ),
              const SizedBox(height: 16),
              Text(
                loc.loyaltyNoActivityTitle,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.titleFontSize,
                  fontWeight: DesignTokens.titleFontWeight,
                  color: DesignTokens.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.loyaltyNoActivitySubtitle,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.bodyFontSize,
                  fontWeight: DesignTokens.bodyFontWeight,
                  color: DesignTokens.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.local_pizza_outlined),
                label: Text(loc.loyaltyOrderNow),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryColor,
                  foregroundColor: DesignTokens.foregroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                  padding: DesignTokens.buttonPadding,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoyaltyContent(Loyalty data, AppLocalizations loc) {
    final pts = data.points;
    final progress = (pts % 100) / 100.0;
    final df = DateFormat.yMd();
    final rankTitle = _getRankTitle(pts, loc);
    final rankLevel = _getRankLevel(pts);

    return ListView(
      children: [
        Card(
          color: DesignTokens.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          elevation: DesignTokens.cardElevation,
          child: Padding(
            padding: DesignTokens.cardPadding,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: DesignTokens.primaryColor,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rankTitle,
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: DesignTokens.titleFontSize,
                              fontWeight: DesignTokens.titleFontWeight,
                              color: DesignTokens.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.loyaltyLevel(rankLevel),
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: DesignTokens.bodyFontSize,
                              fontWeight: DesignTokens.bodyFontWeight,
                              color: DesignTokens.secondaryTextColor,
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
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.titleFontSize,
                            fontWeight: DesignTokens.titleFontWeight,
                            color: DesignTokens.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.loyaltyLastRedeemed,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.captionFontSize,
                            fontWeight: DesignTokens.bodyFontWeight,
                            color: DesignTokens.secondaryTextColor,
                          ),
                        ),
                        Text(
                          df.format(data.lastRedeemed),
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.captionFontSize,
                            fontWeight: DesignTokens.bodyFontWeight,
                            color: DesignTokens.secondaryTextColor,
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
                  color: DesignTokens.primaryColor,
                  backgroundColor: DesignTokens.shimmerBaseColor,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.loyaltyNextReward(100 - (pts % 100)),
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.captionFontSize,
                    fontWeight: DesignTokens.bodyFontWeight,
                    color: DesignTokens.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          loc.loyaltyYourRewards,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.titleFontSize,
            fontWeight: DesignTokens.titleFontWeight,
            color: DesignTokens.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...data.redeemedRewards
            .map((reward) => _buildRewardCard(reward, data, loc)),
        if (_claimError != null) ...[
          const SizedBox(height: 8),
          Text(
            _claimError!,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.bodyFontSize,
              fontWeight: DesignTokens.bodyFontWeight,
              color: DesignTokens.errorTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildRewardCard(
      LoyaltyReward reward, Loyalty data, AppLocalizations loc) {
    final canClaim = !reward.claimed && reward.requiredPoints <= data.points;
    final df = DateFormat.yMd();

    return Card(
      color: DesignTokens.surfaceColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      elevation: DesignTokens.cardElevation,
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Row(
          children: [
            Icon(
              reward.claimed ? Icons.check_circle : Icons.redeem,
              color: reward.claimed
                  ? DesignTokens.successColor
                  : DesignTokens.secondaryColor,
              size: 36,
              semanticLabel: reward.claimed
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
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.bodyFontSize,
                      fontWeight: DesignTokens.bodyFontWeight,
                      color: DesignTokens.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward.claimed
                        ? loc.loyaltyRewardClaimedOn(
                            df.format(reward.claimedAt ?? reward.timestamp))
                        : loc
                            .loyaltyRewardRequiredPoints(reward.requiredPoints),
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.captionFontSize,
                      fontWeight: DesignTokens.bodyFontWeight,
                      color: DesignTokens.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            reward.claimed
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      loc.rewardClaimed,
                      style: TextStyle(
                        color: DesignTokens.successColor,
                        fontSize: DesignTokens.captionFontSize,
                        fontWeight: DesignTokens.bodyFontWeight,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: canClaim && !_isClaiming
                        ? () => _handleClaim(reward, data, loc)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryColor,
                      foregroundColor: DesignTokens.foregroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.buttonRadius),
                      ),
                      padding: DesignTokens.buttonPadding,
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


