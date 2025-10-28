import 'package:flutter/material.dart';

/// Pagination controls for admin tables/lists.
/// Supports "Previous" and "Next" buttons, with page display.
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canGoBack = currentPage > 1;
    final canGoForward = currentPage < totalPages;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: canGoBack ? onPrevious : null,
          tooltip: 'Previous page',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Page $currentPage of $totalPages',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: canGoForward ? onNext : null,
          tooltip: 'Next page',
        ),
      ],
    );
  }
}
