// customer_web/lib/widgets/menu_item_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.item, this.onTap});

  final shared.MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unavailable =
        !item.availability || item.archived || (item.hideInMenu == true);
    final priceLabel = '\$${item.price.toStringAsFixed(2)}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: unavailable ? null : onTap,
        child: Opacity(
          opacity: unavailable ? 0.55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: item.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(scheme),
                      )
                    : _placeholder(scheme),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          unavailable ? 'Unavailable' : priceLabel,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: unavailable
                                    ? scheme.error
                                    : scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (item.allergens.isNotEmpty) ...[
                          const Spacer(),
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.restaurant, size: 40, color: scheme.onSurfaceVariant),
    );
  }
}
