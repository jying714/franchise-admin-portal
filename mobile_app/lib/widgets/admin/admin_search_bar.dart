import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef AdminSearchCallback = void Function(String query);

class AdminSearchBar extends StatelessWidget {
  final String? hintText;
  final TextEditingController controller;
  final AdminSearchCallback? onChanged;
  final AdminSearchCallback? onSubmitted;
  final VoidCallback? onClear;

  const AdminSearchBar({
    super.key,
    this.hintText,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText ?? loc.adminSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    if (onChanged != null) onChanged!('');
                    if (onClear != null) onClear!();
                  },
                  tooltip: loc.clear,
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        onChanged: (val) => onChanged?.call(val),
        onSubmitted: onSubmitted,
      ),
    );
  }
}
