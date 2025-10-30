import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/models/address.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef FieldValidator = String? Function(String?);

class AddressForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final void Function(Address address) onSubmit;
  final Address? initialValue;
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
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }

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
                    BorderRadius.circular(DesignTokens.formFieldRadius),
              ),
              hintStyle: const TextStyle(
                color: DesignTokens.hintTextColor,
              ),
            ),
            validator:
                widget.fieldValidators?['label'] ?? defaultLabelValidator,
            onSaved: (value) => _label = value,
            style: const TextStyle(
              color: DesignTokens.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.bodyFontWeight,
            ),
          ),
          const SizedBox(height: DesignTokens.gridSpacing),
          TextFormField(
            initialValue: _street,
            decoration: InputDecoration(
              labelText: loc.street,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignTokens.formFieldRadius),
              ),
              hintStyle: const TextStyle(
                color: DesignTokens.hintTextColor,
              ),
            ),
            validator:
                widget.fieldValidators?['street'] ?? defaultStreetValidator,
            onSaved: (value) => _street = value,
            style: const TextStyle(
              color: DesignTokens.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.bodyFontWeight,
            ),
          ),
          const SizedBox(height: DesignTokens.gridSpacing),
          TextFormField(
            initialValue: _city,
            decoration: InputDecoration(
              labelText: loc.city,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignTokens.formFieldRadius),
              ),
              hintStyle: const TextStyle(
                color: DesignTokens.hintTextColor,
              ),
            ),
            validator: widget.fieldValidators?['city'] ?? defaultCityValidator,
            onSaved: (value) => _city = value,
            style: const TextStyle(
              color: DesignTokens.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.bodyFontWeight,
            ),
          ),
          const SizedBox(height: DesignTokens.gridSpacing),
          TextFormField(
            initialValue: _state,
            decoration: InputDecoration(
              labelText: loc.state,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignTokens.formFieldRadius),
              ),
              hintStyle: const TextStyle(
                color: DesignTokens.hintTextColor,
              ),
            ),
            validator:
                widget.fieldValidators?['state'] ?? defaultStateValidator,
            onSaved: (value) => _state = value,
            style: const TextStyle(
              color: DesignTokens.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.bodyFontWeight,
            ),
          ),
          const SizedBox(height: DesignTokens.gridSpacing),
          TextFormField(
            initialValue: _zip,
            decoration: InputDecoration(
              labelText: loc.zipCode,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignTokens.formFieldRadius),
              ),
              hintStyle: const TextStyle(
                color: DesignTokens.hintTextColor,
              ),
            ),
            validator: widget.fieldValidators?['zip'] ?? defaultZipValidator,
            onSaved: (value) => _zip = value,
            style: const TextStyle(
              color: DesignTokens.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.bodyFontWeight,
            ),
          ),
          const SizedBox(height: DesignTokens.gridSpacing * 2),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryColor,
              foregroundColor: DesignTokens.foregroundColor,
              padding: DesignTokens.buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
              elevation: DesignTokens.buttonElevation,
            ),
            onPressed: () {
              if (widget.formKey.currentState!.validate()) {
                widget.formKey.currentState!.save();
                final address = Address(
                  id: UniqueKey().toString(),
                  label: _label!,
                  street: _street!,
                  city: _city!,
                  state: _state!,
                  zip: _zip!,
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
