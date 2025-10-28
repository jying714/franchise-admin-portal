import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/widgets/sign_out_button.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/widgets/profile_nav_tile.dart';
import 'package:doughboys_pizzeria_final/config/branding_config.dart';
import 'package:doughboys_pizzeria_final/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:doughboys_pizzeria_final/core/services/firestore_service.dart';
import 'package:doughboys_pizzeria_final/core/models/user.dart' as user_model;
import 'package:doughboys_pizzeria_final/widgets/empty_state_widget.dart';
import 'package:doughboys_pizzeria_final/features/user_accounts/delivery_addresses_screen.dart';
import 'package:doughboys_pizzeria_final/features/user_accounts/order_history_screen.dart';
import 'package:doughboys_pizzeria_final/features/user_accounts/scheduled_orders_screen.dart';
import 'package:doughboys_pizzeria_final/features/user_accounts/favorites_screen.dart';
import 'package:doughboys_pizzeria_final/features/language/language_screen.dart';
import 'package:doughboys_pizzeria_final/features/chat_support/chat_screen.dart';
import 'package:doughboys_pizzeria_final/features/home/home_screen.dart';
import 'package:doughboys_pizzeria_final/admin/admin_dashboard_screen.dart';
import 'package:doughboys_pizzeria_final/widgets/info_tile.dart';

// New dialog for forced profile review
import 'package:doughboys_pizzeria_final/features/user_accounts/complete_profile_dialog.dart';
import 'package:doughboys_pizzeria_final/widgets/confirmation_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _dialogShown = false;

  Future<void> _showEditFieldDialog({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSubmitted,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              onSubmitted(val.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                onSubmitted(value);
                Navigator.of(context).pop();
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.profile,
          style: const TextStyle(
            fontSize: DesignTokens.titleFontSize,
            color: DesignTokens.foregroundColor,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: DesignTokens.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColor),
      ),
      backgroundColor: DesignTokens.backgroundColor,
      body: Padding(
        padding: DesignTokens.cardPadding,
        child: StreamBuilder<fb_auth.User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final fb_auth.User? user = snapshot.data;
            if (user == null) {
              return EmptyStateWidget(
                title: l10n.notSignedIn,
                message: l10n.pleaseSignInToAccessProfile,
                iconData: Icons.person_off,
              );
            }
            // Fetch the full User object from Firestore using UID
            return StreamBuilder<user_model.User?>(
              stream: firestoreService.getUserByIdStream(user.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user_model.User? fullUser = userSnapshot.data;
                if (fullUser == null) {
                  return EmptyStateWidget(
                    title: l10n.profileNotFound,
                    message: l10n.couldNotRetrieveProfile,
                    iconData: Icons.error_outline,
                  );
                }

                // ---- FORCED PROFILE COMPLETION LOGIC ----
                if ((fullUser.completeProfile ?? false) == false &&
                    !_dialogShown) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!_dialogShown) {
                      _dialogShown = true;
                      final result = await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => CompleteProfileDialog(user: fullUser),
                      );
                      // Refresh the profile after the dialog closes
                      if (mounted) setState(() {});
                      _dialogShown = false;
                    }
                  });
                  // Show loading indicator while waiting for dialog completion
                  return const Center(child: CircularProgressIndicator());
                }

                // ---- PROFILE DISPLAY ----
                return ListView(
                  children: [
                    InfoTile(
                      label: l10n.name,
                      value: fullUser.name,
                      trailing: IconButton(
                        icon:
                            Icon(Icons.edit, color: DesignTokens.primaryColor),
                        tooltip: l10n.edit,
                        onPressed: () {
                          _showEditFieldDialog(
                            title: l10n.editName,
                            initialValue: fullUser.name,
                            hintText: l10n.name,
                            onSubmitted: (newName) async {
                              final updatedUser =
                                  fullUser.copyWith(name: newName);
                              await firestoreService.updateUser(updatedUser);
                              setState(() {}); // Refresh UI
                            },
                          );
                        },
                      ),
                    ),
                    InfoTile(
                      label: l10n.phoneNumber,
                      value: fullUser.phoneNumber,
                      trailing: IconButton(
                        icon:
                            Icon(Icons.edit, color: DesignTokens.primaryColor),
                        tooltip: l10n.edit,
                        onPressed: () {
                          _showEditFieldDialog(
                            title: l10n.editPhoneNumber,
                            initialValue: fullUser.phoneNumber ?? '',
                            keyboardType: TextInputType.phone,
                            hintText: l10n.phoneNumber,
                            onSubmitted: (newPhone) async {
                              final updatedUser =
                                  fullUser.copyWith(phoneNumber: newPhone);
                              await firestoreService.updateUser(updatedUser);
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    InfoTile(label: l10n.email, value: fullUser.email),
                    if (fullUser.role != user_model.User.roleCustomer)
                      InfoTile(label: 'Role', value: fullUser.role),
                    const Divider(),
                    ProfileNavTile(
                      label: l10n.deliveryAddresses,
                      destination: const DeliveryAddressesScreen(),
                    ),
                    ProfileNavTile(
                      label: l10n.orderHistory,
                      destination: const OrderHistoryScreen(),
                    ),
                    ProfileNavTile(
                      label: l10n.favorites,
                      destination: const FavoritesScreen(),
                    ),
                    ProfileNavTile(
                      label: l10n.scheduledOrders,
                      destination: const ScheduledOrdersScreen(),
                    ),
                    ProfileNavTile(
                      label: l10n.language,
                      destination: const LanguageScreen(),
                    ),
                    ProfileNavTile(
                      label: l10n.chatWithUs,
                      destination: const ChatScreen(),
                    ),
// ADMIN DASHBOARD ENTRYPOINT
                    if (fullUser.isOwner ||
                        fullUser.isAdmin ||
                        fullUser.isManager ||
                        fullUser.isStaff)
                      ProfileNavTile(
                        label: "Admin Dashboard",
                        destination: const AdminDashboardScreen(),
                        icon: Icons.admin_panel_settings,
                        highlight: true,
                      ),

                    const SizedBox(height: DesignTokens.gridSpacing * 2),
                    SignOutButton(
                      signOutLabel: l10n.signOut,
                      confirmationTitle: l10n.signOut,
                      confirmationMessage:
                          l10n.signOutConfirmationMessage, // From ARB
                      confirmLabel: l10n.signOut,
                      cancelLabel: l10n.cancel,
                      onSignOut: () async {
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
