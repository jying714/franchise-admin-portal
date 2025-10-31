import 'package:flutter/material.dart';
import '../package:shared_core/src/core/models/menu_item.dart';
import '../package:shared_core/src/core/models/ingredient_reference.dart';
import '../package:shared_core/src/core/models/customization_group.dart';
import '../package:shared_core/src/core/models/nutrition_info.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// âœ… Production-ready card UI to preview a MenuItem as it would appear
/// in the customer-facing app.
///
/// Used within onboarding flow to validate:
/// - Ingredient relationships
/// - Customization presence
/// - Image and out-of-stock behavior
class PreviewMenuItemCard extends StatelessWidget {
  final MenuItem menuItem;

  const PreviewMenuItemCard({Key? key, required this.menuItem})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final outOfStock = menuItem.outOfStock;
    final priceString = '\$${menuItem.price.toStringAsFixed(2)}';

    return Card(
      color: outOfStock ? Colors.grey.shade200 : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: outOfStock ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(context),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildInfoSection(context, priceString, outOfStock)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: menuItem.imageUrl.isNotEmpty
          ? Image.network(
              menuItem.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 48),
            )
          : Container(
              width: 100,
              height: 100,
              color: Colors.grey.shade100,
              child: const Icon(Icons.image, size: 40),
            ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, String priceString, bool outOfStock) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          menuItem.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          menuItem.description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        _buildIngredientsPreview(),
        if (menuItem.customizations.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildCustomizationSummary(),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              priceString,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: outOfStock ? Colors.grey : Colors.black,
                  ),
            ),
            if (outOfStock)
              const Text(
                'Out of Stock',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        )
      ],
    );
  }

  Widget _buildIngredientsPreview() {
    final tags = [
      ...?menuItem.includedIngredients?.map((i) => i['name'] as String? ?? ''),
      ...?menuItem.optionalAddOns?.map((i) => i['name'] as String? ?? ''),
    ].where((tag) => tag.isNotEmpty).toList();

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags
          .map((tag) => Chip(
                label: Text(tag),
                backgroundColor: Colors.grey.shade100,
              ))
          .toList(),
    );
  }

  Widget _buildCustomizationSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: menuItem.customizations.map((group) {
        final groupLabel = group.name.isNotEmpty ? group.name : 'Custom';
        final entries =
            group.options?.map((e) => e.name).join(', ') ?? 'None selected';
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '$groupLabel: $entries',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        );
      }).toList(),
    );
  }
}


