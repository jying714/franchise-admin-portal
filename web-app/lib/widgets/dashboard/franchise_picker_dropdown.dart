import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class FranchisePickerDropdown extends StatelessWidget {
  final String? selectedFranchiseId;

  const FranchisePickerDropdown({super.key, this.selectedFranchiseId});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Proper shared. access — no shadowing
    final franchiseProvider = Provider.of<shared.FranchiseProvider>(context);
    final adminUser = Provider.of<shared.AdminUserProvider>(context).user;

    final franchises = franchiseProvider.viewableFranchises;
    final currentId = selectedFranchiseId ?? franchiseProvider.franchiseId;

    if (franchises.isEmpty) {
      return Tooltip(
        message: loc?.noFranchisesAvailable ?? 'No franchises found',
        child: Icon(Icons.store_mall_directory, color: Colors.grey.shade400),
      );
    }

    final currentFranchise = franchises.firstWhere(
      (f) => f.id == currentId,
      orElse: () => franchises.first,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentFranchise.id,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        style: Theme.of(context).textTheme.bodyMedium,
        borderRadius: BorderRadius.circular(12),
        dropdownColor: Theme.of(context).colorScheme.surface,
        onChanged: (String? newValue) {
          if (newValue != null && newValue != currentFranchise.id) {
            franchiseProvider.setFranchiseId(newValue);

            // Defer navigation to allow provider update
            Future.microtask(() {
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
