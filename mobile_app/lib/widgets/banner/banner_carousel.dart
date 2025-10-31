import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/config/branding_config.dart';
import 'package:franchise_mobile_app/core/models/banner.dart' as model;
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/banner/promo_banner_card.dart';

typedef BannerTapCallback = void Function(model.Banner banner);

class BannerCarousel extends StatelessWidget {
  final List<model.Banner> banners;
  final BannerTapCallback? onBannerTap;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      // For visual consistency, you could show a placeholder or SizedBox.shrink().
      return const SizedBox.shrink();
    }
    return Padding(
      padding: DesignTokens.gridPadding,
      child: CarouselSlider.builder(
        itemCount: banners.length,
        itemBuilder: (context, index, realIdx) {
          final banner = banners[index];
          return PromoBannerCard(
            banner: banner,
            onTap: () => onBannerTap?.call(banner),
            onCTAPressed: () => onBannerTap?.call(banner),
          );
        },
        options: CarouselOptions(
          height: DesignTokens.bannerHeight,
          autoPlay: true,
          autoPlayInterval: DesignTokens.bannerAutoPlayInterval,
          enlargeCenterPage: true,
          viewportFraction: 1.0,
          enableInfiniteScroll: banners.length > 1,
          pauseAutoPlayOnTouch: true,
        ),
      ),
    );
  }

  String _getCTAForAction(BuildContext context, String type) {
    final loc = AppLocalizations.of(context)!;
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


