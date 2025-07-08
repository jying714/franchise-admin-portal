import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/error_log.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';

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
          .addCommentToErrorLog(log.id, comment);
      setState(() {
        log = log.copyWith(
          comments: List<Map<String, dynamic>>.from(log.comments)..add(comment),
        );
        _commentController.clear();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Comment added.')));
    } finally {
      setState(() => _isCommenting = false);
    }
  }

  Future<void> _toggleResolved() async {
    setState(() => _isResolving = true);
    try {
      await context
          .read<FirestoreService>()
          .setErrorLogStatus(log.id, resolved: !(log.resolved));
      setState(() {
        log = log.copyWith(resolved: !log.resolved);
      });
    } finally {
      setState(() => _isResolving = false);
    }
  }

  Future<void> _toggleArchived() async {
    setState(() => _isArchiving = true);
    try {
      await context
          .read<FirestoreService>()
          .setErrorLogStatus(log.id, archived: !(log.archived));
      setState(() {
        log = log.copyWith(archived: !log.archived);
      });
    } finally {
      setState(() => _isArchiving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              Text('Error Details',
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
                Text('Stack Trace',
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: colorScheme.surfaceVariant,
                  child: SelectableText(
                    log.stackTrace!,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ],
              if (log.contextData != null && log.contextData!.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Context Data',
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  width: double.infinity,
                  color: colorScheme.surfaceVariant,
                  padding: const EdgeInsets.all(10),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(log.contextData),
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ],
              if (log.deviceInfo != null && log.deviceInfo!.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Device Info',
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  width: double.infinity,
                  color: colorScheme.surfaceVariant,
                  padding: const EdgeInsets.all(10),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(log.deviceInfo),
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ],
              // Advanced error fields
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                children: [
                  Chip(
                    avatar: Icon(
                      log.resolved
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: log.resolved
                          ? colorScheme.secondary
                          : colorScheme.outline,
                    ),
                    label: Text(
                      log.resolved ? "Resolved" : "Unresolved",
                      style: TextStyle(
                        color: log.resolved
                            ? colorScheme.secondary
                            : colorScheme.outline,
                      ),
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      log.archived ? Icons.archive : Icons.unarchive,
                      color: log.archived
                          ? colorScheme.secondary
                          : colorScheme.outline,
                    ),
                    label: Text(
                      log.archived ? "Archived" : "Active",
                      style: TextStyle(
                        color: log.archived
                            ? colorScheme.secondary
                            : colorScheme.outline,
                      ),
                    ),
                  ),
                  if (log.userId != null)
                    Chip(
                      avatar: const Icon(Icons.person),
                      label: Text("User: ${log.userId!}"),
                    ),
                  if (log.assignedTo != null)
                    Chip(
                      avatar: const Icon(Icons.assignment_ind),
                      label: Text("Assigned: ${log.assignedTo!}"),
                    ),
                ],
              ),
              if (log.comments.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text('Comments',
                    style: Theme.of(context).textTheme.titleMedium),
                Column(
                  children: log.comments
                      .map((comment) => Container(
                            alignment: Alignment.centerLeft,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
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
                                    child: Text(
                                      comment['userId'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                  ),
                                if (comment['timestamp'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      DateFormat('MM-dd HH:mm').format(
                                          DateTime.tryParse(
                                                  comment['timestamp'] ?? '') ??
                                              DateTime.now()),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
              // Add comment box
              const SizedBox(height: 18),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "Add a comment...",
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
                          onPressed: _addComment,
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
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                        onPressed: () {
                          final errorJson = log.toJson();
                          Clipboard.setData(ClipboardData(
                              text: const JsonEncoder.withIndent('  ')
                                  .convert(errorJson)));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Copied error JSON!')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize:
                              const Size(96, 44), // 96 is a good web min width
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ElevatedButton.icon(
                        icon: Icon(log.resolved
                            ? Icons.radio_button_unchecked
                            : Icons.check_circle),
                        label: Text(log.resolved ? "Unresolve" : "Resolve"),
                        onPressed: _isResolving ? null : _toggleResolved,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          minimumSize: const Size(96, 44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ElevatedButton.icon(
                        icon: Icon(log.archived
                            ? Icons.unarchive
                            : Icons.archive_outlined),
                        label: Text(log.archived ? "Unarchive" : "Archive"),
                        onPressed: _isArchiving ? null : _toggleArchived,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: colorScheme.onTertiary,
                          minimumSize: const Size(96, 44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size(96, 44),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
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
