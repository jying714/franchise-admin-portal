import 'package:flutter/material.dart';

/// Additional Toppings with Meats / Veggies type tabs (mobile parity).
/// Presentational — parent owns pools and add callback.
class MenuItemAdditionalToppingsSection extends StatefulWidget {
  const MenuItemAdditionalToppingsSection({
    super.key,
    required this.meatIds,
    required this.veggieIds,
    required this.labelFor,
    required this.toppingPrice,
    required this.onAdd,
  });

  final List<String> meatIds;
  final List<String> veggieIds;

  /// (id, typeId) → display name
  final String Function(String id, String typeId) labelFor;

  final double toppingPrice;
  final void Function(String id) onAdd;

  @override
  State<MenuItemAdditionalToppingsSection> createState() =>
      _MenuItemAdditionalToppingsSectionState();
}

class _MenuItemAdditionalToppingsSectionState
    extends State<MenuItemAdditionalToppingsSection> {
  late String _selectedTab;

  @override
  void initState() {
    super.initState();
    if (widget.meatIds.isNotEmpty) {
      _selectedTab = 'Meats';
    } else if (widget.veggieIds.isNotEmpty) {
      _selectedTab = 'Veggies';
    } else {
      _selectedTab = '';
    }
  }

  @override
  void didUpdateWidget(covariant MenuItemAdditionalToppingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedTab == 'Meats' && widget.meatIds.isEmpty) {
      _selectedTab = widget.veggieIds.isNotEmpty ? 'Veggies' : '';
    } else if (_selectedTab == 'Veggies' && widget.veggieIds.isEmpty) {
      _selectedTab = widget.meatIds.isNotEmpty ? 'Meats' : '';
    } else if (_selectedTab.isEmpty) {
      if (widget.meatIds.isNotEmpty) {
        _selectedTab = 'Meats';
      } else if (widget.veggieIds.isNotEmpty) {
        _selectedTab = 'Veggies';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.meatIds.isEmpty && widget.veggieIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final tabs = <String>[
      if (widget.meatIds.isNotEmpty) 'Meats',
      if (widget.veggieIds.isNotEmpty) 'Veggies',
    ];

    final activeIds = _selectedTab == 'Meats'
        ? widget.meatIds
        : widget.veggieIds;
    final activeTypeId = _selectedTab == 'Meats' ? 'meats' : 'veggies';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        // Section header (mobile-style primary bar)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          child: Text(
            'Additional Toppings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a type, then add. Added items move to Current Toppings.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        // Type tabs (Meats | Veggies)
        if (tabs.length > 1)
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: tabs.map((label) {
                final selected = _selectedTab == label;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected ? scheme.secondary : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: selected
                              ? scheme.onSecondary
                              : scheme.secondary,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else if (tabs.length == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              tabs.first,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        const SizedBox(height: 10),
        // Items for the selected type
        ...activeIds.map((id) {
          final name = widget.labelFor(id, activeTypeId);
          final label = widget.toppingPrice > 0
              ? '$name (+\$${widget.toppingPrice.toStringAsFixed(2)})'
              : name;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onAdd(id),
                    child: Text(
                      'Click to Add',
                      style: TextStyle(color: scheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
