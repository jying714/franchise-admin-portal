import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class ClearFiltersButton extends StatelessWidget {
  final VoidCallback onClear;
  final bool enabled;

  const ClearFiltersButton({
    super.key,
    required this.onClear,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.filter_alt_off),
      label: const Text("Clear All Filters"),
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).disabledColor,
        side: BorderSide(
          color: enabled
              ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
              : Theme.of(context).disabledColor.withOpacity(0.3),
        ),
      ),
      onPressed: enabled ? onClear : null,
    );
  }
}
