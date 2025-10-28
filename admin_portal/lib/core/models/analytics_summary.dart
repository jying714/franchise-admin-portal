import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsSummary {
  final String franchiseId;
  final String period;
  final int totalOrders;
  final double retentionRate;
  final double totalRevenue;
  final double averageOrderValue;
  final String mostPopularItem;
  final int cancelledOrders;
  final Map<String, int> orderStatusBreakdown;
  final int uniqueCustomers;
  final DateTime? updatedAt;
  final Map<String, int> addOnCounts;
  final double addOnRevenue;
  final Map<String, int> comboCounts;
  final Map<String, int> toppingCounts;
  final Map<String, dynamic>? feedbackStats;
  double get retention => retentionRate;

  AnalyticsSummary({
    required this.franchiseId,
    required this.period,
    required this.totalOrders,
    required this.retentionRate,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.mostPopularItem,
    required this.cancelledOrders,
    required this.orderStatusBreakdown,
    required this.uniqueCustomers,
    this.updatedAt,
    required this.addOnCounts,
    required this.addOnRevenue,
    required this.comboCounts,
    required this.toppingCounts,
    this.feedbackStats,
  });

  factory AnalyticsSummary.fromFirestore(Map<String, dynamic> data, String id) {
    return AnalyticsSummary(
      franchiseId: data['franchiseId'] ?? 'default',
      period: data['period'] ?? '',
      totalOrders: (data['totalOrders'] ?? 0) as int,
      retentionRate: (data['retentionRate'] ?? 0.0).toDouble(),
      totalRevenue: (data['totalRevenue'] ?? 0.0).toDouble(),
      averageOrderValue: (data['averageOrderValue'] ?? 0.0).toDouble(),
      mostPopularItem: data['mostPopularItem'] ?? '-',
      cancelledOrders: (data['cancelledOrders'] ?? 0) as int,
      orderStatusBreakdown:
          (data['orderStatusBreakdown'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
              {},
      uniqueCustomers: (data['uniqueCustomers'] ?? 0) as int,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      addOnCounts: (data['addOnCounts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      addOnRevenue: (data['addOnRevenue'] ?? 0.0).toDouble(),
      comboCounts: (data['comboCounts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      toppingCounts: (data['toppingCounts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      feedbackStats: data['feedbackStats'] != null
          ? Map<String, dynamic>.from(data['feedbackStats'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseId,
      'period': period,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'mostPopularItem': mostPopularItem,
      'cancelledOrders': cancelledOrders,
      'orderStatusBreakdown': orderStatusBreakdown,
      'uniqueCustomers': uniqueCustomers,
      'updatedAt': updatedAt,
      'addOnCounts': addOnCounts,
      'addOnRevenue': addOnRevenue,
      'comboCounts': comboCounts,
      'toppingCounts': toppingCounts,
      if (feedbackStats != null) 'feedbackStats': feedbackStats,
    };
  }

  // === COMPATIBILITY GETTERS (optional, for legacy code) ===

  int get orderVolume => totalOrders;
  double get revenue => totalRevenue;

  /// Returns the item name with the highest count in toppingCounts, or '-' if none.
  String get mostPopular => mostPopularItem.isNotEmpty ? mostPopularItem : '-';

  /// For UI compatibility: Returns orderStatusBreakdown["Placed"] if available.
  int get placedOrders => orderStatusBreakdown["Placed"] ?? 0;
}
