// customer_web/lib/features/checkout/checkout_screen.dart
import 'dart:math';
import '../orders/order_confirmation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import '../cart/line_customization_summary.dart';
import '../../widgets/branding_shell.dart';
import '../auth/sign_in_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _storeOpsStarted = false;
  bool _paying = false;

  double _taxRate = 0.0925;
  TimeOfDay _open = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _close = const TimeOfDay(hour: 21, minute: 0);
  bool _dayClosed = false;

  final CardEditController _cardController = CardEditController();
  bool _cardComplete = false;

  /// POS parity: lowercase "pickup" | "delivery"
  String _deliveryType = 'pickup';
  static const double _deliveryFeeFlat = 5.0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _cardController.dispose();
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double get _deliveryFee =>
      _deliveryType == 'delivery' ? _deliveryFeeFlat : 0.0;

  shared.Address? _buildDeliveryAddress() {
    if (_deliveryType != 'delivery') return null;
    return shared.Address(
      id: 'web_delivery',
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zip: _zipController.text.trim(),
      label: 'Delivery',
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );
  }

  String? _validateDeliveryForm() {
    if (_deliveryType != 'delivery') return null;
    if (_nameController.text.trim().isEmpty) {
      return 'Enter recipient name';
    }
    if (_streetController.text.trim().isEmpty) {
      return 'Enter street address';
    }
    if (_cityController.text.trim().isEmpty) {
      return 'Enter city';
    }
    if (_stateController.text.trim().isEmpty) {
      return 'Enter state';
    }
    if (_zipController.text.trim().isEmpty) {
      return 'Enter ZIP';
    }
    if (_phoneController.text.trim().isEmpty) {
      return 'Enter phone number';
    }
    return null;
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

  bool _inHours(TimeOfDay t) {
    if (_dayClosed) return false;
    int m(TimeOfDay x) => x.hour * 60 + x.minute;
    return m(t) >= m(_open) && m(t) <= m(_close);
  }

  bool get _storeOpenNow => _inHours(TimeOfDay.fromDateTime(DateTime.now()));

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
      final key = _weekdayKey(DateTime.now());
      var open = _open;
      var close = _close;
      var closed = false;

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
        open = TimeOfDay(
          hour: data['openHour'] as int? ?? 11,
          minute: data['openMinute'] as int? ?? 0,
        );
        close = TimeOfDay(
          hour: data['closeHour'] as int? ?? 21,
          minute: data['closeMinute'] as int? ?? 0,
        );
      }

      setState(() {
        if (rate != null && rate >= 0) _taxRate = rate;
        _open = open;
        _close = close;
        _dayClosed = closed;
      });
    } catch (e) {
      debugPrint('[checkout] store_ops: $e');
    }
  }

  String _orderId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random();
    return List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<bool> _confirmCardWeb({
    required String clientSecret,
    required String merchantName,
  }) async {
    if (!_cardComplete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter card details first')),
        );
      }
      return false;
    }
    try {
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(name: merchantName),
          ),
        ),
      );
      return true;
    } on StripeException catch (e) {
      debugPrint('[checkout] Stripe: ${e.error.localizedMessage}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.error.localizedMessage ?? e.error.message ?? 'Payment failed',
            ),
          ),
        );
      }
      return false;
    } on StripeConfigException catch (e) {
      debugPrint('[checkout] StripeConfigException: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stripe not configured. Pass --dart-define=STRIPE_PK=pk_test_… ($e)',
            ),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint('[checkout] confirmPayment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
      return false;
    }
  }

  Future<void> _placeOrder(shared.Order cart, double subtotal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;

    if (!_storeOpenNow) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Store is closed. Open ${_open.format(context)}–${_close.format(context)}.',
          ),
        ),
      );
      return;
    }

    if (!fp.paymentsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payments not set up for this restaurant'),
        ),
      );
      return;
    }

    final addressError = _validateDeliveryForm();
    if (addressError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(addressError)));
      return;
    }

    final tax = subtotal * _taxRate;
    final deliveryFee = _deliveryFee;
    final total = subtotal + tax + deliveryFee;
    final deliveryAddress = _buildDeliveryAddress();
    final recipientName = _nameController.text.trim();
    final orderId = _orderId();

    setState(() => _paying = true);
    try {
      // pending_payment before PI (webhook resolves orderId) — mobile parity
      final pending = cart.copyWith(
        id: orderId,
        storeId: franchiseId,
        userId: user.uid,
        items: List<shared.OrderItem>.from(cart.items),
        subtotal: subtotal,
        tax: tax,
        deliveryFee: deliveryFee,
        discount: 0,
        total: total,
        deliveryType: _deliveryType,
        deliveryAddress: deliveryAddress,
        userName: recipientName.isNotEmpty
            ? recipientName
            : (user.displayName ?? user.email),
        customerPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        time: TimeOfDay.now().format(context),
        status: 'pending_payment',
        timestamp: DateTime.now(),
        estimatedTime: 30,
        source: 'web',
        timestamps: {
          ...cart.timestamps,
          'pending_payment': DateTime.now().toIso8601String(),
        },
      );
      await fs.addOrder(pending);

      final amountCents = (total * 100).round();
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createOrderPaymentIntent',
      );
      final piResult = await callable.call(<String, dynamic>{
        'franchiseId': franchiseId,
        'amountCents': amountCents,
        'currency': 'usd',
        'orderId': orderId,
      });
      final piData = Map<String, dynamic>.from(piResult.data as Map);
      final clientSecret = piData['clientSecret'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) {
        throw StateError('Missing clientSecret');
      }

      final paid = await _confirmCardWeb(
        clientSecret: clientSecret,
        merchantName: fp.currentAppName,
      );
      if (!paid) {
        setState(() => _paying = false);
        return;
      }

      final now = DateTime.now();
      final kitchen = 'sent_to_kitchen';
      final order = pending.copyWith(
        status: kitchen,
        source: 'web',
        timestamps: {
          ...pending.timestamps,
          'placed': now.toIso8601String(),
          kitchen: now.toIso8601String(),
          'paid': now.toIso8601String(),
        },
      );
      await fs.addOrder(order);
      await fs.updateCart(order.copyWith(items: []));

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => OrderConfirmationScreen(
            orderId: orderId,
            total: total,
            pickupLabel: _deliveryType == 'delivery' ? 'Delivery' : 'Pickup',
          ),
        ),
        (route) => route.isFirst,
      );
      // Optional: push a simple confirmation later
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) {
      return BrandingShell(
        child: Center(
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
              );
            },
            child: const Text('Sign in to checkout'),
          ),
        ),
      );
    }

    final fp = context.watch<shared.FranchiseProvider>();
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;

    if (!_storeOpsStarted) {
      _storeOpsStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadStoreOps(franchiseId);
      });
    }

    return BrandingShell(
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      child: StreamBuilder<shared.Order?>(
        stream: fs.getCart(user.uid, franchiseId: franchiseId),
        builder: (context, snap) {
          if (!snap.hasData &&
              snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cart = snap.data;
          final items = cart?.items ?? const <shared.OrderItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('Cart is empty'));
          }

          double subtotal = 0;
          for (final i in items) {
            subtotal += i.price * i.quantity;
          }
          final tax = subtotal * _taxRate;
          final deliveryFee = _deliveryFee;
          final total = subtotal + tax + deliveryFee;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Checkout',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _storeOpenNow
                        ? 'Open · ${_open.format(context)}–${_close.format(context)}'
                        : 'Closed · opens ${_open.format(context)}',
                    style: TextStyle(
                      color: _storeOpenNow
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Order type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Pickup'),
                        selected: _deliveryType == 'pickup',
                        onSelected: (_) =>
                            setState(() => _deliveryType = 'pickup'),
                      ),
                      ChoiceChip(
                        label: const Text('Delivery'),
                        selected: _deliveryType == 'delivery',
                        onSelected: (_) =>
                            setState(() => _deliveryType = 'delivery'),
                      ),
                    ],
                  ),
                  if (_deliveryType == 'delivery') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _streetController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Street',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _stateController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _zipController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ZIP',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                  const Divider(),
                  ...items.map((i) {
                    final summary = lineCustomizationSummary(i);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(i.name),
                      trailing: Text(
                        '\$${(i.price * i.quantity).toStringAsFixed(2)}',
                      ),
                      subtitle: Text(
                        [
                          '×${i.quantity}',
                          if (summary.isNotEmpty) summary,
                        ].join('\n'),
                      ),
                      isThreeLine: summary.isNotEmpty,
                    );
                  }),
                  const Divider(),
                  _row('Subtotal', subtotal),
                  _row('Tax (${(_taxRate * 100).toStringAsFixed(2)}%)', tax),
                  if (deliveryFee > 0) _row('Delivery fee', deliveryFee),
                  _row('Total', total, bold: true),
                  const SizedBox(height: 24),
                  Text('Card', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  CardField(
                    controller: _cardController,
                    onCardChanged: (details) {
                      setState(() => _cardComplete = details?.complete == true);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: (_paying || !_storeOpenNow || !_cardComplete)
                        ? null
                        : () => _placeOrder(cart!, subtotal),
                    child: _paying
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Pay \$${total.toStringAsFixed(2)}'),
                  ),
                  if (!fp.paymentsEnabled)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Payments not set up for this restaurant'),
                    ),
                  if (kIsWeb)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Card form uses Stripe on web. Use test card 4242…',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ],
      ),
    );
  }
}
