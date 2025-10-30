import 'package:flutter/material.dart';
import 'package:admin_portal/config/design_tokens.dart';

/// Shimmer-free lightweight skeleton for use in onboarding preview sections.
/// Can optionally accept size constraints or adapt fluidly.
class PreviewMenuItemCardSkeleton extends StatelessWidget {
  const PreviewMenuItemCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePlaceholder(),
            const SizedBox(width: 12),
            Expanded(child: _buildInfoSkeleton(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildInfoSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _skeletonLine(width: 120, height: 18),
        const SizedBox(height: 6),
        _skeletonLine(width: 180, height: 14),
        const SizedBox(height: 10),
        _buildIngredientTagsSkeleton(),
        const SizedBox(height: 10),
        _buildCustomizationSkeleton(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _skeletonLine(width: 60, height: 16),
            _skeletonLine(width: 80, height: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildIngredientTagsSkeleton() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(4, (index) {
        return Container(
          width: 60 + (index * 10),
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }),
    );
  }

  Widget _buildCustomizationSkeleton() {
    return Column(
      children: List.generate(2, (index) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _skeletonLine(width: 160, height: 12),
        );
      }),
    );
  }

  Widget _skeletonLine({double width = 100, double height = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
