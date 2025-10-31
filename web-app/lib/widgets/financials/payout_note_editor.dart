import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import '../../../../packages/shared_core/lib/src/core/utils/error_logger.dart';

/// Widget to add/view notes/comments on a payout.
class PayoutNoteEditor extends StatefulWidget {
  final String payoutId;
  final String? userId;
  final bool developerOnly;
  final List<Map<String, dynamic>>? initialNotes;

  const PayoutNoteEditor({
    super.key,
    required this.payoutId,
    this.userId,
    this.developerOnly = false,
    this.initialNotes,
  });

  @override
  State<PayoutNoteEditor> createState() => _PayoutNoteEditorState();
}

class _PayoutNoteEditorState extends State<PayoutNoteEditor> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;
  String? _error;
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _notes = widget.initialNotes ?? [];
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    try {
      final notes = await FirestoreService().getPayoutComments(widget.payoutId);
      setState(() => _notes = notes);
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch payout comments: $e',
        stack: stack.toString(),
        source: 'PayoutNoteEditor',
        screen: 'payout_note_editor.dart',
        severity: 'error',
      );
    }
  }

  Future<void> _addNote() async {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[PayoutNoteEditor] loc is null! Localization not available for this context.');
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final note = {
        'message': text,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'userId': widget.userId,
        // You could add username, avatar, etc.
      };
      await FirestoreService().addPayoutComment(widget.payoutId, note);
      _controller.clear();
      _focusNode.unfocus();
      setState(() {
        _notes.insert(0, note);
        _submitting = false;
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to add payout note: $e',
        stack: stack.toString(),
        source: 'PayoutNoteEditor',
        screen: 'payout_note_editor.dart',
        severity: 'error',
      );
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.failedToSave ?? 'Failed to save note.')),
      );
    }
  }

  Future<void> _removeNote(Map<String, dynamic> note) async {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[PayoutNoteEditor] loc is null! Localization not available for this context.');
      return;
    }
    try {
      await FirestoreService().removePayoutComment(widget.payoutId, note);
      setState(() {
        _notes.remove(note);
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to remove payout note: $e',
        stack: stack.toString(),
        source: 'PayoutNoteEditor',
        screen: 'payout_note_editor.dart',
        severity: 'error',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.failedToDelete ?? 'Failed to delete note.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[PayoutNoteEditor] loc is null! Localization not available for this context.');
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final canAdd = !widget.developerOnly ||
        (widget.developerOnly &&
            Theme.of(context).brightness == Brightness.dark);

    return Card(
      color: colorScheme.surfaceVariant,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.notes ?? "Notes", style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (canAdd)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !_submitting,
                      decoration: InputDecoration(
                        hintText: loc.addNoteHint ?? "Add a note...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.adminButtonRadius),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    tooltip: loc.addNote ?? "Add Note",
                    onPressed: _submitting ? null : _addNote,
                  ),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            if (_notes.isEmpty)
              Text(loc.noNotesYet ?? "No notes yet.",
                  style: theme.textTheme.bodySmall),
            if (_notes.isNotEmpty)
              Column(
                children: _notes
                    .map((note) => ListTile(
                          leading: const Icon(Icons.sticky_note_2_outlined),
                          title: Text(note['message'] ?? '',
                              style: theme.textTheme.bodyMedium),
                          subtitle: Text(
                            _formatDate(note['createdAt'], context),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: colorScheme.outline),
                          ),
                          trailing: canAdd
                              ? IconButton(
                                  icon: Icon(Icons.delete,
                                      color: colorScheme.error),
                                  tooltip: loc.delete ?? 'Delete',
                                  onPressed: () => _removeNote(note),
                                )
                              : null,
                          // Optionally, support long-press to remove:
                          onLongPress: canAdd
                              ? () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(
                                          loc.deleteNote ?? 'Delete note?'),
                                      content: Text(loc.confirmDeleteNote ??
                                          'Are you sure you want to delete this note?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text(loc.cancel ?? 'Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text(loc.delete ?? 'Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (shouldDelete == true) {
                                    _removeNote(note);
                                  }
                                }
                              : null,
                        ))
                    .toList(),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                loc.featureComingSoon('Rich Text, tagging, attachments'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic value, BuildContext context) {
    if (value == null) return '';
    try {
      final dt = value is String ? DateTime.parse(value) : value as DateTime;
      return MaterialLocalizations.of(context).formatShortDate(dt);
    } catch (_) {
      return value.toString();
    }
  }
}
