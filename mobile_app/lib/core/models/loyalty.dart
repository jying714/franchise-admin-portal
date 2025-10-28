// lib/core/models/loyalty.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the `loyalty` sub‐field on your user document:
///
/// {
///   points: number,
///   transactions: [ { points, orderId, timestamp }, … ],
///   redeemedRewards: [ { name, points, timestamp }, … ]
/// }
class Loyalty {
  final int points;
  final List<LoyaltyTransaction> transactions;
  final List<LoyaltyReward> redeemedRewards;
  final DateTime lastRedeemed;

  Loyalty({
    required this.points,
    required this.transactions,
    required this.redeemedRewards,
    DateTime? lastRedeemed,
  }) : lastRedeemed = lastRedeemed ??
            (redeemedRewards.isNotEmpty
                ? redeemedRewards.last.timestamp
                : DateTime.now());

  /// Allows cloning the Loyalty object with modifications.
  Loyalty copyWith({
    int? points,
    List<LoyaltyTransaction>? transactions,
    List<LoyaltyReward>? redeemedRewards,
    DateTime? lastRedeemed,
  }) {
    return Loyalty(
      points: points ?? this.points,
      transactions: transactions ?? this.transactions,
      redeemedRewards: redeemedRewards ?? this.redeemedRewards,
      lastRedeemed: lastRedeemed ?? this.lastRedeemed,
    );
  }

  factory Loyalty.fromMap(Map<String, dynamic> map) {
    final pts = (map['points'] as num?)?.toInt() ?? 0;
    final txns = (map['transactions'] as List?)
            ?.map((e) =>
                LoyaltyTransaction.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        <LoyaltyTransaction>[];
    final rewards = (map['redeemedRewards'] as List?)
            ?.map((e) =>
                LoyaltyReward.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        <LoyaltyReward>[];

    // If lastRedeemed exists, use it; otherwise, derive from rewards.
    DateTime? lastRedeemed;
    if (map.containsKey('lastRedeemed')) {
      lastRedeemed = (map['lastRedeemed'] as Timestamp?)?.toDate();
    } else if (rewards.isNotEmpty) {
      lastRedeemed = rewards.last.timestamp;
    }

    return Loyalty(
      points: pts,
      transactions: txns,
      redeemedRewards: rewards,
      lastRedeemed: lastRedeemed,
    );
  }

  Map<String, dynamic> toMap() => {
        'points': points,
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'redeemedRewards': redeemedRewards.map((r) => r.toMap()).toList(),
        'lastRedeemed': Timestamp.fromDate(lastRedeemed),
      };
}

class LoyaltyTransaction {
  final int points;
  final String orderId;
  final DateTime timestamp;

  LoyaltyTransaction({
    required this.points,
    required this.orderId,
    required this.timestamp,
  });

  LoyaltyTransaction copyWith({
    int? points,
    String? orderId,
    DateTime? timestamp,
  }) {
    return LoyaltyTransaction(
      points: points ?? this.points,
      orderId: orderId ?? this.orderId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory LoyaltyTransaction.fromMap(Map<String, dynamic> map) =>
      LoyaltyTransaction(
        points: (map['points'] as num?)?.toInt() ?? 0,
        orderId: map['orderId'] as String? ?? '',
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'points': points,
        'orderId': orderId,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

class LoyaltyReward {
  final String name;
  final int requiredPoints;
  final bool claimed;
  final DateTime? claimedAt;
  final DateTime timestamp;

  LoyaltyReward({
    required this.name,
    required this.requiredPoints,
    required this.claimed,
    required this.timestamp,
    this.claimedAt,
  });

  LoyaltyReward copyWith({
    String? name,
    int? requiredPoints,
    bool? claimed,
    DateTime? claimedAt,
    DateTime? timestamp,
  }) {
    return LoyaltyReward(
      name: name ?? this.name,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      claimed: claimed ?? this.claimed,
      timestamp: timestamp ?? this.timestamp,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }

  factory LoyaltyReward.fromMap(Map<String, dynamic> map) {
    final ts = (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final ca = (map['claimedAt'] as Timestamp?)?.toDate();
    final claimed = ca != null;
    return LoyaltyReward(
      name: map['name'] as String? ?? '',
      requiredPoints: (map['points'] as num?)?.toInt() ?? 0,
      claimed: claimed,
      timestamp: ts,
      claimedAt: ca,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'points': requiredPoints,
        'timestamp': Timestamp.fromDate(timestamp),
        if (claimedAt != null) 'claimedAt': Timestamp.fromDate(claimedAt!),
      };
}
