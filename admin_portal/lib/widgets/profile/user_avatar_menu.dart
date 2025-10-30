import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:admin_portal/config/branding_config.dart';
import 'package:admin_portal/core/providers/admin_user_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserAvatarMenu extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  const UserAvatarMenu({Key? key, this.size = 36, this.backgroundColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<AdminUserProvider>(context, listen: false);
    final user = userProvider.user;
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[UserAvatarMenu] loc is null! Localization not available for this context.');
      // Return a minimal placeholder avatar with a tooltip or similar
      return CircleAvatar(
        radius: size / 2,
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(Icons.error, color: Colors.red),
      );
    }
    final avatarUrl = user?.avatarUrl ??
        fb_auth.FirebaseAuth.instance.currentUser?.photoURL ??
        '';

    return PopupMenuButton<_AvatarMenuAction>(
      tooltip: loc.account ?? "Account",
      offset: Offset(0, size + 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) async {
        if (action == _AvatarMenuAction.profile) {
          // Route to profile screen (update as needed)
          Navigator.of(context).pushNamed('/profile');
        } else if (action == _AvatarMenuAction.signout) {
          await fb_auth.FirebaseAuth.instance.signOut();
          Provider.of<AdminUserProvider>(context, listen: false).clear();
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/sign-in', (_) => false);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AvatarMenuAction.profile,
          child: ListTile(
            leading: Icon(Icons.account_circle_outlined),
            title: Text(loc.account ?? "Profile"),
          ),
        ),
        PopupMenuItem(
          value: _AvatarMenuAction.signout,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text(loc.signOut ?? "Sign out"),
          ),
        ),
      ],
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
        backgroundImage: avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : AssetImage(BrandingConfig.defaultProfileIcon) as ImageProvider,
      ),
    );
  }
}

enum _AvatarMenuAction { profile, signout }
