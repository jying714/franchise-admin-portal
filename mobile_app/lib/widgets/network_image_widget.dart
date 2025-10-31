import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A reusable widget that loads & caches a network image,
/// shows a progress indicator while loading, and falls back
/// to a local asset if the URL is empty or the load fails.
/// Optionally applies rounded corners.
class NetworkImageWidget extends StatelessWidget {
  /// The remote image URL. If null/empty, [fallbackAsset] is shown.
  final String? imageUrl;

  /// Path to the local asset to use as a placeholder or on error.
  final String fallbackAsset;

  /// Desired display width.
  final double width;

  /// Desired display height.
  final double height;

  /// How to inscribe the image into the space.
  final BoxFit fit;

  /// Optional corner radius.
  final BorderRadius? borderRadius;

  const NetworkImageWidget({
    Key? key,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget img;

    // 1) If no URL provided, immediately show fallback asset.
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      img = Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      // 2) Otherwise attempt to load via CachedNetworkImage.
      img = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (ctx, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (ctx, url, error) => Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }

    // 3) If a borderRadius is provided, wrap in ClipRRect.
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: img,
      );
    }

    // 4) Otherwise return the image as-is.
    return img;
  }
}


