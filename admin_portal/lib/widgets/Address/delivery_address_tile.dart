import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:admin_portal/core/models/address.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/widgets/Address/edit_address_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';

class DeliveryAddressTile extends StatelessWidget {
  final Address address;
  final VoidCallback onDelete;

  const DeliveryAddressTile({
    super.key,
    required this.address,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: DesignTokens.cardElevation,
      margin: const EdgeInsets.symmetric(
        vertical: DesignTokens.gridSpacing / 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      color: DesignTokens.surfaceColor,
      child: ListTile(
        title: Text(
          address.label,
          style: const TextStyle(
            fontSize: DesignTokens.bodyFontSize,
            color: DesignTokens.textColor,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        subtitle: Text(
          '${address.street}, ${address.city}, ${address.state} ${address.zip}',
          style: const TextStyle(
            fontSize: DesignTokens.captionFontSize,
            color: DesignTokens.secondaryTextColor,
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.bodyFontWeight,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: DesignTokens.primaryColor),
              onPressed: () async {
                final firestoreService =
                    FirestoreService(); // Or use Provider if that's your pattern
                final user = FirebaseAuth.instance.currentUser;
                final localizations = AppLocalizations.of(context)!;
                if (user == null) return;
                await EditAddressDialog.show(
                  context,
                  initialValue: address,
                  onSave: (updatedAddress) async {
                    final franchiseId =
                        Provider.of<FranchiseProvider>(context, listen: false)
                            .franchiseId;
                    await firestoreService.updateAddressForUser(
                      user.uid,
                      updatedAddress,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localizations.addressUpdated ?? 'Address updated',
                          style: const TextStyle(
                            color: DesignTokens.textColor,
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.bodyFontWeight,
                          ),
                        ),
                        backgroundColor: DesignTokens.surfaceColor,
                        duration: DesignTokens.toastDuration,
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: DesignTokens.errorColor),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
