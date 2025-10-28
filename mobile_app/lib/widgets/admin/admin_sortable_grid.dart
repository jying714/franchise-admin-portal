import 'package:flutter/material.dart';

typedef AdminGridSortCallback = void Function(String sortKey, bool ascending);

class AdminSortableGrid<T> extends StatefulWidget {
  final List<T> items;
  final List<String> columns;
  final List<String> sortKeys;
  final List<String> columnKeys;
  final Widget Function(BuildContext, T) itemBuilder;
  final String? sortKey;
  final bool ascending;
  final AdminGridSortCallback? onSort;

  const AdminSortableGrid({
    super.key,
    required this.items,
    required this.columns,
    required this.sortKeys,
    required this.columnKeys,
    required this.itemBuilder,
    this.sortKey,
    this.ascending = true,
    this.onSort,
  });

  @override
  State<AdminSortableGrid<T>> createState() => _AdminSortableGridState<T>();
}

class _AdminSortableGridState<T> extends State<AdminSortableGrid<T>> {
  late String? _sortKey;
  late bool _ascending;

  // Match these widths with AdminMenuItemRow
  static const _colWidths = [
    60.0, // Image
    120.0, // Name
    90.0, // Category
    60.0, // Price
    90.0, // Available
    90.0, // SKU
    180.0, // Dietary/Allergens
    100.0, // Actions
  ];

  @override
  void initState() {
    super.initState();
    _sortKey = widget.sortKey ??
        (widget.sortKeys.isNotEmpty ? widget.sortKeys.first : null);
    _ascending = widget.ascending;
  }

  void _handleSort(String key) {
    setState(() {
      if (_sortKey == key) {
        _ascending = !_ascending;
      } else {
        _sortKey = key;
        _ascending = true;
      }
    });
    if (widget.onSort != null && _sortKey != null) {
      widget.onSort!(_sortKey!, _ascending);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    print(
        '[DEBUG] AdminSortableGrid: widget.items.length = ${widget.items.length}');
    if (isMobile) {
      // Mobile: No horizontal scroll, flexible layout, use Expanded for each column
      return Column(
        children: [
          Row(
            children: List.generate(widget.columns.length, (idx) {
              final colKey = widget.columnKeys[idx];
              final isActive = widget.sortKeys[idx] == _sortKey;
              return Expanded(
                child: InkWell(
                  onTap: widget.sortKeys[idx].isNotEmpty
                      ? () => _handleSort(widget.sortKeys[idx])
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (colKey == 'available')
                        const SizedBox(
                          width: 10,
                          height: 10,
                        )
                      else
                        Text(
                          widget.columns[idx],
                          style: TextStyle(
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive
                                ? Theme.of(context).primaryColor
                                : Colors.black87,
                          ),
                        ),
                      if (isActive)
                        Icon(
                          _ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.items.isEmpty
                ? Center(
                    child: Text(
                      "No items found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.items.length,
                    itemBuilder: (ctx, idx) =>
                        widget.itemBuilder(ctx, widget.items[idx]),
                  ),
          ),
        ],
      );
    } else {
      // Tablet/Desktop: Preserve horizontal scroll and column widths
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _colWidths.length >= widget.columns.length
              ? _colWidths.take(widget.columns.length).reduce((a, b) => a + b)
              : null,
          child: Column(
            children: [
              Row(
                children: List.generate(widget.columns.length, (idx) {
                  final isActive = widget.sortKeys[idx] == _sortKey;
                  return SizedBox(
                    width: _colWidths[idx],
                    child: InkWell(
                      onTap: widget.sortKeys[idx].isNotEmpty
                          ? () => _handleSort(widget.sortKeys[idx])
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.columns[idx],
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? Theme.of(context).primaryColor
                                  : Colors.black87,
                            ),
                          ),
                          if (isActive)
                            Icon(
                              _ascending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const Divider(height: 1),
              Expanded(
                child: widget.items.isEmpty
                    ? Center(
                        child: Text(
                          "No items found.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.items.length,
                        itemBuilder: (ctx, idx) =>
                            widget.itemBuilder(ctx, widget.items[idx]),
                      ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
