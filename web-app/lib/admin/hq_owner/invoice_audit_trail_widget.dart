// File: lib/admin/hq_owner/invoice_audit_trail_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:shared_core/src/core/models/invoice.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

/// InvoiceAuditTrailWidget
/// Displays a chronological timeline of audit events for a given invoice.
/// Shows event type, timestamp, user info, and optional notes.
/// Designed for franchise HQ/Owner portals with localization, theming,
/// and modular UI architecture.

class InvoiceAuditTrailWidget extends StatelessWidget {
  final List<InvoiceAuditEvent> auditEvents;

  const InvoiceAuditTrailWidget({Key? key, required this.auditEvents})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    if (auditEvents.isEmpty) {
      return Center(
        child: Text(loc.noAuditTrail),
      );
    }

    final sortedEvents = List<InvoiceAuditEvent>.from(auditEvents)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        final isLast = index == sortedEvents.length - 1;
        return _buildTimelineTile(context, event, isLast);
      },
    );
  }

  Widget _buildTimelineTile(
      BuildContext context, InvoiceAuditEvent event, bool isLast) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final theme = Theme.of(context);

    final formattedDate =
        MaterialLocalizations.of(context).formatShortDate(event.timestamp);
    final formattedTime = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(event.timestamp),
      alwaysUse24HourFormat: false,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Container(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: DesignTokens.paddingMd),

          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedEventType(event.eventType, loc),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$formattedDate $formattedTime',
                  style: theme.textTheme.bodySmall,
                ),
                if (event.userId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${loc.byUser}: ${event.userId}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (event.notes != null && event.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      event.notes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _localizedEventType(String eventType, AppLocalizations loc) {
    switch (eventType.toLowerCase()) {
      case 'created':
        return loc.eventCreated;
      case 'sent':
        return loc.eventSent;
      case 'viewed':
        return loc.eventViewed;
      case 'paid':
        return loc.eventPaid;
      case 'overdue':
        return loc.eventOverdue;
      case 'refunded':
        return loc.eventRefunded;
      case 'voided':
        return loc.eventVoided;
      case 'failed':
        return loc.eventFailed;
      default:
        return eventType;
    }
  }
}


