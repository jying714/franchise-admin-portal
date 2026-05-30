import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/features/ordering/confirmation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum DeliveryType { delivery, pickup }

enum PaymentMethod { card, applePay, googlePay, cash, posMock }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryType _deliveryType = DeliveryType.pickup;
  TimeOfDay? _selectedTime;
  PaymentMethod? _selectedPayment = PaymentMethod.posMock;
  final TextEditingController _promoController = TextEditingController();
  bool _promoApplied = false;
  String? _promoError;
  bool _isPaying = false;

  static const String validPromoCode = "PIZZA10";
  static const double promoDiscount = 10.0;

  final TimeOfDay _businessOpen = const TimeOfDay(hour: 11, minute: 0);
  final TimeOfDay _businessClose = const TimeOfDay(hour: 21, minute: 0);

  double _orderSubtotal = 0.0;
  double _orderTax = 0.0;
  double _deliveryFee = 0.0;
  double _promoValue = 0.0;
  double _orderTotal = 0.0;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo(AppLocalizations localizations) {
    setState(() {
      _promoError = null;
      if (_promoController.text.trim().toUpperCase() == validPromoCode) {
        _promoApplied = true;
      } else {
        _promoError = localizations.invalidPromo;
        _promoApplied = false;
      }
      _updateOrderTotals();
    });
  }

  Future<void> _selectTime(
      BuildContext context, AppLocalizations localizations) async {
    final now = TimeOfDay.now();
    final initialTime = now.hour < _businessOpen.hour ? _businessOpen : now;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (!context.mounted || picked == null) return;
    if (!_isTimeInBusinessHours(picked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.selectedTimeOutsideBusinessHours),
          backgroundColor: UiConfig.errorColor,
        ),
      );
      return;
    }
    setState(() => _selectedTime = picked);
  }

  bool _isTimeInBusinessHours(TimeOfDay t) {
    int toMin(TimeOfDay x) => x.hour * 60 + x.minute;
    return toMin(t) >= toMin(_businessOpen) &&
        toMin(t) <= toMin(_businessClose);
  }

  Future<bool> _processPayment() async {
    setState(() => _isPaying = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isPaying = false);
    return true;
  }

  String _generateOrderId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(10, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  void _updateOrderTotals() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;

    firestoreService
        .getCart(user.uid,
            franchiseId:
                franchiseId != 'unknown' ? franchiseId : 'doughboyspizzeria')
        .first
        .then((cart) {
      if (!mounted || cart == null) return;

      double subtotal = 0.0;
      for (final item in cart.items) {
        subtotal += item.price * item.quantity;
      }

      setState(() {
        _orderSubtotal = subtotal;
        _orderTax = (_orderSubtotal * 0.0925);
        _deliveryFee = _deliveryType == DeliveryType.delivery ? 5.0 : 0.0;
        _promoValue = _promoApplied ? promoDiscount : 0.0;
        _orderTotal = (_orderSubtotal + _orderTax + _deliveryFee - _promoValue)
            .clamp(0, double.infinity);
      });
    }).catchError((e) {
      // Non-fatal; UI will show stale or zero totals
    });
  }

  Future<void> _submitOrder(AppLocalizations localizations) async {
    if (_selectedTime == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseSelectTime),
          backgroundColor: UiConfig.errorColor,
        ),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.signInToOrder),
          backgroundColor: UiConfig.errorColor,
        ),
      );
      return;
    }

    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .currentFranchiseId;
    final cart = await firestoreService
        .getCart(user.uid,
            franchiseId: franchiseId != 'unknown' ? franchiseId : null)
        .first;
    if (cart == null || cart.items.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.cartEmpty),
          backgroundColor: UiConfig.errorColor,
        ),
      );
      return;
    }

    _updateOrderTotals();

    final success = await _processPayment();
    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.paymentFailed),
          backgroundColor: UiConfig.errorColor,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final orderId = _generateOrderId();
    final order = cart.copyWith(
      id: orderId,
      items: List<shared.OrderItem>.from(cart.items),
      subtotal: _orderSubtotal,
      tax: _orderTax,
      deliveryFee: _deliveryFee,
      discount: _promoValue,
      total: _orderTotal,
      deliveryType: _deliveryType == DeliveryType.delivery
          ? localizations.delivery
          : localizations.pickup,
      time: _selectedTime!.format(context),
      status: 'Placed',
      timestamp: now,
      estimatedTime: 30,
      timestamps: {...cart.timestamps, 'placed': now.toIso8601String()},
    );

    try {
      await firestoreService.addOrder(order);
      await firestoreService.updateCart(order.copyWith(items: []));
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(orderId: orderId),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.orderPlaced),
          backgroundColor: UiConfig.successColor,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.orderFailed}: $e'),
          backgroundColor: UiConfig.errorColor,
        ),
      );
    }
  }

  /// --- Allergen list for cart items in checkout ---
  List<String> _allAllergensInCart(
    List<shared.OrderItem> items,
    List<shared.MenuItem> menuItems,
  ) {
    final allergens = <String>{};
    for (final item in items) {
      final menu = menuItems.firstWhere(
        (m) => m.id == item.menuItemId,
        orElse: () => shared.MenuItem(
          id: item.menuItemId,
          category: '',
          categoryId: '',
          name: '',
          price: 0,
          description: '',
          customizationGroups: [],
          customizations: [],
          taxCategory: '',
          available: true,
          availability: true,
        ),
      );
      for (final allergen in menu.allergens ?? []) {
        if (allergen.isNotEmpty) allergens.add(allergen);
      }
    }
    return allergens.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<shared.FranchiseProvider>(
      builder: (context, provider, child) {
        final user = FirebaseAuth.instance.currentUser;
        final firestoreService =
            Provider.of<shared.FirestoreService>(context, listen: false);

        if (!provider.hasValidFranchise) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return _emptyCheckout(localizations);
        }

        // One-time totals update
        if (_orderSubtotal == 0.0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateOrderTotals();
          });
        }

        return StreamBuilder<shared.Order?>(
          stream: firestoreService.getCart(
            user.uid,
            franchiseId: provider.currentFranchiseId,
          ),
          builder: (context, cartSnapshot) {
            final cart = cartSnapshot.data;

            if (cart == null || cart.items.isEmpty) {
              return _emptyCheckout(localizations);
            }

            return StreamBuilder<List<shared.MenuItem>>(
              stream: firestoreService.getMenuItemsByIds(
                provider.currentFranchiseId,
                cart.items.map((i) => i.menuItemId).toList(),
              ),
              builder: (context, menuSnapshot) {
                final menuItems = menuSnapshot.data ?? [];
                final allAllergens = _allAllergensInCart(cart.items, menuItems);
                final showAllergenWarning = allAllergens.isNotEmpty;

                return Scaffold(
                  backgroundColor: UiConfig.backgroundColor,
                  appBar: AppBar(
                    title: Text(
                      localizations.checkout,
                      style: TextStyle(
                        color: UiConfig.foregroundColorDark,
                        fontSize: shared.DesignTokens.titleFontSize,
                        fontWeight: UiConfig.fontWeightBold,
                        fontFamily: shared.DesignTokens.fontFamily,
                      ),
                    ),
                    backgroundColor: UiConfig.primaryColor,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.white),
                    centerTitle: true,
                  ),
                  body: SingleChildScrollView(
                    padding: UiConfig.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showAllergenWarning)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(
                                left: 4, right: 4, top: 2, bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: UiConfig.errorColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(
                                  shared.DesignTokens.cardRadius),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: UiConfig.errorColor, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${localizations.warning}: ${localizations.itemsInCartCouldContain}\n'
                                    '${allAllergens.join(", ")}',
                                    style: TextStyle(
                                      color: UiConfig.errorColor,
                                      fontWeight: FontWeight.bold,
                                      fontFamily:
                                          shared.DesignTokens.fontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          localizations.orderType,
                          style: TextStyle(
                            fontSize: shared.DesignTokens.bodyFontSize,
                            fontWeight: UiConfig.fontWeightBold,
                            fontFamily: shared.DesignTokens.fontFamily,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<DeliveryType>(
                                title: Text(localizations.pickup),
                                value: DeliveryType.pickup,
                                groupValue: _deliveryType,
                                onChanged: (v) {
                                  setState(() => _deliveryType = v!);
                                  _updateOrderTotals();
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<DeliveryType>(
                                title: Text(localizations.delivery),
                                value: DeliveryType.delivery,
                                groupValue: _deliveryType,
                                onChanged: (v) {
                                  setState(() => _deliveryType = v!);
                                  _updateOrderTotals();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(
                            _selectedTime == null
                                ? localizations.selectTime
                                : '${localizations.time}: ${_selectedTime!.format(context)}',
                            style: const TextStyle(
                                fontSize: shared.DesignTokens.bodyFontSize),
                          ),
                          subtitle: Text(
                            '${localizations.businessHours}: ${_businessOpen.format(context)} - ${_businessClose.format(context)}',
                            style: const TextStyle(
                                fontSize: shared.DesignTokens.captionFontSize),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UiConfig.secondaryColor,
                              foregroundColor: UiConfig.foregroundColorDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    shared.DesignTokens.buttonRadius),
                              ),
                            ),
                            onPressed: () =>
                                _selectTime(context, localizations),
                            child: Text(localizations.pickTime),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _promoController,
                          decoration: InputDecoration(
                            labelText: localizations.promoCode,
                            errorText: _promoError,
                            suffixIcon: _promoApplied
                                ? const Icon(Icons.check, color: Colors.green)
                                : IconButton(
                                    icon: const Icon(Icons.local_offer),
                                    onPressed: () => _applyPromo(localizations),
                                    tooltip: localizations.applyPromo,
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  shared.DesignTokens.formFieldRadius),
                            ),
                          ),
                          enabled: !_promoApplied,
                        ),
                        if (_promoApplied)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${localizations.promoApplied}: -\$${promoDiscount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: UiConfig.successColor,
                                fontSize: shared.DesignTokens.captionFontSize,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.paymentMethod,
                          style: TextStyle(
                            fontSize: shared.DesignTokens.bodyFontSize,
                            fontWeight: UiConfig.fontWeightBold,
                            fontFamily: shared.DesignTokens.fontFamily,
                          ),
                        ),
                        ...PaymentMethod.values.map(
                          (pm) => RadioListTile<PaymentMethod>(
                            title: Text(_paymentLabel(pm, localizations)),
                            value: pm,
                            groupValue: _selectedPayment,
                            onChanged: (v) =>
                                setState(() => _selectedPayment = v),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: shared.DesignTokens.cardElevation,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                shared.DesignTokens.cardRadius),
                          ),
                          color: UiConfig.surfaceColor,
                          child: Padding(
                            padding: UiConfig.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _orderSummaryRow(
                                    localizations.subtotal, _orderSubtotal),
                                _orderSummaryRow(localizations.tax, _orderTax),
                                if (_deliveryFee > 0)
                                  _orderSummaryRow(
                                      localizations.deliveryFee, _deliveryFee),
                                if (_promoApplied)
                                  _orderSummaryRow(localizations.promoDiscount,
                                      -_promoValue),
                                const Divider(),
                                _orderSummaryRow(
                                    localizations.total, _orderTotal,
                                    bold: true),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: UiConfig.primaryColor,
                            foregroundColor: UiConfig.foregroundColorDark,
                            padding: UiConfig.defaultPadding,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  shared.DesignTokens.buttonRadius),
                            ),
                            elevation: shared.DesignTokens.buttonElevation,
                          ),
                          onPressed: _isPaying
                              ? null
                              : () => _submitOrder(localizations),
                          child: _isPaying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(localizations.placeOrder),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _emptyCheckout(AppLocalizations localizations) {
    return Scaffold(
      backgroundColor: UiConfig.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.checkout,
          style: TextStyle(
            color: UiConfig.foregroundColorDark,
            fontSize: shared.DesignTokens.titleFontSize,
            fontWeight: UiConfig.fontWeightBold,
            fontFamily: shared.DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: UiConfig.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          localizations.cartEmpty,
          style: TextStyle(
            fontSize: shared.DesignTokens.bodyFontSize,
            color: UiConfig.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: shared.DesignTokens.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _orderSummaryRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontFamily: shared.DesignTokens.fontFamily,
                fontSize: shared.DesignTokens.bodyFontSize,
              ),
            ),
          ),
          Text(
            '${value < 0 ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? UiConfig.primaryColor : UiConfig.textColor,
              fontSize: shared.DesignTokens.bodyFontSize,
            ),
          ),
        ],
      ),
    );
  }

  String _paymentLabel(PaymentMethod m, AppLocalizations localizations) {
    switch (m) {
      case PaymentMethod.card:
        return localizations.creditDebitCard;
      case PaymentMethod.applePay:
        return localizations.applePay;
      case PaymentMethod.googlePay:
        return localizations.googlePay;
      case PaymentMethod.cash:
        return localizations.cashPayment;
      case PaymentMethod.posMock:
        return localizations.posSystem;
    }
  }
}
