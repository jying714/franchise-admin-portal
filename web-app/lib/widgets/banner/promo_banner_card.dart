import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/network_image_widget.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';

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
            borderRadius: BorderRadius.circular(16),
            child: NetworkImageWidget(
              imageUrl: banner.image,
              fallbackAsset: BrandingConfig.bannerPlaceholder,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: 0.4),
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
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        shadows: [
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
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
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
