// lib/core/models/report.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final DocumentReference franchiseRef;
  final String type; // financial, tax, performance, etc.
  final DateTime? generatedAt;
  final String? generatedBy;
  final String fileUrl;
  final Map<String, dynamic> meta;
  final Map<String, dynamic> customFields;

  Report({
    required this.id,
    required this.franchiseRef,
    required this.type,
    this.generatedAt,
    this.generatedBy,
    required this.fileUrl,
    this.meta = const {},
    this.customFields = const {},
  });

  factory Report.fromFirestore(Map<String, dynamic> data, String id) {
    return Report(
      id: id,
      franchiseRef: data['franchiseId'] as DocumentReference,
      type: data['type'] ?? '',
      generatedAt: (data['generated_at'] as Timestamp?)?.toDate(),
      generatedBy: data['generated_by'],
      fileUrl: data['file_url'] ?? '',
      meta: data['meta'] ?? {},
      customFields: data['custom_fields'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseRef,
      'type': type,
      'generated_at':
          generatedAt != null ? Timestamp.fromDate(generatedAt!) : null,
      'generated_by': generatedBy,
      'file_url': fileUrl,
      'meta': meta,
      'custom_fields': customFields,
    };
  }

  Report copyWith({
    String? id,
    DocumentReference? franchiseRef,
    String? type,
    DateTime? generatedAt,
    String? generatedBy,
    String? fileUrl,
    Map<String, dynamic>? meta,
    Map<String, dynamic>? customFields,
  }) {
    return Report(
      id: id ?? this.id,
      franchiseRef: franchiseRef ?? this.franchiseRef,
      type: type ?? this.type,
      generatedAt: generatedAt ?? this.generatedAt,
      generatedBy: generatedBy ?? this.generatedBy,
      fileUrl: fileUrl ?? this.fileUrl,
      meta: meta ?? this.meta,
      customFields: customFields ?? this.customFields,
    );
  }
}
