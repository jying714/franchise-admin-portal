import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

class PayoutsFilterBar extends StatefulWidget {
  final bool developerMode;

  const PayoutsFilterBar({
    super.key,
    this.developerMode = false,
  });

  @override
  State<PayoutsFilterBar> createState() => _PayoutsFilterBarState();
}

class _PayoutsFilterBarState extends State<PayoutsFilterBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<shared.PayoutFilterProvider>(
      context,
      listen: false,
    );
    _searchController = TextEditingController(text: provider.searchQuery);

    provider.addListener(_providerListener);
  }

  void _providerListener() {
    final provider = Provider.of<shared.PayoutFilterProvider>(
      context,
      listen: false,
    );
    if (_searchController.text != provider.searchQuery) {
      _searchController.text = provider.searchQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }
  }

  @override
  void dispose() {
    final provider = Provider.of<shared.PayoutFilterProvider>(
      context,
      listen: false,
    );
    provider.removeListener(_providerListener);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filterProvider = Provider.of<shared.PayoutFilterProvider>(context);

    return Card(
      color: colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            // Status Dropdown
            DropdownButton<String>(
              value: filterProvider.status,
              style: theme.textTheme.bodyMedium,
              icon: const Icon(Icons.arrow_drop_down),
              underline: const SizedBox(),
              dropdownColor: colorScheme.surface,
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(loc.all ?? "All"),
                ),
                DropdownMenuItem(
                  value: 'pending',
                  child: Text(loc.pending),
                ),
                DropdownMenuItem(
                  value: 'sent',
                  child: Text(loc.sent),
                ),
                DropdownMenuItem(
                  value: 'failed',
                  child: Text(loc.failed),
                ),
              ],
              onChanged: (v) {
                if (v != null && v != filterProvider.status) {
                  filterProvider.setStatus(v);
                }
              },
            ),
            const SizedBox(width: 14),

            // Search Bar
            Expanded(
              child: TextField(
                controller: _searchController,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: loc.searchPayoutsHint ?? 'Search payouts...',
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.adminCardRadius),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.adminCardRadius),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  filterProvider.setSearchQuery(value);
                },
              ),
            ),
            const SizedBox(width: 14),

            if (widget.developerMode)
              Tooltip(
                message: loc.featureComingSoon('Advanced Filtering'),
                child: IconButton(
                  icon: const Icon(Icons.filter_alt_rounded),
                  color: colorScheme.primary,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          loc.featureComingSoon('Advanced Filtering'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
