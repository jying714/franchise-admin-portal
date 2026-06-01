import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'edit_address_dialog.dart';

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
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: ListTile(
        title: Text(
          address.label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        subtitle: Text(
          '${address.street}, ${address.city}, ${address.state} ${address.zip}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                await EditAddressDialog.show(
                  context,
                  initialValue: address,
                  onSave: (updatedAddress) async {
                    if (updatedAddress is! shared.Address) return;

                    final firestoreService =
                        provider.Provider.of<shared.FirestoreService>(
                      context,
                      listen: false,
                    );

                    await firestoreService.updateAddressForUser(
                      user.uid,
                      updatedAddress,
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          loc.addressUpdated ?? 'Address updated',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
