import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class FranchisePickerDropdown extends StatelessWidget {
  final String? selectedFranchiseId;

  const FranchisePickerDropdown({super.key, this.selectedFranchiseId});

  @override
  Widget build(BuildContext context) {
    print('[FranchisePickerDropdown] build called (dropdown in AppBar only)');

    final shared.FranchiseProvider = Provider.of<shared.FranchiseProvider>(context);
    final user = Provider.of<AdminUserProvider>(context).user;
    final loc = AppLocalizations.of(context);

    final franchises = shared.FranchiseProvider.viewableFranchises;
    print('[FranchisePickerDropdown] All franchises: $franchises');
    final currentId = selectedFranchiseId ?? shared.FranchiseProvider.franchiseId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (franchises == null || franchises.isEmpty) {
      return Tooltip(
        message: loc?.noFranchisesAvailable ?? 'No franchises found',
        child: Icon(Icons.store_mall_directory, color: Colors.grey.shade400),
      );
    }

    final currentFranchise = franchises.firstWhere(
      (f) => f.id == currentId,
      orElse: () => franchises.first,
    );

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentFranchise.id,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        style: Theme.of(context).textTheme.bodyMedium,
        borderRadius: BorderRadius.circular(12),
        dropdownColor: Theme.of(context).colorScheme.surface,
        onChanged: (String? newValue) {
          if (newValue != null && newValue != currentFranchise.id) {
            print(
                '[FranchisePickerDropdown] Selected new franchise ID: $newValue');
            final selectedFranchise = franchises.firstWhere(
              (f) => f.id == newValue,
              orElse: () => FranchiseInfo(id: newValue, name: 'Unknown'),
            );
            print(
                '[FranchisePickerDropdown] Selected franchise name: ${selectedFranchise.name}');

            shared.FranchiseProvider.setFranchiseId(newValue);

            // ðŸ§  Defer route transition slightly to allow provider update to propagate
            Future.microtask(() {
              print(
                  '[FranchisePickerDropdown] Navigating to Admin Dashboard after franchise selection...');
              Navigator.pushNamed(
                context,
                '/admin/dashboard?section=onboardingMenu',
              );
            });
          }
        },
        items: franchises.map<DropdownMenuItem<String>>((f) {
          return DropdownMenuItem<String>(
            value: f.id,
            child: Row(
              children: [
                Icon(
                  Icons.store_mall_directory,
                  color: isDark ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  f.name,
                  style: TextStyle(
                    fontWeight: f.id == currentFranchise.id
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}




