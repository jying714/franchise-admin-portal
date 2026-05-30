import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_mobile_app/widgets/Address/delivery_address_tile.dart';
import 'package:shared_core/shared_core.dart' as shared;

// P1 Batch 2: Duplicated widgets cleanup (Address/ + categories/ + header/)

class AddressListView extends StatelessWidget {
  final List<shared.Address> addresses;
  final Future<void> Function(shared.Address address) onDelete;

  const AddressListView({
    super.key,
    required this.addresses,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected for franchise/{franchiseId}/ scoping (Batch 2)
    Provider.of<shared.FranchiseProvider>(context, listen: false);

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
