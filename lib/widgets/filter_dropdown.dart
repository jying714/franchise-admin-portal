import 'package:flutter/material.dart';

/// A dropdown filter for admin tables/lists.
/// Generic for any type T (e.g., String for status, category, etc.).
class FilterDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T)? getLabel;

  const FilterDropdown({
    Key? key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.getLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        DropdownButton<T>(
          value: value,
          items: options
              .map((option) => DropdownMenuItem<T>(
                    value: option,
                    child: Text(getLabel != null
                        ? getLabel!(option)
                        : option.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
          underline:
              Container(height: 2, color: Theme.of(context).primaryColorLight),
        ),
      ],
    );
  }
}
