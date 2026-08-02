// customer_web/lib/features/menu/menu_browse_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'menu_item_detail_screen.dart';
import '../../widgets/branding_shell.dart';
import '../../widgets/menu_item_card.dart';
import '../cart/cart_screen.dart';

/// Signed-out menu browse for a bound franchise.
/// Uses existing FirestoreService menu APIs only.
class MenuBrowseScreen extends StatelessWidget {
  const MenuBrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<shared.FranchiseProvider>();
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;

    if (!fp.hasValidFranchise) {
      return const BrandingShell(
        child: Center(child: Text('No restaurant selected')),
      );
    }

    return BrandingShell(
      actions: [
        IconButton(
          tooltip: 'Cart',
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const CartScreen()));
          },
        ),
      ],
      child: StreamBuilder<List<shared.MenuItem>>(
        stream: fs.getMenuItems(franchiseId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load menu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items =
              snapshot.data!
                  .where((m) => m.hideInMenu != true && !m.archived)
                  .toList()
                ..sort((a, b) {
                  final ao = a.sortOrder ?? 9999;
                  final bo = b.sortOrder ?? 9999;
                  if (ao != bo) return ao.compareTo(bo);
                  return a.name.compareTo(b.name);
                });

          if (items.isEmpty) {
            return const Center(child: Text('Menu is empty'));
          }

          // Group by category label (display only — no second schema).
          final byCategory = <String, List<shared.MenuItem>>{};
          for (final item in items) {
            final key = item.category.trim().isEmpty
                ? 'Menu'
                : item.category.trim();
            byCategory.putIfAbsent(key, () => []).add(item);
          }
          final categoryNames = byCategory.keys.toList()..sort();

          return CustomScrollView(
            slivers: [
              for (final cat in categoryNames) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      cat,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = byCategory[cat]![index];
                      return MenuItemCard(
                        item: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MenuItemDetailScreen(item: item),
                            ),
                          );
                        },
                      );
                    }, childCount: byCategory[cat]!.length),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}
