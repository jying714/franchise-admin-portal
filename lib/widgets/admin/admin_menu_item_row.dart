import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_menu_item_actions_row.dart';
import 'package:franchise_admin_portal/core/models/menu_item.dart';
import 'package:franchise_admin_portal/core/models/category.dart';
import 'package:franchise_admin_portal/core/models/user.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/network_image_widget.dart';
import 'package:franchise_admin_portal/widgets/dietary_allergen_chips_row.dart';
import 'package:franchise_admin_portal/widgets/status_chip.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class AdminMenuItemRow extends StatelessWidget {
  final MenuItem item;
  final bool isSelected;
  final List<Category> categories;
  final User user;
  final bool canEdit;
  final bool canDeleteOrExport;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onCustomize;
  final VoidCallback onDelete;
  final List<String> visibleColumns;

  const AdminMenuItemRow({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.categories,
    required this.user,
    required this.canEdit,
    required this.canDeleteOrExport,
    required this.onSelect,
    required this.onEdit,
    required this.onCustomize,
    required this.onDelete,
    required this.visibleColumns,
  }) : super(key: key);

  Widget _buildCellMobile(String key, MenuItem item, String categoryName) {
    switch (key) {
      case 'image':
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: NetworkImageWidget(
              imageUrl: item.image,
              fallbackAsset: BrandingConfig.defaultPizzaIcon,
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      case 'available':
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: item.availability ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        );
      case 'name':
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      case 'category':
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizedBox(
            width: 90,
            child: Text(
              categoryName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        );
      case 'price':
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            '\$${item.price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      case 'sku':
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizedBox(
            width: 90,
            child: Text(
              item.sku ?? '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        );
      case 'dietary':
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizedBox(
            width: 180,
            child: DietaryAllergenChipsRow(
              dietaryTags: item.dietaryTags,
              allergens: item.allergens,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final categoryName = item.category;

    if (isMobile) {
      return Card(
        color: isSelected ? Colors.grey.shade400 : DesignTokens.surfaceColor,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                for (final col in visibleColumns)
                  _buildCellMobile(col, item, categoryName),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    if (canEdit)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: const [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (canEdit)
                      PopupMenuItem(
                        value: 'customize',
                        child: Row(
                          children: const [
                            Icon(Icons.tune, size: 18),
                            SizedBox(width: 8),
                            Text('Customize'),
                          ],
                        ),
                      ),
                    if (canDeleteOrExport)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(Icons.delete,
                                size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'customize':
                        onCustomize();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Widget _buildCell(String key) {
        switch (key) {
          case 'image':
            return SizedBox(
              width: 60,
              height: 48,
              child: NetworkImageWidget(
                imageUrl: item.image,
                fallbackAsset: BrandingConfig.defaultPizzaIcon,
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          case 'name':
            return SizedBox(
              width: 120,
              child: Text(item.name, overflow: TextOverflow.ellipsis),
            );
          case 'category':
            return SizedBox(
              width: 90,
              child: Text(categoryName, overflow: TextOverflow.ellipsis),
            );
          case 'price':
            return SizedBox(
              width: 60,
              child: Text('\$${item.price.toStringAsFixed(2)}'),
            );
          case 'available':
            return SizedBox(
              width: 90,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.availability ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.availability ? "Available" : "Unavailable",
                    style: TextStyle(
                      color: item.availability ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          case 'sku':
            return SizedBox(
              width: 90,
              child: Text(item.sku ?? '', overflow: TextOverflow.ellipsis),
            );
          case 'dietary':
            return SizedBox(
              width: 180,
              child: DietaryAllergenChipsRow(
                dietaryTags: item.dietaryTags,
                allergens: item.allergens,
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      }

      return Card(
        color: isSelected ? Colors.grey.shade400 : DesignTokens.surfaceColor,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...visibleColumns.map(_buildCell).toList(),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      if (canEdit)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: const [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (canEdit)
                        PopupMenuItem(
                          value: 'customize',
                          child: Row(
                            children: const [
                              Icon(Icons.tune, size: 18),
                              SizedBox(width: 8),
                              Text('Customize'),
                            ],
                          ),
                        ),
                      if (canDeleteOrExport)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: const [
                              Icon(Icons.delete,
                                  size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'customize':
                          onCustomize();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
