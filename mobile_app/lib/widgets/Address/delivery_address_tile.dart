import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/Address/edit_address_dialog.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// P1 Batch 2: Duplicated widgets cleanup (Address/ + categories/ + header/)

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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: shared.DesignTokens.cardElevation,
      margin: EdgeInsets.symmetric(
        vertical: shared.DesignTokens.gridSpacing / 2,
      ),
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(shared.DesignTokens.cardRadius),
        side: BorderSide(color: scheme.outline),
      ),
      child: ListTile(
        title: Text(
          address.label,
          style: TextStyle(
            fontSize: shared.DesignTokens.bodyFontSize,
            color: scheme.onSurface,
            fontWeight: shared.UiConfig.fontWeightBold,
            fontFamily: shared.DesignTokens.fontFamily,
          ),
        ),
        subtitle: Text(
          '${address.street}, ${address.city}, ${address.state} ${address.zip}',
          style: TextStyle(
            fontSize: shared.DesignTokens.captionFontSize,
            color: scheme.onSurfaceVariant,
            fontFamily: shared.DesignTokens.fontFamily,
            fontWeight: shared.UiConfig.fontWeightNormal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: scheme.primary),
              onPressed: () async {
                Provider.of<shared.FranchiseProvider>(context, listen: false);
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
                            color: scheme.onSurface,
                            fontFamily: shared.DesignTokens.fontFamily,
                            fontWeight: shared.UiConfig.fontWeightNormal,
                          ),
                        ),
                        backgroundColor: scheme.surface,
                        duration: Duration(
                            seconds: shared.DesignTokens.toastDuration),
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: scheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
