import 'package:flutter/material.dart';
import 'package:shared_core/src/core/models/error_log.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/collapsible_panel.dart';
import 'package:shared_core/src/core/providers/franchise_provider.dart';

String _truncateTooltip(String text, [int max = 150]) {
  if (text.length <= max) return text;
  return text.substring(0, max) + '...';
}

class ErrorLogDetailDrawer extends StatefulWidget {
  final ErrorLog log;
  const ErrorLogDetailDrawer({Key? key, required this.log}) : super(key: key);

  @override
  State<ErrorLogDetailDrawer> createState() => _ErrorLogDetailDrawerState();
}

class _ErrorLogDetailDrawerState extends State<ErrorLogDetailDrawer> {
  final _commentController = TextEditingController();
  bool _isCommenting = false;
  bool _isResolving = false;
  bool _isArchiving = false;
  late ErrorLog log;

  @override
  void initState() {
    super.initState();
    log = widget.log;
  }

  Future<void> _addComment() async {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isCommenting = true);
    try {
      final comment = {
        'text': text,
        'userId': log.userId ?? 'system',
        'timestamp': DateTime.now().toIso8601String(),
      };
      await context
          .read<FirestoreService>()
          .addCommentToErrorLog(franchiseId, log.id, comment);
      setState(() {
        log = log.copyWith(
          comments: List<Map<String, dynamic>>.from(log.comments)..add(comment),
        );
        _commentController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commentAdded)));
    } finally {
      setState(() => _isCommenting = false);
    }
  }

  Future<void> _toggleResolved() async {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    setState(() => _isResolving = true);
    try {
      await context
          .read<FirestoreService>()
          .setErrorLogStatus(franchiseId, log.id, resolved: !(log.resolved));
      setState(() {
        log = log.copyWith(resolved: !log.resolved);
      });
    } finally {
      setState(() => _isResolving = false);
    }
  }

  Future<void> _toggleArchived() async {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    setState(() => _isArchiving = true);
    try {
      await context
          .read<FirestoreService>()
          .setErrorLogStatus(franchiseId, log.id, archived: !(log.archived));
      setState(() {
        log = log.copyWith(archived: !log.archived);
      });
    } finally {
      setState(() => _isArchiving = false);
    }
  }

  String _timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return AppLocalizations.of(context)!.justNow;
    if (diff.inMinutes < 60)
      return AppLocalizations.of(context)!.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24)
      return AppLocalizations.of(context)!.hoursAgo(diff.inHours);
    return AppLocalizations.of(context)!.daysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.errorDetailsTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    log.severity.toLowerCase() == 'fatal'
                        ? Icons.error
                        : Icons.warning,
                    color: log.severity.toLowerCase() == 'fatal'
                        ? colorScheme.error
                        : colorScheme.secondary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    log.severity,
                    style: TextStyle(
                      color: log.severity.toLowerCase() == 'fatal'
                          ? colorScheme.error
                          : colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp),
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7))),
                ],
              ),
              const SizedBox(height: 18),
              SelectableText(
                log.message,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),

              if (log.stackTrace != null && log.stackTrace!.isNotEmpty) ...[
                const SizedBox(height: 18),
                CollapsiblePanel(
                  title: loc.stackTraceSection,
                  child: Container(
                    width: double.infinity,
                    color: colorScheme.surfaceVariant,
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        log.stackTrace!,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
              if (log.contextData != null && log.contextData!.isNotEmpty) ...[
                const SizedBox(height: 8),
                CollapsiblePanel(
                  title: loc.contextDataSection,
                  child: Container(
                    width: double.infinity,
                    color: colorScheme.surfaceVariant,
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        const JsonEncoder.withIndent('  ')
                            .convert(log.contextData),
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
              if (log.deviceInfo != null && log.deviceInfo!.isNotEmpty) ...[
                const SizedBox(height: 8),
                CollapsiblePanel(
                  title: loc.deviceInfoSection,
                  child: Container(
                    width: double.infinity,
                    color: colorScheme.surfaceVariant,
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        const JsonEncoder.withIndent('  ')
                            .convert(log.deviceInfo),
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                children: [
                  Tooltip(
                    message: log.resolved
                        ? loc.resolvedTooltip
                        : loc.unresolvedTooltip,
                    child: Chip(
                      avatar: Icon(
                        log.resolved
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: log.resolved
                            ? colorScheme.secondary
                            : colorScheme.outline,
                      ),
                      label: Text(
                        log.resolved ? loc.resolved : loc.unresolvedOnly,
                        style: TextStyle(
                          color: log.resolved
                              ? colorScheme.secondary
                              : colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: log.archived
                        ? loc.archivedTooltip
                        : loc.notArchivedTooltip,
                    child: Chip(
                      avatar: Icon(
                        log.archived ? Icons.archive : Icons.unarchive,
                        color: log.archived
                            ? colorScheme.secondary
                            : colorScheme.outline,
                      ),
                      label: Text(
                        log.archived ? loc.archived : loc.active,
                        style: TextStyle(
                          color: log.archived
                              ? colorScheme.secondary
                              : colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  if (log.userId != null)
                    Tooltip(
                      message: loc.userIdTooltip,
                      child: Chip(
                        avatar: const Icon(Icons.person),
                        label: Text("${loc.userLabel}: ${log.userId!}"),
                      ),
                    ),
                ],
              ),
              if (log.comments.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(loc.commentsSection,
                    style: Theme.of(context).textTheme.titleMedium),
                Column(
                  children: log.comments.map((comment) {
                    DateTime? timestamp;
                    if (comment['timestamp'] != null) {
                      timestamp = DateTime.tryParse(comment['timestamp']);
                    }
                    final timeAgo =
                        timestamp != null ? _timeAgo(timestamp) : '';
                    return Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.comment,
                              color: colorScheme.secondary, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              comment['text'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (comment['userId'] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(
                                  (comment['userId'] as String?)?.isNotEmpty ==
                                          true
                                      ? comment['userId'][0].toUpperCase()
                                      : '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (timeAgo.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                timeAgo,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Add comment box
              const SizedBox(height: 18),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: loc.addCommentHint,
                  suffixIcon: _isCommenting
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          tooltip: loc.addCommentTooltip,
                          onPressed: _isCommenting ? null : _addComment,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                minLines: 1,
                maxLines: 4,
                enabled: !_isCommenting,
              ),
              const SizedBox(height: 18),
              IntrinsicWidth(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Tooltip(
                        message: loc.copyErrorTooltip,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: Text(loc.copy),
                          onPressed: () {
                            final errorJson = log.toJson();
                            Clipboard.setData(ClipboardData(
                                text: const JsonEncoder.withIndent('  ')
                                    .convert(errorJson)));
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.copiedJson)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(
                                96, 44), // 96 is a good web min width
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Tooltip(
                        message: log.resolved
                            ? loc.unresolveTooltip
                            : loc.resolveTooltip,
                        child: ElevatedButton.icon(
                          icon: Icon(log.resolved
                              ? Icons.radio_button_unchecked
                              : Icons.check_circle),
                          label:
                              Text(log.resolved ? loc.unresolve : loc.resolve),
                          onPressed: _isResolving ? null : _toggleResolved,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                            minimumSize: const Size(96, 44),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Tooltip(
                        message: log.archived
                            ? loc.unarchiveTooltip
                            : loc.archiveTooltip,
                        child: ElevatedButton.icon(
                          icon: Icon(log.archived
                              ? Icons.unarchive
                              : Icons.archive_outlined),
                          label:
                              Text(log.archived ? loc.unarchive : loc.archive),
                          onPressed: _isArchiving ? null : _toggleArchived,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.tertiary,
                            foregroundColor: colorScheme.onTertiary,
                            minimumSize: const Size(96, 44),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Tooltip(
                        message: loc.closeTooltip,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: Text(loc.close),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(96, 44),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

extension ErrorLogCopyWith on ErrorLog {
  ErrorLog copyWith({
    String? id,
    String? message,
    String? severity,
    String? source,
    String? screen,
    String? stackTrace,
    Map<String, dynamic>? contextData,
    Map<String, dynamic>? deviceInfo,
    String? userId,
    String? errorType,
    String? assignedTo,
    bool? resolved,
    bool? archived,
    List<Map<String, dynamic>>? comments,
    DateTime? timestamp,
    DateTime? updatedAt,
  }) {
    return ErrorLog(
      id: id ?? this.id,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      source: source ?? this.source,
      screen: screen ?? this.screen,
      stackTrace: stackTrace ?? this.stackTrace,
      contextData: contextData ?? this.contextData,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      userId: userId ?? this.userId,
      errorType: errorType ?? this.errorType,
      assignedTo: assignedTo ?? this.assignedTo,
      resolved: resolved ?? this.resolved,
      archived: archived ?? this.archived,
      comments: comments ?? this.comments,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


