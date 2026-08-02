// customer_web/lib/features/home/storefront_home_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../../widgets/branding_shell.dart';
import '../menu/menu_category_grid_screen.dart';

/// Parity D0: bound franchise marketing home (hero from config/storefront).
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
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('storefront')
          .get();
      final data = snap.data() ?? {};
      _heroImageUrl = data['heroImageUrl']?.toString();
      _headline = data['heroHeadline']?.toString();
      _subheadline = data['heroSubheadline']?.toString();
      _storyBody = data['storyBody']?.toString();
      _storefrontPhotoUrl = data['storefrontPhotoUrl']?.toString();
    } catch (e) {
      _loadError = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openMenu() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MenuCategoryGridScreen()),
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

    return BrandingShell(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 360,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_heroImageUrl != null &&
                            _heroImageUrl!.trim().isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: _heroImageUrl!.trim(),
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Container(color: primary),
                          )
                        else
                          Container(color: primary),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.15),
                                Colors.black.withOpacity(0.65),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
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
                                onPressed: _openMenu,
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
                if (_loadError != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Could not load website content: $_loadError',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
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
                                      errorWidget: (_, __, ___) =>
                                          const SizedBox.shrink(),
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
                                    errorWidget: (_, __, ___) =>
                                        const SizedBox.shrink(),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_storyBody == null ||
                            _storyBody!.trim().isEmpty) ...[
                          Text(
                            'Welcome to $name',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Browse the menu and order online.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        OutlinedButton(
                          onPressed: _openMenu,
                          child: const Text('View menu'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
