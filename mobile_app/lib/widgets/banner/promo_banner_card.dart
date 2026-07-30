import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

class PromoBannerCard extends StatelessWidget {
  final shared.Banner banner;
  final VoidCallback? onTap;
  final VoidCallback? onCTAPressed;

  const PromoBannerCard({
    super.key,
    required this.banner,
    this.onTap,
    this.onCTAPressed,
  });

  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected (P1 Batch 1) for franchise/{franchiseId}/ scoping centrality
    Provider.of<shared.FranchiseProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(shared.DesignTokens.bannerBorderRadius),
            child: NetworkImageWidget(
              imageUrl: banner.image,
              fallbackAsset: shared.BrandingConfig.bannerPlaceholder,
              width: double.infinity,
              height: shared.DesignTokens.bannerHeight,
              fit: BoxFit.cover,
              borderRadius:
                  BorderRadius.circular(shared.DesignTokens.bannerBorderRadius),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(shared.DesignTokens.bannerBorderRadius),
              color: shared.UiConfig.bannerOverlayColor
                  .withAlpha(shared.DesignTokens.bannerOverlayAlpha),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (banner.title.isNotEmpty)
                  Text(
                    banner.title,
                    style: TextStyle(
                      fontSize: shared.DesignTokens.titleFontSize,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: shared.UiConfig.fontWeightBold,
                      shadows: [
                        Shadow(
                            color: Theme.of(context)
                                .colorScheme
                                .shadow
                                .withOpacity(0.54),
                            blurRadius: 4),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (banner.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      banner.subtitle,
                      style: TextStyle(
                        fontSize: shared.DesignTokens.captionFontSize,
                        color: shared.UiConfig.foregroundColor,
                        fontWeight: FontWeight.w400,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (banner.action.type != 'none')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: shared.UiConfig.secondaryColor,
                        foregroundColor: shared.UiConfig.foregroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: onCTAPressed ?? onTap,
                      child: Text(
                        (banner.action.ctaText != null &&
                                banner.action.ctaText!.isNotEmpty)
                            ? banner.action.ctaText!
                            : _getCTAForAction(loc, banner.action.type),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCTAForAction(AppLocalizations loc, String type) {
    switch (type) {
      case 'linkCategory':
        return loc.browseCategoryCta;
      case 'linkItem':
        return loc.orderNowCta;
      case 'promo':
        return loc.applyPromoCta;
      default:
        return loc.defaultBannerCta;
    }
  }
}
