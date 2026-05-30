// P1 Duplicated Widgets Batch 1 (May 30, 2026)
// Mobile canonical for customer flows (mobile_app/lib/widgets/banner/).
// Web banner/ kept only for admin previews. Update to barrel only (no src/).
// Safe for deletion in next batch if admin previews reuse via path dep on mobile_app or shared_ui pkg.
// No critical customer preview flows touched.

import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/network_image_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PromoBannerCard extends StatelessWidget {
  final shared.Banner banner;
  final VoidCallback? onTap;
  final VoidCallback? onCTAPressed;

  const PromoBannerCard({
    Key? key,
    required this.banner,
    this.onTap,
    this.onCTAPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(DesignTokens.bannerBorderRadius),
            child: NetworkImageWidget(
              imageUrl: banner.image,
              fallbackAsset: BrandingConfig.bannerPlaceholder,
              width: double.infinity,
              height: DesignTokens.bannerHeight,
              fit: BoxFit.cover,
              borderRadius:
                  BorderRadius.circular(DesignTokens.bannerBorderRadius),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DesignTokens.bannerBorderRadius),
              color: DesignTokens.bannerOverlayColor
                  .withAlpha(DesignTokens.bannerOverlayAlpha),
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
                      fontSize: DesignTokens.titleFontSize,
                      color: DesignTokens.foregroundColor,
                      fontWeight: DesignTokens.titleFontWeight,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4),
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
                        fontSize: DesignTokens.captionFontSize,
                        color: DesignTokens.foregroundColor,
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
                        backgroundColor: DesignTokens.secondaryColor,
                        foregroundColor: DesignTokens.foregroundColor,
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


