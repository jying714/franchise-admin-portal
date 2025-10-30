import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:admin_portal/core/providers/user_profile_notifier.dart';

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
  print(
      '[DEBUG-NAV] Called navigateAfterFranchiseSelection with franchiseId="$franchiseId" '
      'user="${Provider.of<UserProfileNotifier>(context, listen: false).user}" '
      'isDeveloper=${Provider.of<UserProfileNotifier>(context, listen: false).user?.isDeveloper}');
  final franchiseProvider =
      Provider.of<FranchiseProvider>(context, listen: false);
  final user = Provider.of<UserProfileNotifier>(context, listen: false).user;

  franchiseProvider.setFranchiseId(franchiseId);

  if (user != null && user.isDeveloper) {
    print(
        '[DEBUG-NAV] Navigating to /developer/dashboard from navigateAfterFranchiseSelection');
    Navigator.of(context).pushReplacementNamed('/developer/dashboard');
  } else {
    print(
        '[DEBUG-NAV] Navigating to /admin/dashboard from navigateAfterFranchiseSelection');
    Navigator.of(context).pushReplacementNamed('/admin/dashboard');
  }
}
