import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/sign_out_button.dart';
import 'package:franchise_mobile_app/widgets/profile_nav_tile.dart';
import 'package:franchise_mobile_app/widgets/info_tile.dart';
import 'package:franchise_mobile_app/widgets/empty_state_widget.dart';
import 'package:franchise_mobile_app/features/user_accounts/delivery_addresses_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/order_history_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/scheduled_orders_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/favorites_screen.dart';
import 'package:franchise_mobile_app/features/language/language_screen.dart';
import 'package:franchise_mobile_app/features/chat_support/chat_screen.dart';
import 'package:franchise_mobile_app/features/home/home_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/complete_profile_dialog.dart';
import 'package:franchise_mobile_app/core/models/user.dart' as user_model;
import 'package:franchise_mobile_app/features/loyalty/loyalty_screen.dart';
import 'package:franchise_mobile_app/widgets/loyalty_points_widget.dart';

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
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hintText),
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
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                onSubmitted(value);
                Navigator.of(context).pop();
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<shared.AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return Consumer<shared.FranchiseProvider>(
      builder: (context, franchiseProvider, child) {
        if (!franchiseProvider.hasValidFranchise) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.profile,
              style: TextStyle(
                fontSize: DesignTokens.titleFontSize,
                color: UiConfig.foregroundColorDark,
                fontWeight: UiConfig.fontWeightBold,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            backgroundColor: UiConfig.primaryColor,
            centerTitle: true,
            elevation: 0,
            iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
          ),
          backgroundColor: UiConfig.backgroundColorDark,
          body: Padding(
            padding: UiConfig.defaultScreenPadding,
            child: StreamBuilder<shared.User?>(
              stream: authService.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final shared.User? user = snapshot.data;
                if (user == null) {
                  return EmptyStateWidget(
                    title: l10n.notSignedIn,
                    message: l10n.pleaseSignInToAccessProfile,
                    iconData: Icons.person_off,
                  );
                }

                return StreamBuilder<shared.User?>(
                  stream: firestoreService.getUserByIdStream(user.id),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final shared.User? fullUser = userSnapshot.data;
                    if (fullUser == null) {
                      return EmptyStateWidget(
                        title: l10n.profileNotFound,
                        message: l10n.couldNotRetrieveProfile,
                        iconData: Icons.error_outline,
                      );
                    }

                    // Forced profile completion
                    if ((fullUser.completeProfile ?? false) == false &&
                        !_dialogShown) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        if (!_dialogShown && mounted) {
                          _dialogShown = true;

                          final localUser = user_model.User(
                            id: fullUser.id,
                            name: fullUser.name,
                            email: fullUser.email,
                            phoneNumber: fullUser.phoneNumber,
                            roles: fullUser.roles,
                            addresses: fullUser.addresses,
                            language: fullUser.language,
                            status: fullUser.status,
                            defaultFranchise: fullUser.defaultFranchise,
                            avatarUrl: fullUser.avatarUrl,
                            franchiseIds: fullUser.franchiseIds,
                            completeProfile: fullUser.completeProfile,
                            onboardingComplete: fullUser.onboardingComplete,
                            isActive: fullUser.isActive,
                            updatedAt: fullUser.updatedAt,
                          );

                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) =>
                                CompleteProfileDialog(user: localUser),
                          );

                          if (mounted) setState(() {});
                          _dialogShown = false;
                        }
                      });
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView(
                      children: [
                        InfoTile(
                          label: l10n.name,
                          value: fullUser.name,
                          trailing: IconButton(
                            icon:
                                Icon(Icons.edit, color: UiConfig.primaryColor),
                            tooltip: l10n.edit,
                            onPressed: () {
                              _showEditFieldDialog(
                                title: l10n.editName,
                                initialValue: fullUser.name,
                                hintText: l10n.name,
                                onSubmitted: (newName) async {
                                  final updatedUser =
                                      fullUser.copyWith(name: newName);
                                  await firestoreService
                                      .updateUser(updatedUser);
                                  if (mounted) setState(() {});
                                },
                              );
                            },
                          ),
                        ),
                        InfoTile(
                          label: l10n.phoneNumber,
                          value: fullUser.phoneNumber ?? '',
                          trailing: IconButton(
                            icon:
                                Icon(Icons.edit, color: UiConfig.primaryColor),
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
                                  await firestoreService
                                      .updateUser(updatedUser);
                                  if (mounted) setState(() {});
                                },
                              );
                            },
                          ),
                        ),
                        InfoTile(label: l10n.email, value: fullUser.email),
                        const Divider(),

                        // Loyalty points display (foundational, franchise-aware)
                        const LoyaltyPointsWidget(),

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
                          label: l10n.loyalty,
                          destination: const LoyaltyScreen(),
                          icon: Icons.card_giftcard,
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
                        const SizedBox(height: DesignTokens.gridSpacing * 2),
                        SignOutButton(
                          signOutLabel: l10n.signOut,
                          confirmationTitle: l10n.signOut,
                          confirmationMessage: l10n.signOutConfirmationMessage,
                          confirmLabel: l10n.signOut,
                          cancelLabel: l10n.cancel,
                          onSignOut: () async {
                            await authService.signOut();
                            if (mounted) {
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
      },
    );
  }
}
