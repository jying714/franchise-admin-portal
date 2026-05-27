import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/widgets/Address/edit_address_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/src/core/config/design_tokens.dart';

class DeliveryAddressTile extends StatelessWidget {
  final shared.Address address;
  final VoidCallback onDelete;

  const DeliveryAddressTile({
    super.key,
    required this.address,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      elevation: DesignTokens.cardElevation,
      margin: EdgeInsets.symmetric(
        vertical: DesignTokens.gridSpacing / 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      color: UiConfig.surfaceColor,
      child: ListTile(
        title: Text(
          address.label,
          style: TextStyle(
            fontSize: DesignTokens.bodyFontSize,
            color: UiConfig.textColor,
            fontWeight: UiConfig.fontWeightBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        subtitle: Text(
          '${address.street}, ${address.city}, ${address.state} ${address.zip}',
          style: TextStyle(
            fontSize: DesignTokens.captionFontSize,
            color: UiConfig.secondaryTextColor,
            fontFamily: DesignTokens.fontFamily,
            fontWeight: UiConfig.fontWeightNormal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: UiConfig.primaryColor),
              onPressed: () async {
                final firestoreService = Provider.of<shared.FirestoreService>(
                    context,
                    listen: false);
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                await EditAddressDialog.show(
                  context,
                  initialValue: address,
                  onSave: (updatedAddress) async {
                    await firestoreService.updateAddressForUser(
                        user.uid, updatedAddress);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          loc.addressUpdated ?? 'Address updated',
                          style: TextStyle(
                            color: UiConfig.textColor,
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: UiConfig.fontWeightNormal,
                          ),
                        ),
                        backgroundColor: UiConfig.surfaceColor,
                        duration: Duration(seconds: DesignTokens.toastDuration),
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: UiConfig.errorColor),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
