import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/generated/app_localizations.dart';

// P1 Batch 2: Duplicated widgets cleanup (Address/ + categories/ + header/)

typedef FieldValidator = String? Function(String?);

class AddressForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final void Function(shared.Address address) onSubmit;
  final shared.Address? initialValue;
  final String? submitLabel;
  final Map<String, FieldValidator>? fieldValidators;

  const AddressForm({
    super.key,
    required this.formKey,
    required this.onSubmit,
    this.initialValue,
    this.submitLabel,
    this.fieldValidators,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  late String? _label;
  late String? _street;
  late String? _city;
  late String? _state;
  late String? _zip;

  @override
  void initState() {
    super.initState();
    _label = widget.initialValue?.label;
    _street = widget.initialValue?.street;
    _city = widget.initialValue?.city;
    _state = widget.initialValue?.state;
    _zip = widget.initialValue?.zip;
  }

  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected for franchise/{franchiseId}/ scoping (Batch 2)
    Provider.of<shared.FranchiseProvider>(context, listen: false);

    final loc = AppLocalizations.of(context)!;

    // Default US validation logic
    String? defaultLabelValidator(String? value) =>
        value == null || value.isEmpty ? loc.labelRequired : null;
    String? defaultStreetValidator(String? value) =>
        value == null || value.isEmpty ? loc.streetRequired : null;
    String? defaultCityValidator(String? value) =>
        value == null || value.isEmpty ? loc.cityRequired : null;
    String? defaultStateValidator(String? value) =>
        value == null || value.isEmpty ? loc.stateRequired : null;
    String? defaultZipValidator(String? value) {
      if (value == null || value.isEmpty) return loc.zipRequired;
      if (!RegExp(r'^\d{5}$').hasMatch(value)) return loc.invalidZip;
      return null;
    }

    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          TextFormField(
            initialValue: _label,
            decoration: InputDecoration(
              labelText: loc.labelExample,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(shared.DesignTokens.formFieldRadius),
              ),
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            validator:
                widget.fieldValidators?['label'] ?? defaultLabelValidator,
            onSaved: (value) => _label = value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightNormal,
            ),
          ),
          const SizedBox(height: shared.DesignTokens.gridSpacing),
          TextFormField(
            initialValue: _street,
            decoration: InputDecoration(
              labelText: loc.street,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(shared.DesignTokens.formFieldRadius),
              ),
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            validator:
                widget.fieldValidators?['street'] ?? defaultStreetValidator,
            onSaved: (value) => _street = value,
            style: TextStyle(
              color: shared.UiConfig.textColor,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightNormal,
            ),
          ),
          const SizedBox(height: shared.DesignTokens.gridSpacing),
          TextFormField(
            initialValue: _city,
            decoration: InputDecoration(
              labelText: loc.city,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(shared.DesignTokens.formFieldRadius),
              ),
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            validator: widget.fieldValidators?['city'] ?? defaultCityValidator,
            onSaved: (value) => _city = value,
            style: TextStyle(
              color: shared.UiConfig.textColor,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightNormal,
            ),
          ),
          const SizedBox(height: shared.DesignTokens.gridSpacing),
          TextFormField(
            initialValue: _state,
            decoration: InputDecoration(
              labelText: loc.state,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(shared.DesignTokens.formFieldRadius),
              ),
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            validator:
                widget.fieldValidators?['state'] ?? defaultStateValidator,
            onSaved: (value) => _state = value,
            style: TextStyle(
              color: shared.UiConfig.textColor,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightNormal,
            ),
          ),
          const SizedBox(height: shared.DesignTokens.gridSpacing),
          TextFormField(
            initialValue: _zip,
            decoration: InputDecoration(
              labelText: loc.zipCode,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(shared.DesignTokens.formFieldRadius),
              ),
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            validator: widget.fieldValidators?['zip'] ?? defaultZipValidator,
            onSaved: (value) => _zip = value,
            style: TextStyle(
              color: shared.UiConfig.textColor,
              fontFamily: shared.DesignTokens.fontFamily,
              fontWeight: shared.UiConfig.fontWeightNormal,
            ),
          ),
          const SizedBox(height: shared.DesignTokens.gridSpacing * 2),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: shared.UiConfig.defaultPadding,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(shared.DesignTokens.buttonRadius),
              ),
              elevation: shared.DesignTokens.buttonElevation,
            ),
            onPressed: () {
              if (widget.formKey.currentState!.validate()) {
                widget.formKey.currentState!.save();
                final address = shared.Address(
                  id: '', // Firestore will generate real ID on save
                  label: _label!.trim(),
                  street: _street!.trim(),
                  city: _city!.trim(),
                  state: _state!.trim(),
                  zip: _zip!.trim(),
                );
                widget.onSubmit(address);
                widget.formKey.currentState!.reset();
                FocusScope.of(context).unfocus();
              }
            },
            child: Text(widget.submitLabel ?? loc.addAddress),
          ),
        ],
      ),
    );
  }
}
