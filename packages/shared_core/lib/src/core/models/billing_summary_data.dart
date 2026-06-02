import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// Billing Summary Data Model
///
/// Lightweight, immutable summary used primarily in dashboards
/// for quick financial visibility (franchise owner + HQ views).
///
/// Follows shared_core patterns: pure Dart, no Flutter dependencies,
/// comprehensive toMap/fromMap for Firestore/JSON serialization.

class BillingSummaryData {
  final double totalOutstanding;
  final int overdueCount;
  final double paidLast30Days;

  /// Derived field for UI convenience
  final bool hasOutstanding;

  BillingSummaryData({
    required this.totalOutstanding,
    required this.overdueCount,
    required this.paidLast30Days,
  }) : hasOutstanding = totalOutstanding > 0.0;

  /// Copy with pattern for immutability
  BillingSummaryData copyWith({
    double? totalOutstanding,
    int? overdueCount,
    double? paidLast30Days,
  }) {
    return BillingSummaryData(
      totalOutstanding: totalOutstanding ?? this.totalOutstanding,
      overdueCount: overdueCount ?? this.overdueCount,
      paidLast30Days: paidLast30Days ?? this.paidLast30Days,
    );
  }

  /// JSON / Firestore Serialization
  Map<String, dynamic> toMap() {
    return {
      'totalOutstanding': totalOutstanding,
      'overdueCount': overdueCount,
      'paidLast30Days': paidLast30Days,
      'hasOutstanding': hasOutstanding,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory BillingSummaryData.fromMap(Map<String, dynamic> map) {
    return BillingSummaryData(
      totalOutstanding: (map['totalOutstanding'] as num?)?.toDouble() ?? 0.0,
      overdueCount: map['overdueCount'] as int? ?? 0,
      paidLast30Days: (map['paidLast30Days'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Equality & HashCode (important for Provider / comparison)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingSummaryData &&
          runtimeType == other.runtimeType &&
          totalOutstanding == other.totalOutstanding &&
          overdueCount == other.overdueCount &&
          paidLast30Days == other.paidLast30Days;

  @override
  int get hashCode =>
      totalOutstanding.hashCode ^
      overdueCount.hashCode ^
      paidLast30Days.hashCode;

  @override
  String toString() =>
      'BillingSummaryData(totalOutstanding: $totalOutstanding, overdueCount: $overdueCount, paidLast30Days: $paidLast30Days, hasOutstanding: $hasOutstanding)';
}
