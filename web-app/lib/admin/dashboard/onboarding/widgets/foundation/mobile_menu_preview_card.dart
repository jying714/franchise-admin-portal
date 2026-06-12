import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/ui_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/menu_item_card.dart'; // Reuse existing mobile-style card
import 'package:franchise_admin_portal/widgets/categories/category_card.dart'; // Reuse if suitable, or fallback
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class MobileMenuPreviewCard extends StatelessWidget {
  final String franchiseId;
  final int currentTabIndex;

  const MobileMenuPreviewCard({
    super.key,
    required this.franchiseId,
    this.currentTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final categoryProvider = context.watch<shared.CategoryProvider>();
    final franchiseInfoProvider = context.watch<shared.FranchiseInfoProvider>();
    final franchise = franchiseInfoProvider.franchise;

    final categories = categoryProvider.categories;
    final isEmpty = categories.isEmpty;

    return Container(
      width: 340,
      height: 680,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: Colors.grey.shade800, width: 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Column(
          children: [
            // Phone Status Bar Simulation
            Container(
              height: 30,
              color: Colors.black,
              child: const Center(
                child: Text(
                  '9:41',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
            // App Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: UiConfig.primaryColor,
              child: Row(
                children: [
                  if (franchise?.logoUrl != null &&
                      franchise!.logoUrl!.isNotEmpty)
                    CircleAvatar(
                      backgroundImage: NetworkImage(franchise.logoUrl!),
                      radius: 18,
                    )
                  else
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(Icons.local_pizza, color: Colors.red),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      franchise?.name ?? 'Doughboys Pizzeria',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.search, color: Colors.white),
                  const SizedBox(width: 16),
                  const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                ],
              ),
            ),
            // Category Grid Preview (matches mobile MainMenuScreen)
            Expanded(
              child: isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.restaurant_menu,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              loc?.previewEmptyState ??
                                  'Add categories in the tabs above to see live preview',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () {}, // Preview only - no navigation
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_pizza,
                                      size: 48, color: UiConfig.primaryColor),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      category.displayName ?? category.name,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
