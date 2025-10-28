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

    if (isMobile) {
      // Mobile: List-based, columns stack vertically.
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
      // Tablet/Desktop: grid row/column, no overflow, always readable.
      // By default, all columns except the last are Expanded; last is for actions and can be SizedBox.
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                for (int idx = 0; idx < widget.columns.length; idx++)
                  if (idx == widget.columns.length - 1)
                    SizedBox(
                      width: 100,
                      child: Center(
                        child: Text(widget.columns[idx],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    Expanded(
                      flex: 3,
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
                                fontWeight: widget.sortKeys[idx] == _sortKey
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: widget.sortKeys[idx] == _sortKey
                                    ? Theme.of(context).primaryColor
                                    : Colors.black87,
                              ),
                            ),
                            if (widget.sortKeys[idx] == _sortKey)
                              Icon(
                                _ascending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
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
    }
  }
}
