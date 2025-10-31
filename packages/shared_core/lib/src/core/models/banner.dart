import 'package:cloud_firestore/cloud_firestore.dart';

class Banner {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final Action action;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;

  Banner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.action,
    required this.startDate,
    required this.endDate,
    required this.active,
  });

  factory Banner.fromFirestore(Map<String, dynamic> data, String id) {
    return Banner(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      image: data['image'] ?? '',
      action: Action.fromMap(data['action'] ?? {}),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: data['active'] ?? false,
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
    };
  }
}

class Action {
  final String type;
  final String? value;
  final String? ctaText; // <-- Modular CTA text

  Action({
    required this.type,
    this.value,
    this.ctaText,
  });

  factory Action.fromMap(Map<String, dynamic> data) {
    return Action(
      type: data['type'] ?? 'none',
      value: data['value'],
      ctaText: data['ctaText'],
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
