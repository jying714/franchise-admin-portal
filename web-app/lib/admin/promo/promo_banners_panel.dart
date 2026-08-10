import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/admin/promo/banner_form_dialog.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/services/admin_firestore_service.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';

class PromoBannersPanel extends StatelessWidget {
  final String franchiseId;
  final bool canEdit;

  const PromoBannersPanel({
    super.key,
    required this.franchiseId,
    required this.canEdit,
  });

  AdminFirestoreService? _adminFs(BuildContext context) {
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    if (fs is AdminFirestoreService) return fs;
    return null;
  }

  Future<void> _openForm(
    BuildContext context, {
    shared.Banner? existing,
  }) async {
    final admin = _adminFs(context);
    if (admin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin Firestore service required')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => BannerFormDialog(
        banner: existing,
        onSave: (banner) => admin.saveFranchiseBanner(franchiseId, banner),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    shared.Banner banner,
  ) async {
    final admin = _adminFs(context);
    if (admin == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete banner?'),
        content: Text('Delete “${banner.title}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await admin.deleteFranchiseBanner(franchiseId, banner.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final admin = _adminFs(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Home & menu banners',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            if (canEdit)
              FilledButton.icon(
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add banner'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Image slides on mobile menu. Link to category, item, promo code, or URL.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: admin == null
              ? const Center(child: Text('Admin service not available'))
              : StreamBuilder<List<shared.Banner>>(
                  stream: admin.streamFranchiseBanners(franchiseId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingShimmerWidget();
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load banners\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error),
                        ),
                      );
                    }
                    final banners = snapshot.data ?? const <shared.Banner>[];
                    if (banners.isEmpty) {
                      return Center(
                        child: Text(
                          'No banners yet. Add one to show on the mobile menu carousel.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: banners.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: scheme.outline),
                      itemBuilder: (context, i) {
                        final b = banners[i];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: b.image.isNotEmpty
                                ? Image.network(
                                    b.image,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: scheme.surfaceContainerHighest,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: scheme.surfaceContainerHighest,
                                    child: const Icon(Icons.image_outlined),
                                  ),
                          ),
                          title: Text(
                            b.title.isNotEmpty ? b.title : 'Untitled banner',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              if (b.subtitle.isNotEmpty) b.subtitle,
                              'sort ${b.sortOrder}',
                              b.action.type,
                              b.active ? 'Active' : 'Inactive',
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: canEdit
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _openForm(context, existing: b),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _confirmDelete(context, b),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
