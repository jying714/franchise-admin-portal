// File: lib/core/models/platform_financial_kpis.dart

import 'package:flutter/foundation.dart';

/// Model representing platform-wide SaaS financial KPIs for the platform owner dashboard.
/// Easily extendable for new metrics. Immutable for robust state management.
@immutable
class PlatformFinancialKpis {
  /// Monthly Recurring Revenue (from current month's subscription invoices)
  final double mrr;

  /// Annual Recurring Revenue (MRR * 12)
  final double arr;

  /// Count of unique active franchises (franchises invoiced this month)
  final int activeFranchises;

  /// Total value of payouts issued platform-wide in last 30 days
  final double recentPayouts;

  // 💡 Future Feature Placeholders:
  // final double churnRate;
  // final double arpu;
  // final int newFranchises;
  // final double refunds;

  const PlatformFinancialKpis({
    required this.mrr,
    required this.arr,
    required this.activeFranchises,
    required this.recentPayouts,
    // this.churnRate = 0,
    // this.arpu = 0,
    // this.newFranchises = 0,
    // this.refunds = 0,
  });

  /// JSON serialization (for testing, storage, cloud sync, etc.)
  Map<String, dynamic> toJson() => {
        'mrr': mrr,
        'arr': arr,
        'activeFranchises': activeFranchises,
        'recentPayouts': recentPayouts,
        // 'churnRate': churnRate,
        // 'arpu': arpu,
        // 'newFranchises': newFranchises,
        // 'refunds': refunds,
      };

  /// Factory to create from Firestore or API data (if used directly)
  factory PlatformFinancialKpis.fromJson(Map<String, dynamic> json) {
    return PlatformFinancialKpis(
      mrr: (json['mrr'] ?? 0).toDouble(),
      arr: (json['arr'] ?? 0).toDouble(),
      activeFranchises: (json['activeFranchises'] ?? 0) as int,
      recentPayouts: (json['recentPayouts'] ?? 0).toDouble(),
      // churnRate: (json['churnRate'] ?? 0).toDouble(),
      // arpu: (json['arpu'] ?? 0).toDouble(),
      // newFranchises: (json['newFranchises'] ?? 0) as int,
      // refunds: (json['refunds'] ?? 0).toDouble(),
    );
  }
}
