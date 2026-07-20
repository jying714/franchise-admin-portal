import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/widgets/Address/address_list_view.dart';
import 'package:franchise_mobile_app/widgets/Address/address_form.dart';
import 'package:franchise_mobile_app/widgets/empty_state_widget.dart';
import 'package:franchise_mobile_app/widgets/confirmation_dialog.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// P1 Batch 2: Duplicated widgets cleanup (Address/ + categories/ + header/)

class DeliveryAddressesBody extends StatefulWidget {
  final List<shared.Address> addresses;
  final shared.FirestoreService firestoreService;
  final firebase_auth.User user;
  final GlobalKey<FormState> formKey;

  const DeliveryAddressesBody({
    super.key,
    required this.addresses,
    required this.firestoreService,
    required this.user,
    required this.formKey,
  });

  @override
  State<DeliveryAddressesBody> createState() => _DeliveryAddressesBodyState();
}

class _DeliveryAddressesBodyState extends State<DeliveryAddressesBody> {
  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected for franchise/{franchiseId}/ scoping (Batch 2)
    Provider.of<shared.FranchiseProvider>(context, listen: false);

    final localizations = AppLocalizations.of(context)!;
    final addresses = widget.addresses;
    final firestoreService = widget.firestoreService;
    final user = widget.user;
    final formKey = widget.formKey;

    return Padding(
      padding: shared.UiConfig.cardPadding,
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
                    confirmColor: shared.UiConfig.errorColor,
                  );
                  if (shouldDelete == true) {
                    await firestoreService.removeAddressForUser(
                        user.uid, address.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localizations.addressRemoved,
                          style: TextStyle(
                            color: shared.UiConfig.textColor,
                            fontFamily: shared.DesignTokens.fontFamily,
                            fontWeight: shared.UiConfig.fontWeightNormal,
                          ),
                        ),
                        backgroundColor: shared.UiConfig.surfaceColor,
                        duration: Duration(
                            seconds: shared.DesignTokens.toastDuration),
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
                    confirmColor: shared.UiConfig.primaryColor,
                  );
                  if (shouldAdd == true) {
                    await firestoreService.addAddressForUser(
                        user.uid, newAddress);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localizations.addressAdded,
                          style: TextStyle(
                            color: shared.UiConfig.textColor,
                            fontFamily: shared.DesignTokens.fontFamily,
                            fontWeight: shared.UiConfig.fontWeightNormal,
                          ),
                        ),
                        backgroundColor: shared.UiConfig.surfaceColor,
                        duration: Duration(
                            seconds: shared.DesignTokens.toastDuration),
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
