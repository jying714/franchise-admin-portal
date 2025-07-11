import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/models/franchise_info.dart'; // <-- use this
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FranchiseSelectorDialogContent extends StatelessWidget {
  const FranchiseSelectorDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final franchiseProvider =
        Provider.of<FranchiseProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return FutureBuilder<List<FranchiseInfo>>(
      future:
          firestoreService.getFranchises(), // must return List<FranchiseInfo>
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              loc.failedToLoadFranchises,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final franchises = snapshot.data ?? [];
        return ListView.builder(
          shrinkWrap: true,
          itemCount: franchises.length,
          itemBuilder: (context, index) {
            final franchise = franchises[index];
            return ListTile(
              title: Text(franchise.name ?? franchise.id),
              subtitle: Text('ID: ${franchise.id}'),
              onTap: () {
                franchiseProvider.setFranchiseId(franchise.id);
                Navigator.of(context).pop(); // Close dialog
              },
            );
          },
        );
      },
    );
  }
}
