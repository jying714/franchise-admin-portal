import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/features/ordering/confirmation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:franchise_mobile_app/generated/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final TextEditingController _phoneController = TextEditingController();
  bool _promoApplied = false;
  String? _promoError;
  bool _isPaying = false;
  bool _pendingPromoConsumed = false;

  // P2.3: Wired MockPaymentService (foundations for real gateway later)
  late final shared.PaymentService _paymentService =
      shared.createPaymentService();

  /// Last successfully applied promo (null if none / cleared).
  shared.Promo? _appliedPromo;
  String _promoSummary = '';

  /// Fallback until store_ops loads (matches prior hardcode).
  TimeOfDay _businessOpen = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _businessClose = const TimeOfDay(hour: 21, minute: 0);
  bool _dayClosed = false;

  /// Decimal rate e.g. 0.0925. Loaded from config/store_ops.
  double _taxRate = 0.0925;

  /// Flat delivery fee in dollars. Loaded from config/store_ops.deliveryFee.
  /// Fallback 5.0 matches prior hardcode until the doc is read.
  double _deliveryFeeFlat = 5.0;

  bool _storeOpsLoadStarted = false;

  double _orderSubtotal = 0.0;
  double _orderTax = 0.0;
  double _deliveryFee = 0.0;
  double _promoValue = 0.0;
  double _orderTotal = 0.0;

  bool _paymentsRefreshStarted = false;

  Widget _checkoutModLine(
    ColorScheme scheme,
    String label,
    List<String> values,
  ) {
    if (values.isEmpty) return const SizedBox.shrink();
    final shown = values.take(6).toList();
    final extra = values.length - shown.length;
    final valueText =
        extra > 0 ? '${shown.join(', ')} +$extra more' : shown.join(', ');
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontSize: shared.DesignTokens.captionFontSize,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                fontFamily: shared.DesignTokens.fontFamily,
              ),
            ),
            TextSpan(
              text: valueText,
              style: TextStyle(
                fontSize: shared.DesignTokens.captionFontSize,
                fontWeight: shared.UiConfig.fontWeightMedium,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                fontFamily: shared.DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkoutItemCustomizations(
    Map<String, dynamic>? customizations,
    Map<String, String> ingredientNames,
    ColorScheme scheme,
  ) {
    if (customizations == null || customizations.isEmpty) {
      return const SizedBox.shrink();
    }
    final map = Map<String, dynamic>.from(customizations);
    String nameOf(String id) => ingredientNames[id] ?? id;
    final rows = <Widget>[];

    final size = map['size']?.toString();
    if (size != null && size.isNotEmpty) {
      rows.add(_checkoutModLine(scheme, 'Size', [size]));
    }

    final current = map['currentIngredients'];
    if (current is List && current.isNotEmpty) {
      final opts = map['ingredientOptions'];
      final parts = <String>[];
      for (final raw in current) {
        final id = raw.toString();
        if (id.isEmpty) continue;
        var label = nameOf(id);
        if (opts is Map && opts[id] is Map) {
          final o = Map<String, dynamic>.from(opts[id] as Map);
          if (o['double'] == true) label = 'Dbl $label';
          final p = o['portion']?.toString();
          if (p == 'left') label = '$label (L)';
          if (p == 'right') label = '$label (R)';
        }
        parts.add(label);
      }
      if (parts.isNotEmpty)
        rows.add(_checkoutModLine(scheme, 'Toppings', parts));
    }

    final cheeses = map['cheeses'];
    if (cheeses is List && cheeses.isNotEmpty) {
      final cheeseOpts = map['cheeseOptions'];
      final parts = <String>[];
      for (final raw in cheeses) {
        final id = raw.toString();
        var label = nameOf(id);
        if (cheeseOpts is Map && cheeseOpts[id] is Map) {
          final o = Map<String, dynamic>.from(cheeseOpts[id] as Map);
          if (o['double'] == true) label = 'Dbl $label';
        }
        parts.add(label);
      }
      if (parts.isNotEmpty) rows.add(_checkoutModLine(scheme, 'Cheese', parts));
    }

    final sauce = map['sauce'];
    if (sauce is List && sauce.isNotEmpty) {
      final parts = <String>[];
      for (final s in sauce) {
        if (s is! Map) continue;
        final id = s['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        parts.add(nameOf(id));
      }
      if (parts.isNotEmpty) rows.add(_checkoutModLine(scheme, 'Sauce', parts));
    }

    final addOns = map['selectedAddOns'];
    if (addOns is List && addOns.isNotEmpty) {
      rows.add(_checkoutModLine(
        scheme,
        'Extras',
        addOns.map((e) => nameOf(e.toString())).toList(),
      ));
    }

    final dips = map['dippedSplits'];
    if (dips is List && dips.isNotEmpty) {
      final parts = dips
          .map((e) => e.toString())
          .where((id) => id.isNotEmpty && id != 'plain')
          .map(nameOf)
          .toList();
      if (parts.isNotEmpty) rows.add(_checkoutModLine(scheme, 'Toss', parts));
    }

    final cups = map['sideDipCups'];
    if (cups is Map && cups.isNotEmpty) {
      final parts = cups.entries
          .where((e) => (e.value is num) && (e.value as num) > 0)
          .map((e) {
        final n = (e.value as num).toInt();
        final name = nameOf(e.key.toString());
        return n > 1 ? '$name ×$n' : name;
      }).toList();
      if (parts.isNotEmpty) rows.add(_checkoutModLine(scheme, 'Dips', parts));
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo(AppLocalizations localizations) async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _promoError = localizations.invalidPromo;
        _promoApplied = false;
        _appliedPromo = null;
        _promoSummary = '';
        _promoValue = 0;
      });
      _updateOrderTotals();
      return;
    }

    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = franchiseProvider.currentFranchiseId;
    final user = FirebaseAuth.instance.currentUser;

    if (franchiseId.isEmpty || franchiseId == 'unknown' || user == null) {
      setState(() {
        _promoError = localizations.invalidPromo;
        _promoApplied = false;
        _appliedPromo = null;
      });
      return;
    }

    try {
      final promos = await firestoreService.getPromos(franchiseId).first;
      shared.Promo? match;
      for (final p in promos) {
        if (p.code.trim().toUpperCase() == code) {
          match = p;
          break;
        }
      }
      if (match == null) {
        if (!mounted) return;
        setState(() {
          _promoError = localizations.invalidPromo;
          _promoApplied = false;
          _appliedPromo = null;
          _promoSummary = '';
          _promoValue = 0;
        });
        _updateOrderTotals();
        return;
      }

      final cart = await firestoreService
          .getCart(user.uid, franchiseId: franchiseId)
          .first;
      if (!mounted) return;
      if (cart == null || cart.items.isEmpty) {
        setState(() {
          _promoError = localizations.invalidPromo;
          _promoApplied = false;
          _appliedPromo = null;
        });
        return;
      }

      double subtotal = 0;
      for (final item in cart.items) {
        subtotal += item.price * item.quantity;
      }
      final deliveryFee =
          _deliveryType == DeliveryType.delivery ? _deliveryFeeFlat : 0.0;

      final result = shared.PromoPricing.evaluate(
        promo: match,
        lines: List<shared.OrderItem>.from(cart.items),
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        channel: 'mobile',
      );

      if (!result.ok) {
        setState(() {
          _promoError = result.reason ?? localizations.invalidPromo;
          _promoApplied = false;
          _appliedPromo = null;
          _promoSummary = '';
          _promoValue = 0;
        });
        _updateOrderTotals();
        return;
      }

      final applied = match;
      setState(() {
        _promoError = null;
        _promoApplied = true;
        _appliedPromo = applied;
        _promoSummary = result.summary;
        _promoValue = result.discountAmount;
        if (applied.isDelivery) {
          _deliveryFee = result.deliveryFeeAfter;
        }
      });
      _updateOrderTotals();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _promoError = localizations.invalidPromo;
        _promoApplied = false;
        _appliedPromo = null;
        _promoSummary = '';
        _promoValue = 0;
      });
    }
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
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    setState(() => _selectedTime = picked);
  }

  bool _isTimeInBusinessHours(TimeOfDay t) {
    if (_dayClosed) return false;
    int toMin(TimeOfDay x) => x.hour * 60 + x.minute;
    return toMin(t) >= toMin(_businessOpen) &&
        toMin(t) <= toMin(_businessClose);
  }

  static String _weekdayKey(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      default:
        return 'sun';
    }
  }

  Future<void> _loadStoreOps(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('store_ops')
          .get();
      final data = snap.data();
      if (data == null || !mounted) return;

      final rate = (data['taxRate'] as num?)?.toDouble();
      final now = DateTime.now();
      final key = _weekdayKey(now);

      TimeOfDay open = _businessOpen;
      TimeOfDay close = _businessClose;
      bool closed = false;

      final hoursRaw = data['hours'];
      if (hoursRaw is Map && hoursRaw[key] is Map) {
        final day = Map<String, dynamic>.from(hoursRaw[key] as Map);
        closed = day['closed'] == true;
        open = TimeOfDay(
          hour: day['openHour'] as int? ?? 11,
          minute: day['openMinute'] as int? ?? 0,
        );
        close = TimeOfDay(
          hour: day['closeHour'] as int? ?? 21,
          minute: day['closeMinute'] as int? ?? 0,
        );
      } else {
        // Legacy single daily pair
        open = TimeOfDay(
          hour: data['openHour'] as int? ?? 11,
          minute: data['openMinute'] as int? ?? 0,
        );
        close = TimeOfDay(
          hour: data['closeHour'] as int? ?? 21,
          minute: data['closeMinute'] as int? ?? 0,
        );
      }

      final fee = (data['deliveryFee'] as num?)?.toDouble();

      setState(() {
        if (rate != null && rate >= 0) _taxRate = rate;
        if (fee != null && fee >= 0) _deliveryFeeFlat = fee;
        _businessOpen = open;
        _businessClose = close;
        _dayClosed = closed;
      });
      _updateOrderTotals();
    } catch (e) {
      debugPrint('[checkout] store_ops load failed: $e');
    }
  }

  bool get _storeOpenNow =>
      _isTimeInBusinessHours(TimeOfDay.fromDateTime(DateTime.now()));

  Future<bool> _processPayment({String? orderId}) async {
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final isCardRail = _selectedPayment == PaymentMethod.card ||
        _selectedPayment == PaymentMethod.applePay ||
        _selectedPayment == PaymentMethod.googlePay;

    if (isCardRail && !franchiseProvider.paymentsEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payments not set up for this restaurant'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    }

    setState(() => _isPaying = true);

    try {
      if (!isCardRail) {
        final result = await _paymentService.processPayment(
          amount: _orderTotal,
          currency: 'USD',
          paymentMethod: _selectedPayment?.name ?? 'posMock',
          metadata: {
            'franchiseId': franchiseProvider.currentFranchiseId,
            'userId': FirebaseAuth.instance.currentUser?.uid,
          },
        );
        setState(() => _isPaying = false);
        return result.success;
      }

      // Card rails: Connect PaymentIntent + PaymentSheet (ST5).
      final amountCents = (_orderTotal * 100).round();
      final callable =
          FirebaseFunctions.instance.httpsCallable('createOrderPaymentIntent');
      final piResult = await callable.call(<String, dynamic>{
        'franchiseId': franchiseProvider.currentFranchiseId,
        'amountCents': amountCents,
        'currency': 'usd',
        if (orderId != null) 'orderId': orderId,
      });
      final piData = Map<String, dynamic>.from(piResult.data as Map);
      final clientSecret = piData['clientSecret'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) {
        setState(() => _isPaying = false);
        return false;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: franchiseProvider.currentAppName.isNotEmpty
              ? franchiseProvider.currentAppName
              : 'Franchise',
          style: ThemeMode.light,
          billingDetails: const BillingDetails(
            address: Address(
              city: null,
              country: 'US',
              line1: null,
              line2: null,
              postalCode: null,
              state: null,
            ),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      setState(() => _isPaying = false);
      return true;
    } on StripeException catch (e) {
      setState(() => _isPaying = false);
      final msg = e.error.localizedMessage ?? e.error.message ?? '$e';
      shared.ErrorLogger.log(
        message: 'Stripe PaymentSheet: $msg',
        source: 'CheckoutScreen',
        severity: 'error',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    } on FirebaseFunctionsException catch (e) {
      setState(() => _isPaying = false);
      final msg = e.message ?? e.code;
      shared.ErrorLogger.log(
        message: 'createOrderPaymentIntent: $msg',
        source: 'CheckoutScreen',
        severity: 'error',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment setup failed: $msg'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    } catch (e) {
      setState(() => _isPaying = false);
      shared.ErrorLogger.log(
        message: 'Payment processing error: $e',
        source: 'CheckoutScreen',
        severity: 'error',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _refreshPaymentsFromFranchiseDoc() async {
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final id = fp.currentFranchiseId;
    if (id.isEmpty || id == 'unknown') return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(id)
          .get(const GetOptions(source: Source.server));
      if (!mounted || !doc.exists || doc.data() == null) return;
      final data = doc.data()!;
      debugPrint(
        '[checkout] paymentsEnabled=${data['paymentsEnabled']} '
        'status=${data['stripeConnectStatus']}',
      );
      fp.setBrandingFromFranchiseDoc(data);
    } catch (e) {
      debugPrint('[checkout] payments refresh failed: $e');
    }
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

    if (franchiseId.isEmpty || franchiseId == 'unknown') return;

    firestoreService
        .getCart(user.uid, franchiseId: franchiseId)
        .first
        .then((cart) {
      if (!mounted || cart == null) return;

      double subtotal = 0.0;
      for (final item in cart.items) {
        subtotal += item.price * item.quantity;
      }

      setState(() {
        _orderSubtotal = subtotal;
        final deliveryBase =
            _deliveryType == DeliveryType.delivery ? _deliveryFeeFlat : 0.0;
        var promoValue = 0.0;
        var deliveryFee = deliveryBase;
        if (_promoApplied && _appliedPromo != null) {
          final result = shared.PromoPricing.evaluate(
            promo: _appliedPromo!,
            lines: List<shared.OrderItem>.from(cart.items),
            subtotal: subtotal,
            deliveryFee: deliveryBase,
            channel: 'mobile',
          );
          if (result.ok) {
            promoValue = result.discountAmount;
            deliveryFee = result.deliveryFeeAfter;
            _promoSummary = result.summary;
          } else {
            _promoApplied = false;
            _appliedPromo = null;
            _promoSummary = '';
            _promoError = result.reason;
          }
        }
        _promoValue = promoValue;
        _deliveryFee = deliveryFee;
        _orderTax = _orderSubtotal * _taxRate;
        _orderTotal = (_orderSubtotal + _orderTax + _deliveryFee - _promoValue)
            .clamp(0.0, double.infinity);
      });
    }).catchError((e) {
      // Non-fatal; UI will show stale or zero totals
    });
  }

  Future<void> _submitOrder(AppLocalizations localizations) async {
    // MVP: no scheduled/after-hours queue. Refuse when store is closed.
    if (!_storeOpenNow) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Store is closed. Open '
            '${_businessOpen.format(context)}–${_businessClose.format(context)}.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.pleaseSelectTime,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          duration: Duration(seconds: shared.DesignTokens.toastDurationSeconds),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone number is required'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.signInToOrder,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          duration: Duration(seconds: shared.DesignTokens.toastDurationSeconds),
          behavior: SnackBarBehavior.floating,
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
          content: Text(
            localizations.cartEmpty,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          duration: Duration(seconds: shared.DesignTokens.toastDurationSeconds),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _updateOrderTotals();

    final orderId = _generateOrderId();
    final isCardRail = _selectedPayment == PaymentMethod.card ||
        _selectedPayment == PaymentMethod.applePay ||
        _selectedPayment == PaymentMethod.googlePay;

    // Persist order before PI so webhook metadata.orderId resolves (ST4/ST5).
    if (isCardRail) {
      final pending = cart.copyWith(
        id: orderId,
        storeId: franchiseId,
        userId: user.uid,
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
        status: 'pending_payment',
        timestamp: DateTime.now(),
        estimatedTime: 30,
        customerPhone: phone,
        timestamps: {
          ...cart.timestamps,
          'pending_payment': DateTime.now().toIso8601String(),
        },
      );
      await firestoreService.addOrder(pending);
    }

    final success = await _processPayment(
      orderId: isCardRail ? orderId : null,
    );
    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.paymentFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final now = DateTime.now();
    // MVP: no scheduled hold. In store hours → straight to kitchen.
    // Scheduled / after-hours queue = post-MVP.
    final inStoreHours = _isTimeInBusinessHours(TimeOfDay.fromDateTime(now));
    final kitchenStatus = shared.OrderStatus.sentToKitchen;
    final status = inStoreHours ? kitchenStatus : 'placed';

    final order = cart.copyWith(
      id: orderId,
      storeId: franchiseId,
      userId: user.uid,
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
      status: status,
      timestamp: now,
      estimatedTime: 30,
      source: 'mobile',
      customerPhone: phone,
      timestamps: {
        ...cart.timestamps,
        'placed': now.toIso8601String(),
        if (inStoreHours) kitchenStatus: now.toIso8601String(),
        if (isCardRail) 'paid': now.toIso8601String(),
      },
    );

    try {
      await firestoreService.addOrder(order);
      await firestoreService.updateCart(order.copyWith(items: []));

      try {
        await const shared.InventoryFirestoreRepository().applySaleDecrement(
          db: FirebaseFirestore.instance,
          franchiseId: franchiseId,
          orderId: orderId,
          items: order.items,
        );
      } catch (e) {
        debugPrint('[checkout] inventory decrement skipped: $e');
      }

      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(orderId: orderId),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.orderPlaced),
          backgroundColor: shared.UiConfig.successColor,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.orderFailed}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
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

        if (!_pendingPromoConsumed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _pendingPromoConsumed) return;
            _pendingPromoConsumed = true;
            final pending = Provider.of<shared.FranchiseProvider>(
              context,
              listen: false,
            ).pendingPromoCode;
            if (pending == null || pending.isEmpty) return;
            _promoController.text = pending;
            _applyPromo(localizations);
            Provider.of<shared.FranchiseProvider>(context, listen: false)
                .clearPendingPromoCode();
          });
        }

        // ST5: pull paymentsEnabled from server (avoid stale branding cache)
        if (!_paymentsRefreshStarted) {
          _paymentsRefreshStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _refreshPaymentsFromFranchiseDoc();
          });
        }

        if (!_storeOpsLoadStarted) {
          _storeOpsLoadStarted = true;
          final fid = provider.currentFranchiseId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadStoreOps(fid);
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
                  backgroundColor: Theme.of(context).colorScheme.background,
                  appBar: FranchiseAppBar(
                    title: localizations.checkout,
                    showLogo: true,
                    logoUrl: shared.UiConfig.currentLogoUrl,
                    logoAsset: shared.BrandingConfig.appBarLogoAsset,
                    centerTitle: true,
                  ),
                  body: SafeArea(
                    bottom: true,
                    child: SingleChildScrollView(
                      padding: shared.UiConfig.cardPadding,
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(
                                    shared.DesignTokens.cardRadius),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${localizations.warning}: ${localizations.itemsInCartCouldContain}\n'
                                      '${allAllergens.join(", ")}',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        fontWeight: FontWeight.bold,
                                        fontFamily:
                                            shared.DesignTokens.fontFamily,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Order summary (pre-pay review) — uses outer `cart`
                          FutureBuilder<List<shared.IngredientMetadata>>(
                            future: firestoreService.getAllIngredientMetadata(
                              provider.currentFranchiseId,
                            ),
                            builder: (context, metaSnap) {
                              final names = <String, String>{
                                for (final m in metaSnap.data ??
                                    const <shared.IngredientMetadata>[])
                                  m.id: m.name,
                              };
                              final scheme = Theme.of(context).colorScheme;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Order summary',
                                        style: TextStyle(
                                          fontWeight:
                                              shared.UiConfig.fontWeightBold,
                                          fontSize:
                                              shared.DesignTokens.bodyFontSize,
                                          fontFamily:
                                              shared.DesignTokens.fontFamily,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...cart.items.map((item) {
                                        final qtyLabel = item.quantity > 1
                                            ? '  ×${item.quantity}'
                                            : '';
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '${item.name}$qtyLabel',
                                                      style: TextStyle(
                                                        fontWeight: shared
                                                            .UiConfig
                                                            .fontWeightMedium,
                                                        fontFamily: shared
                                                            .DesignTokens
                                                            .fontFamily,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontFamily: shared
                                                          .DesignTokens
                                                          .fontFamily,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              _checkoutItemCustomizations(
                                                item.customizations,
                                                names,
                                                scheme,
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Text(
                            localizations.orderType,
                            style: TextStyle(
                              fontSize: shared.DesignTokens.bodyFontSize,
                              fontWeight: shared.UiConfig.fontWeightBold,
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
                                  fontSize:
                                      shared.DesignTokens.captionFontSize),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onSecondary,
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
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone number',
                              hintText: 'Required for order contact',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    shared.DesignTokens.formFieldRadius),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _promoController,
                            decoration: InputDecoration(
                              labelText: localizations.promoCode,
                              errorText: _promoError,
                              suffixIcon: _promoApplied
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      tooltip: 'Remove',
                                      onPressed: () {
                                        setState(() {
                                          _promoApplied = false;
                                          _appliedPromo = null;
                                          _promoSummary = '';
                                          _promoValue = 0;
                                          _promoError = null;
                                        });
                                        _updateOrderTotals();
                                      },
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.local_offer),
                                      onPressed: () =>
                                          _applyPromo(localizations),
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
                                _promoSummary.isNotEmpty
                                    ? _promoSummary
                                    : '${localizations.promoApplied}: -\$${_promoValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: shared.UiConfig.successColor,
                                  fontSize: shared.DesignTokens.captionFontSize,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.paymentMethod,
                            style: TextStyle(
                              fontSize: shared.DesignTokens.bodyFontSize,
                              fontWeight: shared.UiConfig.fontWeightBold,
                              fontFamily: shared.DesignTokens.fontFamily,
                            ),
                          ),
                          ...PaymentMethod.values.map(
                            (pm) {
                              final isCardRail = pm == PaymentMethod.card ||
                                  pm == PaymentMethod.applePay ||
                                  pm == PaymentMethod.googlePay;
                              final cardBlocked =
                                  isCardRail && !provider.paymentsEnabled;
                              return RadioListTile<PaymentMethod>(
                                title: Text(
                                  cardBlocked
                                      ? '${_paymentLabel(pm, localizations)} (not set up)'
                                      : _paymentLabel(pm, localizations),
                                ),
                                value: pm,
                                groupValue: _selectedPayment,
                                onChanged: cardBlocked
                                    ? null
                                    : (v) =>
                                        setState(() => _selectedPayment = v),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: shared.DesignTokens.cardElevation,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  shared.DesignTokens.cardRadius),
                            ),
                            color: Theme.of(context).colorScheme.surface,
                            child: Padding(
                              padding: shared.UiConfig.cardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _orderSummaryRow(
                                      localizations.subtotal, _orderSubtotal),
                                  _orderSummaryRow(
                                      localizations.tax, _orderTax),
                                  if (_deliveryFee > 0)
                                    _orderSummaryRow(localizations.deliveryFee,
                                        _deliveryFee),
                                  if (_promoApplied)
                                    _orderSummaryRow(
                                        localizations.promoDiscount,
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
                          Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 16,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                padding: shared.UiConfig.defaultPadding,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      shared.DesignTokens.buttonRadius),
                                ),
                                elevation: shared.DesignTokens.buttonElevation,
                              ),
                              onPressed: (_isPaying || !_storeOpenNow)
                                  ? null
                                  : () => _submitOrder(localizations),
                              child: _isPaying
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    )
                                  : Text(localizations.placeOrder),
                            ),
                          ),
                          if (!_storeOpenNow)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Store closed · opens ${_businessOpen.format(context)}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: shared.DesignTokens.captionFontSize,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ), // SafeArea close
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: FranchiseAppBar(
        title: localizations.checkout,
        showLogo: true,
        logoUrl: shared.UiConfig.currentLogoUrl,
        logoAsset: shared.BrandingConfig.appBarLogoAsset,
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          localizations.cartEmpty,
          style: TextStyle(
            fontSize: shared.DesignTokens.bodyFontSize,
            color: Theme.of(context).colorScheme.onSurface,
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
              color: bold
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
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
