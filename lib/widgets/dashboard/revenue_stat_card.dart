import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:intl/intl.dart';

enum RevenuePeriod { daily, weekly, monthly }

class RevenueStatCard extends StatefulWidget {
  const RevenueStatCard({super.key});

  @override
  State<RevenueStatCard> createState() => _RevenueStatCardState();
}

class _RevenueStatCardState extends State<RevenueStatCard> {
  RevenuePeriod _period = RevenuePeriod.daily;

  String get _label {
    switch (_period) {
      case RevenuePeriod.daily:
        return 'Total Revenue (Today)';
      case RevenuePeriod.weekly:
        return 'Total Revenue (This Week)';
      case RevenuePeriod.monthly:
        return 'Total Revenue (This Month)';
    }
  }

  String get _tooltip {
    switch (_period) {
      case RevenuePeriod.daily:
        return 'Total revenue for today';
      case RevenuePeriod.weekly:
        return 'Total revenue for this week';
      case RevenuePeriod.monthly:
        return 'Total revenue for this month';
    }
  }

  Future<double> _getValue(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    switch (_period) {
      case RevenuePeriod.daily:
        return firestore.getTotalRevenueToday();
      case RevenuePeriod.weekly:
        return firestore.getTotalRevenueForPeriod('week');
      case RevenuePeriod.monthly:
        return firestore.getTotalRevenueForPeriod('month');
    }
  }

  String _formatValue(double value) {
    final formatter = NumberFormat.simpleCurrency(decimalDigits: 2);
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.primary;
    final background = Theme.of(context).cardColor;

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
              // Menu at top right, absolute
              Positioned(
                right: 6,
                top: 6,
                child: PopupMenuButton<RevenuePeriod>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Select period',
                  onSelected: (period) {
                    setState(() {
                      _period = period;
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: RevenuePeriod.daily,
                      child: Text('Today'),
                    ),
                    PopupMenuItem(
                      value: RevenuePeriod.weekly,
                      child: Text('This Week'),
                    ),
                    PopupMenuItem(
                      value: RevenuePeriod.monthly,
                      child: Text('This Month'),
                    ),
                  ],
                ),
              ),
              // Main KPI column, always vertically centered
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: FutureBuilder<double>(
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
                                Icons.attach_money,
                                color: cardColor,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 14),
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cardColor),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }
                      if (snapshot.hasError) {
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
                                Icons.attach_money,
                                color: cardColor,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Icon(Icons.error, color: Colors.red, size: 28),
                            Text('Error', style: TextStyle(color: Colors.red)),
                          ],
                        );
                      }
                      final value = snapshot.data ?? 0.0;
                      final display = _formatValue(value);

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
                              Icons.attach_money,
                              color: cardColor,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                display,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: cardColor,
                                ),
                                semanticsLabel: display,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _label,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
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
