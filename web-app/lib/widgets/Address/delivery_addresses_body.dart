import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/Address/address_list_view.dart';
import 'package:franchise_admin_portal/widgets/Address/address_form.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/confirmation_dialog.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeliveryAddressesBody extends StatefulWidget {
  final List<shared.Address> addresses;
  final shared.FirestoreService firestoreService;
  final User user;
  final GlobalKey<FormState> formKey;
  final String franchiseId;

  const DeliveryAddressesBody({
    super.key,
    required this.addresses,
    required this.firestoreService,
    required this.user,
    required this.formKey,
    required this.franchiseId,
  });

  @override
  State<DeliveryAddressesBody> createState() => _DeliveryAddressesBodyState();
}

class _DeliveryAddressesBodyState extends State<DeliveryAddressesBody> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final addresses = widget.addresses;
    final firestoreService = widget.firestoreService;
    final user = widget.user;
    final formKey = widget.formKey;

    return Padding(
      padding: DesignTokens.cardPadding,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).viewPadding.bottom +
              16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (addresses.isEmpty)
              EmptyStateWidget(
                title: loc.noAddressesSaved,
                iconData: Icons.home_outlined,
              )
            else
              AddressListView(
                addresses: addresses,
                onDelete: (address) async {
                  final shouldDelete = await ConfirmationDialog.show(
                    context,
                    title: loc.areYouSure,
                    message: loc.deleteAddress,
                    confirmLabel: loc.confirm,
                    cancelLabel: loc.cancel,
                    icon: Icons.delete,
                    confirmColor: Colors.red,
                    onConfirm: () {},
                  );
                  if (shouldDelete == true) {
                    await firestoreService.removeAddressForUser(
                      user.uid,
                      address.id,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.addressRemoved),
                        backgroundColor: Colors.white,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            if (addresses.length < 5)
              AddressForm(
                formKey: formKey,
                submitLabel: loc.addAddress,
                onSubmit: (newAddress) async {
                  final shouldAdd = await ConfirmationDialog.show(
                    context,
                    title: loc.areYouSure,
                    message: loc.addAddress,
                    confirmLabel: loc.confirm,
                    cancelLabel: loc.cancel,
                    icon: Icons.add_location_alt,
                    confirmColor: Colors.blue,
                    onConfirm: () {},
                  );
                  if (shouldAdd == true) {
                    await firestoreService.addAddressForUser(
                      user.uid,
                      newAddress,
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.addressAdded),
                        backgroundColor: Colors.white,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
