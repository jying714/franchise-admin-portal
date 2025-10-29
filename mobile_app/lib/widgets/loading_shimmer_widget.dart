import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';

class LoadingShimmerWidget extends StatelessWidget {
  final int itemCount;
  final double cardHeight;
  final double cardWidth;
  final Axis direction;

  // Admin grid support
  final bool isAdminGrid;
  final int gridColumns;

  const LoadingShimmerWidget({
    Key? key,
    this.itemCount = 4,
    this.cardHeight = 160.0,
    this.cardWidth = double.infinity,
    this.direction = Axis.vertical,
    this.isAdminGrid = false,
    this.gridColumns = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isAdminGrid) {
      return Shimmer.fromColors(
        baseColor: DesignTokens.shimmerBaseColor,
        highlightColor: DesignTokens.shimmerHighlightColor,
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: gridColumns,
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                height: cardHeight,
                width: cardWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: DesignTokens.shimmerBaseColor,
      highlightColor: DesignTokens.shimmerHighlightColor,
      child: GridView.count(
        crossAxisCount: 2, // or 3 for tablet
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1,
        padding: const EdgeInsets.all(12),
        children: List.generate(
          itemCount,
          (index) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
          ),
        ),
      ),
    );
  }
}
