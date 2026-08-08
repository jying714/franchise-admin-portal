import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

enum OrdersPeriod { daily, weekly, monthly }

class OrdersStatCard extends StatefulWidget {
  final String franchiseId;

  const OrdersStatCard({Key? key, required this.franchiseId}) : super(key: key);

  @override
  State<OrdersStatCard> createState() => _OrdersStatCardState();
}

class _OrdersStatCardState extends State<OrdersStatCard> {
  OrdersPeriod _period = OrdersPeriod.daily;

  String get _label {
    switch (_period) {
      case OrdersPeriod.daily:
        return 'Orders (Today)';
      case OrdersPeriod.weekly:
        return 'Orders (This Week)';
      case OrdersPeriod.monthly:
        return 'Orders (This Month)';
    }
  }

  String get _tooltip {
    switch (_period) {
      case OrdersPeriod.daily:
        return 'Total orders for today';
      case OrdersPeriod.weekly:
        return 'Total orders for this week';
      case OrdersPeriod.monthly:
        return 'Total orders for this month';
    }
  }

  Future<int> _getValue(BuildContext context) {
    final firestore = Provider.of<shared.FirestoreService>(
      context,
      listen: false,
    );
    switch (_period) {
      case OrdersPeriod.daily:
        return firestore.getTotalOrdersForPeriod(widget.franchiseId, 'today');
      case OrdersPeriod.weekly:
        return firestore.getTotalOrdersForPeriod(widget.franchiseId, 'week');
      case OrdersPeriod.monthly:
        return firestore.getTotalOrdersForPeriod(widget.franchiseId, 'month');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: _label,
      container: true,
      child: Tooltip(
        message: _tooltip,
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 6,
                top: 6,
                child: PopupMenuButton<OrdersPeriod>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Select period',
                  onSelected: (period) {
                    setState(() => _period = period);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: OrdersPeriod.daily,
                      child: Text('Today'),
                    ),
                    PopupMenuItem(
                      value: OrdersPeriod.weekly,
                      child: Text('This Week'),
                    ),
                    PopupMenuItem(
                      value: OrdersPeriod.monthly,
                      child: Text('This Month'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 180,
                  child: FutureBuilder<int>(
                    future: _getValue(context),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: cardColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.shopping_cart,
                                color: cardColor,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 14),
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cardColor),
                            ),
                          ],
                        );
                      }
                      if (snapshot.hasError) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error,
                                color: Theme.of(context).colorScheme.error,
                                size: 28),
                            const SizedBox(height: 8),
                            Text(
                              'Error',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error),
                            ),
                          ],
                        );
                      }
                      final value = snapshot.data ?? 0;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.shopping_cart,
                              color: cardColor,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$value',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: cardColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _label,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
