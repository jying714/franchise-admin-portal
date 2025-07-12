import 'package:cloud_firestore/cloud_firestore.dart';

class CashFlowForecast {
  final String franchiseId;
  final String period; // e.g. "2025-07", "2025-Q3"
  final double openingBalance;
  final double projectedInflow;
  final double projectedOutflow;
  final double projectedClosingBalance;
  final Timestamp? createdAt;

  CashFlowForecast({
    required this.franchiseId,
    required this.period,
    required this.openingBalance,
    required this.projectedInflow,
    required this.projectedOutflow,
    required this.projectedClosingBalance,
    this.createdAt,
  });

  factory CashFlowForecast.fromFirestore(Map<String, dynamic> data, String id) {
    num toNum(dynamic v) => v is num ? v : 0;
    print('fromFirestore got data: $data');
    return CashFlowForecast(
      franchiseId: data['franchiseId'] ?? id,
      period: data['period'] ?? '',
      openingBalance: toNum(data['openingBalance']).toDouble(),
      projectedInflow: toNum(data['projectedInflow']).toDouble(),
      projectedOutflow: toNum(data['projectedOutflow']).toDouble(),
      projectedClosingBalance:
          toNum(data['projectedClosingBalance']).toDouble(),
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'franchiseId': franchiseId,
        'period': period,
        'openingBalance': openingBalance,
        'projectedInflow': projectedInflow,
        'projectedOutflow': projectedOutflow,
        'projectedClosingBalance': projectedClosingBalance,
        'createdAt': createdAt,
      };
}
