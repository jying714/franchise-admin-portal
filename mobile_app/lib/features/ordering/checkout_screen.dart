import 'dart:math';
import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:franchise_mobile_app/core/models/order.dart' as order_model;
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:franchise_mobile_app/features/ordering/confirmation_screen.dart';
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
          backgroundColor: DesignTokens.errorColor,
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
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    firestoreService.getCart(user.uid).first.then((cart) {
      if (cart == null) return;
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
    });
  }

  Future<void> _submitOrder(AppLocalizations localizations) async {
    if (_selectedTime == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseSelectTime),
          backgroundColor: DesignTokens.errorColor,
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
          backgroundColor: DesignTokens.errorColor,
        ),
      );
      return;
    }

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final cart = await firestoreService.getCart(user.uid).first;
    if (cart == null || cart.items.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.cartEmpty),
          backgroundColor: DesignTokens.errorColor,
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
          backgroundColor: DesignTokens.errorColor,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final orderId = _generateOrderId();
    final order = cart.copyWith(
      id: orderId,
      items: List<order_model.OrderItem>.from(cart.items), // <<<< REQUIRED LINE
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
      print('[DEBUG] Calling addOrder...');
      await firestoreService.addOrder(order);
      print('[DEBUG] addOrder completed.');
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
          backgroundColor: DesignTokens.successTextColor,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.orderFailed}: $e'),
          backgroundColor: DesignTokens.errorColor,
        ),
      );
    }
  }

  /// --- Allergen list for cart items in checkout ---
  List<String> _allAllergensInCart(
    List<order_model.OrderItem> items,
    List<MenuItem> menuItems,
  ) {
    final allergens = <String>{};
    for (final item in items) {
      final menu = menuItems.firstWhere(
        (m) => m.id == item.menuItemId,
        orElse: () => MenuItem(
          id: item.menuItemId,
          category: '',
          categoryId: '',
          name: '',
          price: 0,
          description: '',
          customizationGroups: [],
          customizations: [],
          taxCategory: '',
          availability: true,
        ),
      );
      for (final allergen in menu.allergens) {
        if (allergen.isNotEmpty) allergens.add(allergen);
      }
    }
    return allergens.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateOrderTotals();
    });

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    // --- StreamBuilder to display allergens at checkout, just like cart ---
    return StreamBuilder<order_model.Order?>(
      stream: user == null ? null : firestoreService.getCart(user.uid),
      builder: (context, cartSnapshot) {
        final cart = cartSnapshot.data;
        if (cart == null || cart.items.isEmpty) {
          return _emptyCheckout(localizations);
        }
        return StreamBuilder<List<MenuItem>>(
          stream: firestoreService.getMenuItemsByIds(
            cart.items.map((i) => i.menuItemId).toList(),
          ),
          builder: (context, menuSnapshot) {
            final menuItems = menuSnapshot.data ?? [];
            final allAllergens = _allAllergensInCart(cart.items, menuItems);
            final showAllergenWarning = allAllergens.isNotEmpty;

            return Scaffold(
              backgroundColor: DesignTokens.backgroundColor,
              appBar: AppBar(
                title: Text(
                  localizations.checkout,
                  style: const TextStyle(
                    color: DesignTokens.foregroundColor,
                    fontSize: DesignTokens.titleFontSize,
                    fontWeight: DesignTokens.titleFontWeight,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
                backgroundColor: DesignTokens.primaryColor,
                elevation: 0,
                iconTheme:
                    const IconThemeData(color: DesignTokens.foregroundColor),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                padding: DesignTokens.cardPadding,
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
                          color: DesignTokens.errorBgColor.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.cardRadius),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: DesignTokens.errorColor, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${localizations.warning}: ${localizations.itemsInCartCouldContain}\n'
                                '${allAllergens.join(", ")}',
                                style: TextStyle(
                                  color: DesignTokens.errorColor,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: DesignTokens.fontFamily,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      localizations.orderType,
                      style: const TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        fontWeight: DesignTokens.titleFontWeight,
                        fontFamily: DesignTokens.fontFamily,
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
                            fontSize: DesignTokens.bodyFontSize),
                      ),
                      subtitle: Text(
                        '${localizations.businessHours}: ${_businessOpen.format(context)} - ${_businessClose.format(context)}',
                        style: const TextStyle(
                            fontSize: DesignTokens.captionFontSize),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.secondaryColor,
                          foregroundColor: DesignTokens.foregroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                DesignTokens.buttonRadius),
                          ),
                        ),
                        onPressed: () => _selectTime(context, localizations),
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
                              DesignTokens.formFieldRadius),
                        ),
                      ),
                      enabled: !_promoApplied,
                    ),
                    if (_promoApplied)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${localizations.promoApplied}: -\$${promoDiscount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: DesignTokens.successTextColor,
                            fontSize: DesignTokens.captionFontSize,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.paymentMethod,
                      style: const TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        fontWeight: DesignTokens.titleFontWeight,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                    ...PaymentMethod.values.map(
                      (pm) => RadioListTile<PaymentMethod>(
                        title: Text(_paymentLabel(pm, localizations)),
                        value: pm,
                        groupValue: _selectedPayment,
                        onChanged: (v) => setState(() => _selectedPayment = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: DesignTokens.cardElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.cardRadius),
                      ),
                      color: DesignTokens.surfaceColor,
                      child: Padding(
                        padding: DesignTokens.cardPadding,
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
                              _orderSummaryRow(
                                  localizations.promoDiscount, -_promoValue),
                            const Divider(),
                            _orderSummaryRow(localizations.total, _orderTotal,
                                bold: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryColor,
                        foregroundColor: DesignTokens.foregroundColor,
                        padding: DesignTokens.buttonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius),
                        ),
                        elevation: DesignTokens.buttonElevation,
                      ),
                      onPressed:
                          _isPaying ? null : () => _submitOrder(localizations),
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
  }

  Widget _emptyCheckout(AppLocalizations localizations) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.checkout,
          style: const TextStyle(
            color: DesignTokens.foregroundColor,
            fontSize: DesignTokens.titleFontSize,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: DesignTokens.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColor),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          localizations.cartEmpty,
          style: const TextStyle(
            fontSize: DesignTokens.bodyFontSize,
            color: DesignTokens.textColor,
            fontWeight: FontWeight.bold,
            fontFamily: DesignTokens.fontFamily,
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
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.bodyFontSize,
              ),
            ),
          ),
          Text(
            '${value < 0 ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? DesignTokens.primaryColor : DesignTokens.textColor,
              fontSize: DesignTokens.bodyFontSize,
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
