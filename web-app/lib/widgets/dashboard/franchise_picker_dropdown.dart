import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        onChanged: (String? newValue) async {
          if (newValue == null || newValue == currentFranchise.id) return;

          await franchiseProvider.setFranchiseId(newValue);

          // Reload franchise doc so name / colors / logo update in-place
          try {
            final snap = await FirebaseFirestore.instance
                .collection('franchises')
                .doc(newValue)
                .get();
            if (snap.exists && snap.data() != null) {
              franchiseProvider.setBrandingFromFranchiseDoc(snap.data()!);
            } else {
              // Fallback: at least apply name/logo from the list entry
              final info = franchises.firstWhere(
                (f) => f.id == newValue,
                orElse: () => currentFranchise,
              );
              franchiseProvider.applyBrandingFromInfo(info);
            }
          } catch (_) {
            final info = franchises.firstWhere(
              (f) => f.id == newValue,
              orElse: () => currentFranchise,
            );
            franchiseProvider.applyBrandingFromInfo(info);
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
