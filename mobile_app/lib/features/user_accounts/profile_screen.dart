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
import 'package:cloud_firestore/cloud_firestore.dart'; // P2 theme test reload only
import 'package:qr_flutter/qr_flutter.dart'; // P2 QR display foundations
import 'package:franchise_mobile_app/features/ordering/qr_scan_screen.dart';

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

                        // P2 dev-only: simple live theme switcher for white-label testing.
                        // Toggles UiConfig + app-wide ThemeData via FranchiseProvider branding.
                        // In real use this would come from FranchiseSelector + full reload.
                        _buildThemeTestSection(context, franchiseProvider, firestoreService),

                        // P2: Franchise QR display (shareable deep link) - foundations
                        _buildFranchiseQRSection(context, franchiseProvider),

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

  // P2 test helper - simple theme switcher (dev foundations only).
  // Demonstrates live color/appName propagation without full app restart.
  Widget _buildThemeTestSection(
    BuildContext context,
    shared.FranchiseProvider fp,
    shared.FirestoreService fs,
  ) {
    // l10n available for future localization of test labels
    return Card(
      color: UiConfig.surfaceColor,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: UiConfig.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 Theme Test (P2 Dev)',
              style: UiConfig.bodyBoldStyle.copyWith(color: UiConfig.primaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to live-switch branding. Affects this screen + global ThemeData.',
              style: UiConfig.captionStyle,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31837), // doughboys red
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    fp.setBrandingFromFranchiseDoc({
                      'name': 'Doughboys Pizzeria',
                      'appName': 'Doughboys Pizzeria',
                      'primaryColorHex': '#E31837',
                      'secondaryColorHex': '#FFD700',
                      'logoUrl': null,
                    });
                    // Optional: also change the logical franchise id for full flow
                    await fp.setFranchiseId('doughboys_pizzeria');
                    if (mounted) setState(() {});
                  },
                  child: const Text('Doughboys (Red/Gold)'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32), // green test
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    fp.setBrandingFromFranchiseDoc({
                      'name': 'Test Green Bistro',
                      'appName': 'Green Bistro',
                      'primaryColorHex': '#2E7D32',
                      'secondaryColorHex': '#81C784',
                    });
                    await fp.setFranchiseId('test_green');
                    if (mounted) setState(() {});
                  },
                  child: const Text('Test Green'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    // Re-load real data for current id (if exists in Firestore)
                    try {
                      final doc = await FirebaseFirestore.instance
                          .collection('franchises')
                          .doc(fp.currentFranchiseId)
                          .get();
                      if (doc.exists) {
                        fp.setBrandingFromFranchiseDoc(doc.data()!);
                      }
                    } catch (_) {}
                    if (mounted) setState(() {});
                  },
                  child: const Text('Reload Current'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // P2 foundations: display current franchise as scannable QR (deep link payload)
  Widget _buildFranchiseQRSection(
    BuildContext context,
    shared.FranchiseProvider fp,
  ) {
    final fid = fp.currentFranchiseId;
    if (!fp.hasValidFranchise || fid == 'unknown') {
      return const SizedBox.shrink();
    }

    final qrData = shared.generateFranchiseQR(fid, name: fp.currentAppName);
    final displayName = fp.currentAppName;

    return Card(
      color: UiConfig.surfaceColor,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: UiConfig.cardPadding,
        child: Column(
          children: [
            Text(
              'Share this Franchise',
              style: UiConfig.bodyBoldStyle.copyWith(color: UiConfig.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(displayName, style: UiConfig.captionStyle),
            const SizedBox(height: 12),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 160,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan to switch to this location',
              style: UiConfig.captionStyle.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Open Scanner'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QrScanScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
