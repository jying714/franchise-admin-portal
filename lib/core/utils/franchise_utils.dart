import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';

String getScopedFranchiseId(BuildContext context) {
  final user = Provider.of<UserProfileNotifier>(context, listen: false).user;
  final provider = Provider.of<FranchiseProvider>(context, listen: false);

  if (user == null) return 'unknown';

  if (user.isDeveloper) return provider.franchiseId;
  return user.defaultFranchise ?? provider.franchiseId;
}

Future<void> navigateAfterFranchiseSelection(
  BuildContext context,
  String franchiseId,
) async {
  final franchiseProvider =
      Provider.of<FranchiseProvider>(context, listen: false);
  final user = Provider.of<UserProfileNotifier>(context, listen: false).user;

  franchiseProvider.setFranchiseId(franchiseId);

  if (user != null && user.isDeveloper) {
    Navigator.of(context).pushReplacementNamed('/developer/dashboard');
  } else {
    Navigator.of(context).pushReplacementNamed('/admin/dashboard');
  }
}
