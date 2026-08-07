// customer_web/lib/features/home/storefront_home_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import '../../widgets/storefront_shell.dart';
import '../checkout/checkout_screen.dart';
import '../menu/menu_category_grid_screen.dart';
import '../menu/menu_category_items_screen.dart';

/// Bound franchise marketing home (hero + story from config/storefront).
/// Menu section lives in-place: categories grid ↔ items list under the shell.
class StorefrontHomeScreen extends StatefulWidget {
  const StorefrontHomeScreen({super.key});

  @override
  State<StorefrontHomeScreen> createState() => _StorefrontHomeScreenState();
}

class _StorefrontHomeScreenState extends State<StorefrontHomeScreen> {
  bool _loading = true;
  String? _heroImageUrl;
  String? _headline;
  String? _subheadline;
  String? _storyBody;
  String? _storefrontPhotoUrl;
  String? _loadError;
  String? _loadedForId;

  // Footer (store_ops + franchise contact)
  String? _footerPhone;
  String? _footerAddress;
  String? _footerHoursLabel;

  // In-place menu section state
  String? _selectedCategoryId;
  String? _selectedCategoryName;
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
      final storefront = results[0].data() ?? {};
      final storeOps = results[1].data() ?? {};
      final franchise = results[2].data() ?? {};

      _heroImageUrl = storefront['heroImageUrl']?.toString();
      _headline = storefront['heroHeadline']?.toString();
      _subheadline = storefront['heroSubheadline']?.toString();
      _storyBody = storefront['storyBody']?.toString();
      _storefrontPhotoUrl = storefront['storefrontPhotoUrl']?.toString();

      _footerPhone =
          (franchise['publicPhone'] ??
                  franchise['contactPhone'] ??
                  franchise['phone'] ??
                  storeOps['phone'])
              ?.toString();
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
        _footerAddress = parts.isEmpty ? null : parts.join(' · ');
      } else {
        _footerAddress = null;
      }
      _footerHoursLabel = _formatTodayHours(storeOps);
    } catch (e) {
      _loadError = '$e';
    }
    if (mounted) setState(() => _loading = false);
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

  static String _fmtTod(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $ampm';
  }

  void _selectCategory(String id, String name) {
    setState(() {
      _selectedCategoryId = id;
      _selectedCategoryName = name;
      _showingCheckout = false;
      _showingConfirmation = false;
    });
  }

  void _clearCategory() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _showingCheckout = false;
      _showingConfirmation = false;
    });
  }

  void _openCart() {
    StorefrontShell.openCartSheet();
  }

  void _showOrderConfirmation({
    required String orderId,
    required double total,
    required String pickupLabel,
  }) {
    setState(() {
      _showingCheckout = false;
      _showingConfirmation = true;
      _confirmOrderId = orderId;
      _confirmTotal = total;
      _confirmPickupLabel = pickupLabel;
    });
  }

  void _backToMenuFromConfirm() {
    setState(() {
      _showingCheckout = false;
      _showingConfirmation = false;
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _confirmOrderId = null;
    });
  }

  void _openCheckout() {
    setState(() {
      _showingCheckout = true;
      _showingConfirmation = false;
    });
  }

  void _closeCheckout() {
    setState(() {
      _showingCheckout = false;
    });
  }

  void _scrollToMenu() {
    final ctx = StorefrontShell.menuSectionKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<shared.FranchiseProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final name = fp.currentAppName;

    final title = (_headline != null && _headline!.trim().isNotEmpty)
        ? _headline!.trim()
        : name;
    final subtitle = (_subheadline != null && _subheadline!.trim().isNotEmpty)
        ? _subheadline!.trim()
        : 'Order online for pickup';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // —— Hero ——
        SliverToBoxAdapter(
          child: SizedBox(
            height: 360,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Brand fill behind banner so letterboxing matches red/green identity
                Container(color: primary),
                if (_heroImageUrl != null && _heroImageUrl!.trim().isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: _heroImageUrl!.trim(),
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          _clearCategory();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToMenu();
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        child: const Text('Order online'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // —— Load error ——
        if (_loadError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load website content: $_loadError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),

        // —— Story ——
        if (_storyBody != null && _storyBody!.trim().isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final photo = _storefrontPhotoUrl?.trim() ?? '';
                  final storyCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to $name',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _storyBody!.trim(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  );
                  if (!wide || photo.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (photo.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: photo,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        storyCol,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: photo,
                            height: 240,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: storyCol),
                    ],
                  );
                },
              ),
            ),
          ),

        // —— Fallback welcome when no story body ——
        if (_storyBody == null || _storyBody!.trim().isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to $name',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse the menu and order online.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // —— Menu section (key for Order now / Order online scroll) ——
        SliverToBoxAdapter(
          key: StorefrontShell.menuSectionKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
            child: Row(
              children: [
                if (_showingConfirmation) ...[
                  Expanded(
                    child: Text(
                      'Order placed',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ] else if (_showingCheckout) ...[
                  IconButton(
                    tooltip: 'Back to menu',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _closeCheckout,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Checkout',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ] else if (_selectedCategoryId != null) ...[
                  IconButton(
                    tooltip: 'Back to categories',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _clearCategory,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _selectedCategoryName ?? 'Menu',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      'Menu',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                IconButton(
                  tooltip: 'Cart',
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: _openCart,
                ),
              ],
            ),
          ),
        ),

        // —— In-place content: confirmation | checkout | cart | categories | items ——
        if (_showingConfirmation)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
                      const SizedBox(height: 8),
                      Text(
                        'We’ll have it ready soon. You can keep browsing the menu.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _backToMenuFromConfirm,
                        child: const Text('Back to menu'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (_showingCheckout)
          SliverToBoxAdapter(
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
          )
        else if (_selectedCategoryId == null)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 520,
              child: MenuCategoryGridScreen(
                onCategorySelected: _selectCategory,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: SizedBox(
              height: 600,
              child: MenuCategoryItemsScreen(
                categoryId: _selectedCategoryId!,
                categoryName: _selectedCategoryName ?? '',
                embed: true,
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 32),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            color: Theme.of(context).colorScheme.primary,
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_footerAddress != null &&
                      _footerAddress!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_footerAddress!, textAlign: TextAlign.center),
                  ],
                  if (_footerPhone != null &&
                      _footerPhone!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(_footerPhone!, textAlign: TextAlign.center),
                  ],
                  if (_footerHoursLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(_footerHoursLabel!, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
