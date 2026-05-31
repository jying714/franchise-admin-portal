// web_app/lib/core/utils/franchise_utils.dart
// UI + Provider logic â€” ONLY in web_app

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

String getScopedFranchiseId(BuildContext context) {
  final userProfile = Provider.of<UserProfileProvider>(context, listen: false);
  final shared.FranchiseProvider =
      Provider.of<shared.FranchiseProvider>(context, listen: false);
  final user = userProfile.user;

  if (user == null) return 'unknown';

  if (user.isDeveloper) return shared.FranchiseProvider.franchiseId;
  return user.defaultFranchise ?? shared.FranchiseProvider.franchiseId;
}

Future<void> navigateAfterFranchiseSelection(
  BuildContext context,
  String franchiseId,
) async {
  final shared.FranchiseProvider =
      Provider.of<shared.FranchiseProvider>(context, listen: false);
  final userProfile = Provider.of<UserProfileProvider>(context, listen: false);
  final user = userProfile.user;

  shared.FranchiseProvider.setFranchiseId(franchiseId);

  if (user?.isDeveloper == true) {
    debugPrint('[NAV] â†’ /developer/dashboard');
    Navigator.of(context).pushReplacementNamed('/developer/dashboard');
  } else {
    debugPrint('[NAV] â†’ /admin/dashboard');
    Navigator.of(context).pushReplacementNamed('/admin/dashboard');
  }
}

