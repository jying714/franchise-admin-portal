import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// InvoiceSearchBar
/// A reusable widget for searching, filtering, and sorting invoice history.
/// Includes:
/// - Text search input with debounce support.
/// - Status dropdown filter.
/// - Sort order selector.
/// - Uses localized labels from AppLocalizations.
/// - Uses consistent spacing and theming from DesignTokens.
/// - Designed modularly to fit dashboard/filter panels.

typedef InvoiceSearchCallback = void Function(String? searchTerm);
typedef InvoiceStatusFilterCallback = void Function(String? status);
typedef InvoiceSortOrderCallback = void Function(InvoiceSortOrder order);

enum InvoiceSortOrder {
  dateAsc,
  dateDesc,
  totalAsc,
  totalDesc,
}

class InvoiceSearchBar extends StatefulWidget {
  final InvoiceSearchCallback? onSearchChanged;
  final InvoiceStatusFilterCallback? onStatusFilterChanged;
  final InvoiceSortOrderCallback? onSortOrderChanged;

  final String? initialSearchTerm;
  final String? initialStatusFilter;
  final InvoiceSortOrder initialSortOrder;

  const InvoiceSearchBar({
    Key? key,
    this.onSearchChanged,
    this.onStatusFilterChanged,
    this.onSortOrderChanged,
    this.initialSearchTerm,
    this.initialStatusFilter,
    this.initialSortOrder = InvoiceSortOrder.dateDesc,
  }) : super(key: key);

  @override
  State<InvoiceSearchBar> createState() => _InvoiceSearchBarState();
}

class _InvoiceSearchBarState extends State<InvoiceSearchBar> {
  late TextEditingController _searchController;
  String? _selectedStatus;
  late InvoiceSortOrder _selectedSortOrder;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.initialSearchTerm ?? '');
    _selectedStatus = widget.initialStatusFilter;
    _selectedSortOrder = widget.initialSortOrder;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    widget.onSearchChanged?.call(_searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim());
  }

  void _onStatusChanged(String? value) {
    setState(() {
      _selectedStatus = value;
    });
    widget.onStatusFilterChanged?.call(value);
  }

  void _onSortOrderChanged(InvoiceSortOrder? order) {
    if (order == null) return;
    setState(() {
      _selectedSortOrder = order;
    });
    widget.onSortOrderChanged?.call(order);
  }

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

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: loc.searchInvoices,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => _onSearchChanged(),
          ),
          const SizedBox(height: DesignTokens.paddingMd),

          // Filters & Sort Row
          Row(
            children: [
              // Status filter dropdown
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: loc.filterByStatus,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: <String?>[
                    null,
                    'draft',
                    'sent',
                    'paid',
                    'overdue',
                    'refunded',
                    'voided',
                    'failed',
                  ].map((status) {
                    return DropdownMenuItem<String?>(
                      value: status,
                      child: Text(status == null
                          ? loc.allStatuses
                          : _capitalize(status)),
                    );
                  }).toList(),
                  onChanged: _onStatusChanged,
                  isExpanded: true,
                ),
              ),

              const SizedBox(width: DesignTokens.paddingMd),

              // Sort order dropdown
              Expanded(
                child: DropdownButtonFormField<InvoiceSortOrder>(
                  value: _selectedSortOrder,
                  decoration: InputDecoration(
                    labelText: loc.sortBy,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: InvoiceSortOrder.dateDesc,
                      child: Text(loc.sortDateDesc),
                    ),
                    DropdownMenuItem(
                      value: InvoiceSortOrder.dateAsc,
                      child: Text(loc.sortDateAsc),
                    ),
                    DropdownMenuItem(
                      value: InvoiceSortOrder.totalDesc,
                      child: Text(loc.sortTotalDesc),
                    ),
                    DropdownMenuItem(
                      value: InvoiceSortOrder.totalAsc,
                      child: Text(loc.sortTotalAsc),
                    ),
                  ],
                  onChanged: _onSortOrderChanged,
                  isExpanded: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}


