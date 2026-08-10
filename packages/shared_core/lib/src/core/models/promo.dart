import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical promotion kinds written by Admin and evaluated by PromoPricing.
class PromoType {
  PromoType._();

  static const String percent = 'percent';
  static const String amount = 'amount';
  static const String itemPercent = 'item_percent';
  static const String itemAmount = 'item_amount';
  static const String bogo = 'bogo';
  static const String freeItem = 'free_item';
  static const String delivery = 'delivery';

  static const List<String> all = <String>[
    percent,
    amount,
    itemPercent,
    itemAmount,
    bogo,
    freeItem,
    delivery,
  ];

  static String normalize(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    switch (t) {
      case percent:
      case 'percentage':
      case 'pct':
      case '%':
        return percent;
      case amount:
      case 'fixed':
      case 'flat':
      case 'dollar':
      case 'dollars':
        return amount;
      case itemPercent:
      case 'item-percent':
      case 'item%':
        return itemPercent;
      case itemAmount:
      case 'item-amount':
      case 'item_fixed':
        return itemAmount;
      case bogo:
      case 'buy_one_get_one':
      case 'bxgy':
        return bogo;
      case freeItem:
      case 'free-item':
      case 'freeitem':
        return freeItem;
      case delivery:
      case 'delivery_fee':
      case 'free_delivery':
        return delivery;
      default:
        // Legacy free-text / numeric junk → amount
        return amount;
    }
  }

  static String label(String type) {
    switch (normalize(type)) {
      case percent:
        return '% off order';
      case amount:
        return '\$ off order';
      case itemPercent:
        return '% off items';
      case itemAmount:
        return '\$ off items';
      case bogo:
        return 'Buy X get Y';
      case freeItem:
        return 'Free item';
      case delivery:
        return 'Delivery deal';
      default:
        return type;
    }
  }
}

class PromoMaxUsesType {
  PromoMaxUsesType._();

  static const String total = 'total';
  static const String perUser = 'per_user';

  static const List<String> all = <String>[total, perUser];

  static String normalize(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    if (t == perUser || t == 'per-user' || t == 'user') return perUser;
    return total;
  }
}

/// How BOGO picks which units get the discount.
class BogoApplyTo {
  BogoApplyTo._();

  static const String cheapest = 'cheapest';
  static const String mostExpensive = 'most_expensive';
  static const String sameItem = 'same_item';

  static const List<String> all = <String>[
    cheapest,
    mostExpensive,
    sameItem,
  ];

  static String normalize(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    if (t == mostExpensive || t == 'expensive' || t == 'highest') {
      return mostExpensive;
    }
    if (t == sameItem || t == 'same' || t == 'matching') {
      return sameItem;
    }
    return cheapest;
  }
}

/// Delivery discount mode when [Promo.type] is [PromoType.delivery].
class DeliveryDiscountType {
  DeliveryDiscountType._();

  static const String free = 'free';
  static const String amount = 'amount';
  static const String percent = 'percent';

  static const List<String> all = <String>[free, amount, percent];

  static String normalize(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    if (t == amount || t == 'fixed') return amount;
    if (t == percent || t == 'pct') return percent;
    return free;
  }
}

/// Franchise promotion (`franchises/{id}/promotions/{id}`).
class Promo {
  final String id;
  final String name;
  final String description;

  /// Uppercase redemption code (empty = display / auto later).
  final String code;

  /// One of [PromoType.all].
  final String type;

  /// Legacy/generic scope: menu item or category ids (also merged into qualify*).
  final List<String> items;

  /// % points or currency amount for percent/amount/item_* types.
  final double discount;

  final int maxUses;
  final String maxUsesType;
  final double minOrderValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;

  /// Local daypart (happy hour). Empty [daysOfWeek] = every day.
  /// Days: 1=Mon … 7=Sun (DateTime.weekday).
  final List<int> daysOfWeek;

  /// "HH:mm" 24h local, inclusive start. Null = no time window.
  final String? daypartStart;

  /// "HH:mm" 24h local, inclusive end. Null = no time window.
  final String? daypartEnd;

  final String? imageUrl;
  final int sortOrder;
  final List<String> channels;

  /// Qualification (item / BOGO / free-item gates).
  final List<String> qualifyMenuItemIds;
  final List<String> qualifyCategoryIds;
  final List<String> qualifySizeLabels;
  final int? qualifyMinToppings;
  final int? qualifyMaxToppings;
  final List<String> excludeMenuItemIds;

  /// BOGO
  final int bogoBuyQty;
  final int bogoGetQty;
  final double bogoGetDiscountPct;
  final String bogoApplyTo;

  /// Free item
  final String? freeMenuItemId;
  final double? freeItemMaxPrice;

  /// Delivery deal
  final String deliveryDiscountType;
  final double deliveryDiscountValue;

  final bool stackable;
  final int priority;

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
    this.daysOfWeek = const <int>[],
    this.daypartStart,
    this.daypartEnd,
    this.imageUrl,
    this.sortOrder = 0,
    this.channels = const <String>[],
    this.qualifyMenuItemIds = const <String>[],
    this.qualifyCategoryIds = const <String>[],
    this.qualifySizeLabels = const <String>[],
    this.qualifyMinToppings,
    this.qualifyMaxToppings,
    this.excludeMenuItemIds = const <String>[],
    this.bogoBuyQty = 1,
    this.bogoGetQty = 1,
    this.bogoGetDiscountPct = 50,
    this.bogoApplyTo = BogoApplyTo.cheapest,
    this.freeMenuItemId,
    this.freeItemMaxPrice,
    this.deliveryDiscountType = DeliveryDiscountType.free,
    this.deliveryDiscountValue = 0,
    this.stackable = false,
    this.priority = 0,
    this.target,
    this.timeRules,
  });

  List<String> get applicableItems => items;

  String? get segment => target?.segment;

  String get promoName => name;
  String get promoDescription => description;
  String get promoCode => code;

  bool get isPercent => type == PromoType.percent;
  bool get isAmount => type == PromoType.amount;
  bool get isItemPercent => type == PromoType.itemPercent;
  bool get isItemAmount => type == PromoType.itemAmount;
  bool get isBogo => type == PromoType.bogo;
  bool get isFreeItem => type == PromoType.freeItem;
  bool get isDelivery => type == PromoType.delivery;

  bool isLiveAt(DateTime now) {
    if (!active) return false;
    final n = DateTime(now.year, now.month, now.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    if (n.isBefore(s) || n.isAfter(e)) return false;
    return isDaypartActiveAt(now);
  }

  /// Day-of-week + HH:mm window. Empty days = all days; null times = all day.
  bool isDaypartActiveAt(DateTime now) {
    if (daysOfWeek.isNotEmpty && !daysOfWeek.contains(now.weekday)) {
      return false;
    }
    final start = daypartStart?.trim();
    final end = daypartEnd?.trim();
    if (start == null || start.isEmpty || end == null || end.isEmpty) {
      return true;
    }
    final nowM = now.hour * 60 + now.minute;
    final startM = _parseHhMm(start);
    final endM = _parseHhMm(end);
    if (startM == null || endM == null) return true;
    if (startM <= endM) {
      return nowM >= startM && nowM <= endM;
    }
    // Overnight window (e.g. 22:00–02:00)
    return nowM >= startM || nowM <= endM;
  }

  static int? _parseHhMm(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  bool isAvailableOnChannel(String channel) {
    if (channels.isEmpty) return true;
    final c = channel.trim().toLowerCase();
    return channels.map((e) => e.trim().toLowerCase()).contains(c);
  }

  /// Combined item id scope: explicit qualify list + legacy [items].
  List<String> get effectiveMenuItemIds {
    final out = <String>{
      ...qualifyMenuItemIds,
      ...items,
    };
    return out.toList();
  }

  /// Simple cart % / $ helper (no line rules). Prefer PromoPricing for full types.
  double computeSimpleCartDiscount(double subtotal) {
    if (subtotal <= 0 || discount <= 0) return 0.0;
    if (minOrderValue > 0 && subtotal < minOrderValue) return 0.0;
    if (type != PromoType.percent && type != PromoType.amount) return 0.0;
    double raw;
    if (isPercent) {
      raw = subtotal * (discount.clamp(0.0, 100.0) / 100.0);
    } else {
      raw = discount;
    }
    if (raw > subtotal) raw = subtotal;
    return (raw * 100).roundToDouble() / 100.0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static List<String> _asStringList(dynamic v) {
    if (v is! List) return const <String>[];
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  factory Promo.fromFirestore(Map<String, dynamic> data, String id) {
    final nameRaw = (data['name'] as String?)?.trim() ?? '';
    final titleRaw = (data['title'] as String?)?.trim() ?? '';
    final name = nameRaw.isNotEmpty ? nameRaw : titleRaw;

    final type = PromoType.normalize(data['type'] as String?);

    var discount = _asDouble(data['discount']);
    if (discount <= 0) {
      final legacy = _asDouble(data['value']);
      if (legacy > 0) discount = legacy;
    }

    var minOrder = _asDouble(data['minOrderValue']);
    if (minOrder <= 0 && data['rules'] is Map) {
      final rules = Map<String, dynamic>.from(data['rules'] as Map);
      minOrder = _asDouble(rules['minOrder'] ?? rules['minOrderValue']);
    }

    final code = ((data['code'] as String?) ?? '').trim().toUpperCase();
    final image = (data['imageUrl'] as String?)?.trim() ??
        (data['image'] as String?)?.trim();

    return Promo(
      id: id,
      name: name,
      description: (data['description'] as String?) ?? '',
      code: code,
      type: type,
      items: _asStringList(data['items']),
      discount: discount,
      maxUses: _asInt(data['maxUses']),
      maxUsesType: PromoMaxUsesType.normalize(data['maxUsesType'] as String?),
      minOrderValue: minOrder,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: data['active'] == true,
      daysOfWeek: () {
        final raw = data['daysOfWeek'];
        if (raw is! List) return const <int>[];
        return raw
            .map((e) => e is int ? e : int.tryParse('$e'))
            .whereType<int>()
            .where((d) => d >= 1 && d <= 7)
            .toList();
      }(),
      daypartStart: (data['daypartStart'] as String?)?.trim().isNotEmpty == true
          ? (data['daypartStart'] as String).trim()
          : null,
      daypartEnd: (data['daypartEnd'] as String?)?.trim().isNotEmpty == true
          ? (data['daypartEnd'] as String).trim()
          : null,
      imageUrl: (image != null && image.isNotEmpty) ? image : null,
      sortOrder: _asInt(data['sortOrder']),
      channels: _asStringList(data['channels']),
      qualifyMenuItemIds: _asStringList(data['qualifyMenuItemIds']),
      qualifyCategoryIds: _asStringList(data['qualifyCategoryIds']),
      qualifySizeLabels: _asStringList(data['qualifySizeLabels']),
      qualifyMinToppings: data['qualifyMinToppings'] == null
          ? null
          : _asInt(data['qualifyMinToppings']),
      qualifyMaxToppings: data['qualifyMaxToppings'] == null
          ? null
          : _asInt(data['qualifyMaxToppings']),
      excludeMenuItemIds: _asStringList(data['excludeMenuItemIds']),
      bogoBuyQty: _asInt(data['bogoBuyQty'], fallback: 1).clamp(1, 99),
      bogoGetQty: _asInt(data['bogoGetQty'], fallback: 1).clamp(1, 99),
      bogoGetDiscountPct: () {
        final v = _asDouble(data['bogoGetDiscountPct']);
        return v > 0 ? v.clamp(0.0, 100.0) : 50.0;
      }(),
      bogoApplyTo: BogoApplyTo.normalize(data['bogoApplyTo'] as String?),
      freeMenuItemId:
          (data['freeMenuItemId'] as String?)?.trim().isNotEmpty == true
              ? (data['freeMenuItemId'] as String).trim()
              : null,
      freeItemMaxPrice: data['freeItemMaxPrice'] == null
          ? null
          : _asDouble(data['freeItemMaxPrice']),
      deliveryDiscountType: DeliveryDiscountType.normalize(
          data['deliveryDiscountType'] as String?),
      deliveryDiscountValue: _asDouble(data['deliveryDiscountValue']),
      stackable: data['stackable'] == true,
      priority: _asInt(data['priority']),
      target: data['target'] != null
          ? Segment.fromMap(Map<String, dynamic>.from(data['target'] as Map))
          : null,
      timeRules: data['timeRules'] != null
          ? TimeRule.fromMap(
              Map<String, dynamic>.from(data['timeRules'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'code': code.trim().toUpperCase(),
      'type': PromoType.normalize(type),
      'items': items,
      'discount': discount,
      'maxUses': maxUses,
      'maxUsesType': PromoMaxUsesType.normalize(maxUsesType),
      'minOrderValue': minOrderValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'active': active,
      'sortOrder': sortOrder,
      'channels': channels,
      if (imageUrl != null && imageUrl!.trim().isNotEmpty)
        'imageUrl': imageUrl!.trim(),
      'qualifyMenuItemIds': qualifyMenuItemIds,
      'qualifyCategoryIds': qualifyCategoryIds,
      'qualifySizeLabels': qualifySizeLabels,
      if (qualifyMinToppings != null) 'qualifyMinToppings': qualifyMinToppings,
      if (qualifyMaxToppings != null) 'qualifyMaxToppings': qualifyMaxToppings,
      'excludeMenuItemIds': excludeMenuItemIds,
      'bogoBuyQty': bogoBuyQty,
      'bogoGetQty': bogoGetQty,
      'bogoGetDiscountPct': bogoGetDiscountPct,
      'bogoApplyTo': BogoApplyTo.normalize(bogoApplyTo),
      if (freeMenuItemId != null && freeMenuItemId!.isNotEmpty)
        'freeMenuItemId': freeMenuItemId,
      if (freeItemMaxPrice != null) 'freeItemMaxPrice': freeItemMaxPrice,
      'deliveryDiscountType':
          DeliveryDiscountType.normalize(deliveryDiscountType),
      'deliveryDiscountValue': deliveryDiscountValue,
      'stackable': stackable,
      'priority': priority,
      'target': target?.toMap(),
      'timeRules': timeRules?.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'daysOfWeek': daysOfWeek,
      if (daypartStart != null && daypartStart!.isNotEmpty)
        'daypartStart': daypartStart,
      if (daypartEnd != null && daypartEnd!.isNotEmpty)
        'daypartEnd': daypartEnd,
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
    String? imageUrl,
    int? sortOrder,
    List<String>? channels,
    List<String>? qualifyMenuItemIds,
    List<String>? qualifyCategoryIds,
    List<String>? qualifySizeLabels,
    int? qualifyMinToppings,
    int? qualifyMaxToppings,
    List<String>? excludeMenuItemIds,
    int? bogoBuyQty,
    int? bogoGetQty,
    double? bogoGetDiscountPct,
    String? bogoApplyTo,
    String? freeMenuItemId,
    double? freeItemMaxPrice,
    String? deliveryDiscountType,
    double? deliveryDiscountValue,
    bool? stackable,
    int? priority,
    Segment? target,
    TimeRule? timeRules,
    List<int>? daysOfWeek,
    String? daypartStart,
    String? daypartEnd,
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
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      channels: channels ?? List<String>.from(this.channels),
      qualifyMenuItemIds:
          qualifyMenuItemIds ?? List<String>.from(this.qualifyMenuItemIds),
      qualifyCategoryIds:
          qualifyCategoryIds ?? List<String>.from(this.qualifyCategoryIds),
      qualifySizeLabels:
          qualifySizeLabels ?? List<String>.from(this.qualifySizeLabels),
      qualifyMinToppings: qualifyMinToppings ?? this.qualifyMinToppings,
      qualifyMaxToppings: qualifyMaxToppings ?? this.qualifyMaxToppings,
      excludeMenuItemIds:
          excludeMenuItemIds ?? List<String>.from(this.excludeMenuItemIds),
      bogoBuyQty: bogoBuyQty ?? this.bogoBuyQty,
      bogoGetQty: bogoGetQty ?? this.bogoGetQty,
      bogoGetDiscountPct: bogoGetDiscountPct ?? this.bogoGetDiscountPct,
      bogoApplyTo: bogoApplyTo ?? this.bogoApplyTo,
      freeMenuItemId: freeMenuItemId ?? this.freeMenuItemId,
      freeItemMaxPrice: freeItemMaxPrice ?? this.freeItemMaxPrice,
      deliveryDiscountType: deliveryDiscountType ?? this.deliveryDiscountType,
      deliveryDiscountValue:
          deliveryDiscountValue ?? this.deliveryDiscountValue,
      stackable: stackable ?? this.stackable,
      priority: priority ?? this.priority,
      target: target ?? this.target,
      timeRules: timeRules ?? this.timeRules,
      daysOfWeek: daysOfWeek ?? List<int>.from(this.daysOfWeek),
      daypartStart: daypartStart ?? this.daypartStart,
      daypartEnd: daypartEnd ?? this.daypartEnd,
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
