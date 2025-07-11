import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/widgets/admin/admin_sidebar.dart';
import 'package:franchise_admin_portal/widgets/admin/franchise_selector.dart';
import 'package:franchise_admin_portal/core/models/franchise_info.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/core/utils/franchise_utils.dart';

class FranchiseSelectorScreen extends StatefulWidget {
  const FranchiseSelectorScreen({super.key});

  @override
  State<FranchiseSelectorScreen> createState() =>
      _FranchiseSelectorScreenState();
}

class _FranchiseSelectorScreenState extends State<FranchiseSelectorScreen> {
  late Future<List<FranchiseInfo>> _franchisesFuture;

  @override
  void initState() {
    super.initState();
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    _franchisesFuture = firestoreService.fetchFranchiseList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final franchiseProvider =
        Provider.of<FranchiseProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.switchFranchise),
      ),
      drawer: AdminSidebar(
        sections: const [],
        selectedIndex: 0,
        onSelect: (_) {},
      ),
      body: SafeArea(
        child: FutureBuilder<List<FranchiseInfo>>(
          future: _franchisesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text(loc.errorLoadingFranchises));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(loc.noFranchisesFound));
            }

            final franchises = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: FranchiseSelector(
                items: franchises,
                selectedFranchiseId: franchiseProvider.franchiseId,
                onSelected: (franchiseId) {
                  print(
                      '[FranchiseSelectorScreen] onSelected fired with: $franchiseId');
                  franchiseProvider.setFranchiseId(franchiseId).then((_) {
                    print(
                        '[FranchiseSelectorScreen] franchiseProvider updated.');
                    Navigator.of(context)
                        .pushReplacementNamed('/admin/dashboard');
                    print('[Routing] Navigating to /admin/dashboard');
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
