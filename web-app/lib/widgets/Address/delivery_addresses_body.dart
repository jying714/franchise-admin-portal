import 'package:flutter/material.dart';
import '../../../../packages/shared_core/lib/src/core/models/address.dart';
import 'package:franchise_admin_portal/widgets/Address/address_list_view.dart';
import 'package:franchise_admin_portal/widgets/Address/address_form.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/widgets/confirmation_dialog.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import '../../../../packages/shared_core/lib/src/core/services/firestore_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeliveryAddressesBody extends StatefulWidget {
  final List<Address> addresses;
  final FirestoreService firestoreService;
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
    final localizations = AppLocalizations.of(context)!;
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
                title: localizations.noAddressesSaved,
                iconData: Icons.home_outlined,
              )
            else
              AddressListView(
                addresses: addresses,
                onDelete: (address) async {
                  final shouldDelete = await ConfirmationDialog.show(
                    context,
                    title: localizations.areYouSure,
                    message: localizations.deleteAddress,
                    onConfirm: () {},
                    confirmLabel: localizations.confirm,
                    cancelLabel: localizations.cancel,
                    icon: Icons.delete,
                    confirmColor: DesignTokens.errorColor,
                  );
                  if (shouldDelete == true) {
                    await firestoreService.removeAddressForUser(
                        user.uid, address.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localizations.addressRemoved,
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
                  }
                },
              ),
            if (addresses.length < 5)
              AddressForm(
                formKey: formKey,
                submitLabel: localizations.addAddress,
                // You can inject validation logic here if needed for franchise/international
                onSubmit: (newAddress) async {
                  final shouldAdd = await ConfirmationDialog.show(
                    context,
                    title: localizations.areYouSure,
                    message: localizations.addAddress,
                    onConfirm: () {},
                    confirmLabel: localizations.confirm,
                    cancelLabel: localizations.cancel,
                    icon: Icons.add_location_alt,
                    confirmColor: DesignTokens.primaryColor,
                  );
                  if (shouldAdd == true) {
                    await firestoreService.addAddressForUser(
                        user.uid, newAddress);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localizations.addressAdded,
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
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
