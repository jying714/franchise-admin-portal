import 'package:cloud_firestore/cloud_firestore.dart';

class Promo {
  final String id;
  final String name; // Human-readable promo name
  final String description; // Human-readable description
  final String code; // Optional promo code string
  final String type; // Discount type (e.g. 'percent', 'amount', etc)
  final List<String> items; // List of item IDs or categories promo applies to
  final double discount; // Discount value
  final int maxUses;
  final String maxUsesType;
  final double minOrderValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;
  final Segment? target;
  final TimeRule? timeRules;

  Promo({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
    required this.type,
    required this.items,
    required this.discount,
    required this.maxUses,
    required this.maxUsesType,
    required this.minOrderValue,
    required this.startDate,
    required this.endDate,
    required this.active,
    this.target,
    this.timeRules,
  });

  // Useful for export and admin logic
  List<String> get applicableItems => items;

  // Flat segment for export/compatibility
  String? get segment => target?.segment;

  // For export compatibility with codebases that expect these:
  String get promoName => name;
  String get promoDescription => description;
  String get promoCode => code;

  factory Promo.fromFirestore(Map<String, dynamic> data, String id) {
    return Promo(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      code: data['code'] ?? '',
      type: data['type'] ?? '',
      items: (data['items'] as List<dynamic>?)?.cast<String>() ?? [],
      discount: (data['discount'] ?? 0.0).toDouble(),
      maxUses: data['maxUses'] ?? 0,
      maxUsesType: data['maxUsesType'] ?? '',
      minOrderValue: (data['minOrderValue'] ?? 0.0).toDouble(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: data['active'] ?? false,
      target: data['target'] != null ? Segment.fromMap(data['target']) : null,
      timeRules: data['timeRules'] != null
          ? TimeRule.fromMap(data['timeRules'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'code': code,
      'type': type,
      'items': items,
      'discount': discount,
      'maxUses': maxUses,
      'maxUsesType': maxUsesType,
      'minOrderValue': minOrderValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'active': active,
      'target': target?.toMap(),
      'timeRules': timeRules?.toMap(),
    };
  }

  Promo copyWith({
    String? id,
    String? name,
    String? description,
    String? code,
    String? type,
    List<String>? items,
    double? discount,
    int? maxUses,
    String? maxUsesType,
    double? minOrderValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    Segment? target,
    TimeRule? timeRules,
  }) {
    return Promo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      type: type ?? this.type,
      items: items ?? List<String>.from(this.items),
      discount: discount ?? this.discount,
      maxUses: maxUses ?? this.maxUses,
      maxUsesType: maxUsesType ?? this.maxUsesType,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      target: target ?? this.target,
      timeRules: timeRules ?? this.timeRules,
    );
  }
}

class Segment {
  final String segment;
  final dynamic value;

  Segment({required this.segment, required this.value});

  factory Segment.fromMap(Map<String, dynamic> data) {
    return Segment(
      segment: data['segment'] ?? '',
      value: data['value'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'segment': segment,
      'value': value,
    };
  }
}

class TimeRule {
  final String startTime;
  final String endTime;
  final double discount;

  TimeRule({
    required this.startTime,
    required this.endTime,
    required this.discount,
  });

  factory TimeRule.fromMap(Map<String, dynamic> data) {
    return TimeRule(
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      discount: (data['discount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'discount': discount,
    };
  }
}
