// 📄 lib/admin/owner/screens/full_franchise_subscription_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/core/models/enriched/enriched_franchise_subscription.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/services/enrichment/franchise_subscription_enricher.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/admin/developer/platform/franchise_subscription_editor_dialog.dart';
import 'package:franchise_admin_portal/admin/owner/widgets/franchise_subscription_list_tile.dart';

class FullFranchiseSubscriptionListScreen extends StatefulWidget {
  const FullFranchiseSubscriptionListScreen({super.key});

  @override
  State<FullFranchiseSubscriptionListScreen> createState() =>
      _FullFranchiseSubscriptionListScreenState();
}

class _FullFranchiseSubscriptionListScreenState
    extends State<FullFranchiseSubscriptionListScreen> {
  late Future<List<EnrichedFranchiseSubscription>> _enrichedSubsFuture;

  @override
  void initState() {
    super.initState();
    _enrichedSubsFuture = _loadEnrichedSubscriptions();
  }

  Future<List<EnrichedFranchiseSubscription>>
      _loadEnrichedSubscriptions() async {
    try {
      final firestore = context.read<FirestoreService>();
      final enricher = FranchiseSubscriptionEnricher(firestore);
      final enriched = await enricher.enrichAllSubscriptions();

      // 🐞 Debug & duplicate detection
      final seen = <String>{};
      for (final e in enriched) {
        final id = e.subscription.id;
        final plan = e.planId;
        final fid = e.franchiseId;

        if (seen.contains(id)) {
          debugPrint('[⚠️ DUPLICATE] FranchiseId: $fid, Plan: $plan, ID: $id');
        } else {
          seen.add(id);
        }

        debugPrint('[✅ Enriched] FranchiseId: $fid, Plan: $plan, ID: $id');
      }

      return enriched;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'load_enriched_subscriptions_failed',
        stack: stack.toString(),
        source: 'FullFranchiseSubscriptionListScreen',
        screen: 'full_franchise_subscription_list_screen',
        severity: 'error',
        contextData: {'exception': e.toString()},
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AdminUserProvider>().user;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAuthorized =
        user?.isDeveloper == true || user?.isPlatformOwner == true;

    if (!isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.franchiseSubscriptionsTitle)),
        body: Center(
          child: Text(
            loc.unauthorizedAccessMessage,
            style:
                theme.textTheme.bodyLarge?.copyWith(color: colorScheme.error),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.franchiseSubscriptionsTitle),
        backgroundColor: colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<EnrichedFranchiseSubscription>>(
          future: _enrichedSubsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final subs = snapshot.data ?? [];

            if (subs.isEmpty) {
              return Center(child: Text(loc.noSubscriptionsFound));
            }

            return ListView.separated(
              itemCount: subs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final enriched = subs[index];

                return FranchiseSubscriptionListTile(
                  key: ValueKey(enriched.subscription.id),
                  enriched: enriched,
                  onRefreshRequested: () {
                    setState(() {
                      _enrichedSubsFuture = _loadEnrichedSubscriptions();
                    });
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
