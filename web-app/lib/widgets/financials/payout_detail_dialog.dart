import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/financials/payout_note_editor.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/attachment_uploader.dart';

class PayoutDetailDialog extends StatefulWidget {
  final String payoutId;

  const PayoutDetailDialog({
    super.key,
    required this.payoutId,
  });

  @override
  State<PayoutDetailDialog> createState() => _PayoutDetailDialogState();
}

class _PayoutDetailDialogState extends State<PayoutDetailDialog> {
  late Future<Map<String, dynamic>?> _futurePayoutDetails;

  @override
  void initState() {
    super.initState();
    _futurePayoutDetails = _loadPayoutDetails();
  }

  Future<Map<String, dynamic>?> _loadPayoutDetails() async {
    try {
      final firestoreService = Provider.of<shared.FirestoreService>(
        context,
        listen: false,
      );
      return await firestoreService.getPayoutDetailsWithAudit(widget.payoutId);
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: 'Failed to load payout details: $e',
        stack: stack.toString(),
        source: 'PayoutDetailDialog',
        severity: 'error',
        contextData: {'payoutId': widget.payoutId},
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const SizedBox.shrink();
    }

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
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return EmptyStateWidget(
                title: loc.failedToLoadSummary,
                message: loc.tryAgainLater,
                imageAsset: BrandingConfig.bannerPlaceholder,
                onRetry: () =>
                    setState(() => _futurePayoutDetails = _loadPayoutDetails()),
                buttonText: loc.retry,
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return EmptyStateWidget(
                title: loc.noDataFound ?? 'No Data',
                message: loc.payoutNotFound ?? 'Payout not found.',
                imageAsset: BrandingConfig.bannerPlaceholder,
                onRetry: () =>
                    setState(() => _futurePayoutDetails = _loadPayoutDetails()),
                buttonText: loc.retry,
              );
            }

            final payout = shared.Payout.fromFirestore(
                data, data['id'] ?? widget.payoutId);
            final List<Map<String, dynamic>> auditTrail =
                (data['audit_trail'] as List<dynamic>? ?? [])
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();

            return Scaffold(
              backgroundColor: colorScheme.background,
              appBar: AppBar(
                backgroundColor: colorScheme.surface,
                title: Text('${loc.payoutDetail} (${payout.id})'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: loc.retry,
                    onPressed: () => setState(
                        () => _futurePayoutDetails = _loadPayoutDetails()),
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
                      payout: payout,
                      loc: loc,
                      theme: theme,
                    ),
                    const SizedBox(height: 28),
                    _AuditTrailSection(
                      auditTrail: auditTrail,
                      loc: loc,
                      theme: theme,
                    ),
                    const SizedBox(height: 24),

                    // Attachment Uploader
                    AttachmentUploader(
                      payoutId: payout.id,
                      existingAttachments: payout.attachments,
                      onUploaded: () => setState(
                          () => _futurePayoutDetails = _loadPayoutDetails()),
                      onDeleted: () => setState(
                          () => _futurePayoutDetails = _loadPayoutDetails()),
                    ),

                    const SizedBox(height: 24),

                    // Payout Note Editor
                    PayoutNoteEditor(
                      payoutId: payout.id,
                      userId:
                          null, // TODO: Wire from Auth/AdminUserProvider when available
                      developerOnly: false,
                      initialNotes: payout.customFields['comments'] != null
                          ? List<Map<String, dynamic>>.from(
                              payout.customFields['comments'])
                          : null,
                    ),
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

class _PayoutSummarySection extends StatelessWidget {
  final shared.Payout payout;
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
    Widget valueBold(String v) => Text(
          v,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        );

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
              value(payout.method),
              Text('${loc.bankAccount ?? "Account"}:',
                  style: theme.textTheme.bodyMedium),
              value(payout.bankAccountLast4 != null
                  ? '****${payout.bankAccountLast4}'
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
                child: value(payout.notes ?? '-'),
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
          child: Text(
            loc.noAuditTrailFound ?? "No audit trail found.",
            style: theme.textTheme.bodySmall,
          ),
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
                              ? event['timestamp'] as DateTime
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
