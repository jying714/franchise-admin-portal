import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../../../../widgets/storefront_shell.dart';
import '../../../cart/cart_screen.dart';
import '../../../checkout/checkout_screen.dart';
import '../../../menu/menu_category_grid_screen.dart';
import '../../../menu/menu_category_items_screen.dart';
import '../../../menu/menu_item_detail_screen.dart';

/// Modern (Pizzon-inspired) landing — W2 hero.
/// Data from franchises/{id}/config/storefront; accents from theme primary.
class ModernStorefrontHome extends StatefulWidget {
  const ModernStorefrontHome({super.key});

  @override
  State<ModernStorefrontHome> createState() => _ModernStorefrontHomeState();
}

class _ModernStorefrontHomeState extends State<ModernStorefrontHome> {
  bool _loading = true;
  String? _heroImageUrl;
  String? _headline;
  String? _subheadline;
  String? _loadError;
  String? _loadedForId;
  List<shared.MenuItem> _featured = const [];
  String? _footerPhone;
  String? _footerAddress;
  String? _footerHoursLabel;

  // In-place order path (parity with default template)
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _showingCart = false;
  bool _showingCheckout = false;
  bool _showingConfirmation = false;
  String? _confirmOrderId;
  double _confirmTotal = 0;
  String _confirmPickupLabel = 'Pickup';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = Provider.of<shared.FranchiseProvider>(
      context,
      listen: false,
    ).currentFranchiseId;
    if (id.isEmpty || id == 'unknown') return;
    if (_loadedForId == id) return;
    _loadedForId = id;
    _load(id);
  }

  Future<void> _load(String franchiseId) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final rootRef = FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId);
      final results = await Future.wait([
        rootRef.collection('config').doc('storefront').get(),
        rootRef.collection('config').doc('store_ops').get(),
        rootRef.get(),
      ]);
      final data = results[0].data() ?? {};
      final storeOps = results[1].data() ?? {};
      final franchise = results[2].data() ?? {};

      final phone =
          (franchise['publicPhone'] ??
                  franchise['contactPhone'] ??
                  franchise['phone'] ??
                  storeOps['phone'])
              ?.toString();
      String? address;
      final addr = franchise['address'];
      if (addr is Map) {
        final street = (addr['street'] ?? '').toString().trim();
        final city = (addr['city'] ?? '').toString().trim();
        final state = (addr['state'] ?? '').toString().trim();
        final zip = (addr['zip'] ?? addr['postalCode'] ?? '').toString().trim();
        final parts = <String>[
          if (street.isNotEmpty) street,
          if (city.isNotEmpty || state.isNotEmpty || zip.isNotEmpty)
            [
              if (city.isNotEmpty) city,
              if (state.isNotEmpty) state,
              if (zip.isNotEmpty) zip,
            ].join(', '),
        ];
        address = parts.isEmpty ? null : parts.join(' · ');
      }
      final hoursLabel = _formatTodayHours(storeOps);

      final fs = Provider.of<shared.FirestoreService>(context, listen: false);
      final all = await fs.getMenuItems(franchiseId).first;
      final featured =
          all
              .where((m) => m.hideInMenu != true && !m.archived)
              .where((m) => m.isSellable)
              .where((m) => (m.imageUrl ?? '').trim().isNotEmpty)
              .toList()
            ..sort((a, b) {
              final ao = a.sortOrder ?? 9999;
              final bo = b.sortOrder ?? 9999;
              if (ao != bo) return ao.compareTo(bo);
              return a.name.compareTo(b.name);
            });
      final limited = featured.length > 8 ? featured.sublist(0, 8) : featured;

      if (!mounted) return;
      setState(() {
        _heroImageUrl = data['heroImageUrl']?.toString();
        _headline = data['heroHeadline']?.toString();
        _subheadline = data['heroSubheadline']?.toString();
        _featured = limited;
        _footerPhone = phone;
        _footerAddress = address;
        _footerHoursLabel = hoursLabel;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
        _loading = false;
      });
    }
  }

  static String _weekdayKey(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      default:
        return 'sun';
    }
  }

  static String _fmtTod(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $ampm';
  }

  String? _formatTodayHours(Map<String, dynamic> storeOps) {
    final hoursRaw = storeOps['hours'];
    if (hoursRaw is! Map) {
      final openH = storeOps['openHour'] as int?;
      final closeH = storeOps['closeHour'] as int?;
      if (openH == null || closeH == null) return null;
      final openM = storeOps['openMinute'] as int? ?? 0;
      final closeM = storeOps['closeMinute'] as int? ?? 0;
      return 'Today · ${_fmtTod(openH, openM)}–${_fmtTod(closeH, closeM)}';
    }
    final key = _weekdayKey(DateTime.now());
    final dayRaw = hoursRaw[key];
    if (dayRaw is! Map) return null;
    final day = Map<String, dynamic>.from(dayRaw);
    if (day['closed'] == true) return 'Today · Closed';
    final openH = day['openHour'] as int? ?? 11;
    final openM = day['openMinute'] as int? ?? 0;
    final closeH = day['closeHour'] as int? ?? 21;
    final closeM = day['closeMinute'] as int? ?? 0;
    return 'Today · ${_fmtTod(openH, openM)}–${_fmtTod(closeH, closeM)}';
  }

  void _onOrderNow() {
    final ctx = StorefrontShell.menuSectionKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  void _openItem(shared.MenuItem item) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: Theme.of(dialogContext).colorScheme.surface,
                child: MenuItemDetailScreen(item: item),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectCategory(String id, String name) {
    setState(() {
      _selectedCategoryId = id;
      _selectedCategoryName = name;
      _showingCart = false;
      _showingCheckout = false;
      _showingConfirmation = false;
    });
  }

  void _clearCategory() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _showingCart = false;
      _showingCheckout = false;
      _showingConfirmation = false;
    });
  }

  void _openCart() {
    setState(() {
      _showingCart = true;
      _showingCheckout = false;
      _showingConfirmation = false;
    });
  }

  void _closeCart() {
    setState(() {
      _showingCart = false;
      _showingCheckout = false;
    });
  }

  void _openCheckout() {
    setState(() {
      _showingCart = false;
      _showingCheckout = true;
      _showingConfirmation = false;
    });
  }

  void _closeCheckout() {
    setState(() {
      _showingCheckout = false;
      _showingCart = true;
      _showingConfirmation = false;
    });
  }

  void _showOrderConfirmation({
    required String orderId,
    required double total,
    required String pickupLabel,
  }) {
    setState(() {
      _showingCart = false;
      _showingCheckout = false;
      _showingConfirmation = true;
      _confirmOrderId = orderId;
      _confirmTotal = total;
      _confirmPickupLabel = pickupLabel;
    });
  }

  void _backToMenuFromConfirm() {
    setState(() {
      _showingCart = false;
      _showingCheckout = false;
      _showingConfirmation = false;
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _confirmOrderId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<shared.FranchiseProvider>();
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final name = fp.currentAppName;

    final title = (_headline != null && _headline!.trim().isNotEmpty)
        ? _headline!.trim()
        : (name.isNotEmpty ? name : 'Order online');
    final subtitle = (_subheadline != null && _subheadline!.trim().isNotEmpty)
        ? _subheadline!.trim()
        : 'Fresh from our kitchen — order for pickup';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        if (_loadError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load storefront: $_loadError',
                style: TextStyle(color: scheme.error),
              ),
            ),
          ),
        // —— Hero ——
        // Large split layout: copy left, image right (stacks on narrow).
        SliverToBoxAdapter(
          child: SizedBox(
            width: double.infinity,
            height: 420,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full-bleed banner
                if (_heroImageUrl != null && _heroImageUrl!.trim().isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: _heroImageUrl!.trim(),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: (_, __, ___) => Container(color: primary),
                  )
                else
                  Container(color: primary),
                // Scrim for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
                // Copy overlaid, left-aligned within max content width
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 72, 32, 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _HeroCopy(
                        title: title,
                        subtitle: subtitle,
                        primary: primary,
                        onOrderNow: _onOrderNow,
                        onDark: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // —— Featured (marketing strip; optional photos) ——
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 56),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Featured',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A1A),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap an item to customize and add to cart',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_featured.isEmpty)
                      Text(
                        'No featured items with photos yet. Add images on menu items in Admin.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final cross = w >= 900
                              ? 4
                              : w >= 600
                              ? 3
                              : 2;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _featured.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cross,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 0.72,
                                ),
                            itemBuilder: (context, i) {
                              final item = _featured[i];
                              return _ModernMenuCard(
                                item: item,
                                primary: primary,
                                onTap: () => _openItem(item),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // —— Full menu (Order Now scrolls here) ——
        // Category grid → items → cart → checkout (parity with default)
        // ignore: prefer_const_constructors — key is static GlobalKey
        // ---
        SliverToBoxAdapter(
          key: StorefrontShell.menuSectionKey,
          child: Container(
            width: double.infinity,
            color: const Color(0xFFFFF8F0),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child:
                          (_showingCheckout ||
                              _showingCart ||
                              _selectedCategoryId != null)
                          ? IconButton(
                              tooltip: _showingCheckout
                                  ? 'Back to cart'
                                  : _showingCart
                                  ? 'Back to menu'
                                  : 'Back to categories',
                              icon: const Icon(Icons.arrow_back),
                              onPressed: _showingCheckout
                                  ? _closeCheckout
                                  : _showingCart
                                  ? _closeCart
                                  : _clearCategory,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        _showingConfirmation
                            ? 'Order placed'
                            : _showingCheckout
                            ? 'Checkout'
                            : _showingCart
                            ? 'Cart'
                            : _selectedCategoryId != null
                            ? (_selectedCategoryName ?? 'Menu')
                            : 'Menu',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        tooltip: 'Cart',
                        icon: const Icon(Icons.shopping_cart_outlined),
                        onPressed: _openCart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_showingConfirmation)
          const SliverToBoxAdapter(child: SizedBox.shrink())
        else if (_showingCheckout)
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SizedBox(
                  height: 720,
                  child: CheckoutScreen(
                    embed: true,
                    onOrderPlaced:
                        ({
                          required String orderId,
                          required double total,
                          required String pickupLabel,
                        }) {
                          _showOrderConfirmation(
                            orderId: orderId,
                            total: total,
                            pickupLabel: pickupLabel,
                          );
                        },
                  ),
                ),
              ),
            ),
          )
        else if (_showingCart)
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SizedBox(
                  height: 600,
                  child: CartScreen(embed: true, onCheckout: _openCheckout),
                ),
              ),
            ),
          )
        else if (_selectedCategoryId == null)
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SizedBox(
                  height: 520,
                  child: MenuCategoryGridScreen(
                    onCategorySelected: _selectCategory,
                  ),
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SizedBox(
                  height: 600,
                  child: MenuCategoryItemsScreen(
                    categoryId: _selectedCategoryId!,
                    categoryName: _selectedCategoryName ?? '',
                    embed: true,
                  ),
                ),
              ),
            ),
          ),

        if (_showingConfirmation)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 72, color: primary),
                      const SizedBox(height: 16),
                      Text(
                        'Order #${_confirmOrderId ?? ''}',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_confirmPickupLabel · \$${_confirmTotal.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _backToMenuFromConfirm,
                        style: FilledButton.styleFrom(backgroundColor: primary),
                        child: const Text('Back to menu'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // —— Footer ——
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_footerAddress != null &&
                        _footerAddress!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _footerAddress!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_footerPhone != null &&
                        _footerPhone!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _footerPhone!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_footerHoursLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _footerHoursLabel!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _onOrderNow,
                      style: TextButton.styleFrom(foregroundColor: primary),
                      child: const Text('Order Now'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color primary;
  final VoidCallback onOrderNow;
  final bool onDark;

  const _HeroCopy({
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.onOrderNow,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = onDark ? Colors.white70 : const Color(0xFF5C5C5C);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 4,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: titleColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: subColor,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onOrderNow,
          style: FilledButton.styleFrom(
            backgroundColor: onDark ? Colors.white : primary,
            foregroundColor: onDark ? primary : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
          child: const Text('Order Now'),
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  final Color primary;

  const _HeroImage({required this.imageUrl, required this.primary});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: url.isEmpty
            ? Container(
                color: primary.withValues(alpha: 0.12),
                child: Icon(Icons.local_pizza, size: 80, color: primary),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => Container(
                  color: primary.withValues(alpha: 0.08),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: primary.withValues(alpha: 0.12),
                  child: Icon(Icons.local_pizza, size: 80, color: primary),
                ),
              ),
      ),
    );
  }
}

class _ModernMenuCard extends StatelessWidget {
  final shared.MenuItem item;
  final Color primary;
  final VoidCallback onTap;

  const _ModernMenuCard({
    required this.item,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item.imageUrl ?? '').trim();
    final price = item.price;

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: imageUrl.isEmpty
                      ? Container(
                          color: primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.restaurant,
                            color: primary,
                            size: 40,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: (_, __, ___) => Container(
                            color: primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.restaurant,
                              color: primary,
                              size: 40,
                            ),
                          ),
                        ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
