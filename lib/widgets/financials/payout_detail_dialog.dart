import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/models/payout.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';

// Add the two new widgets here:
import 'package:franchise_admin_portal/widgets/financials/payout_note_editor.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/attachment_uploader.dart';

class PayoutDetailDialog extends StatefulWidget {
  final String payoutId;
  const PayoutDetailDialog({Key? key, required this.payoutId})
      : super(key: key);

  @override
  State<PayoutDetailDialog> createState() => _PayoutDetailDialogState();
}

class _PayoutDetailDialogState extends State<PayoutDetailDialog> {
  late Future<Map<String, dynamic>?> _futurePayoutDetails;

  @override
  void initState() {
    super.initState();
    _futurePayoutDetails =
        FirestoreService().getPayoutDetailsWithAudit(widget.payoutId);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, minHeight: 360),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _futurePayoutDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              ErrorLogger.log(
                message: 'Failed to load payout details: ${snapshot.error}',
                stack: snapshot.stackTrace?.toString(),
                screen: 'PayoutDetailDialog',
                source: 'PayoutDetailDialog',
                severity: 'error',
                contextData: {'payoutId': widget.payoutId},
              );
              return EmptyStateWidget(
                title: loc.failedToLoadSummary,
                message: loc.tryAgainLater,
                imageAsset: BrandingConfig.bannerPlaceholder,
                onRetry: () => setState(() {
                  _futurePayoutDetails = FirestoreService()
                      .getPayoutDetailsWithAudit(widget.payoutId);
                }),
                buttonText: loc.retry,
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return EmptyStateWidget(
                title: loc.noDataFound ?? 'No Data',
                message: loc.payoutNotFound ?? 'Payout not found.',
                imageAsset: BrandingConfig.bannerPlaceholder,
                onRetry: () => setState(() {
                  _futurePayoutDetails = FirestoreService()
                      .getPayoutDetailsWithAudit(widget.payoutId);
                }),
                buttonText: loc.retry,
              );
            }

            final payout = Payout.fromFirestore(data, data['id']);
            final List<Map<String, dynamic>> auditTrail =
                (data['audit_trail'] as List<dynamic>? ?? [])
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();

            // Wire in all new features, modular and replace old logic!
            return Scaffold(
              backgroundColor: colorScheme.background,
              appBar: AppBar(
                backgroundColor: colorScheme.surface,
                title: Text('${loc.payoutDetail} (${payout.id})'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: loc.retry,
                    onPressed: () => setState(() {
                      _futurePayoutDetails = FirestoreService()
                          .getPayoutDetailsWithAudit(widget.payoutId);
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: loc.close,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PayoutSummarySection(
                        payout: payout, loc: loc, theme: theme),
                    const SizedBox(height: 28),
                    _AuditTrailSection(
                        auditTrail: auditTrail, loc: loc, theme: theme),
                    const SizedBox(height: 24),
                    // 1. AttachmentUploader
                    AttachmentUploader(
                      payoutId: payout.id,
                      // Pass other needed args (user id, role, etc) as required by your widget
                      existingAttachments:
                          payout.customFields['attachments'] ?? [],
                      onUploaded: () => setState(() {
                        // Re-fetch details to get new attachments
                        _futurePayoutDetails = FirestoreService()
                            .getPayoutDetailsWithAudit(widget.payoutId);
                      }),
                      onDeleted: () => setState(() {
                        _futurePayoutDetails = FirestoreService()
                            .getPayoutDetailsWithAudit(widget.payoutId);
                      }),
                    ),
                    const SizedBox(height: 24),
                    // 2. PayoutNoteEditor
                    PayoutNoteEditor(
                      payoutId: payout.id,
                      // Ideally wire in the correct user id from app state/provider:
                      userId:
                          null, // <-- Replace with correct userId if available
                      developerOnly: false, // Or guard by role
                      initialNotes: payout.customFields['comments'] != null
                          ? List<Map<String, dynamic>>.from(
                              payout.customFields['comments'])
                          : null,
                    ),
                    const SizedBox(height: 20),
                    // Any future features (disputes, adjustments, etc) go below
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// These three stateless widgets remain unchanged except for the removal of any legacy notes/attachments display. All support note and attachment UI/logic is now in the new widgets above.
class _PayoutSummarySection extends StatelessWidget {
  final Payout payout;
  final AppLocalizations loc;
  final ThemeData theme;

  const _PayoutSummarySection({
    required this.payout,
    required this.loc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime? dt) =>
        dt != null ? MaterialLocalizations.of(context).formatFullDate(dt) : '-';

    Widget value(String v) => Text(v, style: theme.textTheme.bodyMedium);
    Widget valueBold(String v) => Text(v,
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
            2: IntrinsicColumnWidth(),
            3: FlexColumnWidth(),
          },
          children: [
            TableRow(children: [
              Text('${loc.status}:', style: theme.textTheme.bodyMedium),
              valueBold(payout.status),
              Text('${loc.amount}:', style: theme.textTheme.bodyMedium),
              value('\$${payout.amount.toStringAsFixed(2)} ${payout.currency}'),
            ]),
            TableRow(children: [
              Text('${loc.payoutMethod ?? "Method"}:',
                  style: theme.textTheme.bodyMedium),
              value(payout.customFields['method'] ?? '-'),
              Text('${loc.bankAccount ?? "Account"}:',
                  style: theme.textTheme.bodyMedium),
              value(payout.customFields['bank_account_last4'] != null
                  ? '****${payout.customFields['bank_account_last4']}'
                  : '-'),
            ]),
            TableRow(children: [
              Text('${loc.createdAt}:', style: theme.textTheme.bodyMedium),
              value(formatDate(payout.scheduledAt)),
              Text('${loc.sentAt ?? "Sent At"}:',
                  style: theme.textTheme.bodyMedium),
              value(formatDate(payout.sentAt)),
            ]),
            TableRow(children: [
              Text('${loc.notes}:', style: theme.textTheme.bodyMedium),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: value(payout.customFields['notes'] ?? '-'),
              ),
              Text('${loc.failureReason}:', style: theme.textTheme.bodyMedium),
              value(payout.failureReason ?? '-'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _AuditTrailSection extends StatelessWidget {
  final List<Map<String, dynamic>> auditTrail;
  final AppLocalizations loc;
  final ThemeData theme;

  const _AuditTrailSection({
    required this.auditTrail,
    required this.loc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (auditTrail.isEmpty) {
      return Card(
        color: theme.colorScheme.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(loc.noAuditTrailFound ?? "No audit trail found.",
              style: theme.textTheme.bodySmall),
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.auditTrail, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final event in auditTrail)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    Icon(Icons.circle,
                        size: 10, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(event['event'] ?? '')),
                    if (event['timestamp'] != null)
                      Text(
                        MaterialLocalizations.of(context).formatShortDate(
                          (event['timestamp'] is DateTime)
                              ? event['timestamp']
                              : DateTime.tryParse(
                                      event['timestamp']?.toString() ?? '') ??
                                  DateTime.now(),
                        ),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.disabledColor),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
