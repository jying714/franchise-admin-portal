import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/app_config.dart';
import 'package:franchise_admin_portal/core/models/franchise_subscription_model.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';

class FullPlatformSubscriptionsScreen extends StatefulWidget {
  const FullPlatformSubscriptionsScreen({super.key});

  @override
  State<FullPlatformSubscriptionsScreen> createState() =>
      _FullPlatformSubscriptionsScreenState();
}

class _FullPlatformSubscriptionsScreenState
    extends State<FullPlatformSubscriptionsScreen> {
  late Future<List<FranchiseSubscription>> _subsFuture;

  @override
  void initState() {
    super.initState();
    _subsFuture = _loadSubscriptions();
  }

  Future<List<FranchiseSubscription>> _loadSubscriptions() async {
    try {
      return await FirestoreService.getFranchiseSubscriptions();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'load_platform_subscriptions_failed',
        stack: stack.toString(),
        source: 'FullPlatformSubscriptionsScreen',
        screen: 'full_platform_subscriptions_screen',
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
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (!(user?.isDeveloper ?? false) && !(user?.isPlatformOwner ?? false)) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.franchiseSubscriptionsTitle)),
        body: Center(
          child: Text(loc.unauthorizedAccessMessage,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.error)),
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
        child: FutureBuilder<List<FranchiseSubscription>>(
          future: _subsFuture,
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
                final sub = subs[index];
                return Card(
                  elevation: DesignTokens.adminCardElevation,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${loc.franchiseIdLabel}: ${sub.franchiseId}',
                                style: theme.textTheme.titleSmall),
                            const Spacer(),
                            Chip(
                              label: Text(loc.translateStatus(sub.status)),
                              backgroundColor:
                                  AppConfig.statusColor(sub.status, theme),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${loc.planIdLabel}: ${sub.platformPlanId}'),
                        const SizedBox(height: 4),
                        if (sub.isTrial)
                          Text(
                              '${loc.trialEndsLabel}: ${AppConfig.formatDate(sub.trialEndsAt)}',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: colorScheme.secondary)),
                        const SizedBox(height: 4),
                        Text(
                            '${loc.nextBillingLabel}: ${AppConfig.formatDate(sub.nextBillingDate)}'),
                        const SizedBox(height: 4),
                        if (sub.discountPercent > 0)
                          Text('${loc.discountLabel}: ${sub.discountPercent}%',
                              style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
