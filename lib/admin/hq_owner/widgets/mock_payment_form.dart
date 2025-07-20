import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/mock_payment_data.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/tight_section_card.dart';
import 'package:franchise_admin_portal/widgets/role_guard.dart';
import 'dart:math' as math;

class MockPaymentForm extends StatefulWidget {
  final Function(MockPaymentData payment) onValidated;

  const MockPaymentForm({
    Key? key,
    required this.onValidated,
  }) : super(key: key);

  @override
  State<MockPaymentForm> createState() => _MockPaymentFormState();
}

class _MockPaymentFormState extends State<MockPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String? _cardType;

  @override
  void dispose() {
    _nameController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return RoleGuard(
      allowedRoles: const ['hq_owner', 'platform_owner', 'developer'],
      child: TightSectionCard(
        title: loc.mockPaymentHeader,
        icon: Icons.credit_card,
        builder: (context) => Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.mockPaymentDisclaimer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _cardType,
                decoration: InputDecoration(
                  labelText: loc.cardType,
                  border: const OutlineInputBorder(),
                ),
                items: ['Visa', 'Mastercard', 'Amex', 'Discover'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _cardType = value;
                  });
                },
                validator: (value) => value == null ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.nameOnCard,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? loc.fieldRequired
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardController,
                decoration: InputDecoration(
                  labelText: loc.cardNumber,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                validator: (value) => value == null || value.trim().length < 16
                    ? loc.invalidCardNumber
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: InputDecoration(
                        labelText: loc.expiryDate,
                        hintText: 'MM/YY',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [_ExpiryDateFormatter()],
                      validator: (value) => value == null ||
                              !RegExp(r"^(0[1-9]|1[0-2])\/\d{2}$")
                                  .hasMatch(value)
                          ? loc.invalidExpiryDate
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: loc.cvv,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [LengthLimitingTextInputFormatter(3)],
                      obscureText: true,
                      validator: (value) => value == null || value.length != 3
                          ? loc.invalidCvv
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _handleValidate,
                  child: Text(loc.validatePayment),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleValidate() {
    final loc = AppLocalizations.of(context)!;
    try {
      if (_formKey.currentState!.validate()) {
        final maskedCard = _cardController.text.replaceAll(RegExp(r'\D'), '');
        final last4 = maskedCard.length >= 4
            ? maskedCard.substring(maskedCard.length - 4)
            : '0000';
        final paymentData = MockPaymentData(
          cardHolderName: _nameController.text.trim(),
          maskedCardString: '${_cardType ?? '****'} **** **** $last4',
          expiryDate: _expiryController.text.trim(),
        );

        debugPrint('[MockPaymentForm] onValidated triggered with $maskedCard');

        widget.onValidated(paymentData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.mockPaymentValidated)),
        );
      }
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Mock payment validation failed',
        stack: stack.toString(),
        source: 'MockPaymentForm',
        screen: 'available_platform_plans_screen',
        severity: 'warning',
        contextData: {'exception': e.toString()},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.genericErrorOccurred),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    int selectionIndex = 0;
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
        if (i < newValue.selection.baseOffset) selectionIndex++;
      }
      buffer.write(digitsOnly[i]);
      if (i < newValue.selection.baseOffset) selectionIndex++;
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final rawText = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    int selectionIndex = newValue.selection.baseOffset;
    for (int i = 0; i < rawText.length && i < 4; i++) {
      if (i == 2) {
        buffer.write('/');
        if (i < selectionIndex) selectionIndex++;
      }
      buffer.write(rawText[i]);
    }

    final resultText = buffer.toString();
    return TextEditingValue(
      text: resultText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
