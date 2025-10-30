import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String level;
  final String icon;
  final DateTime createdAt;
  final DateTime? dismissedAt;
  final String franchiseId;
  final String? locationId;
  final Map<String, dynamic> customFields;
  final List<String> seenBy;

  AlertModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.level,
    required this.icon,
    required this.createdAt,
    required this.franchiseId,
    this.locationId,
    this.dismissedAt,
    this.customFields = const {},
    this.seenBy = const [],
  });

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      level: data['level'] ?? 'info',
      icon: data['icon'] ?? 'info',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      dismissedAt: data['dismissed_at'] != null
          ? (data['dismissed_at'] as Timestamp).toDate()
          : null,
      franchiseId: _extractIdFromDocRef(data['franchiseId']),
      locationId: data['locationId'] != null
          ? _extractIdFromDocRef(data['locationId'])
          : null,
      customFields: Map<String, dynamic>.from(data['custom_fields'] ?? {}),
      seenBy: (data['seen_by'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static String _extractIdFromDocRef(dynamic ref) {
    if (ref == null) return '';
    if (ref is String) return ref;
    if (ref is Map && ref.containsKey('path')) {
      return ref['path'].split('/').last;
    }
    return '';
  }
}
