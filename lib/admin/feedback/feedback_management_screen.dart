import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:franchise_admin_portal/core/models/feedback_entry.dart'
    as feedback_model;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  String _filterType = 'all'; // all, ordering, orderExperience
  String _sortOrder = 'recent'; // recent, oldest, lowest, highest
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content column
          Expanded(
            flex: 11,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          loc.feedbackManagement,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: DesignTokens.titleFontSize,
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.titleFontWeight,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon:
                              const Icon(Icons.refresh, color: Colors.black87),
                          onPressed: () => setState(() {}),
                          tooltip: loc.refresh,
                        ),
                      ],
                    ),
                  ),
                  // --- Filter & Sort Controls ---
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    child: Row(
                      children: [
                        // Filter by type
                        DropdownButton<String>(
                          value: _filterType,
                          onChanged: (val) =>
                              setState(() => _filterType = val!),
                          items: [
                            DropdownMenuItem(
                                value: 'all', child: Text(loc.allTypes)),
                            DropdownMenuItem(
                                value: 'ordering',
                                child: Text(loc.filterAppFeedback)),
                            DropdownMenuItem(
                                value: 'orderExperience',
                                child: Text(loc.filterOrderFeedback)),
                          ],
                          underline: SizedBox(),
                          style: TextStyle(color: DesignTokens.textColor),
                        ),
                        const SizedBox(width: 12),
                        // Sort order
                        DropdownButton<String>(
                          value: _sortOrder,
                          onChanged: (val) => setState(() => _sortOrder = val!),
                          items: [
                            DropdownMenuItem(
                                value: 'recent', child: Text(loc.sortRecent)),
                            DropdownMenuItem(
                                value: 'oldest', child: Text(loc.sortOldest)),
                            DropdownMenuItem(
                                value: 'lowest', child: Text(loc.sortLowest)),
                            DropdownMenuItem(
                                value: 'highest', child: Text(loc.sortHighest)),
                          ],
                          underline: SizedBox(),
                          style: TextStyle(color: DesignTokens.textColor),
                        ),
                        const SizedBox(width: 12),
                        // Search bar
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: loc.searchFeedback,
                              prefixIcon: const Icon(Icons.search, size: 18),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                    width: 0.5, color: Colors.grey.shade400),
                              ),
                              isDense: true,
                            ),
                            style: TextStyle(fontSize: 14),
                            onChanged: (v) => setState(() => _search = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- Feedback List ---
                  Expanded(
                    child: StreamBuilder<List<feedback_model.FeedbackEntry>>(
                      stream: firestoreService.getFeedbackEntries(franchiseId),
                      builder: (context, snapshot) {
                        print("Feedback snapshot: ${snapshot.data}");
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              loc.noFeedbackSubmitted,
                              style: TextStyle(
                                color: DesignTokens.secondaryTextColor,
                                fontSize: DesignTokens.bodyFontSize,
                                fontFamily: DesignTokens.fontFamily,
                              ),
                            ),
                          );
                        }

                        // --- Filtering & Sorting ---
                        List<feedback_model.FeedbackEntry> feedbacks =
                            snapshot.data!;
                        if (_filterType != 'all') {
                          feedbacks = feedbacks
                              .where((f) => f.feedbackMode == _filterType)
                              .toList();
                        }
                        if (_search.trim().isNotEmpty) {
                          final s = _search.toLowerCase();
                          feedbacks = feedbacks
                              .where((f) =>
                                  (f.comment?.toLowerCase().contains(s) ??
                                      false) ||
                                  (f.categories.any(
                                      (c) => c.toLowerCase().contains(s))) ||
                                  f.orderId.toLowerCase().contains(s) ||
                                  f.userId.toLowerCase().contains(s))
                              .toList();
                        }
                        switch (_sortOrder) {
                          case 'recent':
                            feedbacks.sort(
                                (a, b) => b.timestamp.compareTo(a.timestamp));
                            break;
                          case 'oldest':
                            feedbacks.sort(
                                (a, b) => a.timestamp.compareTo(b.timestamp));
                            break;
                          case 'lowest':
                            feedbacks
                                .sort((a, b) => a.rating.compareTo(b.rating));
                            break;
                          case 'highest':
                            feedbacks
                                .sort((a, b) => b.rating.compareTo(a.rating));
                            break;
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: feedbacks.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, thickness: 0.5),
                          itemBuilder: (context, i) {
                            final feedback = feedbacks[i];
                            final isOrderFeedback =
                                feedback.feedbackMode == 'orderExperience';

                            return ListTile(
                              leading: _TypeIcon(feedback: feedback),
                              title: Row(
                                children: [
                                  Text(
                                    isOrderFeedback
                                        ? loc.filterOrderFeedback
                                        : loc.filterAppFeedback,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isOrderFeedback
                                          ? DesignTokens.primaryColor
                                          : DesignTokens.secondaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Row(
                                    children: List.generate(
                                        5,
                                        (idx) => Icon(
                                              idx < feedback.rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: idx < feedback.rating
                                                  ? Colors.amber
                                                  : Colors.grey.shade400,
                                              size: 18,
                                            )),
                                  ),
                                  if (feedback.anonymous) ...[
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message: loc.feedbackAnonymous,
                                      child: const Icon(Icons.visibility_off,
                                          color: Colors.grey, size: 16),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (feedback.orderId.isNotEmpty)
                                    Text(
                                        '${loc.orderIdLabel}: ${feedback.orderId}',
                                        style: TextStyle(fontSize: 12)),
                                  if (feedback.categories.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            feedback.categories.map((catScore) {
                                          final parts = catScore.split(':');
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Chip(
                                              label: Text(
                                                parts.length > 1
                                                    ? '${parts[0].trim()}: ${parts[1].trim()}'
                                                    : catScore,
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                              backgroundColor:
                                                  DesignTokens.surfaceColor,
                                              side: BorderSide.none,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  if ((feedback.comment?.isNotEmpty ?? false) ||
                                      feedback.message.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 4, bottom: 2),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${loc.notesLabel ?? 'Notes:'} ',
                                            style: TextStyle(
                                              color: DesignTokens
                                                  .secondaryTextColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              feedback.comment?.isNotEmpty ==
                                                      true
                                                  ? feedback.comment!
                                                  : (feedback.message.isNotEmpty
                                                      ? feedback.message
                                                      : loc.noMessage),
                                              style: TextStyle(
                                                color: DesignTokens
                                                    .secondaryTextColor,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      DateFormat('yyyy-MM-dd – HH:mm')
                                          .format(feedback.timestamp),
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            color: Colors.red, size: 18),
                                        const SizedBox(width: 6),
                                        Text(loc.delete),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (val) {
                                  if (val == 'delete')
                                    _confirmDelete(
                                        context, firestoreService, feedback.id);
                                },
                              ),
                              onTap: () => _showFeedbackDetailDialog(
                                  context, feedback, loc),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right panel placeholder
          Expanded(
            flex: 9,
            child: Container(),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, FirestoreService service, String feedbackId) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[YourWidget] loc is null! Localization not available for this context.');
      // Optionally show a SnackBar:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Localization missing! [debug]')),
      );
      return; // Stop execution
    }
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.deleteFeedback),
        content: Text(loc.deleteFeedbackConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () async {
              await service.deleteFeedbackEntry(franchiseId, feedbackId);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDetailDialog(BuildContext context,
      feedback_model.FeedbackEntry feedback, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            _TypeIcon(feedback: feedback),
            const SizedBox(width: 8),
            Text(
              feedback.feedbackMode == 'orderExperience'
                  ? loc.filterOrderFeedback
                  : loc.filterAppFeedback,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...List.generate(
                5,
                (idx) => Icon(
                      idx < feedback.rating ? Icons.star : Icons.star_border,
                      color: idx < feedback.rating
                          ? Colors.amber
                          : Colors.grey.shade400,
                      size: 18,
                    )),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (feedback.orderId.isNotEmpty)
                Text('${loc.orderIdLabel}: ${feedback.orderId}'),
              if (feedback.anonymous)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(loc.feedbackAnonymous,
                      style: TextStyle(color: Colors.grey)),
                ),
              if (feedback.categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: feedback.categories.map((catScore) {
                      final parts = catScore.split(':');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Chip(
                          label: Text(
                            parts.length > 1
                                ? '${parts[0].trim()}: ${parts[1].trim()}'
                                : catScore,
                            style: const TextStyle(fontSize: 13),
                          ),
                          backgroundColor: DesignTokens.surfaceColor,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  feedback.comment?.isNotEmpty == true
                      ? feedback.comment!
                      : (feedback.message.isNotEmpty
                          ? feedback.message
                          : loc.noMessage),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              Text(
                  '${loc.submitted}: ${DateFormat('yyyy-MM-dd – HH:mm').format(feedback.timestamp)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (feedback.userId.isNotEmpty && !feedback.anonymous)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('User: ${feedback.userId}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }
}

// --- Helper Widget for Type Icon ---
class _TypeIcon extends StatelessWidget {
  final feedback_model.FeedbackEntry feedback;
  const _TypeIcon({required this.feedback});
  @override
  Widget build(BuildContext context) {
    final isOrderFeedback = feedback.feedbackMode == 'orderExperience';
    return Icon(
      isOrderFeedback ? Icons.fastfood : Icons.app_settings_alt,
      color: isOrderFeedback
          ? DesignTokens.primaryColor
          : DesignTokens.secondaryColor,
      size: 28,
    );
  }
}
