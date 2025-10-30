import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/core/models/user.dart' as admin_user;
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:provider/provider.dart';

class StaffDirectoryScreen extends StatefulWidget {
  const StaffDirectoryScreen({Key? key}) : super(key: key);

  @override
  State<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends State<StaffDirectoryScreen> {
  late Future<List<admin_user.User>> _staffFuture;

  @override
  void initState() {
    super.initState();
    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    final firestoreService = context.read<FirestoreService>();
    _staffFuture = firestoreService.allUsers(franchiseId: franchiseId).first;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.staffDirectory)),
      body: FutureBuilder<List<admin_user.User>>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(loc.errorLoadingStaff));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(loc.noStaffFound));
          }

          final staff = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: staff.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final user = staff[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: Text(user.roles.join(", ")),
                onTap: () {
                  // TODO: Future enhancement - navigate to staff detail / edit screen
                },
              );
            },
          );
        },
      ),
    );
  }
}
