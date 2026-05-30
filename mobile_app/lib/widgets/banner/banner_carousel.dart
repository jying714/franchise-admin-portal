import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/banner/promo_banner_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/config/ui_config.dart';

typedef BannerTapCallback = void Function(shared.Banner banner);

class BannerCarousel extends StatelessWidget {
  final List<shared.Banner> banners;
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
      padding: UiConfig.defaultPadding,
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
          height: shared.DesignTokens.bannerHeight,
          autoPlay: true,
          autoPlayInterval:
              Duration(seconds: shared.DesignTokens.bannerAutoPlayInterval),
          enlargeCenterPage: true,
          viewportFraction: 1.0,
          enableInfiniteScroll: banners.length > 1,
          pauseAutoPlayOnTouch: true,
        ),
      ),
    );
  }
}
