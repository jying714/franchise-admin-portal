import 'package:cloud_firestore/cloud_firestore.dart';

/// Home / menu marketing slide (`franchises/{id}/banners/{id}`).
class Banner {
  final String id;
  final String title;
  final String subtitle;

  /// Image URL (Firebase Storage or CDN).
  final String image;

  final Action action;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;

  /// Lower sorts first in the carousel.
  final int sortOrder;

  Banner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.action,
    required this.startDate,
    required this.endDate,
    required this.active,
    this.sortOrder = 0,
  });

  bool isLiveAt(DateTime now) {
    if (!active) return false;
    final n = DateTime(now.year, now.month, now.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !n.isBefore(s) && !n.isAfter(e);
  }

  factory Banner.fromFirestore(Map<String, dynamic> data, String id) {
    final sortRaw = data['sortOrder'];
    final sortOrder = sortRaw is int
        ? sortRaw
        : sortRaw is num
            ? sortRaw.toInt()
            : int.tryParse('$sortRaw') ?? 0;

    return Banner(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      image: data['image'] ?? data['imageUrl'] ?? '',
      action: Action.fromMap(
        data['action'] is Map
            ? Map<String, dynamic>.from(data['action'] as Map)
            : const <String, dynamic>{},
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: data['active'] == true,
      sortOrder: sortOrder,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'image': image,
      'action': action.toMap(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'active': active,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Banner copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? image,
    Action? action,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    int? sortOrder,
  }) {
    return Banner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      image: image ?? this.image,
      action: action ?? this.action,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Banner CTA.
///
/// Known [type] values:
/// - `none`
/// - `linkCategory` — [value] = categoryId
/// - `linkItem` — [value] = menuItemId
/// - `promo` — [value] = promo code (uppercase)
/// - `url` — [value] = https URL (web)
class Action {
  final String type;
  final String? value;
  final String? ctaText;

  Action({
    required this.type,
    this.value,
    this.ctaText,
  });

  factory Action.fromMap(Map<String, dynamic> data) {
    return Action(
      type: (data['type'] as String?)?.trim().isNotEmpty == true
          ? (data['type'] as String).trim()
          : 'none',
      value: data['value'] as String?,
      ctaText: data['ctaText'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      if (ctaText != null && ctaText!.isNotEmpty) 'ctaText': ctaText,
    };
  }
}
