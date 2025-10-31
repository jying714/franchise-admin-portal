// ignore_for_file: unused_import

import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/widgets/Address/address_list_view.dart';
import 'package:franchise_mobile_app/widgets/Address/address_form.dart';
import 'package:franchise_mobile_app/widgets/Address/delivery_addresses_body.dart';
import 'package:franchise_mobile_app/widgets/Address/edit_address_dialog.dart';
import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/widgets/Address/delivery_address_tile.dart';
import 'package:franchise_mobile_app/widgets/confirmation_dialog.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:franchise_mobile_app/core/models/address.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/widgets/empty_state_widget.dart';

class DeliveryAddressesScreen extends StatefulWidget {
  const DeliveryAddressesScreen({super.key});

  @override
  State<DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _street, _city, _state, _zip, _label;

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: FranchiseAppBar(
        title: localizations.deliveryAddresses,
        // Optional: pass logo and branding config for franchise support
        showLogo: false, // set true and provide logoAsset if desired
        centerTitle: true,
        backgroundColor: DesignTokens.primaryColor,
        foregroundColor: DesignTokens.foregroundColor,
        elevation: 0,
        // actions, leading, and other props as needed
      ),
      backgroundColor: DesignTokens.backgroundColor,
      body: user == null
          ? EmptyStateWidget(
              title: localizations.mustSignInForAddresses,
              iconData: Icons.lock_outline,
            )
          : StreamBuilder<List<Address>>(
              stream: firestoreService.getAddressesForUser(user.uid),
              builder: (context, snapshot) {
                final addresses = snapshot.data ?? [];
                // print('STREAMBUILDER snapshot.data: ${snapshot.data}');
                // print('STREAMBUILDER snapshot.hasData: ${snapshot.hasData}');
                // print('STREAMBUILDER error: ${snapshot.error}');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return DeliveryAddressesBody(
                  addresses: addresses,
                  firestoreService: firestoreService,
                  user: user,
                  formKey: _formKey,
                );
              },
            ),
    );
  }
}


