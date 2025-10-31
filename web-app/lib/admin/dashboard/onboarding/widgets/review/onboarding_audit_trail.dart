// File: lib/admin/dashboard/onboarding/widgets/review/onboarding_audit_trail.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../../../../packages/shared_core/lib/src/core/models/audit_log.dart';
import '../../../../../../../packages/shared_core/lib/src/core/services/audit_log_service.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';

/// Displays recent onboarding audit trail events for the current franchise.
/// - Fetches logs from AuditLogService
/// - Shows event type, timestamp, user info, and allows data export/download
class OnboardingAuditTrail extends StatefulWidget {
  final String franchiseId;

  const OnboardingAuditTrail({Key? key, required this.franchiseId})
      : super(key: key);

  @override
  State<OnboardingAuditTrail> createState() => _OnboardingAuditTrailState();
}

class _OnboardingAuditTrailState extends State<OnboardingAuditTrail> {
  List<AuditLog> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auditLogService =
          Provider.of<AuditLogService>(context, listen: false);
      final logs =
          await auditLogService.getOnboardingAuditLogs(widget.franchiseId);

      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[OnboardingAuditTrail][ERROR] $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Onboarding Audit Trail",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17.2,
                color: colorScheme.primary,
                fontFamily: DesignTokens.fontFamily,
                letterSpacing: 0.11,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: EmptyStateWidget(
                  iconData: Icons.error_outline,
                  title: "Audit Trail Failed",
                  message: _error!,
                ),
              )
            else if (_logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: EmptyStateWidget(
                  iconData: Icons.history_toggle_off_rounded,
                  title: "No Onboarding Events",
                  message:
                      "No onboarding publish or audit events found for this franchise.",
                ),
              )
            else
              _buildAuditList(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditList(BuildContext context, ColorScheme colorScheme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => Divider(
          height: 18, color: colorScheme.outlineVariant.withOpacity(0.11)),
      itemBuilder: (context, idx) {
        final log = _logs[idx];
        IconData icon;
        Color iconColor;
        String label;
        switch (log.eventType) {
          case AuditLogEventType.publishOnboarding:
            icon = Icons.rocket_launch_rounded;
            iconColor = colorScheme.primary;
            label = "Published";
            break;
          case AuditLogEventType.cancelOnboarding:
            icon = Icons.cancel_rounded;
            iconColor = colorScheme.error;
            label = "Cancelled";
            break;
          case AuditLogEventType.editOnboarding:
            icon = Icons.edit_rounded;
            iconColor = colorScheme.tertiary;
            label = "Edited";
            break;
          default:
            icon = Icons.info_outline_rounded;
            iconColor = colorScheme.secondary;
            label = log.eventType?.toString() ?? "Other";
        }
        final dt = log.createdAt;
        final user = log.userName ?? log.userEmail ?? "Unknown user";

        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          leading: Icon(icon, color: iconColor, size: 28),
          title: Text(
            "$label Onboarding",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: iconColor,
              fontSize: 15.7,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.73),
                  fontSize: 14.2,
                ),
              ),
              if (dt != null)
                Text(
                  _formatDateTime(dt),
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.61),
                    fontSize: 13.2,
                  ),
                ),
              if (log.exportSnapshot != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: TextButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export snapshot'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    onPressed: () {
                      _copyExportSnapshot(context, log.exportSnapshot!);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    // Use local formatting or package:intl for more advanced options if desired
    return "${dt.year}-${_two(dt.month)}-${_two(dt.day)}  ${_two(dt.hour)}:${_two(dt.minute)}";
  }

  String _two(int n) => n < 10 ? "0$n" : "$n";

  Future<void> _copyExportSnapshot(
      BuildContext context, Map<String, dynamic> snapshot) async {
    try {
      // Exports JSON to clipboard; could use a download utility if running on web
      final jsonStr = snapshot.toString();
      await Clipboard.setData(ClipboardData(text: jsonStr));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audit snapshot copied to clipboard.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy export: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
