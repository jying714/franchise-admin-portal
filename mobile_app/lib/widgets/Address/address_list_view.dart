import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/core/models/address.dart';
import 'package:franchise_mobile_app/widgets/Address/delivery_address_tile.dart';

class AddressListView extends StatelessWidget {
  final List<Address> addresses;
  final Future<void> Function(Address address) onDelete;

  const AddressListView({
    super.key,
    required this.addresses,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return DeliveryAddressTile(
          address: address,
          onDelete: () => onDelete(address),
        );
      },
    );
  }
}


