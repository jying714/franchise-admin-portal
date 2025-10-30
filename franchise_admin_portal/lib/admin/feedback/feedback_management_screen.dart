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
import 'package:franchise_admin_portal/widgets/feedback/feedback_detail_dialog.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  String _filterType = 'all';
  String _sortOrder = 'recent';
  String _search = '';

  void _confirmDelete(
      BuildContext context, FirestoreService service, String feedbackId) {
    final loc = AppLocalizations.of(context);
    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    if (loc == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.deleteFeedback),
        content: Text(loc.deleteFeedbackConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await service.deleteFeedbackEntry(franchiseId, feedbackId);
              if (!mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  // void _showFeedbackDetailDialog(BuildContext context,
  //     feedback_model.FeedbackEntry feedback, AppLocalizations loc) {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: Row(
  //         children: [
  //           _TypeIcon(feedback: feedback),
  //           const SizedBox(width: 8),
  //           Text(
  //             feedback.feedbackMode == 'orderExperience'
  //                 ? loc.filterOrderFeedback
  //                 : loc.filterAppFeedback,
  //             style: const TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           ...List.generate(
  //             5,
  //             (idx) => Icon(
  //               idx < feedback.rating ? Icons.star : Icons.star_border,
  //               color:
  //                   idx < feedback.rating ? Colors.amber : Colors.grey.shade400,
  //               size: 18,
  //             ),
  //           ),
  //         ],
  //       ),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             if (feedback.orderId.isNotEmpty)
  //               Text('${loc.orderIdLabel}: ${feedback.orderId}'),
  //             if (feedback.anonymous)
  //               Padding(
  //                 padding: const EdgeInsets.only(top: 6),
  //                 child: Text(loc.feedbackAnonymous,
  //                     style: const TextStyle(color: Colors.grey)),
  //               ),
  //             if (feedback.categories.isNotEmpty)
  //               Padding(
  //                 padding: const EdgeInsets.only(top: 2.0),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: feedback.categories.map((catScore) {
  //                     final parts = catScore.split(':');
  //                     return Padding(
  //                       padding: const EdgeInsets.only(bottom: 4),
  //                       child: Chip(
  //                         label: Text(
  //                           parts.length > 1
  //                               ? '${parts[0].trim()}: ${parts[1].trim()}'
  //                               : catScore,
  //                           style: const TextStyle(fontSize: 13),
  //                         ),
  //                         backgroundColor: DesignTokens.surfaceColor,
  //                         side: BorderSide.none,
  //                         visualDensity: VisualDensity.compact,
  //                       ),
  //                     );
  //                   }).toList(),
  //                 ),
  //               ),
  //             Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 8),
  //               child: Text(
  //                 feedback.comment?.isNotEmpty == true
  //                     ? feedback.comment!
  //                     : (feedback.message.isNotEmpty
  //                         ? feedback.message
  //                         : loc.noMessage),
  //                 style: const TextStyle(fontSize: 15),
  //               ),
  //             ),
  //             Text(
  //                 '${loc.submitted}: ${DateFormat('yyyy-MM-dd – HH:mm').format(feedback.timestamp)}',
  //                 style: const TextStyle(fontSize: 12, color: Colors.grey)),
  //             if (feedback.userId.isNotEmpty && !feedback.anonymous)
  //               Padding(
  //                 padding: const EdgeInsets.only(top: 6),
  //                 child: Text('User: ${feedback.userId}',
  //                     style: const TextStyle(fontSize: 12, color: Colors.grey)),
  //               ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: Text(loc.close),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final firestoreService = context.read<FirestoreService>();
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dropdownTextStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.black87,
    );

    if (loc == null) {
      return const Scaffold(body: Center(child: Text('Localization missing')));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Row(
        children: [
          Expanded(
            flex: 11,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(loc.feedbackManagement,
                          style: theme.textTheme.titleLarge),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _filterType,
                        onChanged: (val) => setState(() => _filterType = val!),
                        items: [
                          DropdownMenuItem(
                              value: 'all',
                              child:
                                  Text(loc.allTypes, style: dropdownTextStyle)),
                          DropdownMenuItem(
                              value: 'ordering',
                              child: Text(loc.filterAppFeedback,
                                  style: dropdownTextStyle)),
                          DropdownMenuItem(
                              value: 'orderExperience',
                              child: Text(loc.filterOrderFeedback,
                                  style: dropdownTextStyle)),
                        ],
                        dropdownColor: Theme.of(context).cardColor,
                        style: dropdownTextStyle,
                        underline: const SizedBox(),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _sortOrder,
                        onChanged: (val) => setState(() => _sortOrder = val!),
                        items: [
                          DropdownMenuItem(
                              value: 'recent',
                              child: Text(loc.sortRecent,
                                  style: dropdownTextStyle)),
                          DropdownMenuItem(
                              value: 'oldest',
                              child: Text(loc.sortOldest,
                                  style: dropdownTextStyle)),
                          DropdownMenuItem(
                              value: 'lowest',
                              child: Text(loc.sortLowest,
                                  style: dropdownTextStyle)),
                          DropdownMenuItem(
                              value: 'highest',
                              child: Text(loc.sortHighest,
                                  style: dropdownTextStyle)),
                        ],
                        dropdownColor: Theme.of(context).cardColor,
                        style: dropdownTextStyle,
                        underline: const SizedBox(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: loc.searchFeedback,
                            prefixIcon: const Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                  width: 0.5, color: Colors.grey.shade400),
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<List<feedback_model.FeedbackEntry>>(
                      stream: firestoreService.getFeedbackEntries(franchiseId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text(loc.noFeedbackSubmitted));
                        }
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
                                  f.categories.any(
                                      (c) => c.toLowerCase().contains(s)) ||
                                  f.orderId.toLowerCase().contains(s) ||
                                  f.userId.toLowerCase().contains(s))
                              .toList();
                        }
                        switch (_sortOrder) {
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
                          default:
                            feedbacks.sort(
                                (a, b) => b.timestamp.compareTo(a.timestamp));
                        }
                        return ListView.separated(
                          itemCount: feedbacks.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final feedback = feedbacks[i];
                            final isOrderFeedback =
                                feedback.feedbackMode == 'orderExperience';
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
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
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.secondary,
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
                                        style: const TextStyle(fontSize: 12)),
                                  if (feedback.categories.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: feedback.categories
                                              .map((catScore) {
                                            final parts = catScore.split(':');
                                            final labelText = parts.length > 1
                                                ? '${parts[0].trim()}: ${parts[1].trim()}'
                                                : catScore;

                                            final theme = Theme.of(context);
                                            final chipBackground = theme
                                                .colorScheme.surfaceVariant;
                                            final chipTextColor = theme
                                                .colorScheme.onSurfaceVariant;

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: Chip(
                                                label: Text(
                                                  labelText,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: chipTextColor,
                                                  ),
                                                ),
                                                backgroundColor: chipBackground,
                                                side: BorderSide.none,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  if ((feedback.comment?.isNotEmpty ?? false) ||
                                      feedback.message.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('${loc.notesLabel ?? 'Notes:'} ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13)),
                                          Expanded(
                                            child: Text(
                                              feedback.comment?.isNotEmpty ==
                                                      true
                                                  ? feedback.comment!
                                                  : feedback.message,
                                              style:
                                                  const TextStyle(fontSize: 13),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
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
                                onSelected: (val) {
                                  if (val == 'delete') {
                                    _confirmDelete(
                                        context, firestoreService, feedback.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete,
                                            color: Colors.red, size: 18),
                                        const SizedBox(width: 6),
                                        Text(loc.delete),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) =>
                                    FeedbackDetailDialog(feedback: feedback),
                              ),
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
          const Expanded(flex: 9, child: SizedBox()),
        ],
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final feedback_model.FeedbackEntry feedback;
  const _TypeIcon({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final isOrderFeedback = feedback.feedbackMode == 'orderExperience';
    return Icon(
      isOrderFeedback ? Icons.fastfood : Icons.app_settings_alt,
      color: isOrderFeedback
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      size: 28,
    );
  }
}
