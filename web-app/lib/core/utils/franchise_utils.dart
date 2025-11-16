// web_app/lib/core/utils/franchise_utils.dart
// UI + Provider logic — ONLY in web_app

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

String getScopedFranchiseId(BuildContext context) {
  final userProfile = Provider.of<UserProfileProvider>(context, listen: false);
  final franchiseProvider =
      Provider.of<FranchiseProvider>(context, listen: false);
  final user = userProfile.user;

  if (user == null) return 'unknown';

  if (user.isDeveloper) return franchiseProvider.franchiseId;
  return user.defaultFranchise ?? franchiseProvider.franchiseId;
}

Future<void> navigateAfterFranchiseSelection(
  BuildContext context,
  String franchiseId,
) async {
  final franchiseProvider =
      Provider.of<FranchiseProvider>(context, listen: false);
  final userProfile = Provider.of<UserProfileProvider>(context, listen: false);
  final user = userProfile.user;

  franchiseProvider.setFranchiseId(franchiseId);

  if (user?.isDeveloper == true) {
    debugPrint('[NAV] → /developer/dashboard');
    Navigator.of(context).pushReplacementNamed('/developer/dashboard');
  } else {
    debugPrint('[NAV] → /admin/dashboard');
    Navigator.of(context).pushReplacementNamed('/admin/dashboard');
  }
}
